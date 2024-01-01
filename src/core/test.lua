-------------------------------------------------------------------------------
---@script: test.lua
---@author: zimawhit3
---@desc:   This module implements testing mode.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...
local L             = Constants.L
local LibStub       = LibStub
local DRList 		= LibStub( "DRList-1.0" )

-----------------------------------------
--                Lua
-----------------------------------------
local mceil     = math.ceil
local mfloor    = math.floor
local mrand     = math.random
local tinsert   = table.insert
local tremove   = table.remove

-----------------------------------------
--              Blizzard
-----------------------------------------
local CTimerNewTicker                   = C_Timer.NewTicker
local GetNumSpellTabs                   = GetNumSpellTabs
local GetSpellBookItemName              = GetSpellBookItemName
local GetSpellInfo                      = GetSpellInfo
local GetSpellTabInfo                   = GetSpellTabInfo
local GetTime                           = GetTime
local IsClassic                         = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsSpellKnown                      = IsSpellKnown
local UnitHealthMax                     = UnitHealthMax
local wipe                              = wipe

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                   Test Mode
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------
local AURA_FILTERS          = { "HELPFUL", "HARMFUL" };
local TEST_UPDATE_PERIOD    = 1;

----------------------------------------
--                Private
----------------------------------------

---
--- @type table<EnemyFrame, integer>
---
--- Fake max healths defined for `EnemyFrame`s.
---
local max_healths = {};

---
--- @type EnemyFrame?
---
--- The previous enemy holding the fake objective.
---
local old_obj_holder = nil;

---
--- @type EnemyFrame?
---
--- The current enemy holding the fake objective.
---
local curr_obj_holder = nil;

---
--- Creates a new aura for use by the testing mode.
---
--- @param filter any
--- @return AuraData?
---
local function CreateFakeAura( filter )

    local found_auras = Constants.FoundAuras[ filter ];

    local aura_table, add_DR_aura;
    if filter == "HARMFUL" then
        --
        -- 20% probability to get diminishing Aura Applied
        --
        add_DR_aura = mrand( 1, 5 ) == 1;
    end

    local unit_caster, can_apply_aura, cast_by_player;

    if add_DR_aura and #found_auras.foundDRAuras > 0 then
        aura_table = found_auras.foundDRAuras;

    else
        --
        -- 20% probablility to add a player Aura if no DR was applied
        --
        if mrand( 1, 5 ) == 1 then
            unit_caster     = "player";
            can_apply_aura  = true;
            cast_by_player  = true;
            aura_table      = found_auras.foundPlayerAuras;

        else
            aura_table      = found_auras.foundNonPlayerAuras;

        end
    end

    if not aura_table or ( #aura_table < 1 ) then
        return;
    end

    local aura_to_send = aura_table[ mrand( 1, #aura_table ) ];

    --
    -- This spellID does not existing in this version of the game
    --
    if not GetSpellInfo( aura_to_send.spellId ) then
        return;
    end

    local new_aura =
    {
        applications            = aura_to_send.applications,
        name                    = GetSpellInfo( aura_to_send.spellId ),
        auraInstanceID          = nil,
        canApplyAura            = can_apply_aura or aura_to_send.canApplyAura,
        charges	                = nil,
        dispelName              = aura_to_send.dispelName,
        duration                = aura_to_send.duration,
        expirationTime          = GetTime() + aura_to_send.duration,
        icon                    = aura_to_send.icon,
        isBossAura              = aura_to_send.isBossAura,
        isFromPlayerOrPlayerPet = cast_by_player or aura_to_send.isFromPlayerOrPlayerPet,
        isHarmful               = filter == "HARMFUL",
        isHelpful               = filter == "HELPFUL",
        isNameplateOnly	        = nil,
        isRaid                  = nil,
        isStealable	            = aura_to_send.isStealable,
        maxCharges              = nil,
        nameplateShowAll        = aura_to_send.nameplateShowAll,
        nameplateShowPersonal   = aura_to_send.nameplateShowPersonal,
        --
        -- Some auras return additional values that typically correspond to something 
        -- shown in the tooltip, such as the remaining strength of an absorption effect.
        --
        points = nil,
        sourceUnit = unit_caster or aura_to_send.sourceUnit,
        spellId	= aura_to_send.spellId,
        timeMod	= aura_to_send.timeMod
    };

    return new_aura;
end

---
---
---
--- @param scores PVPScoreInfo[]
--- @param faction number
---
local function IsValidClassicRaceClass( scores, faction )
    if not IsClassic then
        return true;
    end

    local score = scores[ faction ];

    if ( faction == 1 and score.raceName == "Blood Elf" ) or
       ( faction == 0 and score.raceName == "Draenei" ) then
        return false;
    end

    if faction == 0 and score.className == "SHAMAN" or score.className == "PALADIN" then
        return false;
    end

    return true;
end

---
--- Create fake auras for the `EnemyFrame` and update existing auras.
---
--- @param enemy_frame EnemyFrame
---
local function UpdateFakeAuras( enemy_frame )
	local current_time  = GetTime();
    local fake_auras    = Vantage.TestingMode.fake_auras;
	local fake_drs      = Vantage.TestingMode.fake_drs;
    local enemy_name    = enemy_frame.player_info.name;

	fake_auras[ enemy_name ] = fake_auras[ enemy_name ] or {};

    local filter;
	for i = 1, #AURA_FILTERS do

        filter                              = AURA_FILTERS[ i ];
		fake_auras[ enemy_name ][ filter ]  = fake_auras[ enemy_name ][ filter ] or {};
		fake_drs[ enemy_name ]              = fake_drs[ enemy_name ] or {};

        --
        -- Add new auras
        --
		if enemy_frame.player_info.alive then
			local new_fake_aura = CreateFakeAura( filter );
			if new_fake_aura then

                ---@diagnostic disable-next-line: undefined-field
                local new_aura_cat = DRList:GetCategoryBySpellID( IsClassic and new_fake_aura.name or new_fake_aura.spellId );
				local no_new_auras = false;

				for j = 1, #fake_auras[ enemy_name ][ filter ] do

					local fake_aura = fake_auras[ enemy_name ][ filter ][ j ];

                    ---@diagnostic disable-next-line: undefined-field
					local current_aura_cat = DRList:GetCategoryBySpellID( IsClassic and fake_aura.name or fake_aura.spellId );

					if current_aura_cat and new_aura_cat and current_aura_cat == new_aura_cat then
						no_new_auras = true;
						break;
                    --
                    -- We tried to apply the same spell twice but its not a DR, dont add it, we dont wan't to clutter it
					--
                    elseif new_fake_aura.spellId == fake_aura.spellId then
						no_new_auras = true;
						break;
					end
				end

				local status = fake_drs[ enemy_name ][ new_aura_cat ] and fake_drs[ enemy_name ][ new_aura_cat ].status;

                --
                -- Check if the aura even can be applied - The new aura can only be applied if 
                -- the `expirationTime` of the new aura would be later than the current one.
                -- 
				-- This is only the case if the aura is already 50% expired.
				--
                if status then
					if status <= 2 then
						local duration = new_fake_aura.duration / ( 2 ^ status );
						new_fake_aura.duration          = duration;
						new_fake_aura.expirationTime    = current_time + duration;

                    --
                    -- We are at full DR and we can't apply the aura for a fourth time.
                    --
                    else
						no_new_auras = true;

					end
				end

				if not no_new_auras then
					tinsert( fake_auras[ enemy_name ][ filter ], new_fake_aura );
				end
			end
		end

        --
		-- Remove all expired auras
		--
        for j = #fake_auras[ enemy_name ][ filter ], 1, -1 do

            local fake_aura = fake_auras[ enemy_name ][ filter ][ j ];
			if fake_aura.expirationTime <= current_time then

                ---@diagnostic disable-next-line: undefined-field
				local category = DRList:GetCategoryBySpellID( IsClassic and fake_aura.name or fake_aura.spellId );
				if category then
                    fake_drs[ enemy_name ][ category ]                   = fake_drs[ enemy_name ][ category ] or {};
                    ---@diagnostic disable-next-line: undefined-field
					fake_drs[ enemy_name ][ category ].expirationTime    = fake_aura.expirationTime + DRList:GetResetTime( category );
					fake_drs[ enemy_name ][ category ].status            = ( fake_drs[ enemy_name ][ category ].status or 0 ) + 1;
				end

				tremove( fake_auras[ enemy_name ][ filter ], j );
                enemy_frame.modules.drtracker:AuraRemoved( fake_aura.spellId );
			end
		end
	end

    --
	-- Set all expired DRs to status 0
	--
    for _, dr in pairs( fake_drs[ enemy_name ] ) do
		if dr.expirationTime and dr.expirationTime <= current_time then
			dr.status           = 0;
			dr.expirationTime   = nil;
		end
	end

	enemy_frame:FAKE_UNIT_AURA();

end

---
--- The testing mode's fake OnUpdate. This will simulate
--- events and effects on `EnemyFrame`s.
---
local function FakeOnUpdate()

    local has_flag          = false;
    local range_supported   = Vantage.Database.profile.Enemies.RangeIndicator_Enabled;
    for _, enemy_frame in pairs( Vantage.EnemyFrames ) do

        if enemy_frame.player_info.alive then

            local n = mrand( 1, 7 );

            --
            -- Simulate objective
            --
            if ( Vantage.BattleGroundSize == 15 or Vantage.BattleGroundSize == 10 ) and n == 1 and ( not has_flag ) then
                --
                -- Hide old flag carrier
                --
                old_obj_holder = curr_obj_holder;
                if old_obj_holder and old_obj_holder.player_info.alive then
                    old_obj_holder:ToggleObjective();
                end
                enemy_frame:ToggleObjective();

                curr_obj_holder = enemy_frame;
                has_flag        = true;

            --
            -- Simulate racial
            --
            elseif n == 2 and enemy_frame.modules.racial.cooldown:GetCooldownDuration() == 0 then
                if enemy_frame.player_info.race == "Human" and enemy_frame.modules.trinket.cooldown:GetCooldownDuration() == 0 then
                    enemy_frame:SPELL_CAST_SUCCESS(
                        enemy_frame.player_info.name,
                        "",
                        Constants.GetRacialSpellID( enemy_frame.player_info.race, enemy_frame.player_info.class )
                    );
                else
                    enemy_frame:SPELL_CAST_SUCCESS(
                        enemy_frame.player_info.name,
                        "",
                        Constants.GetRacialSpellID( enemy_frame.player_info.race, enemy_frame.player_info.class )
                    );
                end
            --
            -- Simulate trinket
            --
            elseif n == 3 and enemy_frame.modules.trinket.cooldown:GetCooldownDuration() == 0 then
                enemy_frame:SPELL_CAST_SUCCESS( enemy_frame.player_info.name, "", IsClassic and 23273 or 42292 );

            --
            -- Simulate resource usage
            --
            elseif n == 4 then
                enemy_frame:FAKE_UNIT_POWER_FREQUENT();

            --
            -- Simulate target indicators
            --
            elseif n == 5 then
                Vantage:UpdateAllyTarget(
                    Vantage.allies[ mrand( 1, 5 ) ],
                    enemy_frame.player_info.name,
                    enemy_frame.player_info.faction
                );

            --
            -- Toggle enemy into range
            --
            elseif n == 6 then
                if range_supported then
                    enemy_frame:UpdateRange( not enemy_frame.inRange );
                end

            --
            -- Simulate combat
            --
            elseif n == 7 then
                enemy_frame.modules.combatindicator:UpdateCombatCooldown( GetTime() );

            end

            UpdateFakeAuras( enemy_frame );
            enemy_frame:FAKE_UNIT_HEALTH();
        end
    end
end

----------------------------------------
--                 Public
----------------------------------------

---
--- Create fake allies for testing mode.
---
function Vantage:CreateFakeAllies()
    --
    -- User wants to use current group members
    --
    if self.Config.Testmode_UseTeammates then
        for i = 1, GetNumGroupMembers() do
            self:AddAllyByUnitId( "party" .. i );
        end
    else
        for i = 1, 5 do
            local new_ally = self.NewPlayerFromPVPScoreInfo(
                ---@diagnostic disable-next-line: missing-fields
                {
                    name        = "Player" .. i,
                    className   = Constants.ClassList[ mrand( 1, #Constants.ClassList ) ],
                    faction     = self.PlayerInfo.faction,
                    raceName    = "Bot",
                }
            );
            tinsert( self.allies, new_ally );
        end
    end
end

---
--- Create fake enemies for testing mode.
---
function Vantage:CreateFakeEnemies()

    local count = tonumber( self.TestingMode.mode_size ) or 10;

    local num_healers, num_tanks;
    if count == 10 then
        num_healers = mrand( 2, 3 );
        num_tanks   = mrand( 0, 1 );
    elseif count == 15 then
        num_healers = mrand( 4, 5 );
        num_tanks   = mrand( 0, 3 );
    else
        num_healers = mrand( 8, 10 );
        num_tanks   = mrand( 0, 4 );
    end

    local num_dam = count - num_healers - num_tanks;
    self:CreateFakePlayerData( num_healers, "HEALER" );
    self:CreateFakePlayerData( num_tanks, "TANK" );
    self:CreateFakePlayerData( num_dam, "DAMAGER" );
end

---
--- Creates `num_players` fake players based on the `role`.
---
--- @param num_players  number
--- @param role         string
---
function Vantage:CreateFakePlayerData( num_players, role )

    local random_players    = Constants.FakePlayers[ role ];
    local selected_players  = {};

    for i = 1, num_players do
        local random_index;
        repeat
            random_index = mrand( 1, #random_players );
        until
        (
            not selected_players[ random_index ] and
            IsValidClassicRaceClass( random_players[ random_index ],  self.PlayerInfo.faction )
        );

        selected_players[ random_index ] = true;

        self:CreateEnemyFrame( random_players[ random_index ][ self.PlayerInfo.faction ] );
    end
end

---
--- Enables the testing mode.
---
function Vantage:EnableTestMode()

    Constants:LoadTestAuras();
    self.TestingMode.active = true;

    local map_ids = {};
    for map_id, _ in pairs( Constants.BattleGroundBuffs ) do
        map_ids[ #map_ids + 1] = map_id;
    end

    self.BattleGroundBuffs = Constants.BattleGroundBuffs[ map_ids[ mrand( 1, #map_ids ) ] ];

    for i = 1, #AURA_FILTERS do
        local filter        = AURA_FILTERS[ i ];
        local auras         = Constants.FakeAuras[ filter ];
        local found_auras   = Constants.FoundAuras[ filter ];
        local player_spells = {};
        local num_tabs      = GetNumSpellTabs();

        for j = 1, num_tabs do
            local name, texture, offset, numSpells = GetSpellTabInfo( j );
            for k = 1, numSpells do
                local id                = k + offset;
                local _, _, spell_id    = GetSpellBookItemName( id, 'spell' );
                if spell_id and IsSpellKnown( spell_id ) then
                    player_spells[ spell_id ] = true;
                end
            end
        end

        for spell_id, aura_details in pairs( auras ) do
            if GetSpellInfo( spell_id ) then
                ---@diagnostic disable-next-line: undefined-field
                if filter == "HARMFUL" and DRList:GetCategoryBySpellID( IsClassic and aura_details.name or spell_id ) then
                    found_auras.foundDRAuras[ #found_auras.foundDRAuras + 1 ] = aura_details;

                elseif player_spells[ spell_id ] then
                    --
                    -- this buff could be applied from the player
                    --
                    found_auras.foundPlayerAuras[ #found_auras.foundPlayerAuras + 1 ] = aura_details;

                else
                    found_auras.foundNonPlayerAuras[ #found_auras.foundNonPlayerAuras + 1 ] = aura_details;

                end
            end
        end
    end

    self.BattleGroundSize = tonumber( self.TestingMode.mode_size );
    if self.BattleGroundSize == 10 then
        self.BattleGroundStartMessage = "";
    end

    self:CreateFakeAllies();
    self:CreateFakeEnemies();
    self:ApplyAllEnemySettings();
    self:TestUpdateTimerStart();
    self:StartRezTimer();
    self:Notify( L.TestmodeEnabled );
end

---
--- Disables the testing mode, and cleans up any used resources.
---
function Vantage:DisableTestMode()

    wipe( max_healths );
    wipe( Constants.FakeAuras );
    wipe( self.TestingMode.fake_auras );
    wipe( self.TestingMode.fake_drs );
    wipe( self.allies );

    old_obj_holder                  = nil;
    curr_obj_holder                 = nil;
    self.TestingMode.active         = false;
    self.BattleGroundSize           = 0;
    self.BattleGroundStartMessage   = nil;

    self:TestUpdateTimerCancel();
	self:RemoveAllEnemyPlayers();
    self:StopRezTimer();
	self:Disable();
	self:Notify( L.TestmodeDisabled );
end

---
--- Stops the testing mode's fake OnUpdate.
---
function Vantage:TestUpdateTimerCancel()
    if self.TestingMode.update_timer then
        self.TestingMode.update_timer:Cancel();
        self.TestingMode.update_timer = nil;
    end
end

---
--- Starts the testing mode's fake OnUpdate.
---
function Vantage:TestUpdateTimerStart()
    if not self.TestingMode.update_timer then
        self.TestingMode.update_timer = CTimerNewTicker( TEST_UPDATE_PERIOD, FakeOnUpdate );
    end
end

---
--- Toggles the testing mode on or off.
---
function Vantage:ToggleTestMode()
    if not self.TestingMode.active then
        self:EnableTestMode();
    else
        self:DisableTestMode();
    end
end

---
--- Toggles the testing mode's fake OnUpdate on or off.
---
function Vantage:ToggleTestModeOnUpdate()
    if not self.TestingMode.update_timer then
        self:TestUpdateTimerStart();
    else
        self:TestUpdateTimerCancel();
    end
end

-------------------------------------------------------------------------------
--                             Fake Event Callbacks
-------------------------------------------------------------------------------

---
---
---
--- @param enemy EnemyFrame
--- @return integer
---
function Vantage:FakeUnitHealth( enemy )
    local max_health    = self:FakeUnitHealthMax( enemy );
    local health        = mrand( 0, 100 );
    if health == 0 then
        enemy:PlayerDied();
        return health;
    end
    return mfloor( ( health / 100 ) * max_health );
end

---
---
---
--- @param enemy EnemyFrame
--- @return integer
---
function Vantage:FakeUnitHealthMax( enemy )
    if not max_healths[ enemy ] then
        local my_max_health     = UnitHealthMax( "player" );
        local max_health_diff   = mrand( -15, 15 );
        max_healths[ enemy ]    = mceil( my_max_health * ( 1 + ( max_health_diff / 100 ) ) );
    end
    return max_healths[ enemy ];
end

-------------------------------------------------------------------------------
---@script: main.lua
---@author: zimawhit3
---@desc:   This module implements the main frame for the addon.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants          = ...
local BLIZZARD_SORT_ORDER   = Constants.ClassSortOrder
local LibStub               = LibStub

-----------------------------------------
--                Lua
-----------------------------------------
local ceil      = math.ceil
local fmt       = string.format
local mmax      = math.max
local strsplit  = strsplit
local tinsert   = table.insert
local tremove   = table.remove
local tsort     = table.sort

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFramePool               = CreateFramePool
local CTimerNewTicker               = C_Timer.NewTicker
local GetServerTime                 = GetServerTime
local GetUnitName                   = GetUnitName
local InCombatLockdown              = InCombatLockdown
local PLAYER_COUNT_ALLIANCE         = PLAYER_COUNT_ALLIANCE
local PLAYER_COUNT_HORDE            = PLAYER_COUNT_HORDE
local RequestBattlefieldScoreData   = RequestBattlefieldScoreData
local UnitExists                    = UnitExists
local UnitFactionGroup              = UnitFactionGroup
local UnitGUID                      = UnitGUID
local UnitIsDeadOrGhost             = UnitIsDeadOrGhost
local wipe                          = wipe

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                           Vantage MainFrame (1337 h4ckz0r)
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
--- @type integer
---
--- The interval between requesting score updates from Blizzard.
---
local REQUEST_PERIOD = 2;

---
--- @type number
---
--- The update period for updating enemy frames.
---
local UPDATE_PERIOD = .05;

-----------------------------------------
--                Types
-----------------------------------------

-----------------------------------------
--               Private
-----------------------------------------

---
--- @type cbObject?
---
local timer = nil;

---
--- A wrapper around `Vantage:ApplyAllEnemySettings` for use with a C_Timer timer.
---
local function ApplyEnemyFrameSettings()
    Vantage:ApplyAllEnemySettings();
    timer = nil;
end

---
--- A wrapper around the `RequestBattlefieldScoreData` for use with a C_Timer timer.
---
local function RequestTimer()
    RequestBattlefieldScoreData();
end

---
--- Comparison function for sorting enemies by class using the Blizzard
--- sort order.
---
--- @param a string
--- @param b string
--- @return boolean
---
local function SortEnemiesByClassName( a, b )

    local enemy_frames      = Vantage.EnemyFrames;
    local player_info_a     = enemy_frames[ a ].player_info;
    local player_info_b     = enemy_frames[ b ].player_info;
    local player_a_index    = BLIZZARD_SORT_ORDER[ player_info_a.class ];
    local player_b_index    = BLIZZARD_SORT_ORDER[ player_info_b.class ];

    if player_a_index == player_b_index and player_info_a.name < player_info_b.name then
        return true;
    end
    return player_a_index < player_b_index;
end

-----------------------------------------
--               Public
-----------------------------------------

---
--- Start the timer to apply all enemy frame settings. We use a timer to apply
--- changes are 0.2 seconds to prevent the UI from getting too laggy when the
--- user uses a slider option in the GUI.
---
function Vantage:ApplyAllSettings()
    if timer then
        timer:Cancel();
    end
	timer = CTimerNewTicker( 0.2, ApplyEnemyFrameSettings, 1 );
end

---
--- Apply all enemy frame settings based on the current battleground size.
---
--- This is mainly to be called from options.lua.
---
function Vantage:ApplyAllEnemySettings()
    if self.BattleGroundSize and self.BattleGroundSize > 0 then
        self:StartBG();
    end
end

---
--- Apply the battleground-specific configuration settings to the main frame.
---
function Vantage:ApplyBGSizeSettings()

    self.BG_Config = self.Config[ tostring( self.BattleGroundSize ) ];

    if InCombatLockdown() then
        self.QueueForUpdateAfterCombat( "ApplyBGSizeSettings", self );
        return;
    end

    self:SetSize( self.BG_Config.BarWidth, 30 );
    self:SetScale( self.BG_Config.Framescale );
    self:ClearAllPoints();

    if not self.BG_Config.Position_X and not self.BG_Config.Position_Y then
        self:SetPoint( "CENTER", UIParent, "CENTER" );
    else
        local scale = self:GetEffectiveScale();
        self:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", self.BG_Config.Position_X / scale, self.BG_Config.Position_Y / scale );
    end

    self:SetPlayerCountJustifyV( self.BG_Config.BarVerticalGrowDirection );
    self.PlayerCount:ApplyFontStringSettings( self.BG_Config.PlayerCount.Text );
    self.BattlegroundRezTimer:ApplyFontStringSettings( self.BG_Config.BattlegroundRezTimer.Text );

    --
    -- Force repositioning for setting up enemy frames.
    --
    self:SortEnemyPlayers( true );
    self:UpdatePlayerCount();
    self:CheckEnabled();
end

---
--- Position the enemy frames and their contained modules based on their
--- sorted order.
---
function Vantage:ButtonPositioning()

    local config        = self.BG_Config;
    local player_count  = #self.EnemyOrder;
    local rowsPerColumn = ceil( player_count / config.BarColumns );

    local pointX, offsetX, offsetY, pointY, relPointY, offsetDirectionX, offsetDirectionY;

    if config.BarHorizontalGrowDirection == "rightwards" then
        pointX              = "LEFT";
        offsetDirectionX    = 1;
    else
        pointX              = "RIGHT";
        offsetDirectionX    = -1;
    end

    if config.BarVerticalGrowDirection == "downwards" then
        pointY              = "TOP";
        relPointY           = "BOTTOM";
        offsetDirectionY    = -1;
    else
        pointY              = "BOTTOM";
        relPointY           = "TOP";
        offsetDirectionY    = 1;
    end

    local point         = pointY .. pointX;
    local relpoint      = relPointY .. pointX;
    local column        = 1;
    local row           = 1;
    local enemy_frame   = nil;

    for i = 1, #self.EnemyOrder do

        enemy_frame = self.EnemyFrames[ self.EnemyOrder[ i ] ];

        if column > 1 then
            offsetX = ( column - 1 ) * ( config.BarWidth + config.BarHorizontalSpacing ) * offsetDirectionX;
        else
            offsetX = 0;
        end

        if row > 1 then
            offsetY = ( row - 1 ) * ( config.BarHeight + config.BarVerticalSpacing ) * offsetDirectionY;
        else
            offsetY = 0;
        end

        enemy_frame:ClearAllPoints();
        enemy_frame:SetPoint( point, self, relpoint, offsetX, offsetY );
        enemy_frame:SetModulePositions();

        if row < rowsPerColumn then
            row     = row + 1;
        else
            column  = column + 1;
            row     = 1;
        end

    end
end

---
--- Initializes the frame pool used for EnemyFrames.
---
function Vantage:InitializeFramePool()
    self.EnemyFramePool = CreateFramePool( "Button", self, "SecureUnitButtonTemplate" );
end

---
--- Cancels the battleground score request timer.
---
function Vantage:CancelRequestTimer()
    if self.RequestScoreTimer then
        self.RequestScoreTimer:Cancel();
        self.RequestScoreTimer = nil;
    end
end

---
--- Starts the battleground score request timer.
---
function Vantage:StartBattlegroundRequestTimer()
    if not self.RequestScoreTimer then
        self.RequestScoreTimer = CTimerNewTicker( REQUEST_PERIOD, RequestTimer );
    end
end

---
--- Enable the addon if enabled for the current BG size.
---
function Vantage:CheckEnabled()
    if self.Config.Enabled and self.BattleGroundSize and self.BG_Config.Enabled then
        self:EnableFrames();
    else
        -- TODO: This will unregister from events - is that correct?
        self:DisableFrames();
    end
end

---
--- Enables the addon. 
---
--- Registers for combat events and starts the battlground request timer.
---
function Vantage:Enable()
    if self.BG_Config.Enabled then

        self:Debug( "[Vantage:Enable] Enabling addon for battleground." );

        self.enabled = true;
        self:RegisterCombatEvents();
        self:UpdateRezTimer();

        --
        -- We're in a live BG - start requesting scores
        --
        if not self.TestingMode.active then
            self:StartBattlegroundRequestTimer();
        end
    end
end

---
--- Enable and show enemy frames.
---
function Vantage:EnableFrames()
    --
    -- Test mode - We use our own fake "OnUpdate".
    --
    if self.TestingMode.active then
        self:SetScript( "OnUpdate", nil );
    else
        -- TODO: Why are these here?
        self:RegisterEvent( "NAME_PLATE_UNIT_ADDED" );
        self:SetScript( "OnUpdate", self.OnUpdateEnemyFrames );
    end
    self:Show();
end

---
--- Disable the addon.
---
--- Unregisters from combat events and cancels the battleground request timer.
---
function Vantage:Disable()
    self.enabled    = false;
    self.BG_Config  = nil;
    self:CancelRequestTimer();
    self:DisableFrames();
end

---
--- Disable and hide enemy frames.
---
function Vantage:DisableFrames()
    self:UnregisterEvents();
    self:Hide();
end

---
--- Initializes the player count fontstring.
---
function Vantage:InitializePlayerCount()
    self.PlayerCount = self.NewFontString( self );
	self.PlayerCount:SetPoint( "TOP", self, "TOP" );
    self.PlayerCount:SetJustifyH( "CENTER" );
end

---
--- Resets the Battleground structures to the default state.
---
function Vantage:ResetMapData()
    self.BattleGroundSize           = 0;
    self.BattleGroundStartMessage   = "";

    if self.BattleGroundBuffs then
        wipe( self.BattleGroundBuffs );
    end

    if self.BattleGroundDebuffs then
        wipe( self.BattleGroundDebuffs );
    end

end

---
--- Sets the positioning of the fontstrings used by the addon based on
--- the current grow direction.
---
--- @param direction string
---
function Vantage:SetPlayerCountJustifyV( direction )
    if direction == "downwards" then
        self.PlayerCount:SetJustifyV( "BOTTOM" );
        self.BattlegroundRezTimer:SetJustifyV( "BOTTOM" );
    else
        self.PlayerCount:SetJustifyV( "TOP" );
        self.BattlegroundRezTimer:SetJustifyV( "TOP" );
    end
end

---
--- Load the enemy module configurations for the 
---
function Vantage:LoadModuleConfigurations()
    if not self.Configs_Loaded then
        self.Module_Configs[ "Buffs" ]              = self:NewEnemyAuraConfig( false );
        self.Module_Configs[ "Castbar" ]            = self:NewEnemyCastBarConfig();
        self.Module_Configs[ "Class" ]              = self:NewEnemyClassConfig();
        self.Module_Configs[ "Combatindicator" ]    = self:NewCombatIndicatorConfig();
        self.Module_Configs[ "Debuffs" ]            = self:NewEnemyAuraConfig( true );
        self.Module_Configs[ "Drtracker" ]          = self:NewDRTrackerConfig();
        self.Module_Configs[ "Healthbar" ]          = self:NewHealthBarConfig();
        self.Module_Configs[ "Highestpriority" ]    = self:NewEnemyHighestPriorityConfig();
        self.Module_Configs[ "Level" ]              = self:NewEnemyLevelConfig();
        self.Module_Configs[ "Name" ]               = self:NewEnemyNameConfig();
        self.Module_Configs[ "Objective" ]          = self:NewEnemyObjectiveConfig();
        self.Module_Configs[ "Racial" ]             = self:NewEnemyRacialConfig();
        self.Module_Configs[ "Resource" ]           = self:NewEnemyResourceConfig();
        self.Module_Configs[ "Targetcounter" ]      = self:NewTargetCounterConfig();
        self.Module_Configs[ "Targetindicator" ]    = self:NewTargetIndicatorConfig();
        self.Module_Configs[ "Trinket" ]            = self:NewTrinketConfig();
        self.Configs_Loaded                         = true;
    end
end

---
---
---
--- @param reposition boolean?
---
function Vantage:UpdateEnemyPlayerCount( reposition )
    if InCombatLockdown() then
        self.QueueForUpdateAfterCombat( "UpdateEnemyPlayerCount", self );
    else
        self:SortEnemyPlayers( reposition or false );
        self:UpdatePlayerCount();
    end
end

---
--- Updates the addon user's focus frame.
---
function Vantage:UpdateFocus()
    local focus_name = GetUnitName( "focus", true );
    if ( self.current_focus and self.current_focus ~= focus_name ) or
       ( not self.current_focus and focus_name ) then


        local enemy_player;

        --
        -- Clear our current focus frame before setting the new focus
        --
        if self.current_focus then
            enemy_player = self:GetEnemyFrameByName( self.current_focus );
            if enemy_player then
                enemy_player.player_focus:Hide();
            end
        end

        --
        -- If we've focused someone else, set their frame.
        --
        if focus_name then
            enemy_player = self:GetEnemyFrameByName( focus_name );
            if enemy_player then
                enemy_player.player_focus:Show();
            end
        end

        self.current_focus = focus_name;
    end
end

---
--- Updates the addon user's target frame.
---
function Vantage:UpdateTarget()
    local target_name = GetUnitName( "target", true );
    if ( self.current_target and self.current_target ~= target_name ) or
       ( not self.current_target and target_name ) then


        local enemy_player;

        --
        -- Clear our current focus frame before setting the new focus
        --
        if self.current_target then
            enemy_player = self:GetEnemyFrameByName( self.current_target );
            if enemy_player then
                enemy_player.player_target:Hide();
            end
        end

        --
        -- If we've focused someone else, set their frame.
        --
        if target_name then
            enemy_player = self:GetEnemyFrameByName( target_name );
            if enemy_player then
                enemy_player.player_target:Show();
            end
        end

        self.current_target = target_name;
    end
end

---
--- Update the displayed enemy counter.
---
function Vantage:UpdatePlayerCount()
    if self.BG_Config and self.BG_Config.PlayerCount.Enabled then
        self.PlayerCount:Show();
        self.PlayerCount:SetText( fmt( self.PlayerInfo.faction == 0 and PLAYER_COUNT_ALLIANCE or PLAYER_COUNT_HORDE, #self.EnemyOrder ) );
    else
        self.PlayerCount:Hide();
    end
end

-----------------------------------------
--         Ally Table Management
-----------------------------------------

---
--- Add the `UnitId` to the ally table if it's an ally.
---
--- @param unit_id UnitId
---
function Vantage:AddAllyByUnitId( unit_id )
    if not self:GetAllyByUnitId( unit_id ) then
        local player_GUID = UnitGUID( unit_id );
        if player_GUID and strsplit( "-", player_GUID ) == "Player" then
            local new_ally = self.NewPlayer( unit_id, player_GUID );
            if new_ally then
                self:Debug( fmt( "[Vantage:AddAllyByUnitId] Adding player(%s) to ally table: %s", unit_id, new_ally.name ) );
                self.allies[ new_ally.name ] = new_ally;
            end
        end
    end
end

---
---
---
--- @param name string
--- @return PlayerInfo?
---
function Vantage:GetAllyByName( name )
    if name == self.PlayerInfo.name then
        return self.PlayerInfo;
    elseif self.allies[ name ] then
        return self.allies[ name ];
    end
    return nil;
end

---
---
---
--- @param unit_id UnitId
--- @return PlayerInfo?
---
function Vantage:GetAllyByUnitId( unit_id )
    return unit_id == "player" and
        self.PlayerInfo or
        self:GetAllyByName( GetUnitName( unit_id, true ) );
end

---
---
---
--- @return integer
---
function Vantage:GetNumAllies()
    local result = 0;
    for _ in pairs ( self.allies ) do
        result = result + 1;
    end
    return result;
end

---
---
---
--- @param ally_name string
---
function Vantage:RemoveAlly( ally_name )
    local ally = self.allies[ ally_name ];
    if ally.target then
        local enemy_player = self:GetEnemyFrameByName( ally.target.name );
        if enemy_player then
            enemy_player:IsNoLongerTargeted( ally );
        end
    end
    self.allies[ ally_name ] = nil;
end

---
---
---
function Vantage:RemoveStaleAllies()
    if self.BattleGroundSize and self:GetNumAllies() > self.BattleGroundSize then
        for name in pairs( self.allies ) do
            if not UnitExists( name ) then
                self:RemoveAlly( name );
                break;
            end
        end
    end
end

---
--- Update allies and their respective targets.
---
function Vantage:UpdateAllies()
    for _, ally in pairs( self.allies ) do
        self:UpdateAlly( ally );
    end
end

---
--- Check for updated ally targets and state.
---
--- @param ally PlayerInfo
---
function Vantage:UpdateAlly( ally )

    local target_unit_id  = fmt( "%s-target", ally.name );
    local target_name     = GetUnitName( target_unit_id, true );
    local target_faction  = UnitFactionGroup( target_unit_id ) == "Horde" and 0 or 1;

    --
    -- We only want to update the ally's target if their state has changed.
    --
    -- There's only two possibilities:
    --
    -- 1) The ally's target state exists and it's different than the current target (either the target is empty or a different player).
    -- 2) The ally's target state is empty and they have a current target.
    --
    if ( ally.target and ally.target.name ~= target_name ) or
       ( not ally.target and target_name ) then
        self:UpdateAllyTarget( ally, target_name, target_faction );
    end

    --
    -- If we have a BG Rez timer running, let's check if our allies are alive to keep
    -- the timer in sync.
    --
    if self.BG_Config and self.BG_Config.BattlegroundRezTimer.Enabled then
        if ally.alive then
            if UnitIsDeadOrGhost( ally.name ) then
                ally.alive = false;
            end
        else
            if not UnitIsDeadOrGhost( ally.name ) then
                ally.alive = true;
                self:ResetRezTimer( GetTime() );
            end
        end
    end

end

---
--- Update the ally player's target and any target indicators
--- affected by the change.
---
--- @param ally PlayerInfo
--- @param target_name string?
--- @param target_faction number
---
function Vantage:UpdateAllyTarget( ally, target_name, target_faction )
    --
    -- Our ally currently has no target.
    --
    if not target_name then
        ally:UpdateTarget();
    --
    -- Our ally currently has an enemy target.
    --
    elseif target_faction ~= self.PlayerInfo.faction then
        local enemy_player = self:GetEnemyFrameByName( target_name );
        if enemy_player then
            enemy_player:IsNowTargetedBy( ally );
            ally:UpdateTarget( enemy_player.player_info );
        end
    --
    -- Our ally has targeted another ally.
    --
    else
        local ally_player = self:GetAllyByName( target_name );
        if ally_player then
            ally:UpdateTarget( ally_player );
        end
    end

    --
    -- If the ally had a previous target, update their target indicators.
    --
    if ally.last_target then
        local last_enemy_player = self:GetEnemyFrameByName( ally.last_target.name );
        if last_enemy_player then
            last_enemy_player:IsNoLongerTargeted( ally );
        end
    end
end

-----------------------------------------
--         Enemy Table Management
-----------------------------------------

---
--- Create a new enemy frame from a `PVPScoreInfo`.
---
--- @param score PVPScoreInfo
---
function Vantage:CreateEnemyFrame( score )
    local player_info   = self.NewPlayerFromPVPScoreInfo( score );
    local player_name   = player_info.name;

    self:Debug( "[Vantage:CreateEnemyFrame] Creating enemy -> " .. player_name );

    self.EnemyFrames[ player_name ] = self:NewEnemyFrame( player_info );
    tinsert( self.EnemyOrder, player_name );
end

---
---
---
--- @param src_guid any
--- @return EnemyFrame?
---
function Vantage:GetEnemyFrameByGUID( src_guid )
    for _, enemy_frame in pairs( self.EnemyFrames ) do
        if enemy_frame.player_info.guid == src_guid then
            return enemy_frame;
        end
    end
    return nil;
end

---
---
---
--- @param  name string? The name of the player.
--- @return EnemyFrame? 
---
function Vantage:GetEnemyFrameByName( name )
    if name and self.EnemyFrames[ name ] then
        return self.EnemyFrames[ name ];
    end
    return nil;
end

---
--- Get the player referenced by the `UnitId`'s `EnemyFrame`. 
---
--- @param unit_id UnitId   The `UnitId` of the `EnemyFrame`.
--- @return EnemyFrame?     # An `EnemyFrame` if successful, otherwise nil.
---
function Vantage:GetEnemyFrameByUnitID( unit_id )
    return self:GetEnemyFrameByName( GetUnitName( unit_id, true ) );
end

---
--- Removes user data and releases the enemy frame back to the frame pool.
---
--- @param enemy_frame EnemyFrame
---
function Vantage:RemoveEnemyPlayer( enemy_frame )

    self:Debug( "[Vantage:RemovePlayer] Removing enemy -> " .. enemy_frame.player_info.name );

    if enemy_frame:IsShown() then
        enemy_frame:Hide();
    end

    self:ReleaseEnemyFrame( enemy_frame );
    self.EnemyFrames[ enemy_frame.player_info.name ] = nil;

    for i = #self.EnemyOrder, 1, -1 do
        if self.EnemyOrder[ i ] == enemy_frame.player_info.name then
            tremove( self.EnemyOrder, i );
            break;
        end
    end
    enemy_frame:Reset();
end

---
---
---
function Vantage:RemoveAllEnemyPlayers()
    for _, enemy_frame in pairs( self.EnemyFrames ) do
        self:RemoveEnemyPlayer( enemy_frame );
    end
end

---
--- Scan our current allies targets for valid UnitIds to use for 
--- updating enemy state.
---
function Vantage:ScanEnemiesByAllyTargets()

    local enemy_player_1, enemy_player_2, target_unit_id, timestamp;
    for name in pairs( self.allies ) do

        target_unit_id  = name .. "-target";
        timestamp       = GetServerTime();

        --
        -- Check the target of ally
        --
        enemy_player_1 = self:GetEnemyFrameByUnitID( target_unit_id );
        if enemy_player_1 then

            enemy_player_1:UpdateAll( target_unit_id );
            --[[
            if enemy_player_1:ShouldBroadcast() then
                enemy_player_1:BroadcastState( timestamp );
            end
            ]]--

            --
            -- If the ally had a target, check their target. Only update if
            -- the enemy player differs.
            --
            target_unit_id = target_unit_id .. "-target";
            enemy_player_2 = self:GetEnemyFrameByUnitID( target_unit_id );
            if enemy_player_2 and enemy_player_1 ~= enemy_player_2 then
                enemy_player_2:UpdateAll( target_unit_id );
                --[[
                if enemy_player_2:ShouldBroadcast() then
                    enemy_player_2:BroadcastState( timestamp );
                end
                ]]--
            end

        end
    end

    --
    -- Check my target
    -- 
    if self.PlayerInfo.target then
        enemy_player_1 = self:GetEnemyFrameByName( self.PlayerInfo.target.name );
        if enemy_player_1 then
            enemy_player_1:UpdateAll( "target" );
            --[[
            if enemy_player_1:ShouldBroadcast() then
                enemy_player_1:BroadcastState( timestamp );
            end
            --]]
        end
    end

    --
    -- Check my focus
    --
    if self.current_focus then
        enemy_player_1 = self:GetEnemyFrameByName( self.current_focus );
        if enemy_player_1 then
            enemy_player_1:UpdateAll( "focus" );
            --[[
            if enemy_player_1:ShouldBroadcast() then
                enemy_player_1:BroadcastState( timestamp );
            end
            ]]--
        end
    end

end

---
--- Sort the `EnemyFrame`s players by blizzard class order.
---
--- @param reposition boolean If true, forces reposition of the enemy frames.
---
function Vantage:SortEnemyPlayers( reposition )

    local player_order  = self.ShallowCopy( self.EnemyOrder );
    local order_changed = false;

    tsort( player_order, SortEnemiesByClassName );

    for i = 1, mmax( #player_order, #self.EnemyOrder ) do
        if player_order[ i ] ~= self.EnemyOrder[ i ] then
            order_changed = true;
            break;
        end
    end

    if reposition or order_changed then
        if InCombatLockdown() then
            self.QueueForUpdateAfterCombat( "UpdateEnemyPlayerCount", self );
        end
        self.EnemyOrder = player_order;
        self:ButtonPositioning();
    end
end

---
---
---
function Vantage:ToggleCurrentObjectiveHolder()
    for _, enemy in pairs( self.EnemyFrames ) do
        if enemy.modules.objective.has_objective then
            enemy.modules.objective:HideObjective();
            return;
        end
    end
end

---
--- Update an enemy frame to a new enemy player.
---
--- @param score        PVPScoreInfo
--- @param name         string
--- @param order_index  number
---
function Vantage:UpdateEnemyFrame( score, name, order_index )

    local old_name      = self.EnemyOrder[ order_index ];
    local current_frame = self.EnemyFrames[ old_name ];

    current_frame.player_info:UpdatePlayer( score );
    current_frame:PlayerDetailsChanged();

    self.EnemyOrder[ order_index ]  = name;
    self.EnemyFrames[ old_name ]    = nil;
    self.EnemyFrames[ name ]        = current_frame;
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- The OnUpdate function for the addon. This will run at 20 FPS.
---
--- This function does the majority of the work for updating enemy frames.
---
--- @param elapsed number
---
function Vantage:OnUpdateEnemyFrames( elapsed )

    self.LastOnUpdate = self.LastOnUpdate + elapsed;

    --
    -- Throttle the updates to 20 frames per second.
    --
    if self.LastOnUpdate > UPDATE_PERIOD then
        if self.PlayerInfo.alive then
            self:UpdateAllies();
            self:ScanEnemiesByAllyTargets();
        end
        self.LastOnUpdate = 0.0;
    end
end

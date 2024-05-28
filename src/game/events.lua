-------------------------------------------------------------------------------
---@script: events.lua
---@author: zimawhit3
---@desc:   This module implements the Blizzard event callbacks for the main frame.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------

-----------------------------------------
--                Lua
-----------------------------------------
local fmt       = string.format
local sub       = string.sub
local tinsert   = table.insert

-----------------------------------------
--              Blizzard
-----------------------------------------
local CombatLogGetCurrentEventInfo      = CombatLogGetCurrentEventInfo
local GetNumArenaOpponents              = GetNumArenaOpponents
local GetNumGroupMembers                = GetNumGroupMembers
local GetNumBattlefieldScores           = GetNumBattlefieldScores
local GetNumSpecializationsForClassID   = GetNumSpecializationsForClassID
local GetRaidRosterInfo                 = GetRaidRosterInfo
local GetTime                           = GetTime
local IsInGroup                         = IsInGroup
local IsInRaid                          = IsInRaid
local UnitIsGhost                       = UnitIsGhost
local wipe                              = wipe

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" )

-------------------------------------------------------------------------------
--                      Vantage Game Combat Event Callbacks
-------------------------------------------------------------------------------

----------------------------------------
--               Constants
----------------------------------------
local MAX_RAID_MEMBERS = 40;

----------------------------------------
--                Types
----------------------------------------

---
--- @class PendingUpdate
--- @field event    string
--- @field object   table
--- @field args     ...
---

----------------------------------------
--               Private
----------------------------------------

---
--- @type boolean
---
local HAS_SPECS = not not GetNumSpecializationsForClassID;

---
--- @type PendingUpdate[]
---
local PendingUpdates = {};

---
---
--- Blizzard callback events used by the Vantage addon.
---
local BLIZZARD_EVENTS =
{
    "UPDATE_BATTLEFIELD_SCORE",
    "UPDATE_MOUSEOVER_UNIT",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_FOCUS_CHANGED",
    "UNIT_TARGET",
    "PLAYER_ALIVE",
    "PLAYER_UNGHOST",
    "UNIT_AURA",
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_POWER_FREQUENT",
    "PLAYER_REGEN_ENABLED",
    "UNIT_HEALTH_FREQUENT",
};

---
--- Events used to start the Battleground Rez timer.
---
local REZ_EVENTS =
{
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "CHAT_MSG_RAID_BOSS_EMOTE",
};

---
--- Retrieve the score information of the player at `index` from 
--- the battleground score menu.
---
--- @param index number
--- @return PVPScoreInfo
---
local function parseBattlefieldScore( index )
    local name, faction, race, classTag, specName, deaths, _;
    if HAS_SPECS then
        name, _, _, deaths, _, faction, _, race, _, classTag, _, _, _, _, _, _, specName = GetBattlefieldScore( index );
    else
        name, _, _, deaths, _, faction, _, race, _, classTag = GetBattlefieldScore( index );
    end
    return
    {
        name        = name,
        deaths      = deaths,
        faction     = faction,
        raceName    = race,
        classToken  = classTag,
        talentSpec  = specName or ""
    };
end

---
---
---
--- @param unit UnitId
--- @return boolean
---
local function isNameplateUnit( unit )
    return sub( unit, 1, 8 ) == "nameplate";
end

---
--- 
---
--- @return table<string, PVPScoreInfo>
---
local function getBattleFieldScores()
    local bg_scores = {};
    local score;
    for i = 1, GetNumBattlefieldScores() do
        score = parseBattlefieldScore( i );
        bg_scores[ score.name ] = score;
    end
    return bg_scores;
end

----------------------------------------
--               Public
----------------------------------------

---
---
---
--- @param event    string
--- @param object   table
--- @param args     ...
---
function Vantage.QueueForUpdateAfterCombat( event, object, args )
    for i = 1, #PendingUpdates do
        local pending_update = PendingUpdates[ i ];
        if pending_update.object == object and pending_update.event == event then
            return;
        end
    end
    tinsert( PendingUpdates, { event = event, object = object, args = args } );
end

---
--- Registers the addon frame to combat events callbacks.
---
function Vantage:RegisterCombatEvents()

    for i = 1, #BLIZZARD_EVENTS do
        self:RegisterEvent( BLIZZARD_EVENTS[ i ] );
    end

    if self.CombatLogScanning then
        self:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
    end

    if self.BattleGroundStartMessage then
        for i = 1, #REZ_EVENTS do
            self:RegisterEvent( REZ_EVENTS[ i ] );
        end
    end

end

---
--- Unregisters the addon frame from combat event callbacks.
---
function Vantage:UnregisterEvents()

    for i = 1, #BLIZZARD_EVENTS do
        self:UnregisterEvent( BLIZZARD_EVENTS[ i ] );
    end

    if self.CombatLogScanning then
        self:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
    end

end

----------------------------------------
--               Callbacks
----------------------------------------

---
--- Fired for battleground-event messages that are displayed in a faction-neutral 
--- color by default. 
---
--- @param text string
---
function Vantage:CHAT_MSG_BG_SYSTEM_NEUTRAL( text )
    if text == self.BattleGroundStartMessage then
        self:StartRezTimer();
        self:UnregisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );
        self:UnregisterEvent( "CHAT_MSG_RAID_BOSS_EMOTE" );
    end
end

---
---
---
--- @param text string
---
function Vantage:CHAT_MSG_RAID_BOSS_EMOTE( text )
    if text == self.BattleGroundStartMessage then
        self:StartRezTimer();
        self:UnregisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" );
        self:UnregisterEvent( "CHAT_MSG_RAID_BOSS_EMOTE" );
    end
end

---
--- Fires for Combat Log events such as a player casting a spell or an NPC 
--- taking damage. 
---
function Vantage:COMBAT_LOG_EVENT_UNFILTERED()

    local _, subevent, _, _, srcName, _, _, _, destName,
          _, _, spellId, spellName, _, auraType = CombatLogGetCurrentEventInfo();

    if subevent == "SPELL_CAST_SUCCESS" then
        --
        -- For SPELL_CAST_SUCCESS, the only case we don't care for is if an enemy casted something at themselves.
        --
        local enemy_player = self:GetEnemyFrameByName( destName ) or self:GetEnemyFrameByName( srcName );
        if enemy_player and enemy_player:IsShown() then
            enemy_player[ subevent ]( enemy_player, srcName, destName, spellId, spellName, auraType );
        end

    elseif subevent == "SPELL_AURA_REFRESH" or subevent == "SPELL_AURA_REMOVED" or subevent == "SPELL_INTERRUPT" then
        local enemy_player = self:GetEnemyFrameByName( destName );
        if enemy_player and enemy_player:IsShown() then
            enemy_player[ subevent ]( enemy_player, srcName, destName, spellId, spellName, auraType );
        end
    end
end

---
--- Fired whenever a group or raid is formed or disbanded, players are leaving 
--- or joining the group or raid. 
---
function Vantage:GROUP_ROSTER_UPDATE()
    -- 
    -- It's discouraged to use GetNumGroupMembers() in a raid since there 
    -- can be "holes" between raid1 to raid40.
    --
    if IsInRaid() then
        for i = 1, MAX_RAID_MEMBERS do
            if GetRaidRosterInfo( i ) then
                self:AddAllyByUnitId( "raid" .. i );
            end
        end
    end

    --
    -- We are in a party, so it's safe to use GetNumGroupMembers.
    --
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            self:AddAllyByUnitId( "party" .. i );
        end
    end

    self:RemoveStaleAllies();

end

---
--- Fires when a nameplate is to be added. The event may sometimes fire 
--- before a nameplate is actually added.
---
--- @param unit_id UnitId The added unit in `nameplateN` format.
---
function Vantage:NAME_PLATE_UNIT_ADDED( unit_id )
    local enemy_player = self:GetEnemyFrameByUnitID( unit_id );
    if enemy_player then
        enemy_player:UpdateAll( unit_id );
    end
end

---
--- Fired when the player releases from death to a graveyard; or accepts a 
--- resurrect before releasing their spirit.
---
function Vantage:PLAYER_ALIVE()
    --
    -- We only care about the case we've been resurrected by an ally.
    --
    if not UnitIsGhost( "player" ) then
        self.PlayerInfo.alive = true;
    end
end

---
--- This event is fired whenever the player's focus target (/focus) is changed, 
--- including when the focus target is lost or cleared. 
---
function Vantage:PLAYER_FOCUS_CHANGED()
    self:UpdateFocus();
end

---
--- This event is fired whenever the player's target is changed, including 
--- when the target is lost.
---
function Vantage:PLAYER_TARGET_CHANGED()
    self:UpdateTarget();
end

---
--- Fired after ending combat, as regen rates return to normal. 
--- 
--- Useful for determining when a player has left combat. This occurs when you are 
--- not on the hate list of any NPC, or a few seconds after the latest pvp attack 
--- that you were involved with. 
---
function Vantage:PLAYER_REGEN_ENABLED()
    --
    -- Check if there are any outstanding updates that have been hold 
    -- back due to being in combat.
    --
    local args, evnt, obj, update;
    for i = 1, #PendingUpdates do
        update  = PendingUpdates[ i ];
        obj     = update.object;
        evnt    = update.event;
        args    = update.args;
        obj[ evnt ]( obj, args );
    end
    wipe( PendingUpdates );
end

---
--- Fired when the player is alive after being a ghost.
---
function Vantage:PLAYER_UNGHOST()
	self.PlayerInfo.alive = true;
    self:ResetRezTimer( GetTime() );
end

---
--- Fires when a buff, debuff, status, or item bonus was gained by or faded 
--- from an entity (player, pet, NPC, or mob.) 
---
--- This is primarily used to update enemy's auras through nameplate `UnitId`s.
---
--- @param unit_target              UnitId  The target's UnitID
--- @param unit_aura_update_info    table?  Optional table of information about changed auras.
---
function Vantage:UNIT_AURA( unit_target, unit_aura_update_info )
    if isNameplateUnit( unit_target ) then
        local enemy_player = self:GetEnemyFrameByUnitID( unit_target );
        if enemy_player and enemy_player:IsShown() then
            enemy_player:UpdateAuras( unit_target );
        end
    end
end

---
--- Fires when the health of a unit changes. 
---
--- This is primarily used to update enemy's health through nameplate `UnitId`s.
---
--- @param unit_token UnitId The `UnitId` of the unit whose health has changed.
---
function Vantage:UNIT_HEALTH( unit_token )
    if isNameplateUnit( unit_token ) then
        local enemy_player = self:GetEnemyFrameByUnitID( unit_token );
        if enemy_player and enemy_player:IsShown() then
            enemy_player:UNIT_HEALTH( unit_token );
        end
    end
end

---
--- Same event as UNIT_HEALTH but not throttled as aggressively by the client. 
---
Vantage.UNIT_HEALTH_FREQUENT = Vantage.UNIT_HEALTH;

---
--- Fired when a unit's absorb amount changes (for example, when he gains/loses 
--- an absorb effect such as Power Word: Shield, or when he gains/loses some of 
--- his absorb via getting hit or through an ability). 
---
Vantage.UNIT_ABSORB_AMOUNT_CHANGED      = Vantage.UNIT_HEALTH;
Vantage.UNIT_HEAL_ABSORB_AMOUNT_CHANGED = Vantage.UNIT_HEALTH;
Vantage.UNIT_HEAL_PREDICTION            = Vantage.UNIT_HEALTH;

---
--- Fires when the maximum health of a unit changes.
---
Vantage.UNIT_MAXHEALTH = Vantage.UNIT_HEALTH;

---
--- Fired when a unit's current power (mana, rage, focus, energy, etc...) 
--- changes.
---
--- This is primarily used to update enemy's health through nameplate `UnitId`s.
---
--- @param unit_id      UnitId  The `UnitId` of the unit.
--- @param power_token  string  The type of power resource the unit uses.
---
function Vantage:UNIT_POWER_FREQUENT( unit_id, power_token )
    if isNameplateUnit( unit_id ) then
        local enemy_player = self:GetEnemyFrameByUnitID( unit_id );
        if enemy_player and enemy_player:IsShown() then
            enemy_player:UNIT_POWER_FREQUENT( unit_id, power_token );
        end
    end
end

---
--- Fired when the target of yourself, raid, and party members change.
---
--- @param unit_target UnitId
---
function Vantage:UNIT_TARGET( unit_target )
    local ally_player = self:GetAllyByUnitId( unit_target );
    if ally_player then
        self:UpdateAlly( ally_player );
    end
end

---
--- Fired whenever new battlefield score data has been recieved. This is usually 
--- fired after `RequestBattlefieldScoreData` is called. 
---
function Vantage:UPDATE_BATTLEFIELD_SCORE()

    local bg_scores                     = getBattleFieldScores();
    local new_players_added_or_removed  = false;
    local current_enemy;

    for name, score in pairs( bg_scores ) do

        if score.faction ~= self.PlayerInfo.faction then

            if self.EnemyFrames[ name ] then
                current_enemy = self.EnemyFrames[ name ];
                if current_enemy.player_info.deaths ~= score.deaths then
                    --
                    -- To prevent this from getting out of sync, we'll explicitly tell it the amount of deaths 
                    -- they currently have.
                    --
                    current_enemy:PlayerDied( score.deaths );
                end

                --
                -- 
                --
                if not current_enemy:IsShown() and #self.EnemyOrder == 10 then
                    self:Debug( "[Vantage:UPDATE_BATTLEFIELD_SCORE] Enemy player " .. current_enemy.player_info.name  .. " frame is hidden?" );
                    if not InCombatLockdown() then
                        current_enemy:Show();
                    end
                end

            else
                --
                -- If we were at the max players for the BG, find the player that left
                -- and update them to the new player.
                --
                local num_enemies = #self.EnemyOrder;
                if num_enemies == self.BattleGroundSize then
                    for i = 1, num_enemies do
                        if not bg_scores[ self.EnemyOrder[ i ] ] then
                            self:Debug( fmt( "[Vantage:UPDATE_BATTLEFIELD_SCORE] New enemy player joined: %s | Updating: %s", name, self.EnemyOrder[ i ] ) );
                            self:UpdateEnemyFrame( score, name, i );
                            new_players_added_or_removed = true;
                            break;
                        end
                    end
                --
                -- There's spaces available - create a new frame for the enemy. 
                --
                else
                    self:CreateEnemyFrame( score );
                    new_players_added_or_removed = true;
                end
            end
        end
    end

    --
    -- Remove any players that AFK'd
    --
    for name, enemy in pairs( self.EnemyFrames ) do
        if not bg_scores[ name ] then
            self:RemoveEnemyPlayer( enemy );
            new_players_added_or_removed = true;
        end
    end

    --
    -- We check to make sure we have a full group of allies here in case the player
    -- reloaded in the middle of the BG.
    --
    if self:GetNumAllies() ~= self.BattleGroundSize then
        self:GROUP_ROSTER_UPDATE();
    end

    --
    -- Check for any objective holders.
    --
    local enemy_obj_holder = false;
    for i = 1, GetNumArenaOpponents() do
        local enemy_player = self:GetEnemyFrameByUnitID( "arena" .. i );
        if enemy_player then
            enemy_obj_holder = true;
            self:ToggleCurrentObjectiveHolder();
            enemy_player.modules.objective:ShowObjective();
        end
    end

    --
    -- If there aren't any objective holders, make sure we clear any existing holders.
    --
    if not enemy_obj_holder then
        self:ToggleCurrentObjectiveHolder();
    end

    if new_players_added_or_removed and #self.EnemyOrder > 2 then
        if InCombatLockdown() then
            self.QueueForUpdateAfterCombat( "UpdateEnemyPlayerCount", self, new_players_added_or_removed );
        else
            self:SortEnemyPlayers( true );
            self:UpdatePlayerCount();
        end
    end
end

---
--- Fired when the mouseover object needs to be updated. 
---
function Vantage:UPDATE_MOUSEOVER_UNIT()
    local enemy_player = self:GetEnemyFrameByUnitID( "mouseover" );
    if enemy_player then
        enemy_player:UpdateAll( "mouseover" );
    end
end

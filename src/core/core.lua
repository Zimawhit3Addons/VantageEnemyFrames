-------------------------------------------------------------------------------
---@script: core.lua
---@author: zimawhit3
---@desc:   This module implements the creation of core structures to the addon.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local AddonName, Constants  = ...
local LibStub               = LibStub
local Ace3                  = LibStub( "AceAddon-3.0" )
local BigDebuffs            = Ace3:GetAddon( "BigDebuffs", true )

-----------------------------------------
--                Lua
-----------------------------------------
local fmt       = string.format
local tinsert   = table.insert

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame                   = CreateFrame
local CTimerAfter                   = C_Timer.After
local GetAddOnMetadata              = C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local GetBestMapForUnit             = C_Map.GetBestMapForUnit
local GetServerTime                 = GetServerTime
local GetTime                       = GetTime
local GameTooltip	                = GameTooltip
local UnitAura                      = UnitAura
local UnitFactionGroup              = UnitFactionGroup
local WOW_PROJECT_ID                = WOW_PROJECT_ID

-------------------------------------------------------------------------------
--                                    Addon
-------------------------------------------------------------------------------

---
--- @class Vantage : Frame
---
local Vantage = Ace3:NewAddon(
    CreateFrame( "Frame", "VantageEnemyFrames", UIParent ),
    "Vantage",
    "AceComm-3.0",
    "AceSerializer-3.0"
);

----------------------------------------
--            Core types
----------------------------------------

---
--- @type table
---
Vantage.BG_Config = nil;

---
--- @type boolean
---
--- 
---
Vantage.CombatLogScanning = true;

---
--- @type table
---
--- The Vantage configurations.
---
Vantage.Config = nil;

---
--- @type boolean
---
---
Vantage.Configs_Loaded = false;

---
--- @type VantageConfiguration
---
--- The Vantage SavedVariables database.
---
Vantage.Database = {};

---
--- @type MessageFrame
---
---
---
Vantage.DebugFrame = {};

---
--- @type boolean
---
--- Wether the addon is currently being shown and actively subscribed
--- to callbacks.
---
Vantage.Enabled = false;

---
--- @type number
---
Vantage.Expansion = WOW_PROJECT_ID;

---
--- @diagnostic disable-next-line: undefined-doc-name
--- @type FramePoolMixin
---
--- The frame pool used to acquire and release enemy frames.
---
Vantage.EnemyFramePool = {};

---
--- @type table<string, EnemyFrame>
---
--- The table of enemy player names to `EnemyFrame`s.
---
Vantage.EnemyFrames = {};

---
--- @type string[]
---
--- The enemy names in sorted order.
---
Vantage.EnemyOrder = {};

---
--- @diagnostic disable-next-line: undefined-doc-name
--- @type ButtonFrameTemplate|Frame
---
Vantage.ImportExportFrame = nil;

---
--- @type boolean
---
Vantage.isTestingMode = false;

---
--- @type LogLevel
---
---
---
Vantage.LogLevel = Constants.LogLevel.LOG_LEVEL_NONE;

---
--- @type table<string, ModuleConfiguration>
---
---
Vantage.Module_Configs = {};

---
--- @type table
---
--- The GUI options table.
---
Vantage.options = {};

---
---
---
Vantage.TestingMode =
{
    ---
    --- @type string?
    ---
    mode_size = nil,

    ---
    ---
    ---
    active = false,

    ---
    ---
    ---
    fake_auras = {},

    ---
    ---
    ---
    fake_drs = {},

    ---
    --- @type cbObject
    ---
    update_timer = nil,
};

---
--- @type string
---
Vantage.version = GetAddOnMetadata( AddonName, "Version" );

----------------------------------------
--        Battleground types
----------------------------------------

---
--- @type table<string, PlayerInfo>
---
--- 
---
Vantage.allies = {};

---
--- @type table
---
--- A table of Battleground specific buffs to watchout for based on 
--- the current active battlefield.
---
Vantage.BattleGroundBuffs = {};

---
--- @type table
---
--- A table of Battleground specific debuffs to watchout for based on 
--- the current active battlefield.
---
Vantage.BattleGroundDebuffs = {};

---
--- @type VantageFontString|FontString
---
---
---
Vantage.BattlegroundRezTimer = {};

---
--- @type cbObject?
---
Vantage.BattleGroundNextRezTimer = nil;

---
--- @type number
---
Vantage.BattleGroundNextRezTime = 0.0;

---
--- @type number?
---
--- The max number of players for the current battleground.
---
Vantage.BattleGroundSize = nil;

---
--- @type string?
---
--- The message sent by Blizzard when the current battleground starts.
---
Vantage.BattleGroundStartMessage = nil;

---
--- @type number
---
--- The current Battleground map ID.
---
Vantage.CurrentMapId = 0;

---
--- @type PlayerInfo
---
--- The current addon user's `PlayerInfo`.
---
Vantage.PlayerInfo = nil;

---
--- @type VantageFontString|FontString
---
---
---
Vantage.PlayerCount = {};

---
--- @type string?
---
---
---
Vantage.current_focus = nil;

---
--- @type string?
---
Vantage.current_target = nil;

---
--- @type number
---
Vantage.LastOnUpdate = 0.0;

---
--- @type cbObject?
---
Vantage.RequestScoreTimer = nil;

---
--- @type fun( unit_id: UnitId ): boolean
---
Vantage.broadcast_checker = nil;

---
--- @class VantageAura : AuraData
--- @field priority number
---

----------------------------------------
--               Private
----------------------------------------

---
---
---
local function DelayedUpdateMapId()
    Vantage:UpdateMapID();
end

---
---
---
--- @param spell_id number
--- @return number?
---
local function GetBigDebuffsPriority( spell_id )
	if not Vantage.Database.profile.UseBigDebuffsPriority or not BigDebuffs then
        return nil;
    end

    --- @diagnostic disable-next-line: undefined-field
    if not BigDebuffs.GetDebuffPriority then
        Vantage:Notify( "BigDebuffs missing API: \"GetDebuffPriority\"" );
        return nil;
    end

    --- @diagnostic disable-next-line: undefined-field
	local priority = BigDebuffs:GetDebuffPriority( spell_id );
	if priority == 0 then
        return nil;
    end
	return priority;
end

----------------------------------------
--               Public
----------------------------------------

---
---
---
--- @param texture	Texture
--- @param width 	number
--- @param height 	number
---
function Vantage.CropImage( texture, width, height )
    local left, right, top, bottom = 0.075, 0.925, 0.075, 0.925;
    local ratio = height / width;

    --
    -- Crop the sides
    --
    if ratio > 1 then
        ratio = 1 / ratio;
        texture:SetTexCoord( left + ( ( 1 - ratio ) / 2 ), right - ( ( 1 - ratio ) / 2 ), top, bottom );

    elseif ratio == 1 then
        texture:SetTexCoord( left, right, top, bottom );

    --
    -- Crop the height
    --
    else
        texture:SetTexCoord( left, right, top + ( ( 1 - ratio ) / 2 ), bottom - ( ( 1 - ratio ) / 2 ) );

    end
end

---
---
---
function Vantage.DeepCopy( obj )
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[Vantage.DeepCopy(k)] = Vantage.DeepCopy(v) end
    return res
end

---
--- Debug function to transform any type to a string.
---
--- @param o any
--- @return string
---
function Vantage.Dump( o )
    if type( o ) == "table" then
        local s = "{ ";
        for k, v in pairs( o ) do
            if type( k ) ~= "number" then
                k = '"' .. tostring( k ) .. '"';
            end
            s = s .. '[' .. k .. '] = ' .. Vantage.Dump( v ) .. ',';
        end
        return s .. '} ';
    end
    return tostring( o );
end

---
---
---
--- @param spell_id number
--- @return number?
---
function Vantage.GetSpellPriority( spell_id )
	return GetBigDebuffsPriority( spell_id ) or Constants.SpellPriorities[ spell_id ];
end

---
---
---
--- @param local_time number
--- @return number
---
function Vantage.LocalToServerTime( local_time )
    Vantage:Debug( "[Vantage:LocalToServerTime] Local Time: " .. tostring( local_time ) .. " | Server Time: " .. tostring( local_time + ( GetServerTime() - GetTime() ) ) );
    return local_time + ( GetServerTime() - GetTime() );
end

---
---
---
--- @param a any
--- @param b any
--- @return any
---
function Vantage:Merge( a, b )
    if type( a ) == 'table' and type( b ) == 'table' then
        for k, v in pairs( b ) do
            if type( v ) == 'table' and type( a[ k ] or false ) == 'table' then
                self:Merge( a[ k ], v );
            else
                a[ k ] = v;
            end
        end
    end
    return a;
end

---
--- returns true if <frame> or one of the frames that <frame> is dependent on is anchored to <otherFrame> and nil otherwise
--- dont ancher to otherframe is.
---
--- @param frame_a  ( Frame | ScriptRegion )?
--- @param frame_b  Frame?
--- @return boolean
---
function Vantage:IsFrameDependentOnFrame( frame_a, frame_b )
	if frame_a == nil or frame_b == nil then
		return false;
	end

	if frame_a == frame_b then
		return true;
	end

	local points = frame_a:GetNumPoints();
	for i = 1, points do
		local _, relative_frame = frame_a:GetPoint( i );
		if relative_frame and self:IsFrameDependentOnFrame( relative_frame, frame_b ) then
			return true;
		end
	end
    return false;
end

---
---
---
--- @param timestamp number
--- @return number
---
 function Vantage.ServerTimeToLocalTime( timestamp )
    Vantage:Debug( "[Vantage:ServerTimeToLocalTime] Server Time: " .. tostring( timestamp ) .. " | Local Time: " .. tostring( timestamp - ( GetServerTime() - GetTime() ) ) );
    return timestamp - ( GetServerTime() - GetTime() );
end

---
---
---
--- @param t string[]?
--- @return string[]
---
function Vantage.ShallowCopy( t )
    local t2 = {};
    if t then
        for i = 1, #t do
            tinsert( t2, t[ i ] );
        end
    end
    return t2;
end

---
---
---
--- @param aura AuraData|VantageAura
---
function Vantage.ShowAuraToolTip( aura )
    if aura and aura.spellId then
        GameTooltip:SetSpellByID( aura.spellId );
    end
end

---
--- Shows the tooltip for the owning frame.
---
--- @param owner 	Frame		The owning `Frame` of the tooltip.
--- @param callback function	The callback to run before showing the tooltip.
---
function Vantage:ShowToolTip( owner, callback )
    if self.Database.profile.ShowTooltips then
        GameTooltip:SetOwner( owner, "ANCHOR_RIGHT", 0, 0 );
        callback( owner );
        GameTooltip:Show();
    end
end

---
--- Update the addon user's faction based on their Battleground faction.
---
function Vantage:UpdateBGFaction()

    local player_faction = UnitFactionGroup( "player" ) == "Horde" and 0 or 1;

    --
    -- The same faction buff will always be at index 1. 
    -- 
    -- If we're in a same faction BG, swap the faction.
    --
    local faction_buff = UnitAura( "player", 1, "HELPFUL" );
    if faction_buff and ( faction_buff == "Alliance" or faction_buff == "Horde" ) then
        self.PlayerInfo.faction = player_faction == 0 and 1 or 0;
    else
        self.PlayerInfo.faction = player_faction;
    end
end

---
--- Updates the `BattleGroundSize` based on the current BG map ID.
---
--- @param map_id number The current map ID.
--- @return boolean
---
function Vantage:UpdateBGSize( map_id )

    --
    -- TODO: 
    --  - RBG Map Ids
    --  - Turn on rez timer for RBGs since rez times are normalized.
    --

    --
    -- Warsong Gulch
    -- 
    if map_id == 1339 or map_id == 1460 then
        self.BattleGroundSize           = 10;
        self.BattleGroundStartMessage   = "Let the battle for Warsong Gulch begin!";

    --
    -- Eye of the Storm
    --
    elseif map_id == 112 or map_id == 397 or map_id == 1956 then
        self.BattleGroundSize = 15;

    --
    -- Arathi Basin
    --
    elseif map_id == 93 or map_id == 844 or map_id == 1366 or map_id == 1461 then
        self.BattleGroundSize = 15;

    --
    -- Alterac Valley
    --
    elseif map_id == 91 or map_id == 1537 or map_id == 2162 or map_id == 1459 then
        self.BattleGroundSize = 40;

    --
    -- Twin Peaks
    --
    elseif map_id == 206 then
        self.BattleGroundSize           = 10;
        self.BattleGroundStartMessage   = ""; -- TODO

    --
    -- Battle for Gilneas
    --
    elseif map_id == 275 then
        self.BattleGroundSize           = 10;
        self.BattleGroundStartMessage   = "The battle for Gilneas has begun!";

    --
    -- Strand of the Ancients
    --
    elseif map_id == 128 then
        self.BattleGroundSize = 15;

    --
    -- Isle of Conquest
    --
    elseif map_id == 169 then
        self.BattleGroundSize = 40;

    else
        self:Notify( fmt( "Unknown map ID: %d - Please report this issue to https://www.github.com/zimawhit3/VantageEnemyFrames", map_id ) );
        return false;
    end

    self:Debug( fmt( "[Vantage:UpdateBGSize] Map id: %d | BG Size: %d", map_id, self.BattleGroundSize ) );
    return true;
end

---
--- Update the current BG's data depending on the map ID. Also, update
--- the player's faction inside the BG.
---
function Vantage:UpdateMapID()

    local map_id = GetBestMapForUnit( "player" );

    --
    -- Check to make sure we recieved a real map ID.
    -- 
    -- If we did, update the map data. Otherwise, we start a timer
    -- that periodically checks in case the `map_id` was not ready.
    --
    if map_id and map_id > 0 then
        self.BattleGroundBuffs      = Constants.BattleGroundBuffs[ map_id ];
        self.BattleGroundDebuffs    = Constants.BattleGroundDebuffs[ map_id ];
        self:UpdateBGFaction();
        if self:UpdateBGSize( map_id ) then
            self:StartBG();
        end
    else
        CTimerAfter( 1, DelayedUpdateMapId );
    end
end


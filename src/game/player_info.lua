-------------------------------------------------------------------------------
---@script: player_info.lua
---@author: zimawhit3
---@desc:   This module implements the `PlayerInfo` class to track player information.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local LibStub   = LibStub

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFromMixins      = CreateFromMixins
local GetUnitName           = GetUnitName
local RAID_CLASS_COLORS     = RAID_CLASS_COLORS
local UnitClassBase         = UnitClassBase
local UnitFactionGroup      = UnitFactionGroup
local UnitRace              = UnitRace

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                PlayerInfoModule
-------------------------------------------------------------------------------

----------------------------------------
--               Types
----------------------------------------

---
--- @class PlayerInfo
--- @field alive boolean
--- @field class string
--- @field deaths integer
--- @field faction integer
--- @field guid string
--- @field last_target PlayerInfo?
--- @field level integer
--- @field name string
--- @field race string
--- @field target PlayerInfo?
---
--- A `PlayerInfo` structure represents a player in the battleground.
---
local PlayerInfo =
{
    ---
    --- @type boolean
    ---
    alive = true,

    ---
    --- @type string
    ---
    --- The name of the player, including the player's server name.
    ---
    name = "",

    ---
    --- @type string
    ---
    --- The locale-independent class name of the player.
    ---
    class = "",

    ---
    --- @type PlayerInfo?
    ---
    last_target = nil,

    ---
    --- @type integer
    ---
    --- The level of the player.
    ---
    level = 0,

    ---
    --- @type integer
    ---
    --- The player's faction ID.
    ---
    faction = 0,

    ---
    --- @type string
    ---
    --- 
    ---
    race = "",

    ---
    --- @type PlayerInfo?
    ---
    ---
    ---
    target = nil,

    ---
    --- @type string
    ---
    --- The player's GUID of the format Player-[serverID]-[playerUID]
    ---
    guid = "",

    ---
    --- @type integer
    ---
    ---
    deaths = 0,
};

----------------------------------------
--               Public
----------------------------------------

---
--- Creates a new `PlayerInfo` from a `UnitId`.
---
--- This is the `PlayerInfo` creation function for ally players.
---
--- @param unit_id      UnitId  The `UnitId` of the player.
--- @param unit_guid    string  The `GUID` of the player.
--- @return PlayerInfo? `PlayerInfo` if successfully initalized, otherwise `nil`.
---
function Vantage.NewPlayer( unit_id, unit_guid )
    local player_info = CreateFromMixins( PlayerInfo );
    player_info:Initialize( unit_id, unit_guid );
    return player_info;
end

---
--- Creates a new `PlayerInfo` from a `PVPScoreInfo`.
---
--- This is the `PlayerInfo` creation function for enemy players.
---
--- @param score_info   PVPScoreInfo    The `PVPScoreInfo` to create a `PlayerInfo` with.
--- @return             PlayerInfo
---
function Vantage.NewPlayerFromPVPScoreInfo( score_info )
    local player_info   = CreateFromMixins( PlayerInfo );
    player_info.name    = score_info.name;
    player_info.class   = score_info.className or score_info.classToken;
    player_info.faction = score_info.faction;
    player_info.race    = score_info.raceName or "";
    player_info.guid    = score_info.guid or "";
    player_info.deaths  = score_info.deaths or 0;
    return player_info;
end

-------------------------------------------------------------------------------
--                                   PlayerInfo
-------------------------------------------------------------------------------

---
---
---
--- @return ColorMixin_RCC
---
function PlayerInfo:ClassColor()
    return RAID_CLASS_COLORS[ self.class ];
end

---
--- Initialize a new `PlayerInfo`.
---
--- @param unit_id      UnitId  The `UnitId` of the player.
--- @param unit_guid    string 
---
function PlayerInfo:Initialize( unit_id, unit_guid )
    self.alive      = not UnitIsDeadOrGhost( unit_id );
    self.name       = GetUnitName( unit_id, true );
    self.guid       = unit_guid;
    self.class      = UnitClassBase( unit_id );
    self.race       = UnitRace( unit_id );
    self.faction    = UnitFactionGroup( unit_id ) == "Horde" and 0 or 1;
    self.deaths     = 0;
end

---
---
---
--- @param score PVPScoreInfo
---
function PlayerInfo:UpdatePlayer( score )
    self.name       = score.name;
    self.class      = score.className or score.classToken;
    self.deaths     = score.deaths;
    self.faction    = score.faction;
    self.race       = score.raceName;
    self.guid       = score.guid or "";
end

---
---
---
--- @param target PlayerInfo?
--- @return string?
---
function PlayerInfo:UpdateTarget( target )
    self.last_target    = self.target;
    self.target         = target;
end

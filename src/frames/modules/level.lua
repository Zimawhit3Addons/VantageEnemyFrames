-------------------------------------------------------------------------------
---@script: level.lua
---@author: zimawhit3
---@desc:   This module implements level text for the EnemyFrame.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...
local L             = Constants.L

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local GetMaxPlayerLevel = GetMaxPlayerLevel
local Mixin             = Mixin
local UnitLevel         = UnitLevel

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                 EnemyFrame Level
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
local ENEMY_LEVEL_OPTIONS = function( location )
    return
    {
        OnlyShowIfNotMaxLevel =
        {
            type    = "toggle",
            name    = L.LevelText_OnlyShowIfNotMaxLevel,
            order   = 2
        },
        LevelTextTextSettings =
        {
            type    = "group",
            name    = L.TextSettings,
            get = function( option )
                return Constants.GetOption( location.Text, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Text, option, ... );
            end,
            inline  = true,
            order   = 3,
            args    = Constants.AddNormalTextSettings( location.Text );
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyLevelConfig
---
local ENEMY_LEVEL_DEFAULT_SETTINGS =
{
	Enabled                 = true,
	Parent                  = "Healthbar",
	UseButtonHeightAsHeight = true,
	ActivePoints            = 1,
	OnlyShowIfNotMaxLevel   = true,
    Points =
    {
        {
            Point           = "TOPLEFT",
            RelativeFrame   = "Healthbar",
            RelativePoint   = "TOPLEFT",
            OffsetX         = 2,
            OffsetY         = 2
        }
    },
	Text =
    {
		FontSize        = 18,
		FontOutline     = "",
		FontColor       = { 1, 1, 1, 1 },
		EnableShadow    = false,
		ShadowColor     = { 0, 0, 0, 1 },
		JustifyH        = "LEFT"
	}
};

---
--- @class EnemyLevel : VantageFontString
--- @field config EnemyLevelConfig
--- @field enabled boolean
--- @field enemy EnemyFrame
--- @field position_set boolean
---
local EnemyLevel =
{
    --- 
    --- @type EnemyLevelConfig
    ---
    config = ENEMY_LEVEL_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type EnemyFrame
    ---
    --- A reference to the parent `EnemyFrame`.
    ---
    enemy = nil,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                 Private
-----------------------------------------
local MaxLevel = GetMaxPlayerLevel();

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create a new `EnemyName` for the `EnemyFrame`.
---
--- @param  enemy   EnemyFrame  The `EnemyFrame` to create a name for.
--- @return EnemyLevel|FontString
---
function Vantage:NewEnemyLevel( enemy )
    local level_fs      = self.NewFontString( enemy );
    local enemy_level   = Mixin( level_fs, EnemyLevel );
    enemy_level.enemy   = enemy;
    return enemy_level;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyLevelConfig()
    return self.NewModuleConfig( "Level", ENEMY_LEVEL_DEFAULT_SETTINGS, ENEMY_LEVEL_OPTIONS );
end

---
---
---
function EnemyLevel:ApplyAllSettings()
    self:ApplyFontStringSettings( self.config.Text );
	self:Display();
end

---
--- Displays the level text on the enemy's frame.
---
function EnemyLevel:Display()
    if not self.config.OnlyShowIfNotMaxLevel and self.enemy.player_info.level < MaxLevel then
        --
        -- To set the width of the frame (the name should have the same space from the role icon/spec icon regardless of level shown)
        --
        --self:SetText( MaxLevel - 1 );
        self:SetWidth( 0 );
        self:SetText( tostring( self.enemy.player_info.level ) );
    else
        self:SetText( "  " );
    end
end

---
--- Sets the `EnemyLevel`'s level.
---
--- @param level number The level of the enemy player to set.
---
function EnemyLevel:SetLevel( level )
    if self.enemy.player_info.level ~= level then
        self.enemy.player_info.level = level;
        self:Display();
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
--- @param unit_id UnitId
---
function EnemyLevel:UpdateLevel( unit_id )
    if self.enabled then
        local level = UnitLevel( unit_id );
        if level then
            if self:GetFont() then
                self:SetLevel( level );
            end
        end
    end
end

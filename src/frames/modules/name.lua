-------------------------------------------------------------------------------
---@script: name.lua
---@author: zimawhit3
---@desc:   This module implements name text for the EnemyFrame.
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

-----------------------------------------
--                Lua
-----------------------------------------
local strsplit  = strsplit
local strupper  = string.upper

-----------------------------------------
--              Blizzard
-----------------------------------------
local Mixin     = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                 EnemyFrame Name
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
--- @param location table
--- @return table
---
local ENEMY_NAME_OPTIONS = function( location )
    return
    {
        ShowRealmNames =
        {
            type    = "toggle",
            name    = L.ShowRealmNames,
            desc    = L.ShowRealmNames_Desc,
            width   = "normal",
            order   = 2
        },
        TextSettings =
        {
            type = "group",
            name = L.TextSettings,
            inline = true,
            order = 4,
            get = function( option )
                return Constants.GetOption( location.Text, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Text, option, ... );
            end,
            args = Constants.AddNormalTextSettings( location.Text );
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyNameConfig
---
local ENEMY_NAME_DEFAULT_SETTINGS =
{
    Enabled         = true,
    Parent          = "Healthbar",
    ActivePoints    = 2,
    ShowRealmNames  = true,
    Points =
    {
        {
            Point           = "TOPLEFT",
            RelativeFrame   = "Level",
            RelativePoint   = "TOPRIGHT",
            OffsetX         = 5,
            OffsetY         = -2
        },
        {
            Point           = "BOTTOMRIGHT",
            RelativeFrame   = "Targetcounter",
            RelativePoint   = "BOTTOMLEFT",
        }
    },
    Text =
    {
        FontSize        = 13,
        FontOutline     = "",
        FontColor       = { 1, 1, 1, 1 },
        EnableShadow    = true,
        ShadowColor     = { 0, 0, 0, 1 },
        JustifyH        = "LEFT",
        JustifyV        = "MIDDLE",
        WordWrap        = false
    }
};

---
--- @class EnemyName : VantageFontString
--- @field config EnemyNameConfig
--- @field enabled boolean
--- @field enemy EnemyFrame
--- @field position_set boolean
---
local EnemyName =
{
    --- 
    --- @type EnemyNameConfig
    ---
    config = ENEMY_NAME_DEFAULT_SETTINGS,

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
--                 Public
-----------------------------------------

---
---
---
--- @param  enemy   EnemyFrame
--- @return EnemyName|FontString
---
function Vantage:NewEnemyName( enemy )
    local name_fs       = self.NewFontString( enemy );
    local enemy_name    = Mixin( name_fs, EnemyName );
    enemy_name.enemy    = enemy;
    return enemy_name;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyNameConfig()
    return self.NewModuleConfig( "Name", ENEMY_NAME_DEFAULT_SETTINGS, ENEMY_NAME_OPTIONS );
end

---
---
---
function EnemyName:ApplyAllSettings()
    self:ApplyFontStringSettings( self.config.Text );
    if self.enabled then
	    self:SetName();
    end
end

---
---
---
function EnemyName:SetName()
    if not self.enemy.player_info then
        Vantage:Debug( "[EnemyName:SetName] Can't set enemy name - no player found." );
        return;
    end

    local player_name = self.enemy.player_info.name;
    if not player_name then
        Vantage:Debug( "[EnemyName:SetName] Can't set enemy name - no name found." );
        return;
    end

    local name, realm = strsplit( "-", player_name, 2 );

    if Vantage.Database.profile.ConvertCyrillic then
        player_name = "";
        for i = 1, name:utf8len() do
            local c = name:utf8sub( i, i );
            if Constants.CyrillicToRomanian[ c ] then
                player_name = player_name .. Constants.CyrillicToRomanian[ c ];

                --
                -- Uppercase the first character
                --
                if i == 1 then
                    player_name = player_name:gsub( "^.", strupper );
                end

            else
                player_name = player_name .. c;

            end
        end

        name = player_name
        if realm then
            player_name = player_name .. "-" .. realm;
        end
    end

    if self.config.ShowRealmNames then
        name = player_name
    end

    self:SetText( name );
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
--- @param player_details any
---
function EnemyName:PlayerDetailsChanged( player_details )
    if self.enabled then
        self:SetName();
    end
end

-------------------------------------------------------------------------------
---@script: resource.lua
---@author: zimawhit3
---@desc:   This module implements the resource frame for the EnemyFrame.
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
local LSM           = LibStub( "LibSharedMedia-3.0" )

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame   = CreateFrame
local Mixin         = Mixin
local PowerBarColor = PowerBarColor
local UnitPower     = UnitPower
local UnitPowerMax  = UnitPowerMax
local UnitPowerType = UnitPowerType

-----------------------------------------
--                Ace3
----------------------------------------- 
local AceGUIWidgetLSMlists  = AceGUIWidgetLSMlists

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                 EnemyFrame Resource
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------
local ENEMY_RESOURCE_FLAGS = { SetZeroHeightWhenDisabled = true };

---
---
---
local ENEMY_RESOURCE_OPTIONS = function( location )
    return
    {
        Texture =
        {
            type            = "select",
            name            = L.BarTexture,
            desc            = L.PowerBar_Texture_Desc,
            dialogControl   = 'LSM30_Statusbar',
            values          = AceGUIWidgetLSMlists.statusbar,
            width           = "normal",
            order           = 3
        },
        Fake = Constants.AddHorizontalSpacing( 4 ),
        Background =
        {
            type        = "color",
            name        = L.BarBackground,
            desc        = L.PowerBar_Background_Desc,
            hasAlpha    = true,
            width       = "normal",
            order       = 5
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyResourceConfig
---
local ENEMY_RESOURCE_DEFAULT_SETTINGS =
{
    Enabled         = true,
    Parent          = "Button",
    Height          = 5,
    Texture         = 'Blizzard Raid Bar',
    Background      = { 0, 0, 0, 0.66 },
    ActivePoints    = 2,
    Points =
    {
        {
            Point           = "BOTTOMLEFT",
            RelativeFrame   = "Class",
            RelativePoint   = "BOTTOMRIGHT",
        },
        {
            Point           = "BOTTOMRIGHT",
            RelativeFrame   = "Button",
            RelativePoint   = "BOTTOMRIGHT",
        }
    }
};

---
--- @class EnemyResource : StatusBar
---
local EnemyResource =
{
    ---
    --- @type Texture
    ---
    ---
    ---
    background = nil,

    --- 
    --- @type EnemyResourceConfig
    ---
    config = ENEMY_RESOURCE_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type table
    ---
    flags = ENEMY_RESOURCE_FLAGS;

    ---
    --- @type number
    ---
    ---
    ---
    max_value = 0,

    ---
    --- @type boolean
    ---
    position_set = false,

    ---
    --- @type string
    ---
    ---
    ---
    power_token = "",
};

-----------------------------------------
--                 Private
-----------------------------------------

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create a new `EnemyResource` for the `EnemyFrame`.
---
--- @param  enemy   EnemyFrame  The `EnemyFrame` to create a resource statusbar for.
--- @return EnemyResource|StatusBar
---
function Vantage:NewEnemyResource( enemy )
    local resource_frame    = CreateFrame( "StatusBar", nil, enemy );
    local enemy_resource    = Mixin( resource_frame, EnemyResource );
    enemy_resource:Initialize();
    return enemy_resource;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyResourceConfig()
    return self.NewModuleConfig(
        "Resource",
        ENEMY_RESOURCE_DEFAULT_SETTINGS,
        ENEMY_RESOURCE_OPTIONS,
        ENEMY_RESOURCE_FLAGS
    );
end

---
---
---
function EnemyResource:ApplyAllSettings()
    self:SetHeight( self.config.Height or 0.01 );
    self:SetStatusBarTexture( LSM:Fetch( "statusbar", self.config.Texture ) );
    self.background:SetVertexColor( unpack( self.config.Background ) );
end

---
---
---
--- @param power_token string
---
function EnemyResource:CheckForNewPowerColor( power_token )
    if self.power_token ~= power_token then
        local color = PowerBarColor[ power_token ];
        if color then
            self:SetStatusBarColor( color.r, color.g, color.b );
            self.power_token = power_token;
        end
    end
end

---
---
---
function EnemyResource:Initialize()
    self:SetMinMaxValues( 0, 1 );
    self.max_value = 1;

    self.background = self:CreateTexture( nil, "BACKGROUND", nil, 2 );
    self.background:SetAllPoints();
    self.background:SetTexture( "Interface/Buttons/WHITE8X8" );
end

---
---
---
function EnemyResource:Reset()
    --
    -- Rage and Runic power start at 0
    --
    if self.power_token == "RAGE" or self.power_token == "RUNIC_POWER" then
        self:SetValue( 0 );
    else
        self:SetMinMaxValues( 0, 1 );
        self.max_value = 1;
        self:SetValue( 1 );
    end
end

---
---
---
--- @param max number?
---
function EnemyResource:UpdateMinMaxValues( max )
    if max and max ~= self.max_value then
        self:SetMinMaxValues( 0, max );
        self.max_value = max;
    end
end

-----------------------------------------
--                Callbacks
-----------------------------------------

---
---
---
--- @param player_info PlayerInfo
---
function EnemyResource:PlayerDetailsChanged( player_info )
    local class_info = Constants.Classes[ player_info.class ];
    if class_info then
        self:CheckForNewPowerColor( class_info.resource );
    end

    --
    -- Rage and Runic power start at 0
    --
    if self.power_token == "RAGE" or self.power_token == "RUNIC_POWER" then
        self:SetValue( 0 );
    end

end

---
---
---
--- @param unit_id UnitId
---
function EnemyResource:UpdatePowerByUnitId( unit_id )
    if self.enabled then
        self:CheckForNewPowerColor( select( 2, UnitPowerType( unit_id ) ) );
        self:UpdateMinMaxValues( UnitPowerMax( unit_id ) );
        self:SetValue( UnitPower( unit_id ) );
    end
end

---
---
---
--- @param power_token  string
--- @param power        number
--- @param max_power    number
---
function EnemyResource:UpdatePower( power_token, power, max_power )
    if self.enabled then
        self:CheckForNewPowerColor( power_token );
        self:UpdateMinMaxValues( max_power );
        self:SetValue( power );
    end
end

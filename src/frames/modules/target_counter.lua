-------------------------------------------------------------------------------
---@script: target_counter.lua
---@author: zimawhit3
---@desc:   This module implements the target counter text for the EnemyFrame.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...;
local L             = Constants.L;
local LibStub       = LibStub

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local Mixin         = Mixin

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                            EnemyFrame Target Counter
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
local TARGET_COUNTER_OPTIONS = function( location )
    return
    {
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
        },
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class TargetCounterConfig
---
local TARGET_COUNTER_DEFAULT_SETTINGS =
{
    Enabled = true,
    Parent = "Healthbar",
    ActivePoints = 2,
    Points =
    {
        {
            Point = "TOPRIGHT",
            RelativeFrame = "Healthbar",
            RelativePoint = "TOPRIGHT",
            OffsetX = -5,
            OffsetY = 0
        },
        {
            Point = "BOTTOMRIGHT",
            RelativeFrame = "Healthbar",
            RelativePoint = "BOTTOMRIGHT",
            OffsetX = -5,
            OffsetY = 0
        },
    },
    Text =
    {
        FontSize        = 13,
        FontOutline     = "",
        FontColor       = { 1, 1, 1, 1 },
        EnableShadow    = true,
        ShadowColor     = { 0, 0, 0, 1 },
        JustifyH        = "RIGHT",
        JustifyV        = "MIDDLE"
    }
};

---
--- @class TargetCounter : VantageFontString
---
local TargetCounter =
{
    ---
    --- @type TargetCounterConfig
    ---
    config = TARGET_COUNTER_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    --- 
    enabled = true,

    ---
    --- @type EnemyFrame
    ---
    enemy = nil,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                Private
-----------------------------------------

-----------------------------------------
--                 Public
-----------------------------------------

---
---
---
--- @param enemy EnemyFrame
--- @return TargetCounter|VantageFontString|FontString
---
function Vantage:NewTargetCounter( enemy )
    local ti_fs             = self.NewFontString( enemy );
    local target_counter    = Mixin( ti_fs, TargetCounter );
    target_counter.enemy    = enemy;
    return target_counter;
end

---
---
---
function Vantage:NewTargetCounterConfig()
    return self.NewModuleConfig( "Targetcounter", TARGET_COUNTER_DEFAULT_SETTINGS, TARGET_COUNTER_OPTIONS );
end

---
---
---
function TargetCounter:ApplyAllSettings()
    self:ApplyFontStringSettings( self.config.Text );
    self:SetText( "0" );
end

---
---
---
function TargetCounter:Reset()
    --
    -- Dont SetWidth before Hide() otherwise it won't work as aimed
    --
    if self:GetFont() then
        self:SetText( "0" );
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Sets the `TargetCounter` to the number of ally players currently
--- targeting the `EnemyFrame`.
---
function TargetCounter:UpdateTargetIndicators()
    if self.enabled and self.enemy then
        self:SetText( tostring( #self.enemy.targeted_by ) );
    end
end

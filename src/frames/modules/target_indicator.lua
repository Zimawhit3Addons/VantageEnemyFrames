-------------------------------------------------------------------------------
---@script: target_indicator.lua
---@author: zimawhit3
---@desc:   This module implements ally target indicator frames for the EnemyFrame.
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
local mfloor        = math.floor

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame   = CreateFrame
local Mixin         = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                            EnemyFrame Target Indicator
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
--- @param location any
--- @return table
---
local TARGET_INDICATOR_OPTIONS = function( location )
    return
    {
        IconWidth =
        {
            type    = "range",
            name    = L.Width,
            min     = 1,
            max     = 20,
            step    = 1,
            width   = "normal",
            order   = 1
        },
        IconHeight =
        {
            type    = "range",
            name    = L.Height,
            min     = 1,
            max     = 20,
            step    = 1,
            width   = "normal",
            order   = 2,
        },
        IconSpacing =
        {
            type    = "range",
            name    = L.HorizontalSpacing,
            min     = 1,
            max     = 20,
            step    = 1,
            width   = "normal",
            order   = 3,
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class TargetIndicatorConfig
---
local TARGET_INDICATOR_DEFAULT_SETTINGS =
{
    Enabled = true,
    Parent = "Healthbar",
    IconWidth = 8,
    IconHeight = 10,
    IconSpacing = 10,
    ActivePoints = 2,
    Points =
    {
        {
            Point = "TOPLEFT",
            RelativeFrame = "Healthbar",
            RelativePoint = "TOPLEFT",
            OffsetX = 0
        },
        {
            Point = "BOTTOMRIGHT",
            RelativeFrame = "Healthbar",
            RelativePoint = "BOTTOMRIGHT",
            OffsetX = 0
        }
    },
};

---
--- @class TargetIndicator
---
local TargetIndicator =
{
    ---
    --- @type TargetIndicatorConfig
    ---
    config = TARGET_INDICATOR_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    --- 
    enabled = true,

    ---
    --- @type EnemyFrame
    ---
    enemy = nil,

    ---
    --- @type table<number, BackdropTemplate|Frame>
    ---
    symbols = nil,

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
--- @return TargetIndicator | Frame
---
function Vantage:NewTargetIndicator( enemy )
    local ti_frame          = CreateFrame( "Frame", nil, enemy );
    local target_indicator  = Mixin( ti_frame, TargetIndicator );
    target_indicator:Initialize( enemy );
    return target_indicator;
end

---
---
---
function Vantage:NewTargetIndicatorConfig()
    return self.NewModuleConfig( "Targetindicator", TARGET_INDICATOR_DEFAULT_SETTINGS, TARGET_INDICATOR_OPTIONS );
end

---
---
---
function TargetIndicator:ApplyAllSettings()
    for i = 1, #self.symbols do
        self:SetSizeAndPosition( i );
    end
end

---
---
---
--- @param enemy EnemyFrame
---
function TargetIndicator:Initialize( enemy )
    self.enemy      = enemy;
    self.symbols    = {};
end

---
---
---
function TargetIndicator:Reset()
    for _, symbol in pairs( self.symbols ) do
        symbol:Hide();
    end
end

---
---
---
--- @param index any
---
function TargetIndicator:SetSizeAndPosition( index )
    local config = self.config;
    local symbol = self.symbols[ index ];
    if symbol and config.IconWidth and config.IconHeight then

        symbol:SetSize( config.IconWidth, config.IconHeight );
        --
        -- 1: 0, 0 2: -10, 0 3: 10, 0 4: -20, 0 > i = even > left, uneven > right
        --
        symbol:SetPoint( "TOP", mfloor( index / 2 ) * ( index % 2 == 0 and -config.IconSpacing or config.IconSpacing ), 0 );
    end

end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
function TargetIndicator:UpdateTargetIndicators()
    if self.enabled and self.enemy then

        for i = 1, #self.enemy.targeted_by do

            local current_player = self.enemy.targeted_by[ i ];
            local current_symbol = self.symbols[ i ];
            if not current_symbol then

                current_symbol = CreateFrame( "Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate" );

                ---@diagnostic disable-next-line: param-type-mismatch
                current_symbol:SetBackdrop({
                    bgFile      = "Interface/Buttons/WHITE8X8", -- drawlayer "BACKGROUND"
                    edgeFile    = 'Interface/Buttons/WHITE8X8', -- drawlayer "BORDER"
                    edgeSize    = 1
                });

                ---@diagnostic disable-next-line: param-type-mismatch
                current_symbol:SetBackdropBorderColor( 0, 0, 0, 1 );

                self.symbols[ i ] = current_symbol;
                self:SetSizeAndPosition( i );
            end

            local class_color = current_player:ClassColor();

            ---@diagnostic disable-next-line: param-type-mismatch
            current_symbol:SetBackdropColor( class_color.r, class_color.g, class_color.b );
            current_symbol:Show();
        end

        --
        -- Hide no longer used ones
        --
        for i = #self.enemy.targeted_by + 1, #self.symbols do
            self.symbols[ i ]:Hide();
        end
    end
end

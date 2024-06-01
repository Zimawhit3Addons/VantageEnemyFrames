-------------------------------------------------------------------------------
---@script: combat_indicator.lua
---@author: zimawhit3
---@desc:   This module implements combat indicators for the EnemyFrame.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants          = ...
local L                     = Constants.L
local LibStub               = LibStub
local LibSpellIconSelector  = LibStub( "LibSpellIconSelector" );

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame		    = CreateFrame
local Mixin                 = Mixin
local UnitAffectingCombat   = UnitAffectingCombat

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                           EnemyFrame Combat Indicator
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
--- Combat drops after 6 seconds.
---
local COMBAT_COOLDOWN = 6;

---
---
---
local COMBAT_INDICATOR_OPTIONS = function( location )
    local t = {};
    t.Combat =
    {
        type = "group",
        name = L.Combat,
        inline = true,
        order = 4,
        get = function( option )
            return Constants.GetOption( location, option );
        end,
        set = function( option, ... )
            return Constants.SetOption( location, option, ... );
        end,
        args =
        {
            Enabled =
            {
                type = "toggle",
                name = VIDEO_OPTIONS_ENABLED,
                order = 1
            },
            Icon =
            {
                type = "execute",
                name = L.Icon,
                image = function() return location.CombatIcon end,
                func = function( option )
                    --
                    -- hold a copy of the option table for the OnOkayButtonPressed otherwise the table will be empty
                    --
                    local optiontable = {};
                    Mixin( optiontable, option );
                    ---@diagnostic disable-next-line: undefined-field
                    LibSpellIconSelector:Show( location, function( spelldata )
                        Constants.SetOption( location, optiontable, spelldata.icon );
                        Vantage:NotifyChange();
                    end)
                end,
                disabled = function() return not location.Enabled end,
                width = "half",
                order = 2,
            },
            CooldownSettings =
            {
                type = "group",
                name = L.Countdowntext,
                get = function( option )
                    return Constants.GetOption( location.Cooldown, option );
                end,
                set = function( option, ... )
                    return Constants.SetOption( location.Cooldown, option, ... );
                end,
                order = 8,
                args = Constants.AddCooldownSettings( location.Cooldown ),
            },
        };
    };
	return t;
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class CombatIndicatorConfig
---
local COMBAT_INDICATOR_DEFAULT_SETTINGS =
{
    Enabled = true,
    ActivePoints = 1,
    Parent = "Healthbar",
    Width = 18,
    Height = 18,
    Points =
    {
        {
            Point           = "TOPRIGHT",
            RelativeFrame   = "Targetcounter",
            RelativePoint   = "TOPLEFT",
            OffsetX         = -2,
            OffsetY         = -2
        }
    },
    Cooldown =
    {
        ShowNumber = true,
        FontSize = 8,
        FontOutline = "OUTLINE",
        EnableShadow = false,
        ShadowColor = { 0, 0, 0, 1 },
    },
    CombatIcon = 132147,
};

---
--- @class CombatIndicator : Frame
---
local CombatIndicator =
{
    --- 
    --- @type CombatIndicatorConfig
    ---
    config = COMBAT_INDICATOR_DEFAULT_SETTINGS,

    ---
    --- @type Frame
    ---
    combat = nil,

    ---
    --- @type Texture
    ---
    combat_texture = nil,

    ---
    --- @type Cooldown|VantageCoolDown
    ---
    cooldown = nil,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type boolean
    ---
    position_set = false,

    ---
    --- @type boolean
    ---
    in_combat = false,
};

-----------------------------------------
--                 Private
-----------------------------------------

-----------------------------------------
--                 Public
-----------------------------------------

---
---
---
--- @param  enemy   EnemyFrame
--- @return CombatIndicator|Frame
---
function Vantage:NewCombatIndicator( enemy )
    local ci_frame          = CreateFrame( "Frame", nil, enemy );
    local combat_indicator  = Mixin( ci_frame, CombatIndicator );
    combat_indicator:Initialize();
    return combat_indicator;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewCombatIndicatorConfig()
    return self.NewModuleConfig( "Combatindicator", COMBAT_INDICATOR_DEFAULT_SETTINGS, COMBAT_INDICATOR_OPTIONS );
end

---
---
---
function CombatIndicator:ApplyAllSettings()
    self.combat_texture:SetTexture( self.config.CombatIcon );
    self.cooldown:ApplyCooldownSettings( self.config.Cooldown, true, true, { 0, 0, 0, 0.5 } );
end

---
---
---
function CombatIndicator:Reset()
    self:Remove();
    self.cooldown:Clear();
end

---
---
---
function CombatIndicator:Initialize()
    self.in_combat = false;
    self.cooldown = Vantage.NewCoolDown( self, self.Remove );
    self.combat = CreateFrame( "Frame", nil, self );
    self.combat:SetAllPoints();
    self.combat:Hide();
    self.combat_texture = self.combat:CreateTexture( nil, "BACKGROUND" );
    self.combat_texture:SetAllPoints();
    self.combat:SetFrameLevel( self:GetFrameLevel() + 1 );
end

---
---
---
function CombatIndicator:Remove()
    self.in_combat = false;
    if self.combat:IsShown() then
        self.combat:Hide();
    end
end

---
---
---
--- @param time number
---
function CombatIndicator:UpdateCombatCooldown( time )
    if self.enabled then
        if not self.in_combat then
            self.in_combat = true;
            self.combat:Show();
        end
        self.cooldown:Clear();
        self.cooldown:SetCooldown( time, COMBAT_COOLDOWN );
    end
end

---
---
---
--- @param in_combat boolean
---
function CombatIndicator:UpdateCombatInternal( in_combat )
    if self.in_combat ~= in_combat then
        self.combat:SetShown( in_combat );
        self.in_combat = in_combat;
    end
end

---
---
---
--- @param unit_id UnitId
---
function CombatIndicator:UpdateCombat( unit_id )
    if self.enabled then
        self:UpdateCombatInternal( UnitAffectingCombat( unit_id ) );
    end
end

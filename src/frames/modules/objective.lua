-------------------------------------------------------------------------------
---@script: objective.lua
---@author: zimawhit3
---@desc:   This module implements objective aura frames for the EnemyFrame.
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
local CreateFrame       = CreateFrame
local GetSpellTexture   = GetSpellTexture
local Mixin             = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                               EnemyFrame Objective
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
local OBJECTIVE_OPTIONS = function( location )
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
        CooldownTextSettings =
        {
            type = "group",
            name = L.Countdowntext,
            inline = true,
            get = function( option )
                return Constants.GetOption( location.Cooldown, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Cooldown, option, ... );
            end,
            order = 2,
            args = Constants.AddCooldownSettings( location.Cooldown );
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyObjectiveConfig
---
local ENEMY_OBJECTIVE_DEFAULT_SETTINGS =
{
    Enabled = true,
    Parent = "Button",
    Width = 36,
    ActivePoints = 2,
    Points =
    {
        {
            Point           = "TOPRIGHT",
            RelativeFrame   = "Targetcounter",
            RelativePoint   = "TOPLEFT",
            OffsetX         = -2
        },
        {
            Point           = "BOTTOMRIGHT",
            RelativeFrame   = "Targetcounter",
            RelativePoint   = "BOTTOMLEFT",
            OffsetX         = -2
        }
    },
    Cooldown =
    {
        ShowNumber      = true,
        FontSize        = 12,
        FontOutline     = "OUTLINE",
        EnableShadow    = false,
        ShadowColor     = { 0, 0, 0, 1 },
    },
    Text =
    {
        FontSize        = 17,
        FontOutline     = "THICKOUTLINE",
        FontColor       = { 1, 1, 1, 1 },
        EnableShadow    = false,
        ShadowColor     = { 0, 0, 0, 1 }
    }
};

---
--- @class EnemyObjective : Frame
---
local EnemyObjective =
{
    ---
    --- @type VantageFontString | FontString
    ---
    aura_text = nil,

    ---
    ---
    ---
    application = 0,

    ---
    --- @type EnemyObjectiveConfig
    ---
    config = ENEMY_OBJECTIVE_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type EnemyFrame
    --- 
    enemy = nil,

    ---
    --- @type VantageCoolDown | Cooldown
    ---
    ---
    ---
    cooldown = nil,

    ---
    --- @type Texture
    ---
    icon = nil,

    ---
    --- @type boolean
    ---
    position_set = false,

    ---
    --- @type boolean
    ---
    has_objective = false,
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
--- @param enemy EnemyFrame
--- @return EnemyObjective|Frame
---
function Vantage:NewEnemyObjective( enemy )
    local class_frame   = CreateFrame( "Frame", nil, enemy );
    local enemy_class   = Mixin( class_frame, EnemyObjective );
    enemy_class:Initialize( enemy );
    return enemy_class;
end

---
---
---
function Vantage:NewEnemyObjectiveConfig()
    return self.NewModuleConfig( "Objective", ENEMY_OBJECTIVE_DEFAULT_SETTINGS, OBJECTIVE_OPTIONS );
end

---
---
---
function EnemyObjective:ApplyAllSettings()
    local config = self.config;
	self.aura_text:ApplyFontStringSettings( config.Text );
	self.cooldown:ApplyCooldownSettings( config.Cooldown, true, true, { 0, 0, 0, 0.75 } );
end

---
---
---
--- @param enemy EnemyFrame
---
function EnemyObjective:Initialize( enemy )

    self:SetFrameLevel( enemy:GetFrameLevel() + 5 );

    self.enemy = enemy;

    self.icon = self:CreateTexture( nil, "BORDER" );
    self.icon:SetAllPoints();
    self.icon:SetAlpha( 0.5 );

    self:Hide();

    self.aura_text = Vantage.NewFontString( self );
    self.aura_text:SetAllPoints()
	self.aura_text:SetJustifyH( "CENTER" );

    self.cooldown = Vantage.NewCoolDown( self, self.Reset );
    self.cooldown:Hide();

    self:SetScript( "OnSizeChanged", self.OnSizeChanged );
end

---
---
---
function EnemyObjective:Reset()
    self:Hide();
	self.icon:SetTexture();
	if self.aura_text:GetFont() then
        self.aura_text:SetText( "" );
    end
    self.cooldown:Clear();
    self.application = 0;
    self.has_objective = false;
end

---
---
--- @param aura VantageAura|AuraData
---
function EnemyObjective:SearchForDebuffs( aura )
    local bg_debuffs = Vantage.BattleGroundDebuffs;
    for i = 1, #bg_debuffs do
        if aura.spellId == bg_debuffs[ i ] and aura.applications ~= self.application then
            self.aura_text:SetText( tostring( aura.applications ) );
            self.application = aura.applications;
        end
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Invoked when a `EnemyObjective`'s size changes.
---
--- @param width     number         The width of the trinket frame.
--- @param height    number         The height of the trinket frame.
---
function EnemyObjective:OnSizeChanged( width, height )
    Vantage.CropImage( self.icon, width, height );
end

---
---
---
function EnemyObjective:ShowObjective()
    if self.enabled and not self.has_objective then
        if Vantage.BattleGroundBuffs then
            self.icon:SetTexture( GetSpellTexture( Vantage.BattleGroundBuffs[ self.enemy.player_info.faction ] ) );
            self:Show();
            self.has_objective = true;
        end
        if self.aura_text:GetFont() then
            self.aura_text:SetText( "" );
        end
        self.Value = nil;
    end
end

---
---
---
function EnemyObjective:HideObjective()
    if self.has_objective then
        self:Reset();
    end
end

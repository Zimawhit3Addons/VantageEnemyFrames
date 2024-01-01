---------------------------------------------------------------------------------
---@script: healthbar.lua
---@author: zimawhit3
---@desc:   This module implements the healthbar frame for the EnemyFrame.   
---------------------------------------------------------------------------------

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
local ceil = math.ceil

-----------------------------------------
--              Blizzard
-----------------------------------------
local AbbreviateLargeNumbers                = AbbreviateLargeNumbers
local CreateColor                           = CreateColor
local CreateFrame                           = CreateFrame
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local Mixin                                 = Mixin

-----------------------------------------
--                Ace3
-----------------------------------------
local AceGUIWidgetLSMlists = AceGUIWidgetLSMlists

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                              EnemyFrame HealthBar
-------------------------------------------------------------------------------

---------------------------------
--           Constants
---------------------------------

---
--- 
---
local HEALTH_BAR_TEXT_TYPES =
{
    ---
    --- @type string
    ---
    --- Displays the health bar's text as the remaining health.
    ---
	health = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_HEALTH,

    ---
    --- @type string
    ---
    --- Displays the health bar's text as the health lost.
    ---
    losthealth = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_LOSTHEALTH,

    ---
    --- @type string
    ---
    --- Displays the health bar's text as a percent of total health.
    ---
    perc = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_PERC
};

---
---
--- @param location table
---
local HEALTH_BAR_OPTIONS = function( location )
    return
    {
		Texture =
        {
			type            = "select",
			name            = L.BarTexture,
			desc            = L.HealthBar_Texture_Desc,
			dialogControl   = 'LSM30_Statusbar',
			values          = AceGUIWidgetLSMlists.statusbar,
			width           = "normal",
			order           = 1
		},
		Filler = Constants.AddHorizontalSpacing( 2 ),
		Background =
        {
			type        = "color",
			name        = L.BarBackground,
			desc        = L.HealthBar_Background_Desc,
			hasAlpha    = true,
			width       = "normal",
			order       = 3
		},
		Fake1 = Constants.AddVerticalSpacing( 4 ),
		HealthPrediction_Enabled =
        {
			type    = "toggle",
			name    = COMPACT_UNIT_FRAME_PROFILE_DISPLAYHEALPREDICTION,
			width   = "normal",
			order   = 5,
		},
		HealthTextEnabled =
        {
			type    = "toggle",
			name    = L.HealthTextEnabled,
			width   = "normal",
			order   = 6,
		},
		HealthTextType =
        {
			type        = "select",
			name        = L.HealthTextType,
			width       = "normal",
			values      = HEALTH_BAR_TEXT_TYPES,
			disabled    = function() return not location.HealthTextEnabled end,
			order       = 7,
		},
		HealthText =
        {
			type = "group",
			name = L.HealthTextSettings,
			get = function( option )
				return Constants.GetOption( location.HealthText, option );
			end,
			set = function( option, ... )
				return Constants.SetOption( location.HealthText, option, ... );
			end,
			disabled = function() return not location.HealthTextEnabled end,
			inline = true,
			order = 8,
			args = Constants.AddNormalTextSettings( location.HealthText )
		}
	};
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class HealthBarConfig
---
local HEALTH_BAR_DEFAULTS =
{
    Parent = "Button",
    Enabled = true,
    Texture = 'Blizzard Raid Bar',
    Background = { 0.0, 0.0, 0.0, 0.66 },
	HealthPrediction_Enabled = true,
    HealthTextEnabled = false,
    HealthTextType = HEALTH_BAR_TEXT_TYPES.health,
    HealthText =
    {
		FontSize = 17,
        FontOutline = "",
        FontColor = { 1, 1, 1, 1 },
        EnableShadow = false,
        ShadowColor = { 0, 0, 0, 1 },
        JustifyH = "CENTER",
        JustifyV = "TOP",
	},
    ActivePoints = 2,
    Points =
    {
		{
			Point           = "BOTTOMLEFT",
			RelativeFrame   = "Resource",
			RelativePoint   = "TOPLEFT",
		},
		{
			Point           = "TOPRIGHT",
			RelativeFrame   = "Button",
			RelativePoint   = "TOPRIGHT",
		}
	}
};

---
--- @class HealthBar : StatusBar
---
local HealthBar =
{
    ---
    --- @type Texture
    ---
    background = nil,

    ---
    --- @type HealthBarConfig
    ---
    config = HEALTH_BAR_DEFAULTS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type Texture
    ---
    heal_absorb = nil,

    ---
    --- @type Texture
    ---
    heal_absorb_left_shadow = nil,

    ---
    --- @type Texture
    ---
    heal_absorb_right_shadow = nil,

    ---
    --- @type Texture
    ---
    heal_absorb_total_overlay = nil,

    ---
    --- @type Texture
    ---
    heal_absorb_total = nil,

    ---
    --- @type Texture
    ---
    health_prediction = nil,

    ---
    --- @type Texture
    --- 
    other_health_prediction = nil,

    ---
    --- @type Texture
    ---
    over_absorb_glow = nil,

    ---
    --- @type Texture
    ---
    over_heal_glow = nil,

    ---
    --- @type VantageFontString|FontString
    ---
    health_text = nil,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                 Private
-----------------------------------------

---
--- Initialize the health prediction textures of the healthbar.
---
--- @param texture   Texture The texture of the frame to initialize.
--- @param other     boolean True if the texture is for heals from another player. Otherwise, false.
---
local function init_health_prediction_texture( texture, other )

    texture:ClearAllPoints();
    texture:SetColorTexture( 1, 1, 1 );

    if other then
        texture:SetGradient( "VERTICAL", CreateColor( 11 / 255, 53 / 255, 43 / 255, 1 ), CreateColor( 21 / 255, 89 / 255, 72 / 255, 1 ) );
    else
        texture:SetGradient( "VERTICAL", CreateColor( 8 / 255, 93 / 255, 72 / 255, 1 ), CreateColor( 11 / 255, 136 / 255, 105 / 255, 1 ) );
        texture:SetVertexColor( 0.0, 0.659, 0.608 );
    end

end

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create a new `HealthBar` for the `EnemyFrame`.
---
--- @param enemy_frame EnemyFrame
--- @return HealthBar|StatusBar
---
function Vantage:NewHealthBar( enemy_frame )
    local frame     = CreateFrame( "StatusBar", nil, enemy_frame );
    local healthbar = Mixin( frame, HealthBar );
    healthbar:Initialize( enemy_frame );
    return healthbar;
end

---
---
---
function Vantage:NewHealthBarConfig()
    return self.NewModuleConfig( "Healthbar", HEALTH_BAR_DEFAULTS, HEALTH_BAR_OPTIONS );
end

---
--- Apply all saved settings to the `HealthBar`.
---
function HealthBar:ApplyAllSettings()
    local config        = self.config;
    local saved_texture = LSM:Fetch( "statusbar", config.Texture );
    if saved_texture then
        self:SetStatusBarTexture( saved_texture );
    end

    self.background:SetVertexColor( unpack( config.Background ) );

    if config.HealthTextEnabled then
        self.health_text:Show();
    else
        self.health_text:Hide();
    end

    self.health_text:ApplyFontStringSettings( config.HealthText );
end

---
--- Initialize the `HealthBar` onto the parent `EnemyFrame`.
---
--- @param parent_frame EnemyFrame
---
function HealthBar:Initialize( parent_frame )

    self:SetMinMaxValues( 0, 1 );

    self.health_text = Vantage.NewFontString( self );
	self.health_text:SetDrawLayer( 'OVERLAY', 2 );
    self.health_text:SetPoint( "BOTTOMLEFT", self, "BOTTOMLEFT", 3, 3 );
	self.health_text:SetPoint( "TOPRIGHT", self, "TOPRIGHT", -3, -3 );

    self.health_prediction          = self:CreateTexture( nil, "BORDER", nil, 5 );
    self.other_health_prediction    = self:CreateTexture( nil, "BORDER", nil, 5 );

    init_health_prediction_texture( self.health_prediction, false );
    init_health_prediction_texture( self.other_health_prediction, true );

    self.heal_absorb = self:CreateTexture( nil, "ARTWORK", nil, 1 );
    self.heal_absorb:ClearAllPoints();
    self.heal_absorb:SetTexture( "Interface\\RaidFrame\\Absorb-Fill", "REPEAT", "REPEAT" );

    self.heal_absorb_left_shadow = self:CreateTexture( nil, "ARTWORK", nil, 1 );
    self.heal_absorb_left_shadow:ClearAllPoints();

    self.heal_absorb_right_shadow = self:CreateTexture( nil, "ARTWORK", nil, 1 );
    self.heal_absorb_right_shadow:ClearAllPoints();

    self.heal_absorb_total_overlay = self:CreateTexture( nil, "BORDER", nil, 6 );
    self.heal_absorb_total_overlay:SetTexture( "Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT" );

    self.heal_absorb_total = self:CreateTexture( nil, "BORDER", nil, 5 );
    self.heal_absorb_total:SetTexture( "Interface\\RaidFrame\\Shield-Fill" );
    self.heal_absorb_total_overlay:SetAllPoints( self.heal_absorb_total );

    self.over_absorb_glow = self:CreateTexture( nil, "ARTWORK", nil, 2 );
    self.over_absorb_glow:SetTexture( "Interface\\RaidFrame\\Shield-Overshield" );
    self.over_absorb_glow:SetBlendMode( "ADD" );
    self.over_absorb_glow:SetPoint( "BOTTOMLEFT", self, "BOTTOMRIGHT", -7, 0 );
    self.over_absorb_glow:SetPoint( "TOPLEFT", self, "TOPRIGHT", -7, 0 );
    self.over_absorb_glow:SetWidth( 16 );
    self.over_absorb_glow:Hide();

    self.over_heal_glow = self:CreateTexture( nil, "ARTWORK", nil, 2 );
    self.over_heal_glow:SetTexture( "Interface\\RaidFrame\\Absorb-Overabsorb" );
    self.over_heal_glow:SetBlendMode( "ADD" );
    self.over_heal_glow:SetPoint( "BOTTOMRIGHT", self, "BOTTOMLEFT", 7, 0 );
    self.over_heal_glow:SetPoint( "TOPRIGHT", self, "TOPLEFT", 7, 0 );
    self.over_heal_glow:SetWidth( 16 );
    self.over_heal_glow:Hide();

    self.background = self:CreateTexture( nil, "BACKGROUND", nil, 2 );
    self.background:SetAllPoints( parent_frame );
    self.background:SetTexture( "Interface/Buttons/WHITE8X8" );
end

---
---
---
function HealthBar:Reset()
    -- TODO
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Update a `HealthBar` to the new enemy's class color.
---
--- @param player_details PlayerInfo
---
function HealthBar:PlayerDetailsChanged( player_details )
    local class_color = RAID_CLASS_COLORS[ player_details.class ];
    self:SetStatusBarColor( class_color.r, class_color.g, class_color.b );
    self:SetMinMaxValues( 0, 1 );
    self:SetValue( player_details.alive and 1 or 0 );
    self.health_text:Hide();
    self.heal_absorb_total_overlay:Hide();
    self.heal_absorb_total:Hide();
end

---
---
---
--- @param unit_id      UnitId?
--- @param health       number
--- @param max_health   number
---
function HealthBar:UpdateHealth( unit_id, health, max_health )
    -- TODO: We should check if the player is alive here for broadcasted messages
    self:SetMinMaxValues( 0, max_health );
    self:SetValue( health );

    local config = self.config;
    if not config.HealthTextEnabled then
        return;
    end

    if config.HealthTextType == HEALTH_BAR_TEXT_TYPES.health then
        health = AbbreviateLargeNumbers( health );
        self.health_text:SetText( health );
        self.health_text:Show();
    elseif config.HealthTextType == HEALTH_BAR_TEXT_TYPES.losthealth then
        local health_lost = max_health - health;
        if ( health_lost > 0 ) then
            health_lost = AbbreviateLargeNumbers( health_lost );
            self.health_text:SetText( "-" .. health_lost );
            self.health_text:Show();
        else
            self.health_text:Hide();
        end
    elseif ( config.HealthTextType == HEALTH_BAR_TEXT_TYPES.perc ) and ( max_health > 0 ) then
        local perc = ceil( 100 * ( health / max_health ) );
        self.health_text:SetFormattedText( "%d%%", perc );
        self.health_text:Show();
    else
        self.health_text:Hide();
    end

    if unit_id and CompactUnitFrame_UpdateHealPrediction then
        self.displayedUnit  = unit_id;
        self.optionTable    = { displayHealPrediction = self.config.HealthPrediction_Enabled };
        CompactUnitFrame_UpdateHealPrediction( self );
    end

end

---
---
---
function HealthBar:UnitDied()
    self:SetValue( 0 );
end

---
---
---
function HealthBar:UnitAlive()
    self:SetMinMaxValues( 0, 1 );
    self:SetValue( 1 );
end
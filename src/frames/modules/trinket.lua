-------------------------------------------------------------------------------
---@script: trinket.lua
---@author: zimawhit3
---@desc:   This module implements the trinket frame for enemy frames.   
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

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame           = CreateFrame
local GameTooltip           = GameTooltip
local GetItemIcon           = GetItemIcon
local Mixin                 = Mixin
local WOW_PROJECT_ID        = WOW_PROJECT_ID
local WOW_PROJECT_CLASSIC   = WOW_PROJECT_CLASSIC

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                              EnemyFrame Trinket
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------
local IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;

---
--- @param location any
--- @return table
---
local TRINKET_OPTIONS = function( location )
	return
    {
        ShowUnusedIcons =
        {
            type = "toggle",
            name = L.ShowUnusedIcons,
            order = 1
        },
		CooldownTextSettings =
        {
			type = "group",
			name = L.Countdowntext,
			inline = true,
			order = 2,
			get = function( option )
				return Constants.GetOption( location.Cooldown, option );
			end,
			set = function( option, ... )
				return Constants.SetOption( location.Cooldown, option, ... );
			end,
			args = Constants.AddCooldownSettings( location.Cooldown );
		}
	}
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class TrinketConfig
---
local TRINKET_DEFAULTS =
{
	Enabled = true,
    Parent = "Button",
    UseButtonHeightAsHeight = true,
    UseButtonHeightAsWidth = true,
    Cooldown =
    {
		ShowNumber = true,
        FontSize = 12,
        FontOutline = "OUTLINE",
        EnableShadow = false,
        ShadowColor = { 0, 0, 0, 1 },
	},
    ShowUnusedIcons = true,
};

---
--- @class Trinket : Frame
---
local Trinket =
{
    ---
    --- @type TrinketConfig
    ---
    --- The settings for the `Trinket` frame.
    ---
    config = TRINKET_DEFAULTS,

    ---
    --- @type VantageCoolDown|Cooldown
    ---
    --- The internal `Cooldown` effect used to display the trinket's cooldown.
    ---
    cooldown = nil,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type number
    ---
    faction = 0,

    ---
    --- @type Texture
    ---
    --- The item icon that provides visuals for the trinket on the `EnemyFrame`.
    ---
    icon = nil,

    ---
    --- @type number
    ---
    --- The SpellId of the trinket effect. Used to display
    --- helpful tooltips on mouse hover.
    ---
    spell_id = 0,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                 Private
-----------------------------------------

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Attatch a new `Trinket` frame to the `EnemyFrame`.
---
--- @param enemy_frame EnemyFrame
--- @return Trinket|Frame
---
function Vantage:NewTrinket( enemy_frame )
    local trinket_frame = CreateFrame( "frame", nil, enemy_frame );
    local trinket       = Mixin( trinket_frame, Trinket );
    trinket:Initialize( enemy_frame.player_info.faction );
    return trinket;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewTrinketConfig()
    return self.NewModuleConfig( "Trinket", TRINKET_DEFAULTS, TRINKET_OPTIONS );
end

---
---
---
function Trinket:ApplyAllSettings()
    self.cooldown:ApplyCooldownSettings( self.config.Cooldown, false, true, { 0, 0, 0, 0.5 } );

    if self.config.ShowUnusedIcons then
        if IsClassic then
            self.icon:SetTexture( GetItemIcon( self.faction == 0 and 18846 or 18856 ) );
        else
            self.icon:SetTexture( GetItemIcon( self.faction == 0 and 37865 or 37864 ) );
        end
    else
        self.icon:SetTexture();
    end
end

---
--- Initializes the `Trinket` frame's cooldown and icon.
---
--- @param faction number
---
function Trinket:Initialize( faction )

    self.faction    = faction;
    self.cooldown   = Vantage.NewCoolDown( self, self.OnCooldownDone );
    self.icon       = self:CreateTexture();

    self.icon:SetAllPoints();

    --
    -- Set the initial item icons and spellId. 
    -- 
    -- The actual spell_id used isn't too important since all 
    -- trinkets use the same item icon.
    --
    -- TODO: Could set Classic spellId's based on the enemy class.
    --
    self.spell_id = IsClassic and 23273 or 42292;

    self:HookScript( "OnEnter", self.OnEnter );
    self:HookScript( "OnLeave", self.OnLeave );
    self:SetScript( "OnSizeChanged", self.OnSizeChanged );
end

---
---
---
function Trinket:OnCooldownDone()
    if not self.config.ShowUnusedIcons then
        self.icon:SetTexture();
    end
end

---
---
---
function Trinket:OnEnter()
    if self.spell_id > 0 then
        Vantage:ShowToolTip( self, self.ShowToolTip );
    end
end

---
---
---
function Trinket:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
---
---
function Trinket:OnSizeChanged( width, height )
    Vantage.CropImage( self.icon, width, height );
end

---
---
---
--- @param spell_id     number
--- @param start_time   number
---
function Trinket:Start( spell_id, start_time )
    local trinket_data = Constants.TrinketData[ spell_id ];
    if trinket_data then
        self:SetCooldown( start_time, trinket_data.cd or 0 );
        return true;
    end
    return false;
end

---
---
---
function Trinket:ShowToolTip()
    -- TODO: Think this works on classic now
    if not IsClassic then
        GameTooltip:SetSpellByID( self.spell_id );
    end
end

---
---
---
--- @param start_time   number
--- @param duration     number
---
function Trinket:SetCooldown( start_time, duration )
    if start_time ~= 0 and duration ~= 0 then
        --
        --
        --
        if not self.config.ShowUnusedIcons then
            if IsClassic then
                self.icon:SetTexture( GetItemIcon( self.faction == 0 and 18846 or 18856 ) );
            else
                self.icon:SetTexture( GetItemIcon( self.faction == 0 and 37865 or 37864 ) );
            end
        end
        self.cooldown:SetCooldown( start_time, duration );
    else
        self.cooldown:Clear();
    end
end

---
--- Reset the trinket back to it's default state.
---
function Trinket:Reset()
    self.spell_id = 0;
    self.icon:SetTexture();
    self.cooldown:Clear();
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
--- @param spell_id     number
--- @param start_time   number
--- @return boolean
---
function Trinket:SPELL_CAST_SUCCESS( spell_id, start_time )
    if self.enabled then
        return self:Start( spell_id, start_time );
    end
    return false;
end

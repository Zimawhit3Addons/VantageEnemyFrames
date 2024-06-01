-------------------------------------------------------------------------------
---@script: auras.lua
---@author: zimawhit3
---@desc:   This module implements frames for auras.
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
local tremove   = table.remove

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame               = CreateFrame
local DebuffTypeColor           = DebuffTypeColor
local Mixin	                    = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                              EnemyFrame Auras
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------
local AURA_FLAGS = { HasDynamicSize = true };

-----------------------------------------
--                Types
-----------------------------------------

---
--- @class EnemyAuraConfig
---
--- The default settings for any aura container.
---
local AURA_DEFAULTS =
{
    Parent = "Button",
    ActivePoints = 1,
    Container =
    {
        IconSize = 22,
        IconsPerRow = 8,
        HorizontalGrowDirection = "leftwards",
        HorizontalSpacing = 2,
        VerticalGrowDirection = "upwards",
        VerticalSpacing = 1,
    },
    Coloring_Enabled = true,
    Cooldown =
    {
        ShowNumber = true,
        FontSize = 8,
        FontOutline = "OUTLINE",
        EnableShadow = false,
        ShadowColor = { 0, 0, 0, 1 },
    },
    Filtering =
    {
        Enabled = true,
        Mode = "Custom",
        CustomFiltering =
        {
            ConditionsMode = "Any",
            SourceFilter_Enabled = true,
            ShowMine = true,
            DispelFilter_Enabled = true,
            CanStealorPurge = true,
            DebuffTypeFiltering_Enabled = false,
            DebuffTypeFiltering_Filterlist = {},
            SpellIDFiltering_Enabled = false,
            SpellIDFiltering_Filterlist = {},
            DurationFilter_Enabled = false,
            DurationFilter_CustomMaxDuration = 20
        }
    }
};

---
--- @class AuraFrame : Button
--- @field border Texture
--- @field container EnemyAura|VantageContainer
--- @field cooldown Cooldown|VantageCoolDown
--- @field count VantageFontString|FontString
--- @field enemy EnemyFrame
--- @field key integer
--- @field icon Texture
--- @field input AuraData|VantageAura
--- @field stealable Texture
---
--- The `AuraFrame` that displays and contains aura data.
---
local AuraFrame = {};

---
--- @class EnemyAura : VantageContainer
--- @field enabled boolean
--- @field flags table
--- @field is_harmful boolean
--- @field position_set boolean
---
--- The `EnemyAura` is a container that holds `AuraFrame`s to display
--- buffs and debuffs on the `EnemyFrame`.
---
local EnemyAura =
{
    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type table
    ---
    flags = AURA_FLAGS,

    ---
    --- @type boolean
    ---
    is_harmful = true,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                Private
-----------------------------------------

---
---
---
--- @param location EnemyAuraConfig
--- @return table
---
local function AddAuraSettings( location )
    return
    {
        ContainerSettings =
        {
            type = "group",
            name = L.ContainerSettings,
            order = 5,
            get = function( option )
                return Constants.GetOption( location.Container, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Container, option, ... );
            end,
            args = Constants.AddContainerSettings( location.Container ),
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
end

---
--- Creates a new `AuraFrame`.
---
--- @param enemy        EnemyFrame
--- @param container    EnemyAura|VantageContainer
--- @diagnostic disable-next-line: undefined-doc-name
--- @return AuraFrame|Button|CompactAuraTemplate
---
local function createAuraFrame( enemy, container )
    local frame         = CreateFrame( "Button", nil, container, "CompactAuraTemplate" );
    local aura_frame    = Mixin( frame, AuraFrame );
    aura_frame:Initialize( container, enemy );
    return aura_frame;
end

---
---
---
--- @param container    EnemyAura|VantageContainer
--- @param aura_frame   AuraFrame
---
local function setupAuraFrame( container, aura_frame )

    if not container.is_harmful then
        aura_frame.stealable:SetShown( aura_frame.input.isStealable );
    else
        local color;
        local debuff_type = aura_frame.input.dispelName;
		if debuff_type then
			color = DebuffTypeColor[ debuff_type ] or DebuffTypeColor[ "none" ];
		else
			color = DebuffTypeColor[ "none" ];
		end
		aura_frame.border:SetVertexColor( color.r, color.g, color.b );
    end

    if aura_frame.input.applications and aura_frame.input.applications > 1 then
		aura_frame.count:SetText( tostring( aura_frame.input.applications ) );
	else
		aura_frame.count:SetText( "" );
	end

    aura_frame.icon:SetTexture( aura_frame.input.icon );
	aura_frame.cooldown:SetCooldown( aura_frame.input.expirationTime - aura_frame.input.duration, aura_frame.input.duration );

end

-----------------------------------------
--                Public
-----------------------------------------

---
--- Create a new `EnemyAura` container to track auras on enemy players.
---
--- @param enemy        EnemyFrame
--- @param is_harmful   boolean
--- @return EnemyAura|Frame|VantageContainer
---
function Vantage:NewEnemyAura( enemy, is_harmful )
    local container             = self.NewContainer( enemy, AURA_DEFAULTS, createAuraFrame, setupAuraFrame );
    local aura_container        = Mixin( container, EnemyAura );
    aura_container.is_harmful   = is_harmful;
    return aura_container;
end

---
--- Create a new `ModuleConfiguration` for the aura container.
---
--- @param is_harmful   boolean True for debuffs, otherwise false.
--- @return ModuleConfiguration
---
function Vantage:NewEnemyAuraConfig( is_harmful )
    if is_harmful then  return self.NewModuleConfig( "Debuffs", AURA_DEFAULTS, AddAuraSettings, AURA_FLAGS );
    else                return self.NewModuleConfig( "Buffs", AURA_DEFAULTS, AddAuraSettings, AURA_FLAGS );
    end
end

---
--- Apply all saved configurations to the `AuraFrame`.
---
function AuraFrame:ApplyChildFrameSettings()
    local config = self.container.config;
    self.cooldown:ApplyCooldownSettings( config.Cooldown, true, false );
    if not self.container.is_harmful then
        self.stealable:SetSize( config.Container.IconSize + 3, config.Container.IconSize + 3 );
    end
end

---
--- Initialize the `AuraFrame`
---
--- @param container    EnemyAura|VantageContainer  The container of the aura.
--- @param enemy        EnemyFrame                  The parent frame to the container.
---
function AuraFrame:Initialize( container, enemy )
    --
    -- We register for an OnCooldownDone callback. This callback is responsible
    -- for cleaning up once the duration of the aura has ended.
    --
    self.cooldown   = Vantage.NewCoolDown( self, self.Remove );
    self.container  = container;
    self.enemy      = enemy;

    --
    -- Add debufftype border
    --
    if container.is_harmful then
        self.border = self:CreateTexture( nil, "OVERLAY" );
        self.border:SetTexture( "Interface\\Buttons\\UI-Debuff-Overlays" );
        self.border:SetPoint( "TOPLEFT", -1, 1 );
        self.border:SetPoint( "BOTTOMRIGHT", 1, -1 );
        self.border:SetTexCoord( 0.296875, 0.5703125, 0, 0.515625 );
    --
    -- add dispellable border from targetframe.xml
    -- 	<Layer level="OVERLAY">
    -- 	<Texture name="$parentStealable" parentKey="Stealable" file="Interface\TargetingFrame\UI-TargetingFrame-Stealable" hidden="true" alphaMode="ADD">
    -- 		<Size x="24" y="24"/>
    -- 		<Anchors>
    -- 			<Anchor point="CENTER" x="0" y="0"/>
    -- 		</Anchors>
    -- 	</Texture>
    -- </Layer>
    --
    else
        self.stealable = self:CreateTexture( nil, "OVERLAY" );
        self.stealable:SetTexture( "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" );
        self.stealable:SetBlendMode( "ADD" );
        self.stealable:SetPoint( "CENTER" );
    end

    self:SetScript( "OnClick", nil );
    self:SetScript( "OnEnter", self.OnEnter );
    self:SetScript( "OnLeave", self.OnLeave );
    self:SetFrameLevel( container:GetFrameLevel() + 5 );

    self.icon = self:CreateTexture( nil, "BACKGROUND" );
    self.icon:SetAllPoints();

    --
    -- -1 to make it behind the SetBackdrop bg
    --
    self.icon:SetDrawLayer( "BORDER", -1 );

    self:ApplyChildFrameSettings();
end

---
--- Invoked when the cursor enters the `AuraFrame`'s interactive area. 
---
function AuraFrame:OnEnter()
    Vantage:ShowToolTip( self, self.ShowToolTip );
end

---
--- Invoked when the mouse cursor leaves the `AuraFrame`'s interactive area.
---
function AuraFrame:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
--- Show the tooltip for the `AuraFrame`.
---
function AuraFrame:ShowToolTip()
    Vantage.ShowAuraToolTip( self.input );
end

---
--- The removal callback for the `AuraFrame`. This is called 
--- from the OnCooldownDone callback set on the `AuraFrame`'s 
--- cooldown frame.
---
function AuraFrame:Remove()
    tremove( self.container.inputs, self.key )
    self.container.aura_heap:remove( self.input );
    self.container:Display();
end

---
--- Removes the input with spell ID `spell_id` from the container's inputs 
--- and resets the display frames.
---
--- @param spell_id number
---
function EnemyAura:RemoveAuraInputBySpellId( spell_id )
    for i = #self.inputs, 1, -1 do
        if self.inputs[ i ].spellId == spell_id then
            tremove( self.inputs, i );
        end
    end
    self:Display();
end

---
--- Remove expired aura inputs by their timestamp.
---
--- @param timestamp number
---
function EnemyAura:RemoveAuraInputsByTimestamp( timestamp )
    for i = #self.inputs, 1, -1 do
        --
        -- Remove the aura input. If the timestamp doesn't exist something went
        -- wrong, and in that case, it should get removed too
        --
        local input_ts = self.inputs[ i ].timestamp;
        if input_ts < timestamp then
            Vantage:Debug( "[EnemyAura:RemoveAuraInputsByTimestamp] Removing buff: " .. ( self.inputs[ i ].name or "none" ) .. " Input Timestamp: " .. input_ts .. " Update Timestamp: " .. timestamp );
            tremove( self.inputs, i );
        end
    end
    self:Display();
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Remove the input associated with the spell ID and reset the child frames.
---
--- @param spell_id number
---
function EnemyAura:AuraRemoved( spell_id )
    for i = #self.inputs, 1, -1 do
        local current_input = self.inputs[ i ];
        if current_input.spellId == spell_id then
            self.aura_heap:remove( current_input );
            tremove( self.inputs, i );
        end
    end
    self:Display();
end

---
--- Take the aura from this container. This *MUST* not be called when
--- the heap is empty, otherwise it will error. 
---
--- @return AuraData|VantageAura
---
function EnemyAura:TakeAura()
    local item = self.aura_heap:dequeue();
    self:RemoveAuraInputBySpellId( item.spellId );
    return item;
end

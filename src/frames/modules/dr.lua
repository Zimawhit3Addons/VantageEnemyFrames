-------------------------------------------------------------------------------
---@script: dr.lua
---@author: zimawhit3
---@desc:   This module implements diminishing returns frames for the EnemyFrame.
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
local DRList        = LibStub( "DRList-1.0" )

-----------------------------------------
--                Lua
-----------------------------------------
local min       = math.min
local tremove   = table.remove

-----------------------------------------
--              Blizzard
-----------------------------------------
local BackdropTemplateMixin = BackdropTemplateMixin
local CreateFrame           = CreateFrame
local GameTooltip           = GameTooltip
local GetSpellTexture       = GetSpellTexture
local GetTime               = GetTime
local Mixin                 = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                EnemyFrame DRs
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------
local DRFlags = { HasDynamicSize = true; };

---
--- The diminishing return states.
---
local ENEMY_DR_STATES =
{
    --
    -- Green (next cc in DR time will be only half duration)
    --
    [1] = { 0, 1, 0, 1 },

    --
    -- Yellow (next cc in DR time will be only 1/4 duration)
    --
    [2] = { 1, 1, 0, 1 },

    --
    -- Red (next cc in DR time will not apply, player is immune)
    --
    [3] = { 1, 0, 0, 1 },
};

---
---
---
local ENEMY_DR_OPTIONS = function( location )
    return
    {
        ContainerSettings =
        {
            type = "group",
            name = L.ContainerSettings,
            order = 1,
            get = function( option )
                return Constants.GetOption( location.Container, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Container, option, ... );
            end,
            args = Constants.AddContainerSettings( location.Container ),
        },
        DisplayType =
        {
            type = "select",
            name = L.DisplayType,
            desc = L.DrTracking_DisplayType_Desc,
            values = Constants.DisplayType,
            order = 2
        },
        CooldownTextSettings =
        {
            type = "group",
            name = L.Countdowntext,
            get = function( option )
                return Constants.GetOption( location.Cooldown, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location.Cooldown, option, ... );
            end,
            order = 3,
            args = Constants.AddCooldownSettings( location.Cooldown );
        },
        Fake1 = Constants.AddVerticalSpacing( 6 ),
        FilteringSettings =
        {
            type = "group",
            name = FILTER,
            order = 4,
            args =
            {
                Filtering_Enabled =
                {
                    type = "toggle",
                    name = L.Filtering_Enabled,
                    desc = L.DrTrackingFiltering_Enabled_Desc,
                    width = 'normal',
                    order = 1
                },
                Filtering_Filterlist =
                {
                    type = "multiselect",
                    name = L.Filtering_Filterlist,
                    desc = L.DrTrackingFiltering_Filterlist_Desc,
                    disabled = function() return not location.Filtering_Enabled end,
                    get = function( option, key )
                        return location.Filtering_Filterlist[ key ]
                    end,
                    set = function( option, key, state )
                        location.Filtering_Filterlist[ key ] = state or nil;
                    end,
                    values = Constants.DR_Categories,
                    order = 2
                }
            }
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class VantageDR
--- @field drCat string
--- @field spellId number
--- @field key number
---


---
--- @class EnemyDRConfig
---
local ENEMY_DR_DEFAULT_SETTINGS =
{
    Enabled = true,
    Parent = "Button",
    ActivePoints = 1,
    DisplayType = "Frame",
    IconSize = 20,
    Cooldown =
    {
        ShowNumber = true,
        FontSize = 12,
        FontOutline = "OUTLINE",
        EnableShadow = false,
        ShadowColor = { 0, 0, 0, 1 },
    },
    Container =
    {
        UseButtonHeightAsSize = true,
        IconSize = 15,
        IconsPerRow = 10,
        HorizontalGrowDirection = "rightwards",
        HorizontalSpacing = 2,
        VerticalGrowDirection = "downwards",
        VerticalSpacing = 1,
    },
    Filtering_Enabled = false,
    Filtering_Filterlist = {},
};

---
--- @class EnemyDRFrame : BackdropTemplate
---
local EnemyDRFrame =
{
    ---
    --- @type VantageCoolDown|Cooldown
    ---
    ---
    ---
    cooldown = nil,

    ---
    --- @type VantageContainer
    ---
    --- A reference to the parent `VantageContainer`.
    ---
    container = nil,

    ---
    --- @type table
    ---
    flags = DRFlags,

    ---
    --- @type number
    ---
    key = 0,

    ---
    --- @type number
    ---
    ---
    ---
    spell_id = 0,

    ---
    --- @type Texture
    ---
    ---
    ---
    icon = nil,

    ---
    --- @type table
    ---
    input = nil,
};

---
--- @class EnemyDRTracker : VantageContainer
---
local EnemyDRTracker =
{
    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type boolean
    ---
    position_set = false,
};

-----------------------------------------
--                 Private
-----------------------------------------

---
--- Creates a new `EnemyDRFrame`.
---
--- @param frame        EnemyFrame
--- @param container    VantageContainer
--- @return EnemyDRFrame|Frame
---
local function CreateDrFrame( frame, container )
    local dr_frame  = CreateFrame( "Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate" );
    local drtracker = Mixin( dr_frame, EnemyDRFrame );
    drtracker:Initialize( container );
    return drtracker;
end

---
--- Sets up an `EnemyDRFrame`.
---
--- @param container    VantageContainer
--- @param dr_frame     EnemyDRFrame
---
local function SetupDrFrame( container, dr_frame )
    dr_frame:SetStatus();
	dr_frame:SetSpellID( dr_frame.input.spellId );
    dr_frame.icon:SetTexture( GetSpellTexture( dr_frame.input.spellId ) );
    ---@diagnostic disable-next-line: undefined-field
	dr_frame.cooldown:SetCooldown( dr_frame.input.start_time,  DRList:GetResetTime( dr_frame.input.drCat ) );
end

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create a new container to track diminishing returns for the `EnemyFrame`.
---
--- @param enemy EnemyFrame
--- @return EnemyDRTracker|Frame|VantageContainer
---
function Vantage:NewDRTracker( enemy )
    local dr_container  = self.NewContainer( enemy, ENEMY_DR_DEFAULT_SETTINGS, CreateDrFrame, SetupDrFrame );
    local dr_tracker    = Mixin( dr_container, EnemyDRTracker );
    return dr_tracker;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewDRTrackerConfig()
    return self.NewModuleConfig( "Drtracker", ENEMY_DR_DEFAULT_SETTINGS, ENEMY_DR_OPTIONS, DRFlags );
end

---
---
---
function EnemyDRFrame:ApplyChildFrameSettings()
    self.cooldown:ApplyCooldownSettings( self.container.config.Cooldown, false, true, { 0, 0, 0, 0.5 } );
	self:SetDisplayType();
end

---
---
---
--- @return number
---
function EnemyDRFrame:GetStatus()
    local status = self.input.status;
    status = min( status, 3 );
    return status;
end

---
---
---
--- @param container VantageContainer
---
function EnemyDRFrame:Initialize( container )

    self.cooldown = Vantage.NewCoolDown( self, self.Remove );

    self:HookScript( "OnEnter", self.OnEnter );
    self:HookScript( "OnLeave", self.OnLeave );

    self.container = container;

    self:SetBackdrop({
		bgFile      = "Interface/Buttons/WHITE8X8", -- drawlayer "BACKGROUND"
		edgeFile    = 'Interface/Buttons/WHITE8X8', -- drawlayer "BORDER"
		edgeSize    = 1
	});

    self:SetBackdropColor( 0, 0, 0, 0 );
    self:SetBackdropBorderColor( 0, 0, 0, 0 );

    --
    -- -1 to make it behind the SetBackdrop bg
    --
    self.icon = self:CreateTexture( nil, "BORDER", nil, -1 );
    self.icon:SetAllPoints();

    self.input          = {};
    self.input.status   = 0;

    self:ApplyChildFrameSettings();
    self:Hide();
end

---
--- Invoked when the cursor enters the `EnemyDRFrame`'s interactive area.
---
function EnemyDRFrame:OnEnter()
    Vantage:ShowToolTip( self, self.ShowToolTip );
end

---
--- Invoked when the mouse cursor leaves the `EnemyDRFrame`'s interactive area.
---
function EnemyDRFrame:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
--- Sets the visual status of the DR's frame.
---
function EnemyDRFrame:SetStatus()
    if self.container.config.DisplayType == "Frame" then
        self:SetBackdropBorderColor( unpack( ENEMY_DR_STATES[ self:GetStatus() ] ) );
    else
        self.cooldown.text:SetTextColor( unpack( ENEMY_DR_STATES[ self:GetStatus() ] ) );
    end
end

---
---
---
function EnemyDRFrame:ShowToolTip()
    GameTooltip:SetSpellByID( self.input.spellId );
end

---
---
---
function EnemyDRFrame:Remove()
    tremove( self.container.inputs, self.key );
    self.container:Display();
end

---
---
---
function EnemyDRFrame:SetDisplayType()
    self.cooldown.text:SetTextColor( 1, 1, 1, 1 );
    self:SetBackdropBorderColor( 0, 0, 0, 0 );
    if self.input and self.input.status ~= 0 then
        self:SetStatus();
    end
end

---
---
---
--- @param spell_id number
---
function EnemyDRFrame:SetSpellID( spell_id )
    self.spell_id = spell_id;
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Start the DR tracker if the removed aura had diminishing returns.
---
--- @param spell_id number
---
function EnemyDRTracker:AuraRemoved( spell_id )
    if self.enabled then
        local config = self.config;

        ---@diagnostic disable-next-line: undefined-field
        local dr_category = DRList:GetCategoryBySpellID( spell_id );
        if not dr_category then
            return;
        end

        if not config.Filtering_Enabled or config.Filtering_Filterlist[ dr_category ] then
            local input = self:FindInputByAttribute( "drCat", dr_category );
            if input then
                input.spellId = spell_id;
            else
                input = self:NewInput( { drCat = dr_category, spellId = spell_id , key = 0 } );
            end

            input.status        = ( input.status or 0 ) + 1;
            input.start_time    = GetTime();
            self:Display();
        end
    end
end

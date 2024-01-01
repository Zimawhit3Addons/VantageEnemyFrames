-------------------------------------------------------------------------------
---@script: racial.lua
---@author: zimawhit3
---@desc:   This module implements the racial cooldown tracking frame for EnemyFrames.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...
local L             = Constants.L

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame           = CreateFrame
local GameTooltip           = GameTooltip
local GetSpellTexture       = GetSpellTexture
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
--                               EnemyFrame Racial
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;

---
---
---
local ENEMY_RACIAL_OPTIONS = function( location )
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
            get = function(option)
                return Constants.GetOption(location.Cooldown, option)
            end,
            set = function(option, ...)
                return Constants.SetOption(location.Cooldown, option, ...)
            end,
            order = 2,
            args = Constants.AddCooldownSettings(location.Cooldown)
        },
        RacialFilteringSettings =
        {
            type = "group",
            name = FILTER,
            desc = L.RacialFilteringSettings_Desc,
            order = 3,
            args =
            {
                Filtering_Enabled =
                {
                    type = "toggle",
                    name = L.Filtering_Enabled,
                    desc = L.RacialFiltering_Enabled_Desc,
                    width = 'normal',
                    order = 1
                },
                Fake = Constants.AddHorizontalSpacing(2),
                Filtering_Filterlist =
                {
                    type = "multiselect",
                    name = L.Filtering_Filterlist,
                    desc = L.RacialFiltering_Filterlist_Desc,
                    disabled = function() return not location.Filtering_Enabled end,
                    get = function( option, key )
                        if Constants.RacialNameToSpellIDs[ key ] then
                            for spell_id in pairs( Constants.RacialNameToSpellIDs[ key ] ) do
                                return location.Filtering_Filterlist[ spell_id ];
                            end
                        end
                    end,
                    set = function( option, key, state ) -- value = spellname
                        if Constants.RacialNameToSpellIDs[ key ] then
                            for spell_id in pairs( Constants.RacialNameToSpellIDs[ key ] ) do
                                location.Filtering_Filterlist[ spell_id ] = state or nil;
                            end
                        end
                    end,
                    values = Constants.RacialNames,
                    order = 3
                }
            }
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyRacialConfig
---
local ENEMY_RACIAL_DEFAULT_SETTINGS =
{
	Enabled = true,
	Parent = "Button",
	UseButtonHeightAsHeight = true,
	UseButtonHeightAsWidth = true,
	Cooldown =
    {
		ShowNumber      = true,
		FontSize        = 12,
		FontOutline     = "OUTLINE",
		EnableShadow    = false,
		ShadowColor     = { 0, 0, 0, 1 },
	},
	Filtering_Enabled = false,
	Filtering_Filterlist = {},
    ShowUnusedIcons = true,
};

---
--- @class EnemyRacial : Frame
---
local EnemyRacial =
{
    ---
    --- @type EnemyRacialConfig
    ---
    config = ENEMY_RACIAL_DEFAULT_SETTINGS,

    ---
    --- @type VantageCoolDown|Cooldown
    ---
    cooldown = nil,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type Texture
    ---
    icon = nil,

    ---
    --- @type boolean
    ---
    position_set = false,

    ---
    --- @type number
    ---
    spell_id = 0,

    ---
    --- @type Trinket|Frame
    ---
    --- A reference to the enemy's trinket frame.
    ---
    trinket = nil,
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
--- @param enemy    EnemyFrame
--- @param trinket  Trinket|Frame
--- @return EnemyRacial|Frame
---
function Vantage:NewEnemyRacial( enemy, trinket )
    local racial_frame  = CreateFrame( "Frame", nil, enemy );
    local enemy_racial  = Mixin( racial_frame, EnemyRacial );
    enemy_racial:Initialize( trinket );
    return enemy_racial;
end

---
---
---
function Vantage:NewEnemyRacialConfig()
    return self.NewModuleConfig( "Racial", ENEMY_RACIAL_DEFAULT_SETTINGS, ENEMY_RACIAL_OPTIONS );
end

---
---
---
function EnemyRacial:ApplyAllSettings()
    self.cooldown:ApplyCooldownSettings( self.config.Cooldown, false, true, { 0, 0, 0, 0.5 } );
end

---
---
---
--- @param start_time   number
---
function EnemyRacial:Start( start_time )
    local racial_cd = Constants.RacialSpellIDtoCooldown[ self.spell_id ];
    if racial_cd then
        --
        -- If the trinket and racial share a cooldown, set the shared cooldown on the
        -- trinket as well. 
        --
        if racial_cd.trinketCD and
           self.trinket.spell_id and
           self.trinket.cooldown:GetCooldownDuration() < racial_cd.trinketCD * 1000 then
            self.trinket:SetCooldown(
                start_time,
                racial_cd.trinketCD
            );
        end

        if self.config.Filtering_Enabled and not self.config.Filtering_Filterlist[ self.spell_id ] then
            return;
        end

        self.cooldown:SetCooldown( start_time, racial_cd.cd );
        if not self.config.ShowUnusedIcons then
            self.icon:SetTexture( GetSpellTexture( self.spell_id ) );
        end
    end
end

---
---
---
--- @param trinket  Trinket|Frame
---
function EnemyRacial:Initialize( trinket )

    self.cooldown   = Vantage.NewCoolDown( self, self.OnCooldownDone );
    self.icon       = self:CreateTexture();
    self.trinket    = trinket;
    self.icon:SetAllPoints();

    self:HookScript( "OnEnter", self.OnEnter );
    self:HookScript( "OnLeave", self.OnLeave );
    self:SetScript( "OnSizeChanged", self.OnSizeChanged );

end

---
---
---
function EnemyRacial:OnCooldownDone()
    if not self.config.ShowUnusedIcons then
        self.icon:SetTexture();
    end
end

---
--- Invoked when the cursor enters the `EnemyRacial`'s interactive area. 
---
function EnemyRacial:OnEnter()
    if self.spell_id > 0 then
        Vantage:ShowToolTip( self, self.ShowToolTip );
    end
end

---
--- Invoked when the mouse cursor leaves the `EnemyRacial`'s interactive area.
---
function EnemyRacial:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
--- Invoked when an `EnemyRacial`'s size changes.
---
--- @param width    number      The width of the trinket frame.
--- @param height   number      The height of the trinket frame.
---
function EnemyRacial:OnSizeChanged( width, height )
    Vantage.CropImage( self.icon, width, height );
end

---
---
---
function EnemyRacial:ShowToolTip()
    if not isClassic then
        GameTooltip:SetSpellByID( self.spell_id );
    end
end

---
---
---
function EnemyRacial:Reset()
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
---@param player_info PlayerInfo
---
function EnemyRacial:PlayerDetailsChanged( player_info )
    self.spell_id = Constants.GetRacialSpellID( player_info.race, player_info.class );
    if self.config.ShowUnusedIcons then
        self.icon:SetTexture( GetSpellTexture( self.spell_id ) );
    end
end

---
---
---
--- @param spell_id     number
--- @param start_time   number
--- @return boolean
---
function EnemyRacial:SPELL_CAST_SUCCESS( spell_id, start_time )
    if self.enabled and self.spell_id == spell_id then
        self:Start( start_time );
        return true;
    end
    return false
end

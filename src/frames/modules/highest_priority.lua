-------------------------------------------------------------------------------
---@script: highest_priority.lua
---@author: zimawhit3
---@desc:   This module implements highest priority auras visuals.
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
local CreateFrame       = CreateFrame
local GameTooltip       = GameTooltip
local GetSpellInfo      = GetSpellInfo
local GetSpellTexture   = GetSpellTexture
local GetTime           = GetTime
local Mixin             = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                           Enemy Highest Priority Aura
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
local HIGHEST_PRIORITY_OPTIONS = function( location )
    return
    {
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
            order = 1,
            args = Constants.AddCooldownSettings( location.Cooldown );
        };
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class HighestPriorityAuraConfig
---
--- The default settings for highest priority aura visuals.
---
local HIGHEST_PRIORITY_DEFAULTS =
{
    Enabled = true,
    Parent = "Button",
    Cooldown =
    {
        ShowNumber      = true,
        FontSize        = 12,
        FontOutline     = "OUTLINE",
        EnableShadow    = false,
        ShadowColor     = { 0, 0, 0, 1 },
    },
    ActivePoints = 2,
    Points =
    {
        {
            Point = "TOPLEFT",
            RelativeFrame = "Class",
            RelativePoint = "TOPLEFT",
        },
        {
            Point = "BOTTOMRIGHT",
            RelativeFrame = "Class",
            RelativePoint = "BOTTOMRIGHT",
        }
    },
};

---
--- @class EnemyHighestPriority : Frame
---
local EnemyHighestPriority =
{
    ---
    --- @type VantageAura|AuraData
    ---
    active_interrupt = nil,

    ---
    --- @type EnemyAura|Frame|VantageContainer
    ---
    --- A reference to the `EnemyFrame`'s buff container.
    ---
    buffs = nil,

    ---
    --- @type EnemyClass|Frame
    ---
    class = nil,

    ---
    --- @type EnemyAura|Frame|VantageContainer
    ---
    --- A reference to the `EnemyFrame`'s debuff container.
    ---
    debuffs = nil,

    ---
    --- @type (VantageAura|AuraData)?
    ---
    displayed_aura = nil,

    ---
    --- @type HighestPriorityAuraConfig
    ---
    config = HIGHEST_PRIORITY_DEFAULTS,

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
    --- @type Texture
    ---
    stealable = nil,
};

-----------------------------------------
--                Private
-----------------------------------------

-----------------------------------------
--                Public
-----------------------------------------

---
---
---
--- @param enemy EnemyFrame
--- @param buffs EnemyAura|Frame|VantageContainer
--- @param debuffs EnemyAura|Frame|VantageContainer
--- @param class EnemyClass|Frame
--- @return EnemyHighestPriority | Frame
---
function Vantage:NewEnemyHighestPriority( enemy, buffs, debuffs, class )
    local priority_frame    = CreateFrame( "Frame", nil, enemy );
    local highest_priority  = Mixin( priority_frame, EnemyHighestPriority );
    highest_priority:Initialize( buffs, debuffs, class );
    return highest_priority;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyHighestPriorityConfig()
    return self.NewModuleConfig( "Highestpriority", HIGHEST_PRIORITY_DEFAULTS, HIGHEST_PRIORITY_OPTIONS );
end

---
---
---
function EnemyHighestPriority:ApplyAllSettings()
    self.cooldown:ApplyCooldownSettings( self.config.Cooldown, true, true, { 0, 0, 0, 0.5 } );
    self:SetOnTop();
end

---
--- Find the highest priority aura from the buffs / debuffs modules and take it.
---
--- @return AuraData|VantageAura?
---
function EnemyHighestPriority:GetCurrentHighestPriority()

    local buff_heap     = self.buffs;
    local debuff_heap   = self.debuffs;
    local result;

    local highest_buff, buff_priority       = buff_heap.aura_heap:peek();
    local highest_debuff, debuff_priority   = debuff_heap.aura_heap:peek();
    local highest_heap, highest_aura;
    if highest_buff and highest_debuff then
        if buff_priority > debuff_priority then
            highest_aura    = highest_buff;
            highest_heap    = buff_heap;
        else
            highest_aura    = highest_debuff;
            highest_heap    = debuff_heap;
        end
    elseif highest_buff then
        highest_aura    = highest_buff;
        highest_heap    = buff_heap;
    elseif highest_debuff then
        highest_aura    = highest_debuff;
        highest_heap    = debuff_heap;
    end

    if highest_heap then
        --
        -- If we have a taken buff, we need to handle it.
        --
        if self.displayed_aura then
            --
            -- Current highest priority aura is less than the displayed aura, just
            -- return the already displayed aura.
            --
            if highest_aura.priority < self.displayed_aura.priority then
                return nil;
            --
            -- Current highest priority aura is equal to the displayed aura, return
            -- the aura with the longest remaining time left.
            --
            elseif highest_aura.priority == self.displayed_aura.priority then
                if highest_aura.expirationTime > self.displayed_aura.expirationTime then
                    result = highest_heap:TakeAura();
                    self:PutBack( self.displayed_aura );
                    self.displayed_aura = nil;
                end
            --
            -- Current highest priority aura is greater than the displayed aura, we
            -- need to reinsert the displayed aura onto the frame.
            --
            else
                result = highest_heap:TakeAura();
                self:PutBack( self.displayed_aura );
                self.displayed_aura = nil;
            end
        else
            result = highest_heap:TakeAura();
        end
    end
    return result;
end

---
---
---
--- @param buffs EnemyAura|Frame|VantageContainer
--- @param debuffs EnemyAura|Frame|VantageContainer
--- @param class EnemyClass|Frame
---
function EnemyHighestPriority:Initialize( buffs, debuffs, class )
    self.buffs              = buffs;
    self.debuffs            = debuffs;
    self.class              = class;
    self.icon               = self:CreateTexture( nil, "BACKGROUND" );
    self.cooldown           = Vantage.NewCoolDown( self, self.Reset );
    self.active_interrupt   = {
        spellId         = 0,
        icon            = 0,
        expirationTime  = 0,
        duration        = 0,
        priority        = 0,
        isStealable     = false,
        timestamp       = 0
    };

    self.stealable = self:CreateTexture( nil, "OVERLAY" );
    self.stealable:SetTexture( "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" );
    self.stealable:SetBlendMode( "ADD" );
    self.stealable:SetPoint( "CENTER" );
    self.stealable:SetShown( false );
    self.icon:SetAllPoints();

    self:HookScript( "OnEnter", self.OnEnter );
    self:HookScript( "OnLeave", self.OnLeave );
    self:HookScript( "OnSizeChanged", self.OnSizeChanged );
    self:Hide();
end

---
---
---
--- @param spell_id number
--- @param duration number
---
function EnemyHighestPriority:UpdateActiveInterrupt( spell_id, duration )
    --
    -- Set the active interrupt
    --
    if spell_id > 0 then
        local current_time = GetTime();

        self.active_interrupt.name              = GetSpellInfo( spell_id );
        self.active_interrupt.spellId           = spell_id;
        self.active_interrupt.icon              = GetSpellTexture( spell_id );
        self.active_interrupt.expirationTime    = current_time + duration;
        self.active_interrupt.duration          = duration;
        ---@diagnostic disable-next-line: inject-field
        self.active_interrupt.priority          = Vantage.GetSpellPriority( spell_id ) or 4;
        self.active_interrupt.timestamp         = current_time + duration;
    --
    -- Reset the active interrupt
    --
    else
        self.active_interrupt.name              = "";
        self.active_interrupt.spellId           = 0;
        self.active_interrupt.icon              = 0;
        self.active_interrupt.expirationTime    = 0;
        self.active_interrupt.duration          = 0;
        ---@diagnostic disable-next-line: inject-field
        self.active_interrupt.priority          = 0;
        self.active_interrupt.timestamp         = 0;
    end

end

---
---
---
--- @param aura any
---
function EnemyHighestPriority:PutBack( aura )
    if aura.isHarmful then
        --Vantage:Debug( "[EnemyHighestPriority:PutBack] Putting aura " .. ( aura.name or "none" ) .. " back into debuff heap" );
        self.debuffs:NewInput( aura );
    else
        --Vantage:Debug( "[EnemyHighestPriority:PutBack] Putting aura " .. ( aura.name or "none" ) .. " back into buff heap" );
        self.buffs:NewInput( aura );
    end
end

---
--- Resets the EnemyHighestPriority frame. This will drop the current aura
--- owned by the frame, so it should only be called from places where the
--- aura is known to have either expired or was removed.
---
function EnemyHighestPriority:Reset()
    self.displayed_aura = nil;
    self.stealable:SetShown( false );
    self.icon:SetTexture();
    self.cooldown:Clear();
    self:UpdateActiveInterrupt( 0, 0 );
    self:Update();
end

---
---
---
function EnemyHighestPriority:SetOnTop()
    local highest_level = 0;
    local current_level = 0;
    local relative_to   = nil;
    for i = 1, self:GetNumPoints() do
        _, relative_to = self:GetPoint( i );
        if relative_to then
            ---@diagnostic disable-next-line: undefined-field
            current_level = relative_to:GetFrameLevel();
            if current_level and current_level > highest_level then
                highest_level = current_level;
            end
        end
    end
    self:SetFrameLevel( highest_level + 1 );
end

---
---
---
--- @param priority_aura AuraData|VantageAura
---
function EnemyHighestPriority:SetDisplayedAura( priority_aura )
    self.displayed_aura = priority_aura;
    self.icon:SetTexture( priority_aura.icon );

    if not priority_aura.isHarmful then
        if priority_aura.isStealable then
            local width, height = self.icon:GetSize();
            self.stealable:SetSize( width + 6, height + 6 );
        end
        self.stealable:SetShown( priority_aura.isStealable );
    else
        self.stealable:SetShown( false );
    end

    --
    -- TODO:
    --  - Need a better approach to auras with infinite duration
    --  - Temporary fix: Anti-Magic zone lasts for 10 seconds.
    --
    if priority_aura.spellId == 51052 then
        priority_aura.duration = 10;
    end

    self.cooldown:Clear();
    self.cooldown:SetCooldown( priority_aura.expirationTime - priority_aura.duration, priority_aura.duration );
end

---
---
---
function EnemyHighestPriority:ShowToolTip()
    Vantage.ShowAuraToolTip( self.displayed_aura );
end

---
---
---
---@param last_update number?
---
function EnemyHighestPriority:Update( last_update )

    self:SetOnTop();

    local current_time  = GetTime();
    local priority_aura = self:GetCurrentHighestPriority();

    --
    -- Reset the active interrupt if its set and has expired - otherwise, set
    -- the priority aura to the interrupt if the priority aura is less than the
    -- interrupt's priority.
    --
    -- TODO: 
    -- - Instead of fucking with the priority_aura, we should handle the interrupt
    --   directly and never put it into the buff/debuff heap
    --
    if self.active_interrupt.spellId > 0 then
        if self.active_interrupt.expirationTime <= current_time then
            self:UpdateActiveInterrupt( 0, 0 );
        elseif not priority_aura then
            --if self.displayed_aura then
            --    self:PutBack( self.displayed_aura );
            --end
            priority_aura = self.active_interrupt;
        elseif self.active_interrupt.priority > priority_aura.priority then
            Vantage:Debug( "[EnemyHighestPriority:Update] Interrupt has higher priority. Resetting priority_aura: " .. ( priority_aura.name or "none" ) );
            self:PutBack( priority_aura );
            priority_aura = self.active_interrupt;
        end
    end

    --
    -- There's another aura we care about
    --
    if priority_aura then
        --Vantage:Debug( "[EnemyHighestPriority:Update] New aura at highest priority. Last updated: " .. ( last_update or "none" ) .. " | Aura: " .. ( priority_aura.name or "none" ) );

        --
        -- TODO:
        -- - this should never get hit
        --
        if self.displayed_aura then
            Vantage:Debug( "[EnemyHighestPriority:Update] ****** Priority aura existing while displayed_aura is set? ******" );
            Vantage:Debug( "[EnemyHighestPriority:Update] Displayed aura: " .. self.displayed_aura.name );

            --
            -- There's a new aura
            --
            if priority_aura.spellId ~= self.displayed_aura.spellId then
                self:SetDisplayedAura( priority_aura );
            --
            -- The current aura was refreshed
            --
            elseif priority_aura.expirationTime ~= self.displayed_aura.expirationTime then
                Vantage:Debug( "[EnemyHighestPriority:Update] Aura was refreshed. Last updated: " .. ( last_update or "none" ) );
                Vantage:Debug( string.format( "[EnemyHighestPriority:Update] Priority  Aura - %s | Duration: %d | Expiration: %d", priority_aura.name or "none", priority_aura.duration or "none", priority_aura.expirationTime or "none" ) );
                self.displayed_aura.expirationTime = priority_aura.expirationTime;
                self.cooldown:Clear();
                self.cooldown:SetCooldown( priority_aura.expirationTime - priority_aura.duration, priority_aura.duration );
            else
                --Vantage:Debug( "[EnemyHighestPriority:Update] Something in container and we have an aura. Last updated: " .. ( last_update or "none" ) );
                --Vantage:Debug( string.format( "[EnemyHighestPriority:Update] Priority  Aura - %s | Duration: %d | Expiration: %d", priority_aura.name or "none", priority_aura.duration or "none", priority_aura.expirationTime or "none" ) );
                --Vantage:Debug( string.format( "[EnemyHighestPriority:Update] Displayed Aura - %s | Duration: %d | Expiration: %d", self.displayed_aura.name or "none", self.displayed_aura.duration or "none", self.displayed_aura.expirationTime or "none" ) );
            end
        --
        -- There's a new aura
        --
        else
            if not self:IsShown() then
                self:Show();
            end
            if self.class:IsShown() then
                self.class:Hide();
            end
            self:SetDisplayedAura( priority_aura );
        end
    --
    -- There were no auras to take, and we don't have a shown aura
    --
    elseif not self.displayed_aura then
        if self:IsShown() then
            self:Hide();
        end
        if self.class.enabled then
            if not self.class:IsShown() then
                self.class:Show();
            end
        end

    --
    --
    --
    else
        if self.displayed_aura.timestamp and last_update and
           self.displayed_aura.timestamp < last_update then --and self.displayed_aura ~= self.active_interrupt then
            self:Reset();
            return;
        end

        --Vantage:Debug( "[EnemyHighestPriority:Update] Nothing in container and we have an aura. Last updated: " .. ( last_update or "none" ) );
        --Vantage:Debug( string.format( "[EnemyHighestPriority:Update] Aura - %s | Duration: %d | Expiration: %d", self.displayed_aura.name or "none", self.displayed_aura.duration or "none", self.displayed_aura.expirationTime or "none" ) );
        --if not self.displayed_aura.name or ( last_update and last_update >= self.displayed_aura.expirationTime ) then
        --    self:Reset();
        --    return;
        --end
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
--- Reset the highest priority aura frame if the current displayed aura
--- had the removed spell ID.
---
--- @param spell_id number
---
function EnemyHighestPriority:AuraRemoved( spell_id )
    if self.displayed_aura and self.displayed_aura.spellId == spell_id then
        self:Reset();
    end
end

---
---
---
--- @param spell_id number
--- @param duration number
---
function EnemyHighestPriority:GotInterrupted( spell_id, duration )
    --self:UpdateActiveInterrupt( spell_id, duration );
    --self:Update();
end

---
--- Invoked when the cursor enters the `EnemyHighestPriority`'s 
--- interactive area. 
---
function EnemyHighestPriority:OnEnter()
    Vantage:ShowToolTip( self, self.ShowToolTip );
end

---
--- Invoked when the mouse cursor leaves the `EnemyHighestPriority`'s 
--- interactive area.
---
function EnemyHighestPriority:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
--- Invoked when an `EnemyHighestPriority`'s size changes.
---
--- @param width    number      The width of the trinket frame.
--- @param height   number      The height of the trinket frame.
---
function EnemyHighestPriority:OnSizeChanged( width, height )
    Vantage.CropImage( self.icon, width, height );
end

---
---
---
function EnemyHighestPriority:UnitDied()
    self:Reset();
end

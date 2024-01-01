-------------------------------------------------------------------------------
---@script: cooldown.lua
---@author: zimawhit3
---@desc:   This module implements custom cooldown frames.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local LibStub   = LibStub

-----------------------------------------
--                Lua
-----------------------------------------

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
--                                Vantage Cooldown
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class VantageCoolDown : Cooldown
---
local VantageCoolDown =
{
    parent = nil,
    callback = nil,
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
--- @param parent_frame Frame
--- @param cooldown_callback function?
--- @return VantageCoolDown|Cooldown
---
function Vantage.NewCoolDown( parent_frame, cooldown_callback )
	local cooldown      = CreateFrame( "Cooldown", nil, parent_frame );
    local v_cooldown    = Mixin( cooldown, VantageCoolDown );
	v_cooldown:Initialize( parent_frame, cooldown_callback );
    return v_cooldown;
end

---
---
---
--- @param config           table
--- @param cd_reverse       boolean
--- @param set_draw_swipe   boolean
--- @param swipe_color      number[]?
---
function VantageCoolDown:ApplyCooldownSettings( config, cd_reverse, set_draw_swipe, swipe_color )
	self:SetReverse( cd_reverse );
    ---@diagnostic disable-next-line: redundant-parameter
	self:SetDrawSwipe( set_draw_swipe );
	if swipe_color then
        self:SetSwipeColor( unpack( swipe_color ) );
    end
	self:SetHideCountdownNumbers( not config.ShowNumber );
	if self.text then
		self.text:ApplyFontStringSettings( config );
	end
end

---
---
---
--- @return FontString?
---
function VantageCoolDown:GetFontString()
    local regions = { self:GetRegions() };
    for _, region in pairs( regions ) do
        ---@diagnostic disable-next-line: undefined-field
        if region:GetObjectType() == "FontString" then
            ---@diagnostic disable-next-line: return-type-mismatch
            return region;
        end
    end
    return nil;
end

---
---
---
--- @param parent_frame Frame
--- @param cooldown_callback function?
---
function VantageCoolDown:Initialize( parent_frame, cooldown_callback )
    self:SetAllPoints();
	self:SetSwipeTexture( "Interface/Buttons/WHITE8X8" );

    self.parent = parent_frame;
    if cooldown_callback then
        self.callback = cooldown_callback;
        self:HookScript( "OnCooldownDone", self.OnCooldownDone );
    end

    local font_string = self:GetFontString();
    if font_string then
        self.text = Vantage.FromFontString( font_string );
    end
end

---
---
---
function VantageCoolDown:OnCooldownDone()
    self.callback( self.parent );
end

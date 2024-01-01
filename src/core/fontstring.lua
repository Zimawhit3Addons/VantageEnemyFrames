-------------------------------------------------------------------------------
---@script: fontstring.lua
---@author: zimawhit3
---@desc:   This module implements custom fontstrings.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local LibStub       = LibStub
local LSM 			= LibStub( "LibSharedMedia-3.0" )

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local Mixin = Mixin

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                Vantage FontString
-------------------------------------------------------------------------------

-----------------------------------------
--                Constants
-----------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class VantageFontString : FontString
---
local VantageFontString = {};

-----------------------------------------
--                Private
-----------------------------------------

-----------------------------------------
--                Public
-----------------------------------------

---
--- Mixin `VantageFontString` methods onto an existing `FontString`.
---
--- @param fs FontString
--- @return VantageFontString|FontString
---
function Vantage.FromFontString( fs )
	return Mixin( fs, VantageFontString );
end

---
--- Create a new `VantageFontString` for the frame.
---
--- @param frame Frame
--- @return VantageFontString|FontString
---
function Vantage.NewFontString( frame )
    local font_string = frame:CreateFontString( nil, "OVERLAY" );
    font_string:SetDrawLayer( 'OVERLAY', 2 );
    return Vantage.FromFontString( font_string );
end

---
---
---
--- @param settings table
---
function VantageFontString:ApplyFontStringSettings( settings )

	local saved_font = LSM:Fetch( "font", Vantage.Database.profile.Font );
	if saved_font then
		self:SetFont( saved_font, settings.FontSize, settings.FontOutline );
	end

    --
    -- TODO:
    --  - idk why, but without this the SetJustifyH and SetJustifyV dont seem to work 
    --    sometimes even tho GetJustifyH returns the new, correct value
    --
    self:GetRect();
	self:GetStringHeight();
	self:GetStringWidth();

	if settings.JustifyH then
		self:SetJustifyH( settings.JustifyH );
	end

	if settings.JustifyV then
		self:SetJustifyV( settings.JustifyV );
	end

	if settings.WordWrap ~= nil then
		self:SetWordWrap( settings.WordWrap );
	end

	if settings.FontColor then
		self:SetTextColor( unpack( settings.FontColor ) );
	end

	self:EnableShadowColor( settings.EnableShadow, settings.ShadowColor );
end

---
--- Enables shadow colors for the fontstring.
---
--- @param enable_shadow boolean
--- @param shadow_color  number[]
---
function VantageFontString:EnableShadowColor( enable_shadow, shadow_color )
    if shadow_color then
        self:SetShadowColor( unpack( shadow_color ) );
    end

    if enable_shadow then
		self:SetShadowOffset( 1, -1 );
	else
		self:SetShadowOffset( 0, 0 );
	end
end
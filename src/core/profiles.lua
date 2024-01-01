-------------------------------------------------------------------------------
---@script: profiles.lua
---@author: zimawhit3
---@desc:   
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local AddonName, Constants  = ...
local L                     = Constants.L
local LibStub               = LibStub
local LibDeflate            = LibStub( "LibDeflate" )
local LibSerialize          = LibStub( "LibSerialize" )

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local ButtonFrameTemplate_HidePortrait  = ButtonFrameTemplate_HidePortrait
local CreateFrame                       = CreateFrame
local CLOSE                             = CLOSE
local DoesTemplateExist                 = DoesTemplateExist
local GameFontNormal                    = GameFontNormal

-----------------------------------------
--                Ace3
-----------------------------------------

---
---@class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                            Imports / Export Profiles
-------------------------------------------------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

----------------------------------------
--                Private
----------------------------------------

---
---
---
--- @return ButtonFrameTemplate|Frame
---
local function CreateImportExportFrame()

    local frame = CreateFrame( "Frame", "ProfileImportExport", UIParent, "ButtonFrameTemplate" );

    --
    -- To make it appear above the options panel
    --
    frame:SetFrameStrata( "TOOLTIP" );

    ButtonFrameTemplate_HidePortrait( frame );

    frame.Inset:SetPoint( "TOPLEFT", 4, -25 );

    frame:SetSize( 500, 500 );
    frame:SetPoint( "CENTER" );

    frame.scrollBar = CreateFrame( "ScrollFrame", nil, frame.Inset, "UIPanelScrollFrameTemplate" );
    frame.scrollBar:SetPoint( "TOPLEFT", 10, -6 );
    frame.scrollBar:SetPoint( "BOTTOMRIGHT", -27, 6 );

    frame.EditBox = CreateFrame( "EditBox" );
    frame.EditBox:SetMultiLine( true );
    frame.EditBox:SetSize( frame.scrollBar:GetWidth(), 170 );
    frame.EditBox:SetPoint( "TOPLEFT", frame.scrollBar );
    frame.EditBox:SetPoint( "BOTTOMRIGHT", frame.scrollBar );
    frame.EditBox:SetFontObject( GameFontNormal );
    frame.EditBox:SetAutoFocus( false );
    frame.EditBox:SetScript( "OnEscapePressed", function(self) self:ClearFocus() end );

    frame.scrollBar:SetScrollChild( frame.EditBox );

    if DoesTemplateExist( "SharedButtonSmallTemplate" ) then
        frame.Button = CreateFrame( "Button", nil, frame, "SharedButtonSmallTemplate" );
    else
        frame.Button = CreateFrame( "Button", nil, frame, "MagicButtonTemplate" );
    end

    frame.Button:SetSize( 80, 22 );
    frame.Button:SetPoint( "BOTTOMRIGHT", -4, 4 );
    frame.Button:SetScript( "OnClick", function( self )
        if frame.mode == "Import" then
            local profile_text = frame.EditBox:GetText();
            if not profile_text or profile_text == "" then
                Vantage:Notify( "Empty input, please enter a exported string here." );
                return;
            end
            local data = Vantage.ReceivePrintData( profile_text );
            if data then
                Vantage.Database.profile = data;
                Vantage:NotifyChange();
            end
        end
        frame:Hide();
    end)
    return frame;
end

---
---
---
--- @param decoded string?
--- @return table?
---
local function DecompressAndDeserialize( decoded )
    if not decoded then
        Vantage:Notify( "[DecompressAndDeserialize] Decoded data is empty." );
        return nil;
    end

    ---@diagnostic disable-next-line: undefined-field
    local decompressed = LibDeflate:DecompressDeflate( decoded );
    if not decompressed then
        Vantage:Notify( "[DecompressAndDeserialize] An error occurred while decompressing." );
        return nil;
    end

    ---@diagnostic disable-next-line: undefined-field
    local success, data = LibSerialize:Deserialize( decompressed );
    if not success then
        Vantage:Notify( "[DecompressAndDeserialize] An error occurred while deserializing." );
        return nil;
    end

    return data;
end

---
---
---
--- @param data table
--- @return string?
---
local function SerializeAndCompress( data )
    ---@diagnostic disable-next-line: undefined-field
	local serialized = LibSerialize:Serialize( data );
	if not serialized then
		Vantage:Notify( "[SerializeAndCompress] An error occurred while serializing the profile data." );
        return nil;
	end
    ---@diagnostic disable-next-line: undefined-field
	local compressed = LibDeflate:CompressDeflate( serialized );
	if not compressed then
		Vantage:Notify( "[SerializeAndCompress] An error occurred while compressing the profile data." )
        return nil;
	end

	return compressed;
end

----------------------------------------
--                 Public
----------------------------------------

---
---
---
--- @param data table
---
function Vantage:ExportDataViaPrint( data )
    local compressed    = SerializeAndCompress( data );
	local encoded       = LibDeflate:EncodeForPrint( compressed );
	if not encoded then
		self:Notify( "[Vantage:ExportDataViaPrint] An error occurred while encoding the profile data." );
        return nil;
	end

	self:ImportExportFrameSetupForMode( "Export", encoded );
end

---
---
---
--- @param mode         string
--- @param export_str   string?
---
function Vantage:ImportExportFrameSetupForMode( mode, export_str )
    self.ImportExportFrame = self.ImportExportFrame or CreateImportExportFrame()

    if self.ImportExportFrame.SetTitle then
        self.ImportExportFrame:SetTitle( AddonName .. ": " .. mode );

    elseif self.ImportExportFrame.TitleText then
        --
        -- workaround for TBCC
        --
        self.ImportExportFrame.TitleText:SetText( AddonName .. ": " .. mode );
    end

    if mode == "Import" then
        self.ImportExportFrame.Button:SetText( L.Import );
        self.ImportExportFrame.EditBox:SetText( "" );
        self.ImportExportFrame.EditBox:SetAutoFocus( true );
    else
        self.ImportExportFrame.Button:SetText( CLOSE );
        self.ImportExportFrame.EditBox:SetText( export_str );
        self.ImportExportFrame.EditBox:HighlightText();
    end
    self.ImportExportFrame.mode = mode;
    self.ImportExportFrame:Show();
end

---
---
---
--- @param data string
--- @return table?
---
function Vantage.ReceivePrintData( data )
    return DecompressAndDeserialize(
        ---@diagnostic disable-next-line: undefined-field
        LibDeflate:DecodeForPrint( data )
    );
end


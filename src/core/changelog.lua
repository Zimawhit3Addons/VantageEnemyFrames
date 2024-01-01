-------------------------------------------------------------------------------
---@script: changelog.lua
---@author: zimawhit3
---@desc:   This module implements the changelog for the addon.
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
local ButtonFrameTemplate_HidePortrait  = ButtonFrameTemplate_HidePortrait
local CreateFromMixins                  = CreateFromMixins

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                    Changelog
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
local NEW_MESSAGE_FONTS =
{
    version = GameFontNormalHuge,
    title   = GameFontNormal,
    text    = GameFontHighlight
};

---
---
---
local VIEWED_MESSAGE_FONTS =
{
    version = GameFontDisableHuge,
    title   = GameFontDisable,
    text    = GameFontDisable
};

-----------------------------------------
--                Types
-----------------------------------------

---
--- @class VantageChangeLog
---
local VantageChangeLog =
{
    ---
    ---
    ---
    changelog = nil,

    ---
    --- @type table
    ---
    saved_variables = nil,

    ---
    ---
    ---
    last_version_key = nil,

    ---
    ---
    ---
    new_version_key = nil,

    ---
    ---
    ---
    texts = nil,

    ---
    ---@diagnostic disable-next-line: undefined-doc-name
    --- @type ButtonFrameTemplate|Frame
    ---
    frame = nil,

    ---
    --- @type Frame
    ---
    scroll_child = nil,

    ---
    --- @type ScrollFrame|UIPanelScrollFrameTemplate
    ---
    scroll_bar = nil,

    ---
    ---
    ---
    previous_entry = nil,

    ---
    --- @type CheckButton|UICheckButtonTemplate
    ---
    check_button = nil

};

-----------------------------------------
--               Private
-----------------------------------------

-----------------------------------------
--               Public
-----------------------------------------

---
---
---
--- @param changelog        table
--- @param saved_variables  table
--- @param last_version     string
--- @param new_version      string
--- @param texts            any?
--- @return VantageChangeLog
---
function Vantage:Register( changelog, saved_variables, last_version, new_version, texts )
    local vantage_changelog             = CreateFromMixins( VantageChangeLog );
    vantage_changelog.changelog         = changelog or {};
    vantage_changelog.saved_variables   = saved_variables;
    vantage_changelog.last_version_key  = last_version;
    vantage_changelog.new_version_key   = new_version;
    vantage_changelog.texts             = texts or {};
    return vantage_changelog;
end

---
---
---
--- @param text     string
--- @param font     Font
--- @param offset   number?
--- @return FontString
---
function VantageChangeLog:CreateString( text, font, offset )
    local entry = self.scroll_child:CreateFontString( nil, "ARTWORK" );
    entry:SetFontObject( font or "GameFontNormal" );
    entry:SetText( text );
    entry:SetJustifyH( "LEFT" );
    entry:SetWidth( self.scroll_bar:GetWidth() );

    if self.previous_entry then
        entry:SetPoint( "TOPLEFT", self.previous_entry, "BOTTOMLEFT", 0, offset or -5 );
    else
        entry:SetPoint( "TOPLEFT", self.scroll_child, "TOPLEFT", -5 );
    end

    self.previous_entry = entry;
    return entry
end

---
---
---
--- @param text     string
--- @param font     Font
--- @param offset   number?
--- @return FontString
---
function VantageChangeLog:CreateBulletedListEntry( text, font, offset )

    local bullet        = self:CreateString( "- ", font, offset );
    local bullet_width  = 16;

    bullet:SetWidth( bullet_width );
    bullet:SetJustifyV( "TOP" );

    local entry = self:CreateString( text, font, offset );
    entry:SetPoint( "TOPLEFT", bullet, "TOPRIGHT" );
    entry:SetWidth( self.scroll_bar:GetWidth() - bullet_width );

    bullet:SetHeight( entry:GetStringHeight() );

    self.previous_entry = bullet;
    return bullet;
end

---
---
---
function VantageChangeLog:OnClick()
    local is_checked = self.check_button:GetChecked();
    self.saved_variables[ self.new_version_key ] = is_checked;
    self.check_button:SetChecked( is_checked );
end

---
---
---
function VantageChangeLog:ShowChangelog()

    local fonts = NEW_MESSAGE_FONTS;

    --
    -- FirstEntry contains the newest version
    --
    local first_entry   = self.changelog[ 1 ];
    local saved_vars    = self.saved_variables;

    if not first_entry then
        return;
    end

    --
    --
    --
    if self.last_version_key and saved_vars[ self.last_version_key ] and
       first_entry.Version <= saved_vars[ self.last_version_key ] and
       saved_vars[ self.new_version_key ] then
        return;
    end

    self.frame = CreateFrame( "Frame", nil, UIParent, "ButtonFrameTemplate" );
    ButtonFrameTemplate_HidePortrait( self.frame );

    if self.frame.SetTitle then
        self.frame:SetTitle( self.texts.title or "VantageEnemyFrames News" );
    else
        --
        -- Workaround for TBCC
        --
        self.frame.TitleText:SetText( self.texts.title or "VantageEnemyFrames News" );
    end

    self.frame.Inset:SetPoint( "TOPLEFT", 4, -25 );
    self.frame:SetSize( 500, 500 );
    self.frame:SetPoint( "CENTER" );

    self.scroll_bar = CreateFrame( "ScrollFrame", nil, self.frame.Inset, "UIPanelScrollFrameTemplate" );
    self.scroll_bar:SetPoint( "TOPLEFT", 10, -6 );
    self.scroll_bar:SetPoint( "BOTTOMRIGHT", -27, 6 );

    self.scroll_child = CreateFrame( "Frame" );

    --
    -- It doesnt seem to matter how big it is, the only thing that not works 
    -- is setting the height to really high number, then you can scroll forever
    --
    self.scroll_child:SetSize(1, 1);

    self.scroll_bar:SetScrollChild( self.scroll_child );

    self.check_button = CreateFrame( "CheckButton", nil, self.frame, "UICheckButtonTemplate" );
    self.check_button:SetChecked( saved_vars[ self.new_version_key ] );
    self.check_button:SetFrameStrata( "HIGH" );
    self.check_button:SetSize( 20, 20 );

    self.check_button:SetScript( "OnClick", self.OnClick );
    self.check_button:SetPoint( "LEFT", self.frame, "BOTTOMLEFT", 10, 13 );
    if self.check_button.text then
        self.check_button.text:SetText( self.texts.onlyShowWhenNewVersion or "Only Show after next update" );

    elseif self.check_button.Text then
        self.check_button.Text:SetText( self.texts.onlyShowWhenNewVersion or "Only Show after next update" );

    end

    --
    --
    --
    for i = 1, #self.changelog do

        local version_entry = self.changelog[ i ];
        if self.last_version_key and saved_vars[ self.last_version_key ] and saved_vars[ self.last_version_key ] >= version_entry.Version then
            fonts = VIEWED_MESSAGE_FONTS
        end

        --
        -- Add version string and add a nice spacing between the version header 
        -- and the previous text.
        --
        self:CreateString( version_entry.Version, fonts.version, -30 );

        if version_entry.General then
            self:CreateString( version_entry.General, fonts.text );
        end

        if version_entry.Sections then

            local section, entries;
            for j = 1, #version_entry.Sections do

                section = version_entry.Sections[ j ];
                entries = section.Entries;

                self:CreateString( section.Header, fonts.title, -8 );

                for k = 1, #entries do
                    self:CreateBulletedListEntry( entries[ k ], fonts.text );
                end
            end

        end
    end

    saved_vars[ self.last_version_key ] = first_entry.Version;
end

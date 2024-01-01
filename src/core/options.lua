-------------------------------------------------------------------------------
---@script: options.lua
---@author: zimawhit3
---@desc:   This module implements the GUI options for the addon.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--               Globals
-----------------------------------------
local AddonName, Constants  = ...
local L                     = Constants.L
local LibStub               = LibStub
local AceConfigRegistry     = LibStub( "AceConfigRegistry-3.0" )
local LRC                   = LibStub( "LibRangeCheck-3.0" )

-----------------------------------------
--                 Lua
-----------------------------------------
local fmt       = string.format
local unpack    = unpack

-----------------------------------------
--              Blizzard
-----------------------------------------
local GetAddOnMetadata  = GetAddOnMetadata
local InCombatLockdown  = InCombatLockdown
local IsInGroup         = IsInGroup
local IsInRaid          = IsInRaid

-----------------------------------------
--                Ace3
-----------------------------------------
local AceGUIWidgetLSMlists  = AceGUIWidgetLSMlists

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                Vantage Options
-------------------------------------------------------------------------------

----------------------------------------
--              Constants
----------------------------------------

---
--- @type table<number, string>
---
---
---
local BG_SIZE_TO_LOCALE =
{
    [10] = "10",    -- L.BGSize_10,
	[15] = "15",    -- L.BGSize_15,
	[40] = "40"     -- L.BGSize_40
};

---
--- @type table<string, string>
---
---
---
local JUSTIFY_H_VALUES =
{
	LEFT    = L.LEFT,
	CENTER  = L.CENTER,
	RIGHT   = L.RIGHT
};

---
--- @type table<string, string>
---
---
---
local JUSTIFY_V_VALUES =
{
	TOP     = L.TOP,
	MIDDLE  = L.MIDDLE,
	BOTTOM  = L.BOTTOM
};

---
--- @type table<string, string>
---
---
---
local FONT_OUTLINES =
{
	[""]                = L.None,
	["OUTLINE"]         = L.Normal,
	["THICKOUTLINE"]    = L.Thick,
};


----------------------------------------
--               Private
----------------------------------------

---
---
--- @param location         any
--- @param module_config    ModuleConfiguration
--- @return boolean
---
local function canAddPoint( location, module_config )
    local activePoints = location.ActivePoints or 0;
    if activePoints > 1 then
        return false;
    end
    if activePoints == 0 then
        return true;
    end

    --
    -- if only 1 point is set
    -- Containers can only have 1 point
    --
    if module_config.flags.HasDynamicSize then
        return false;
    end

    if module_config.flags.Width == "Fixed" and module_config.flags.Height == "Fixed" then
        return false;
    end

    return true;
end

---
---
---
--- @param obj any
--- @return any
---
local function copy( obj )
    if type( obj ) == 'table' then
        local res = {};
        for k, v in pairs( obj ) do
            res[ copy( k ) ] = copy( v );
        end
        return res;
    end
    return obj;
end

---
---
---
--- @param module_name string
--- @return table
---
local function GetAllModuleAnchors( module_name )
    local anchors = {};
    for name, config in pairs( Vantage.Module_Configs ) do
        --
        -- Can't anchor to itself
        --
        if name ~= module_name then
            anchors[ name ] = config.name;
        end
    end
    anchors.Button = L.Button;
    return anchors;
end

---
---
--- @param Point1 any
--- @param Point2 any
--- @return boolean
---
local function isInSameHorizontal( Point1, Point2 )
    local p1 = ( Point1.Point:match( "(TOP)" ) ) or ( Point1.Point:match( "(BOTTOM)" ) ) or false;
    local p2 = ( Point2.Point:match( "(TOP)" ) ) or ( Point2.Point:match( "(BOTTOM)" ) ) or false;
    if p1 == "TOP" and p2 == "TOP" then
        return true;
    elseif not ( p1 == "TOP" or p2 == "TOP" or p1 == "BOTTOM" or p2 == "BOTTOM" ) then
        return true;
    elseif p1 == "BOTTOM" and p2 == "BOTTOM" then
        return true;
    end
    return false;
end

---
---
--- @param Point1 any
--- @param Point2 any
--- @return boolean
---
local function isInSameVertical( Point1, Point2 )
    local p1 = ( Point1.Point:match( "(LEFT)" ) ) or ( Point1.Point:match( "(RIGHT)" ) ) or false;
    local p2 = ( Point2.Point:match( "(LEFT)" ) ) or ( Point2.Point:match( "(RIGHT)" ) ) or false;
    if p1 == "LEFT" and p2 == "LEFT" then
        return true;
    elseif not ( p1 == "LEFT" or p2 == "LEFT" or p1 == "RIGHT" or p2 == "RIGHT" ) then
        return true;
    elseif p1 == "RIGHT" and p2 == "RIGHT" then
        return true;
    end
    return false;
end

---
--- User wants to anchor the module to the relative frame, check if the relative frame is 
--- already anchored to that module.
---
--- @param module_name any
--- @param relative_frame any
--- @return boolean
---
local function ValidateAnchor( module_name, relative_frame )

    if #Vantage.EnemyOrder == 0 then
        Vantage:Notify( "There are currently no players for the selected option available. You can start the testmode to add some players. Otherwise your selected frame can't be validated and there might be frame looping issues, therefore your selected frame is not saved to avoid this issue." );
        return false;
    end

    --
    -- End the loop after just one player since all player frames are using same options
    --
    for _, frame in pairs( Vantage.EnemyFrames ) do
        local anchor        = frame:GetAnchor( relative_frame );
        local isDependant   = Vantage:IsFrameDependentOnFrame( anchor, frame[ module_name ] );
        if isDependant then
            --
            -- thats bad, dont allow this setting
            --
            Vantage:Notify( "You can't anchor this module's frame to this frame because this would result in looped frame anchoring because the frame or one of the frame that this frame is dependant on are already attached to this module." );
            return false;
        else
            return true;
        end
    end

end

----------------------------------------
--                Public
----------------------------------------

---
---
---
--- @return table
---
function Vantage:AddEnemySettings()
    local settings = {};
    local location = Vantage.Database.profile.Enemies;

    settings.GeneralSettings =
    {
        type    = "group",
        name    = GENERAL,
        desc    = L["GeneralSettingsEnemies"],
        get = function( option )
            return Constants.GetOption( location, option );
        end,
        set = function( option, ... )
            return Constants.SetOption( location, option, ... );
        end,
        order = 1,
        args =
        {
            Enabled =
            {
                type    = "toggle",
                name    = ENABLE,
                desc    = "test",
                order   = 1
            },
            Fake    = Constants.AddHorizontalSpacing( 2 ),
            Fake1   = Constants.AddHorizontalSpacing( 3 ),
            Fake2   = Constants.AddHorizontalSpacing( 4 ),
            RangeIndicator_Settings =
            {
                type    = "group",
                name    = L.RangeIndicator_Settings,
                desc    = L.RangeIndicator_Settings_Desc,
                order   = 6,
                args =
                {
                    RangeIndicator_Enabled =
                    {
                        type    = "toggle",
                        name    = L.RangeIndicator_Enabled,
                        desc    = L.RangeIndicator_Enabled_Desc,
                        order   = 1
                    },
                    RangeIndicator_Range =
                    {
                        type = "select",
                        name = L.RangeIndicator_Range,
                        desc = L.RangeIndicator_Range_Desc,
                        disabled = function() return not location.RangeIndicator_Enabled end,
                        values = function()
                            ---@diagnostic disable-next-line: undefined-field
                            local checkers  = LRC:GetHarmCheckers( true );
                            local ranges    = {};
                            for range, checker in checkers do
                                ranges[ range ] = range;
                            end
                            return ranges;
                        end,
                        width = "half",
                        order = 2
                    },
                    RangeIndicator_Alpha =
                    {
                        type = "range",
                        name = L.RangeIndicator_Alpha,
                        desc = L.RangeIndicator_Alpha_Desc,
                        disabled = function() return not location.RangeIndicator_Enabled end,
                        min = 0,
                        max = 1,
                        step = 0.05,
                        order = 3
                    },
                    Fake = Constants.AddVerticalSpacing( 4 ),
                    RangeIndicator_Everything =
                    {
                        type = "toggle",
                        name = L.RangeIndicator_Everything,
                        disabled = function() return not location.RangeIndicator_Enabled end,
                        order = 6
                    },
                }
            },
            KeybindSettings =
            {
                type = "group",
                name = KEY_BINDINGS,
                desc = L.KeybindSettings_Desc..L.NotAvailableInCombat,
                disabled = InCombatLockdown,
                --childGroups = "tab",
                order = 7,
                args =
                {
                    UseClique =
                    {
                        type = "toggle",
                        name = L.EnableClique,
                        desc = L.EnableClique_Desc,
                        order = 1,
                        hidden = true
                    },
                    LeftButton =
                    {
                        type = "group",
                        name = KEY_BUTTON1,
                        order = 2,
                        disabled = function() return location.UseClique end,
                        args = {
                            LeftButtonType = {
                                type = "select",
                                name = KEY_BUTTON1,
                                values = Constants.Buttons,
                                order = 1
                            },
                            LeftButtonValue = {
                                type = "input",
                                name = ENTER_MACRO_LABEL,
                                desc = L.CustomMacro_Desc,
                                disabled = function() return location.LeftButtonType == "Target" or location.LeftButtonType == "Focus" end,
                                multiline = true,
                                width = 'double',
                                order = 2
                            },

                        }
                    },
                    RightButton = {
                        type = "group",
                        name = KEY_BUTTON2,
                        order = 3,
                        disabled = function() return location.UseClique end,
                        args = {
                            RightButtonType = {
                                type = "select",
                                name = KEY_BUTTON2,
                                values = Constants.Buttons,
                                order = 1
                            },
                            RightButtonValue = {
                                type = "input",
                                name = ENTER_MACRO_LABEL,
                                desc = L.CustomMacro_Desc,
                                disabled = function() return location.RightButtonType == "Target" or location.RightButtonType == "Focus" end,
                                multiline = true,
                                width = 'double',
                                order = 2
                            },

                        }
                    },
                    MiddleButton = {
                        type = "group",
                        name = KEY_BUTTON3,
                        order = 4,
                        disabled = function() return location.UseClique end,
                        args = {

                            MiddleButtonType = {
                                type = "select",
                                name = KEY_BUTTON3,
                                values = Constants.Buttons,
                                order = 1
                            },
                            MiddleButtonValue = {
                                type = "input",
                                name = ENTER_MACRO_LABEL,
                                desc = L.CustomMacro_Desc,
                                disabled = function() return location.MiddleButtonType == "Target" or location.MiddleButtonType == "Focus" end,
                                multiline = true,
                                width = 'double',
                                order = 2
                            }
                        }
                    }
                }
            }
        }
    };

    for key, size in pairs( { "10", "15", "40" } ) do
        local defaults  = self.Database.defaults.profile.Enemies[ size ];
        local location  = self.Database.profile.Enemies[ size ];

        settings[ size ] =
        {
            type = "group",
            name = L["BGSize_" .. size ],
            desc = L["BGSize_" .. size .. "_Desc"]:format( L.Enemies ),
            disabled = function() return not self.Config.Enabled end,
            get =  function( option )
                return Constants.GetOption( location, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( location, option, ... );
            end,
            order = key + 1,
            args =
            {
                Enabled =
                {
                    type = "toggle",
                    name = ENABLE,
                    desc = "test",
                    order = 1
                },

                Fake = Constants.AddHorizontalSpacing( 2 ),

                MainFrameSettings =
                {
                    type = "group",
                    name = L.MainFrameSettings,
                    desc = L.MainFrameSettings_Desc:format( L["enemies"] ),
                    disabled = function() return not location.Enabled end,
                    order = 4,
                    args =
                    {
                        Framescale =
                        {
                            type = "range",
                            name = L.Framescale,
                            desc = L.Framescale_Desc..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            min = 0.3,
                            max = 2,
                            step = 0.05,
                            order = 1
                        },
                        PlayerCount =
                        {
                            type = "group",
                            name = L.PlayerCount_Enabled,
                            get = function( option )
                                return Constants.GetOption( location.PlayerCount, option );
                            end,
                            set = function( option, ... )
                                return Constants.SetOption( location.PlayerCount, option, ... );
                            end,
                            order = 2,
                            inline = true,
                            args =
                            {
                                Enabled =
                                {
                                    type = "toggle",
                                    name = L.PlayerCount_Enabled,
                                    desc = L.PlayerCount_Enabled_Desc,
                                    order = 1
                                },
                                PlayerCountTextSettings =
                                {
                                    type = "group",
                                    name = L.TextSettings,
                                    disabled = function() return not location.PlayerCount.Enabled end,
                                    get = function(option)
                                        return Constants.GetOption( location.PlayerCount.Text, option );
                                    end,
                                    set = function(option, ...)
                                        return Constants.SetOption( location.PlayerCount.Text, option, ... );
                                    end,
                                    inline = true,
                                    order = 2,
                                    args = Constants.AddNormalTextSettings( location.PlayerCount.Text );
                                }
                            }
                        },
                        BattlegroundRezTimer =
                        {
                            type = "group",
                            name = L.BattlegroundRezTimer,
                            get = function( option )
                                return Constants.GetOption( location.BattlegroundRezTimer, option );
                            end,
                            set = function( option, ... )
                                return Constants.SetOption( location.BattlegroundRezTimer, option, ... );
                            end,
                            order = 3,
                            inline = true,
                            args =
                            {
                                Enabled =
                                {
                                    type = "toggle",
                                    name = L.BattlegroundRezTimer_Enabled,
                                    desc = L.BattlegroundRezTimer_Enabled_Desc,
                                    order = 1
                                },
                                BattlegroundRezTimerTextSettings =
                                {
                                    type = "group",
                                    name = L.TextSettings,
                                    disabled = function() return not location.BattlegroundRezTimer.Enabled end,
                                    get = function(option)
                                        return Constants.GetOption( location.BattlegroundRezTimer.Text, option );
                                    end,
                                    set = function(option, ...)
                                        return Constants.SetOption( location.BattlegroundRezTimer.Text, option, ... );
                                    end,
                                    inline = true,
                                    order = 2,
                                    args = Constants.AddNormalTextSettings( location.BattlegroundRezTimer.Text );
                                }
                            }
                        }
                    }
                },

                BarSettings =
                {
                    type = "group",
                    name = L.Button,
                    disabled = function() return not location.Enabled end,
                    order = 5,
                    args =
                    {
                        BarWidth =
                        {
                            type = "range",
                            name = L.Width,
                            desc = L.BarWidth_Desc..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            min = 1,
                            max = 400,
                            step = 1,
                            order = 1
                        },
                        BarHeight =
                        {
                            type = "range",
                            name = L.Height,
                            desc = L.BarHeight_Desc..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            min = 1,
                            max = 100,
                            step = 1,
                            order = 2
                        },
                        BarVerticalGrowDirection =
                        {
                            type = "select",
                            name = L.VerticalGrowdirection,
                            desc = L.VerticalGrowdirection_Desc..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            values = Constants.VerticalDirections,
                            order = 3
                        },
                        BarVerticalSpacing =
                        {
                            type = "range",
                            name = L.VerticalSpacing,
                            desc = L.VerticalSpacing..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            min = 0,
                            max = 100,
                            step = 1,
                            order = 4
                        },
                        BarColumns =
                        {
                            type = "range",
                            name = L.Columns,
                            desc = L.Columns_Desc..L.NotAvailableInCombat,
                            disabled = InCombatLockdown,
                            min = 1,
                            max = 4,
                            step = 1,
                            order = 5
                        },
                        BarHorizontalGrowdirection =
                        {
                            type = "select",
                            name = L.VerticalGrowdirection,
                            desc = L.VerticalGrowdirection_Desc..L.NotAvailableInCombat,
                            hidden = function() return location.BarColumns < 2 end,
                            disabled = InCombatLockdown,
                            values = Constants.HorizontalDirections,
                            order = 6
                        },
                        BarHorizontalSpacing =
                        {
                            type = "range",
                            name = L.HorizontalSpacing,
                            desc = L.HorizontalSpacing..L.NotAvailableInCombat,
                            hidden = function() return location.BarColumns < 2 end,
                            disabled = InCombatLockdown,
                            min = 0,
                            max = 400,
                            step = 1,
                            order = 7
                        },
                        ModuleSettings =
                        {
                            type = "group",
                            name = L.ModuleSettings,
                            order = 8,
                            args = self:AddModuleSettings( location, defaults, size )
                        }
                    }
                }
            }
        };
    end
    return settings;
end

---
---
---
--- @param location table
--- @param defaults table
--- @param BGSize   string
--- @return table
---
function Vantage:AddModuleSettings( location, defaults, BGSize )

    local temp = {};

    for module_name, module_config in pairs( self.Module_Configs ) do
        local inner_location = location.ButtonModules[ module_name ];

        if not inner_location then
            self:Debug( "[Vantage:AddModuleSettings] Error -> Module name needs to be fixed: " .. module_name );
        end

        temp[ module_name ] =
        {
            type    = "group",
            name    = module_config.localized_name,
            order   = module_config.order,
            get = function( option )
                return Constants.GetOption( inner_location, option );
            end,
            set = function( option, ... )
                return Constants.SetOption( inner_location, option, ... );
            end,
            childGroups = "tab",
            args =
            {
                Enabled =
                {
                    type    = "toggle",
                    name    = VIDEO_OPTIONS_ENABLED,
                    width   = "normal",
                    order   = 1
                },
                PositionSetting =
                {
                    type = "group",
                    name = L.Position .. " " .. L.AND .. " " .. L.Size,
                    get = function( option )
                        return Constants.GetOption( inner_location, option );
                    end,
                    set = function( option, ... )
                        return Constants.SetOption( inner_location, option, ... );
                    end,
                    disabled  = function() return not inner_location.Enabled end,
                    order = 2,
                    args = Constants.AddPositionSetting( inner_location, module_name, module_config )
                },
                ModuleSettings =
                {
                    type = "group",
                    name = L.ModuleSpecificSettings,
                    get =  function( option )
                        return Constants.GetOption( inner_location, option );
                    end,
                    set = function( option, ... )
                        return Constants.SetOption( inner_location, option, ... );
                    end,
                    disabled  = function() return not inner_location.Enabled or not module_config.options end,
                    order = 3,
                    args = type( module_config.options ) == "function" and module_config.options( inner_location ) or module_config.options or {}
                },
                Reset =
                {
                    type = "execute",
                    name = L.ResetModule,
                    desc = L.ResetModule_Desc:format( L["enemies"], BG_SIZE_TO_LOCALE[ tonumber( BGSize ) ] ),
                    func = function()

                        --
                        -- Copy the default settings from the module's config.
                        --
                        location.ButtonModules[ module_name ] = copy( self.Module_Configs[ module_name ].default_settings );

                        --
                        -- Concat the default settings based on BG size.
                        --
                        self:Merge( location.ButtonModules[ module_name ], Constants.settings.profile.Enemies[BGSize].ButtonModules[ module_name ] );

                        self:NotifyChange();
                    end,
                    width = "full",
                    order = 4,
                }
            }
        };
    end
    return temp;
end

---
---
---
--- @param config table
--- @return table?
---
function Vantage:GetActivePoints( config )
    if config.Points then
        local activePoints = {};
        for i = 1, config.ActivePoints + 1 do
            activePoints[ i ] = config.Points[ i ];
        end
        return activePoints;
    end
end

---
---
---
--- @param Point1   table?
--- @param Point2   table?
--- @return boolean
---
function Vantage:FrameNeedsHeight( Point1, Point2 )
	if not Point1 and not Point2 then
        return false;
    end
	if Point1 and not Point2 then
        return true;
    end
	return isInSameHorizontal( Point1, Point2 );
end

---
---
---
--- @param Point1 table
--- @param Point2 table
--- @return boolean
---
function Vantage:FrameNeedsWidth( Point1, Point2 )
	if not Point1 and not Point2 then
        return false;
    end
	if Point1 and not Point2 then
        return true;
    end
	return isInSameVertical( Point1, Point2 );
end

---
--- Notify the AceConfigRegistry of incoming GUI changes, and
--- 
---
function Vantage:NotifyChange()
    AceConfigRegistry:NotifyChange( "VantageEnemyFrames" );
    self:ProfileChanged();
end

---
---
---
function Vantage:ProfileChanged()
    self:SetupOptions();
    self:ApplyAllSettings();
end

---
---
---
--- @param module_flags table?
--- @param config       table
--- @return boolean
---
function Vantage:ModuleFrameNeedsHeight( module_flags, config )

    if module_flags and ( module_flags.HasDynamicSize or module_flags.Width == "Fixed" ) then
        return false;
    end

    local active_points = self:GetActivePoints( config );
    if active_points then
        return self:FrameNeedsWidth( active_points[ 1 ], active_points[ 2 ] );
    end
	return false;
end

---
---
---
--- @param module_flags table?
--- @param config       table
--- @return boolean
---
function Vantage:ModuleFrameNeedsWidth( module_flags, config )

	if module_flags and ( module_flags.HasDynamicSize or module_flags.Width == "Fixed" ) then
        return false;
    end

	local active_points = self:GetActivePoints( config );
    if active_points then
        return self:FrameNeedsWidth( active_points[ 1 ], active_points[ 2 ] );
    end
	return false;
end

---
--- Setup the GUI options table.
---
function Vantage:SetupOptions()

    self:LoadModuleConfigurations();

    local location = self.Database.profile;
    self.options =
    {
        type = "group",
        name = "Vantage " .. GetAddOnMetadata( AddonName, "Version" ),
        childGroups = "tab",
        get = function( option )
            return Constants.GetOption( location, option )
        end,
        set = function( option, ... )
            return Constants.SetOption( location, option, ... )
        end,
        args =
        {
            TestModeSettings =
            {
                type = "group",
                name = L.TestModeSettings,
                disabled = function() return InCombatLockdown() or ( self:IsShown() and self.TestingMode.active ) end,
                inline = true,
                order = 1,
                args =
                {
                    Testmode_BGSize =
                    {
                        type = "select",
                        name = L.BattlegroundSize,
                        order = 1,
                        disabled = function() return self.TestingMode.active end,
                        get = function() return self.TestingMode.mode_size end,
                        set = function( option, value )
                            self.TestingMode.mode_size = value;
                        end,
                        values = BG_SIZE_TO_LOCALE
                    },
                    Testmode_Enabled =
                    {
                        type = "execute",
                        name = L.Testmode_Toggle,
                        desc = L.Testmode_Toggle_Desc,
                        disabled = function() return InCombatLockdown() or ( self:IsShown() and not self.TestingMode.active ) or not self.TestingMode.mode_size end,
                        func = function() self:ToggleTestMode(); end,
                        order = 2
                    },
                    Testmode_ToggleAnimation =
                    {
                        type = "execute",
                        name = L.Testmode_ToggleAnimation,
                        desc = L.Testmode_ToggleAnimation_Desc,
                        disabled = function() return InCombatLockdown() or not self.TestingMode.active end,
                        func = function() self:ToggleTestModeOnUpdate() end,
                        order = 3
                    },
                    Fake = Constants.AddHorizontalSpacing( 4 ),
                    Testmode_UseTeammates =
                    {
                        type = "toggle",
                        name = L.Testmode_UseTeammates,
                        desc = L.Testmode_UseTeammates_Desc,
                        disabled = function() return self.TestingMode.active or not ( IsInGroup() or IsInRaid() ) end,
                        width = "full",
                        order = 5
                    },
                }
            },

            GeneralSettings =
            {
                type = "group",
                name = L.GeneralSettings,
                desc = L.GeneralSettings_Desc,
                order = 2,
                args =
                {
                    Locked =
                    {
                        type = "toggle",
                        name = L.Locked,
                        desc = L.Locked_Desc,
                        order = 1
                    },
                    ShowTooltips =
                    {
                        type = "toggle",
                        name = L.ShowTooltips,
                        desc = L.ShowTooltips_Desc,
                        order = 5
                    },
                    ConvertCyrillic =
                    {
                        type = "toggle",
                        name = L.ConvertCyrillic,
                        desc = L.ConvertCyrillic_Desc,
                        width = "normal",
                        order = 6
                    },
                    Font =
                    {
                        type = "select",
                        name = L.Font,
                        desc = L.Font_Desc,
                        dialogControl = "LSM30_Font",
                        values = AceGUIWidgetLSMlists.font,
                        order = 7
                    },
                    BigDebuffSettings =
                    {
                        type = "group",
                        name = "BigDebuffs",
                        inline = true,
                        order = 8,
                        args =
                        {
                            UseBigDebuffsPriority =
                            {
                                type = "toggle",
                                name = L.UseBigDebuffsPriority,
                                desc = L.UseBigDebuffsPriority_Desc:format( L.Buffs, L.Debuffs, L.HighestPriorityAura ),
                                order = 1
                            },
                            BigDebuffsPriorityThreshold =
                            {
                                type = "range",
                                name = "Priority threshold",
                                disabled = function() return self.TestingMode.active end,
                                min = 0,
                                max = 100,
                                step = 1,
                                order = 2,
                            }
                        },
                    },
                    MyTarget =
                    {
                        type = "group",
                        name = L.MyTarget,
                        inline = true,
                        order = 9,
                        args = {
                            MyTarget_Color =
                            {
                                type = "color",
                                name = L.Color,
                                desc = L.MyTarget_Color_Desc,
                                hasAlpha = true,
                                order = 1
                            },
                            MyTarget_BorderSize =
                            {
                                type = "range",
                                name = L.BorderSize,
                                min = 1,
                                max = 5,
                                step = 1,
                                order = 2
                            }
                        }
                    },
                    MyFocus =
                    {
                        type = "group",
                        name = L.MyFocus,
                        inline = true,
                        order = 10,
                        args = {
                            MyFocus_Color =
                            {
                                type = "color",
                                name = L.Color,
                                desc = L.MyFocus_Color_Desc,
                                hasAlpha = true,
                                order = 1
                            },
                            MyFocus_BorderSize =
                            {
                                type = "range",
                                name = L.BorderSize,
                                min = 1,
                                max = 5,
                                step = 1,
                                order = 2
                            }
                        }
                    },
                    DevMode =
                    {
                        type = "group",
                        name = "Development",
                        inline = true,
                        order = 11,
                        args =
                        {
                            Enable_DevMode =
                            {
                                type = "toggle",
                                name = "DevMode",
                                desc = "Enable to development mode",
                                order = 1,
                            },
                        }
                    },
                }
            },
            EnemySettings =
            {
                type = "group",
                name = L.Enemies,
                childGroups = "tab",
                order = 3,
                args = self:AddEnemySettings()
            },

            MoreProfileOptions =
            {
                type = "group",
                name = L.MoreProfileOptions,
                childGroups = "tab",
                order = 6,
                args =
                {
                    ImportButton =
                    {
                        type = "execute",
                        name = L.ImportButton,
                        desc = L.ImportButton_Desc,
                        func = function()
                            Vantage:ImportExportFrameSetupForMode( "Import" );
                        end,
                        order = 1,
                    },
                    ExportButton =
                    {
                        type = "execute",
                        name = L.ExportButton,
                        desc = L.ExportButton_Desc,
                        func = function()
                            Vantage:ExportDataViaPrint( Vantage.Database.profile );
                        end,
                        order = 2,
                    }
                }
            }
        }
    };

    AceConfigRegistry:RegisterOptionsTable( "VantageEnemyFrames", self.options );

    --
    -- Add profile tab to the options
    --
    self.options.args.profiles          = LibStub( "AceDBOptions-3.0" ):GetOptionsTable( self.Database );
    self.options.args.profiles.order    = -1;
    self.options.args.profiles.disabled = InCombatLockdown;
end

---
---
---
--- @param location table
--- @return table
---
function Constants.AddCooldownSettings( location )
	return
    {
		ShowNumber =
        {
			type    = "toggle",
			name    = L.ShowNumbers,
			desc    = L.ShowNumbers_Desc,
			order   = 1
		},

        --
        -- TODO: ??????
        -- 
		asdfasdf =
        {
			type = "group",
			name = "",
			desc = "",
			disabled = function()
				return not location.ShowNumber
			end,
			inline = true,
			order = 2,
			args = {
				FontSize = {
					type = "range",
					name = L.FontSize,
					desc = L.FontSize_Desc,
					min = 6,
					max = 40,
					step = 1,
					width = "normal",
					order = 3
				},
				FontOutline = {
					type = "select",
					name = L.Font_Outline,
					desc = L.Font_Outline_Desc,
					values = FONT_OUTLINES,
					order = 4
				},
				Fake1 = Constants.AddVerticalSpacing(5),
				EnableShadow = {
					type = "toggle",
					name = L.FontShadow_Enabled,
					desc = L.FontShadow_Enabled_Desc,
					order = 6
				},
				ShadowColor =
                {
					type = "color",
					name = L.FontShadowColor,
					desc = L.FontShadowColor_Desc,
					disabled = function()
						return not location.EnableShadow
					end,
					hasAlpha = true,
					order = 7
				}
			}
		}
	};
end

---
---
---
--- @param location any
--- @return table
---
function Constants.AddNormalTextSettings( location )
	return
    {
        JustifyH =
        {
            type    = "select",
            name    = L.JustifyH,
            desc    = L.JustifyH_Desc,
            values  = JUSTIFY_H_VALUES
        },
        JustifyV =
        {
            type    = "select",
            name    = L.JustifyV,
            desc    = L.JustifyV_Desc,
            values  = JUSTIFY_V_VALUES
        },
        FontSize =
        {
            type    = "range",
            name    = L.FontSize,
            desc    = L.FontSize_Desc,
            min     = 1,
            max     = 40,
            step    = 1,
            width   = "normal",
            order   = 1
        },
        FontOutline =
        {
            type    = "select",
            name    = L.Font_Outline,
            desc    = L.Font_Outline_Desc,
            values  = FONT_OUTLINES,
            order   = 2
        },
        Fake = Constants.AddVerticalSpacing( 3 ),
        FontColor =
        {
            type        = "color",
            name        = L.Fontcolor,
            desc        = L.Fontcolor_Desc,
            hasAlpha    = true,
            order       = 4
        },
        EnableShadow =
        {
            type    = "toggle",
            name    = L.FontShadow_Enabled,
            desc    = L.FontShadow_Enabled_Desc,
            order   = 5
        },
        ShadowColor =
        {
            type = "color",
            name = L.FontShadowColor,
            desc = L.FontShadowColor_Desc,
            disabled = function()
                return not location.EnableShadow;
            end,
            hasAlpha = true,
            order = 6
        }
    };
end

---
---
---
--- @param location      table
--- @param module_name   string
--- @param module_config ModuleConfiguration
--- @return table?
---
function Constants.AddPositionSetting( location, module_name, module_config )

    local numPoints = location.ActivePoints;
    local temp      = {};
    temp.Parent =
    {
        type = "select",
        name = "Parent",
        values = GetAllModuleAnchors( module_name ),
        order = 2
    };
    temp.Fake1 = Constants.AddVerticalSpacing( 3 );

    if location.Points and numPoints then
        for i = 1, numPoints do
            temp[ "Point" .. i ] =
            {
                type = "group",
                name = L.Point .. " " .. i,
                desc = "",
                get =  function(option)
                    return Constants.GetOption( location.Points[i], option );
                end,
                set = function(option, ...)
                    return Constants.SetOption( location.Points[i], option, ... );
                end,
                inline = true,
                order = i + 3,
                args =
                {
                    Point =
                    {
                        type = "select",
                        name = L.Point,
                        values = Constants.AllPositions,
                        confirm = function()
                            return "Are you sure you want to change this value?";
                        end,
                        order = 1
                    },
                    RelativeFrame =
                    {
                        type = "select",
                        name = "RelativeFrame",
                        values = GetAllModuleAnchors( module_name ),
                        validate = function( option, value )

                            if ValidateAnchor( module_name, value ) then
                                Vantage:Debug( fmt( "Validated anchor: %s", module_name ) );
                                return true;
                            else
                                --
                                -- invalid anchor, there might be some looping issues
                                -- print("hier")
                                --
                                PlaySound( 882 );
                                Vantage:NotifyChange();
                                return false;
                            end
                        end,
                        order = 2
                    },
                    RelativePoint =
                    {
                        type = "select",
                        name = "Relative Point",
                        values = Constants.AllPositions,
                        order = 3
                    },
                    OffsetX =
                    {
                        type = "range",
                        name = L.OffsetX,
                        min = -100,
                        max = 100,
                        step = 1,
                        order = 4
                    },
                    OffsetY =
                    {
                        type    = "range",
                        name    = L.OffsetY,
                        min     = -100,
                        max     = 100,
                        step    = 1,
                        order   = 5
                    },
                    DeletePoint =
                    {
                        type = "execute",
                        name = L.DeletePoint:format( i ),
                        func = function()
                            location.ActivePoints = i - 1;
                            Vantage:NotifyChange();
                        end,
                        --
                        -- Only allow to remove the last point, dont allow removal of all Points
                        --
                        disabled = i ~= numPoints or i == 1,
                        width = "full",
                        order = 6,
                    }
                }
            };
        end
    end

    temp.AddPoint =
    {
        type = "execute",
        name = L.AddPoint,
        func = function()
            location.ActivePoints           = numPoints + 1;
            location.Points                 = location.Points or {};
            location.Points[numPoints + 1]  = location.Points[numPoints + 1] or {
                Point = "TOPLEFT",
                RelativeFrame = "Button",
                RelativePoint = "TOPLEFT"
            };
            Vantage:NotifyChange();
        end,
        disabled = function()
            if not location.Points then
                return false;
            end
            --
            -- dynamic containers with dynamic width and height can have a maximum of 1 point
            --
            return not canAddPoint( location, module_config );
        end,
        width = "full",
        order = numPoints + 4
    };

    temp.WidthGroup =
    {
        type    = "group",
        name    = L.Width,
        order   = numPoints + 5,
        hidden  = function() return not Vantage:ModuleFrameNeedsWidth( module_config.flags, location ) end,
        inline  = true,
        args =
        {
            UseButtonHeightAsWidth =
            {
                type = "toggle",
                name = L.UseButtonHeight,
                order = 1
            },
            Width =
            {
                type = "range",
                name = L.Width,
                min = 0,
                max = 100,
                step = 1,
                hidden = function()
                    if location.UseButtonHeightAsWidth then
                        Vantage:NotifyChange();
                        return true;
                    end
                end,
                order = 2
            }
        }
    };

    temp.HeightGroup =
    {
        type = "group",
        name = L.Height,
        order = numPoints + 6,
        hidden = function()
            if not Vantage:ModuleFrameNeedsHeight( module_config.flags, location ) then
                return true;
            end
        end,
        inline = true,
        args =
        {
            UseButtonHeightAsHeight =
            {
                type = "toggle",
                name = L.UseButtonHeight,
                order = 1
            },
            Height =
            {
                type = "range",
                name = L.Height,
                min = 0,
                max = 100,
                step = 1,
                hidden = function()
                    if location.UseButtonHeightAsHeight then
                        --location.Height = false;
                        Vantage:NotifyChange();
                        return true;
                    end
                end,
                order = 2
            }
        }
    };

    return temp;
end

---
---
---
--- @param location table
--- @param option any
--- @return unknown
---
function Constants.GetOption( location, option )
    local value = location[ option[ #option ] ];
    if type( value ) == "table" then
        return unpack( value );
    end
    return value;
end

---
---
---
--- @param location any
--- @param option any
--- @param ... unknown
---
function Constants.SetOption( location, option, ... )
    local value;
    if option.type == "color" then
        value = { ... };
    else
        value = ...;
    end
    location[ option[ #option ] ] = value;
    Vantage:ApplyAllSettings();
end

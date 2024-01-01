-------------------------------------------------------------------------------
---@script: log.lua
---@author: zimawhit3
---@desc:   This module implements customg logging to the chat frame.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...
local LibStub       = LibStub

-----------------------------------------
--                Lua
-----------------------------------------
local fmt   = string.format

-----------------------------------------
--              Blizzard
-----------------------------------------
local FCF_OpenTemporaryWindow   = FCF_OpenTemporaryWindow
local WrapTextInColorCode       = WrapTextInColorCode

-----------------------------------------
--                Ace3
-----------------------------------------

---
---@class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                     Logging
-------------------------------------------------------------------------------

----------------------------------------
--               Constants
----------------------------------------
local LOG_MAX_HISTORY = 2500;
local COLOR_SUCCESS = "979DFF00";
local COLOR_INFO    = "ff0099ff";

----------------------------------------
--                Types
----------------------------------------

----------------------------------------
--                Private
----------------------------------------

---
--- Create a seperate debug frame for the addon.
---
--- @return Frame 
---
local function CreateDebugFrame()
    local debug_frame = FCF_OpenTemporaryWindow( "FILTERED" );

    debug_frame:SetMaxLines( LOG_MAX_HISTORY );
    debug_frame:ClearAllPoints();
    debug_frame:SetPoint( "CENTER", "UIParent", "CENTER", 0, 0 );
    debug_frame:Show();

    debug_frame.Tab = _G[ debug_frame:GetName() .. "Tab" ]
    debug_frame.Tab.conversationIcon:Hide()

    FCF_SetTabPosition( debug_frame, 0 );
    FCF_SetWindowName( debug_frame, "Vantage_DebugFrame" )
    FCF_UnDockFrame( debug_frame );
	return debug_frame;
end

---
---
---
--- @return unknown
---
local function GetTimestamp()
	local timestampFormat   = "[%I:%M:%S] ";
	local stamp             = BetterDate( timestampFormat, time() );
	return stamp;
end

----------------------------------------
--                 Public
----------------------------------------

---
--- Initializes debug logging for the addon.
---
--- @param level LogLevel
---
function Vantage:InitializeLogging( level )
    if level ~= Constants.LogLevel.LOG_LEVEL_NONE then
        self.DebugFrame = CreateDebugFrame();
    end
    self.LogLevel = level;
end

---
--- Adds message `msg` to the debug frame if the log level is atleast `LOG_LEVEL_DEBUG`.
---
--- @param msg string
---
function Vantage:Debug( msg )
    if Constants.LogLevel.LOG_LEVEL_DEBUG >= self.LogLevel then
        self.DebugFrame:AddMessage( msg );
    end
end

---
--- Adds message `msg` to the debug frame if the log level is atleast `LOG_LEVEL_ERROR`.
---
--- @param msg string
---
function Vantage:Error( msg )
    if Constants.LogLevel.LOG_LEVEL_ERROR >= self.LogLevel then
        self.DebugFrame:AddMessage( msg );
    end
end

---
--- Adds message `msg` to the debug frame if the log level is atleast `LOG_LEVEL_INFO`.
---
--- @param msg string
---
function Vantage:Info( msg )
    if Constants.LogLevel.LOG_LEVEL_INFO >= self.LogLevel then
        self.DebugFrame:AddMessage( msg );
    end
end

---
--- Notify the addon user with message `msg`.
---
--- @param msg string
---
function Vantage:Notify( msg )
    print(
        fmt( "%s%s%s%s",
        WrapTextInColorCode( "VantageEnemyFrames(", COLOR_INFO ),
        WrapTextInColorCode( fmt( "v%s", self.version ), COLOR_SUCCESS ),
        WrapTextInColorCode( "): ", COLOR_INFO ),
        msg
    ));
end

---
--- Adds message `msg` to the debug frame if the log level is atleast `LOG_LEVEL_WARN`.
---
--- @param msg string
---
function Vantage:Warn( msg )
    if Constants.LogLevel.LOG_LEVEL_WARN >= self.LogLevel then
        self.DebugFrame:AddMessage( msg );
    end
end

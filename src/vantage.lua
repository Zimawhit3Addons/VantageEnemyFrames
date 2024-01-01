-------------------------------------------------------------------------------
---@script: vantage.lua
---@author: zimawhit3
---@desc:   This module implements the startup routines to the addon.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants          = ...
local LibStub               = LibStub
local LSM                   = LibStub( "LibSharedMedia-3.0" )
local AceConfigDialog       = LibStub( "AceConfigDialog-3.0" )

-----------------------------------------
--                Lua
-----------------------------------------
local fmt   = string.format

-----------------------------------------
--              Blizzard
-----------------------------------------
local GetServerExpansionLevel       = GetServerExpansionLevel
local GetSpellInfo                  = GetSpellInfo
local IsInInstance                  = IsInInstance
local PVPMatchScoreboard            = PVPMatchScoreboard
local SetBattlefieldScoreFaction    = SetBattlefieldScoreFaction
local UnitGUID                      = UnitGUID
local wipe                          = wipe

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                  Main
-------------------------------------------------------------------------------

---
--- Initialize the addon and set the addon's main frame settings.
---
function Vantage:Initialize()

    self.Config = self.Database.profile.Enemies;

    --
    -- Initialize the core parts of the addon
    --
    Constants:Init_Constants();
    self:InitializeBroadcast();
    self:InitializeFramePool();
    self:InitializePlayerCount();
    self:InitializeRezTimer();

    --
    -- Set the frame's settings.
    --
    self:SetClampedToScreen( true );
    self:SetMovable( true );
    self:SetUserPlaced( true );
    self:SetResizable( true );
    self:SetToplevel( true );
end

---
--- Check our stored spell IDs are accurate for this expansion.
---
function Vantage:CheckUsedSpells()

    for spell_id in pairs( Constants.PriorityAuras.HELPFUL ) do
        if not GetSpellInfo( spell_id ) then
            self:Notify( fmt( "Unknown spell used ( %d ). Please report this to the addon author.", spell_id ) );
        end
    end

    for spell_id in pairs( Constants.PriorityAuras.HARMFUL ) do
        if not GetSpellInfo( spell_id ) then
            self:Notify( fmt( "Unknown spell used ( %d ). Please report this to the addon author.", spell_id ) );
        end
    end

    for spell_id in pairs( Constants.Interruptdurations ) do
        if not GetSpellInfo( spell_id ) then
            self:Notify( fmt( "Unknown spell used ( %d ). Please report this to the addon author.", spell_id ) );
        end
    end

end

-------------------------------------------------------------------------------
--                              Game Event Callbacks
-------------------------------------------------------------------------------

----------------------------------------
--               Private
----------------------------------------

---
--- 
---
local function PVPMatchScoreboard_OnHide()
    if PVPMatchScoreboard.selectedTab ~= 1 then
        --
        -- User was looking at another tab than all players
        -- request a UPDATE_BATTLEFIELD_SCORE.
        --
        ---@diagnostic disable-next-line: param-type-mismatch
        SetBattlefieldScoreFaction( nil );
    end
end

----------------------------------------
--               Callbacks
----------------------------------------

---
--- Vantage's OnEvent handler
---
--- @param event any
--- @param ... unknown
---
function Vantage:OnEvent( event, ... )
    self[ event ]( self, ... );
end

---
--- The Ace3Addon's OnEnable callback called during a `PLAYER_LOGIN` event.
---
--- Triggered immediately before `PLAYER_ENTERING_WORLD` on login and UI Reload, 
--- but NOT when entering/leaving instances.
---
function Vantage:OnEnable()

    if GetServerExpansionLevel() >= 3 then
        self:Notify( "The current expansion is unsupported. Please visit https://www.github.com/zimawhit3/VantageEnemyFrames for more information." );
        return;
    end

    self.PlayerInfo = self.NewPlayer( "player", UnitGUID( "player" ) or "" );
    self.Database   = LibStub( "AceDB-3.0" ):New( "VantageDB", Constants.settings, true );

    self.Database.RegisterCallback( self, "OnProfileChanged", "ProfileChanged" );
    self.Database.RegisterCallback( self, "OnProfileCopied", "ProfileChanged" );
    self.Database.RegisterCallback( self, "OnProfileReset", "ProfileChanged" );

    if self.Database.profile then
        if self.Database.profile.Enable_DevMode then
            self:InitializeLogging( Constants.LogLevel.LOG_LEVEL_DEBUG );
        end
    end

    local changelog = self:Register(
        Constants.changelog,
        self.Database.profile,
        "lastReadVersion",
        "onlyShowWhenNewVersion"
    );
    changelog:ShowChangelog();

    self:Initialize();
    self:Hide();

    AceConfigDialog:SetDefaultSize( "VantageEnemyFrames", 709, 532 );
    AceConfigDialog:AddToBlizOptions( "VantageEnemyFrames", "VantageEnemyFrames" );

    -- 
    -- On Classic, TODO: 
    --
    if PVPMatchScoreboard then
        PVPMatchScoreboard:HookScript( "OnHide", PVPMatchScoreboard_OnHide );
    end

    --
    -- Initialize GUI options.
    --
    self:SetupOptions();

    --
    -- Register for the events to track startup.
    --
    self:RegisterEvent( "GROUP_ROSTER_UPDATE" );
    self:RegisterEvent( "PLAYER_ENTERING_WORLD" );
    self:SetScript( "OnEvent", self.OnEvent );

    --
    -- Addon initialization is done, unregister from "PLAYER_LOGIN".
    --
    self:UnregisterEvent( "PLAYER_LOGIN" );

    --
    -- Notify the addon user of any missing spells.
    --
    self:CheckUsedSpells();
end

---
--- Fires when the player logs in, /reloads the UI or zones between map instances. 
--- Basically whenever the loading screen appears. 
---
function Vantage:PLAYER_ENTERING_WORLD()

    --
    -- If test mode was running, disable it.
    --
    if self.TestingMode.active then
        self:DisableTestMode();
    end

    local in_instance, zone = IsInInstance();

    --
    -- Player not in a BG.
    --
    -- If we just got out of one, make sure we've released the frames back to the pool, and
    -- that the disable routines have ran.
    -- 
    if not in_instance and #self.EnemyOrder > 0 then
        self:RemoveAllEnemyPlayers();
        wipe( self.allies );
        self:Disable();
        self:ResetMapData();
        self:BroadcastVersionCheck();

    --
    -- Player joined a BG.
    --
    -- Run the enable routines, set the player's faction, and update the data depending on the MapID.
    --
    elseif zone == "pvp" then
        self.PlayerInfo.alive = true;
        self:UpdateMapID();
    end
end

---
--- Used to initialize the addon for a BG and register to 
--- combat event callbacks.
---
function Vantage:StartBG()
    Vantage:ApplyBGSizeSettings();
    Vantage:Enable();
end

---
---
---
LSM:Register( "font", "PT Sans Narrow Bold", [[Interface\AddOns\VantageEnemyFrames\fonts\PT Sans Narrow Bold.ttf]] );
LSM:Register( "statusbar", "UI-StatusBar", "Interface\\TargetingFrame\\UI-StatusBar" );

---
---
---
SLASH_VantageEnemyFrames1, SLASH_VantageEnemyFrames2 = "/VantageEnemyFrames", "/vef";
SlashCmdList["VantageEnemyFrames"] = function( msg )
	AceConfigDialog:Open( "VantageEnemyFrames" );
end

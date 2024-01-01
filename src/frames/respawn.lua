-------------------------------------------------------------------------------
---@script: respawn.lua
---@author: zimawhit3
---@desc:   This module implements the battleground ressurection timer.
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
local fmt       = string.format
local mabs      = math.abs

-----------------------------------------
--              Blizzard
-----------------------------------------
local C_TimerNewTicker  = C_Timer.NewTicker
local GetTime           = GetTime

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                EnemyModule
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
--- I've seen Rez's in between 31 - 32; 31.5 seems most common
---
local BG_REZ_INTERVAL = 31.5;
local BG_REZ_FMT_TEXT = "GY Timer: %.1f | Rezzing: %d";

-----------------------------------------
--                Types
-----------------------------------------

-----------------------------------------
--               Private
-----------------------------------------

local last_rez_reset = 0.0;

---
--- The callback used by the ressurection timer. This will check
--- for dead enemies and update the rez timer text accordingly.
---
local function UpdateRezTimer()

    local now           = GetTime();
    local current_time  = Vantage.BattleGroundNextRezTime - now;

    --
    -- Count number of rezzers
    --
    local num_rezzing = 0;
    for _, enemy in pairs( Vantage.EnemyFrames ) do
        if not enemy.player_info.alive then
            num_rezzing = num_rezzing + 1;
        end
    end

    Vantage.BattlegroundRezTimer:SetText( fmt( BG_REZ_FMT_TEXT, current_time, num_rezzing ) );

    --
    -- Rez went off, set to the next rez
    --
    if current_time <= 0 then
        Vantage.BattleGroundNextRezTime = now + BG_REZ_INTERVAL;
        Vantage:RezEnemies();
    end
end

-----------------------------------------
--               Public
-----------------------------------------

---
--- Initializes the battleground rez timer fontstring.
---
function Vantage:InitializeRezTimer()
    self.BattlegroundRezTimer = self.NewFontString( self );
    self.BattlegroundRezTimer:SetPoint( "TOP", self.PlayerCount, "BOTTOM" );
    self.BattlegroundRezTimer:SetJustifyH( "CENTER" );
end

---
--- Resets the Battleground Rez timer if the timer is significantly off.
---
--- @param rez_time number
---
function Vantage:ResetRezTimer( rez_time )

    if last_rez_reset == rez_time then
        return;
    end

    last_rez_reset = rez_time;

    --
    -- If we didn't even have a timer, start it.
    --
    if not self.BattleGroundNextRezTimer then
        Vantage:RezEnemies();
        self.BattleGroundNextRezTime    = rez_time + BG_REZ_INTERVAL;
        self.BattleGroundNextRezTimer   = C_TimerNewTicker( 0.1, UpdateRezTimer );

    --
    -- If the timer is off by a second or more, reset it.
    -- 
    elseif mabs( rez_time - self.BattleGroundNextRezTime ) >= 1 then
        self.BattleGroundNextRezTime = rez_time + BG_REZ_INTERVAL;
        Vantage:RezEnemies();
    end
end

---
---
---
function Vantage:RezEnemies()
    for _, enemy in pairs( self.EnemyFrames ) do
        if not enemy.player_info.alive then
            enemy:PlayerRezzed();
        end
    end
end

---
--- Start the Battleground Rez timer.
---
function Vantage:StartRezTimer()

    if self.BattleGroundNextRezTimer then
        self.BattleGroundNextRezTimer:Cancel();
    end

    self.BattleGroundNextRezTime    = GetTime() + BG_REZ_INTERVAL;
    self.BattleGroundNextRezTimer   = C_TimerNewTicker( 0.1, UpdateRezTimer );

end

---
--- Stop the Battleground Rez timer.
---
function Vantage:StopRezTimer()
    if self.BattleGroundNextRezTimer then
        self.BattleGroundNextRezTimer:Cancel();
        self.BattleGroundNextRezTimer = nil;
    end
end

---
---
---
function Vantage:UpdateRezTimer()
    if self.BG_Config and self.BG_Config.BattlegroundRezTimer.Enabled and self.BattleGroundStartMessage then
        self.BattlegroundRezTimer:SetText( "GY Timer: -- | Rezzing: --" );
        self.BattlegroundRezTimer:Show();
    else
        self.BattlegroundRezTimer:Hide();
    end
end

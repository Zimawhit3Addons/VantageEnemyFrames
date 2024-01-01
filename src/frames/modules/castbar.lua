-------------------------------------------------------------------------------
---@script: castbar.lua
---@author: zimawhit3
---@desc:   
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
local CastingBarFrame_OnLoad    = CastingBarFrame_OnLoad or CastingBarMixin.OnLoad
local CastingBarFrame_SetUnit   = CastingBarFrame_SetUnit or CastingBarMixin.SetUnit
local CreateFrame               = CreateFrame
local Mixin                     = Mixin
local wipe                      = wipe

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                              EnemyFrame Castbars
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
--- @type table<string, string>
---
---
local ENEMY_CASTBAR_STYLES =
{
	Arena   = ARENA,
	Normal  = L.NormalCastingBar,
	Small   = L.SmallCastingBar
};

---
---
---
local ENEMY_CASTBAR_OPTIONS = function( _ )
    return
    {
        Style =
        {
            type    = "select",
            name    = L.Style,
            values  = ENEMY_CASTBAR_STYLES,
            order   = 1
        },
        Scale =
        {
            type    = "range",
            name    = L.Scale,
            min     = 0.1,
            max     = 2,
            step    = 0.05,
            order   = 2
        }
    };
end

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class ArenaCastingBarFrameTemplate : StatusBar
--- @class CastingBarFrameTemplate : StatusBar
--- @class SmallCastingBarFrameTemplate : StatusBar
---

---
--- @class EnemyCastBarConfig
---
local ENEMY_CASTBAR_DEFAULT_SETTINGS =
{
	Parent          = "Button",
	ActivePoints    = 0,
	Style           = "Normal",
	Scale           = 1.5
};

---
--- @class EnemyCastBar : Frame
---
local EnemyCastBar =
{
    ---
    --- @type StatusBar?
    ---
    castbar = nil,

    ---
    --- @type EnemyCastBarConfig
    ---
    config = ENEMY_CASTBAR_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type EnemyFrame
    ---
    enemy = nil,

    ---
    --- @type boolean
    ---
    position_set = false,

    ---
    --- @type string
    ---
    style = "Normal",
};

-----------------------------------------
--                 Private
-----------------------------------------

---
---
---
--- @param castbar EnemyCastBar
--- @return StatusBar
---
local function Arena( castbar )
    castbar:SetWidth( 80 );
    castbar:SetHeight( 14 );

    local f = CreateFrame( "StatusBar", nil, castbar, "ArenaCastingBarFrameTemplate" );
    f:SetAllPoints();
    f.Icon:SetPoint( "RIGHT", f, "LEFT", -5, 0 );
    return f;
end

---
---
---
--- @param castbar EnemyCastBar
--- @return StatusBar
---
local function Normal( castbar )
    castbar:SetWidth( 195 );
    castbar:SetHeight( 13 );

    local f = CreateFrame( "StatusBar", nil, castbar, "CastingBarFrameTemplate" );
    f:SetAllPoints();
    return f;
end

---
---
---
--- @param castbar EnemyCastBar
--- @return StatusBar
---
local function Small( castbar )
    castbar:SetWidth( 150 );
    castbar:SetHeight( 10 );

    local f = CreateFrame( "StatusBar", nil, castbar, "SmallCastingBarFrameTemplate" );
    f:SetAllPoints();
    return f;
end

-----------------------------------------
--                 Public
-----------------------------------------

---
---
---
--- @param enemy any
--- @return EnemyCastBar|Frame
---
function Vantage:NewEnemyCastBar( enemy )
    local castbar_frame = CreateFrame( "Frame", nil, enemy );
    local enemy_castbar = Mixin( castbar_frame, EnemyCastBar );
    enemy_castbar:Initialize( enemy );
    return enemy_castbar;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyCastBarConfig()
    return self.NewModuleConfig( "Castbar", ENEMY_CASTBAR_DEFAULT_SETTINGS, ENEMY_CASTBAR_OPTIONS );
end

---
---
---
function EnemyCastBar:ApplyAllSettings()
    self:NewInternalCastBar();
    --if self.enemy.player_info.unit_id then
    --    CastingBarFrame_SetUnit( self.castbar, self.enemy.player_info.unit_id );
    --end
end

---
---
---
function EnemyCastBar:NewInternalCastBar()
    local style = self.config.Style;
    if style ~= self.style then

        --
        -- This will create a big of garbage behind, but hopefully the user doesn't switch 
        -- the castbar style/template too much.
        --
        if self.castbar then
            self.castbar:UnregisterAllEvents();
            self.castbar:Hide();
            wipe( self.castbar );
        end

        Vantage:Debug( string.format( "[EnemyCastBar:NewInternalCastBar] Style: %s", style ) );
        if not ENEMY_CASTBAR_STYLES[ style ] then
            Vantage:Error( "[EnemyCastBar:NewInternalCastBar] Error: The Castbar template doesnt exist." );
            return;
        end

        if style == "Arena" then        self.castbar = Arena( self );
        elseif style == "Normal" then   self.castbar = Normal( self );
        elseif style == "Small" then    self.castbar = Small( self );
        end

        --
        -- Set a fake unit to avoid the error in the onupdate script CastingBarFrame_OnUpdate 
        -- which gets set by the template.
        --
        CastingBarFrame_OnLoad( self.castbar, "fake" );

        self.style = style;
    end

    local scale = self.config.Scale;
    if scale then
        self:SetScale( scale );
    end
end

---
---
---
function EnemyCastBar:Disable()
    self:Reset();
end

---
---
--- @param enemy    EnemyFrame
---
function EnemyCastBar:Initialize( enemy )
    self.enemy = enemy;
end

---
---
---
function EnemyCastBar:Reset()
    if self.castbar then
        CastingBarFrame_SetUnit( self.castbar, nil );
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
function EnemyCastBar:UnitIdUpdate( unit_id )
    if self.castbar then
        CastingBarFrame_SetUnit( self.castbar, unit_id );
    end
end



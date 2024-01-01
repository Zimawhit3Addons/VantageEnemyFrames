-------------------------------------------------------------------------------
---@script: class.lua
---@author: zimawhit3
---@desc:   This module implements class icons for the EnemyFrame.
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
local unpack    = unpack

-----------------------------------------
--              Blizzard
-----------------------------------------
local CLASS_ICON_TCOORDS    = CLASS_ICON_TCOORDS
local CreateFrame           = CreateFrame
local GameTooltip           = GameTooltip
local GetClassInfo          = GetClassInfo
local GetNumClasses         = GetNumClasses
local Mixin                 = Mixin

-----------------------------------------
--                Ace3
----------------------------------------- 

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                EnemyFrame Class
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class EnemyClassConfig
---
local ENEMY_CLASS_DEFAULT_SETTINGS =
{
    Enabled         = true,
    Width           = 36,
    Parent          = "Button",
    ActivePoints    = 2,
    Points =
    {
        {
            Point           = "TOPLEFT",
            RelativeFrame   = "Button",
            RelativePoint   = "TOPLEFT",
        },
        {
            Point           = "BOTTOMLEFT",
            RelativeFrame   = "Button",
            RelativePoint   = "BOTTOMLEFT",
        }
    }
};

---
--- @class EnemyClass : Frame
---
local EnemyClass =
{
    ---
    --- @type Texture
    ---
    background = nil,

    ---
    --- @type EnemyClassConfig
    ---
    config = ENEMY_CLASS_DEFAULT_SETTINGS,

    ---
    --- @type boolean
    ---
    enabled = true,

    ---
    --- @type EnemyFrame
    ---
    enemy = nil,

    ---
    --- @type Texture
    ---
    icon = nil,

    ---
    --- @type boolean
    ---
    position_set = false,
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
--- @param enemy EnemyFrame
--- @return EnemyClass|Frame
---
function Vantage:NewEnemyClass( enemy )
    local class_frame   = CreateFrame( "Frame", nil, enemy );
    local enemy_class   = Mixin( class_frame, EnemyClass );
    enemy_class:Initialize( enemy );
    return enemy_class;
end

---
---
---
--- @return ModuleConfiguration
---
function Vantage:NewEnemyClassConfig()
    return self.NewModuleConfig( "Class", ENEMY_CLASS_DEFAULT_SETTINGS );
end

---
---
---
function EnemyClass:ApplyAllSettings()
    self:Show();
    self:PlayerDetailsChanged( self.enemy.player_info );
end

---
---
---
--- @param enemy_frame  EnemyFrame
---
function EnemyClass:Initialize( enemy_frame )

    self.enemy = enemy_frame;

    self.background = self:CreateTexture( nil, "BACKGROUND" );
    self.background:SetAllPoints();
    self.background:SetColorTexture( 0, 0, 0, 0.8 );

    self.icon = self:CreateTexture( nil, "OVERLAY" );
	self.icon:SetAllPoints();

    self:HookScript( "OnEnter", self.OnEnter );
    self:HookScript( "OnLeave", self.OnLeave );
    self:PlayerDetailsChanged( enemy_frame.player_info );
    self:Show();
end

---
--- Invoked when the cursor enters the `EnemyClass`'s interactive area. 
---
function EnemyClass:OnEnter()
    Vantage:ShowToolTip( self, self.ShowToolTip );
end

---
--- Invoked when the mouse cursor leaves the `EnemyClass`'s interactive area.
---
function EnemyClass:OnLeave()
    if GameTooltip:IsOwned( self ) then
        GameTooltip:Hide();
    end
end

---
---
---
function EnemyClass:Reset()
    self.icon:SetTexture();
end

---
---
---
function EnemyClass:ShowToolTip()
    if self.enemy.player_info and self.enemy.player_info.class then
        --
        -- We could also just save the localized class name it into the button itself, 
        -- but since its only used for this tooltip no need for that
        --
        local enemy_class = self.enemy.player_info.class;
        local class_name, class_file;
        for i = 1, GetNumClasses() do
            class_name, class_file = GetClassInfo( i );
            if class_file and class_file == enemy_class then
                GameTooltip:SetText( class_name );
                return;
            end
        end
    end
end

-----------------------------------------
--               Callbacks
-----------------------------------------

---
---
---
--- @param player_info PlayerInfo
---
function EnemyClass:PlayerDetailsChanged( player_info )
    local coords = CLASS_ICON_TCOORDS[ player_info.class ];
    if coords then
        self.icon:SetTexture( "Interface\\TargetingFrame\\UI-Classes-Circles" );
        self.icon:SetTexCoord( unpack( coords ) );
    else
        self.icon:SetTexture();
    end
end

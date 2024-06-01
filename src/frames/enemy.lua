-------------------------------------------------------------------------------
---@script: enemy.lua
---@author: zimawhit3
---@desc:   This module implements the EnemyFrame for enemy players.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...
local LibStub       = LibStub
local LRC           = LibStub( "LibRangeCheck-3.0" )
local BigDebuffs    = LibStub( "BigDebuffs", true )

-----------------------------------------
--                Lua
-----------------------------------------
local mrand     = math.random
local tinsert   = table.insert
local tremove   = table.remove
local select    = select
local smatch    = string.match
local strlower  = string.lower
local strupper  = string.upper

-----------------------------------------
--              Blizzard
-----------------------------------------
local GetRealmName      = GetRealmName
local GetServerTime     = GetServerTime
local GetTime           = GetTime
local InCombatLockdown  = InCombatLockdown
local Mixin             = Mixin
local UnitAura          = UnitAura
local UnitExists        = UnitExists
local UnitChannelInfo   = UnitChannelInfo
local UnitHealth        = UnitHealth
local UnitHealthMax     = UnitHealthMax
local UnitIsDead        = UnitIsDead

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                   EnemyFrame
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

---
---
---
local MOUSE_BUTTONS =
{
    [1] = "LeftButton",
    [2] = "RightButton",
    [3] = "MiddleButton"
};

-----------------------------------------
--               Types
-----------------------------------------

---
--- @class EnemyModules
--- @field buffs EnemyAura|Frame|VantageContainer
--- @field debuffs EnemyAura|Frame|VantageContainer
--- @field castbar EnemyCastBar|Frame
--- @field class EnemyClass|Frame
--- @field combatindicator CombatIndicator|Frame
--- @field drtracker EnemyDRTracker|Frame|VantageContainer
--- @field healthbar HealthBar|StatusBar
--- @field highestpriority EnemyHighestPriority|Frame
--- @field level EnemyLevel|FontString
--- @field name EnemyName|FontString
--- @field objective EnemyObjective|Frame
--- @field racial EnemyRacial|Frame
--- @field resource EnemyResource|StatusBar
--- @field targetcounter TargetCounter|VantageFontString|FontString
--- @field targetindicator TargetIndicator|Frame
--- @field trinket Trinket|Frame
---

---
--- @class EnemyFrame : Button
---
--- An `EnemyFrame` is the frame used to represent enemy players.
---
local EnemyFrame =
{
    ---
    --- @type table
    ---
    --- The current addon user's saved configuration based on the size
    --- of the current battleground.
    ---
    bg_config = nil,

    ---
    --- @type table
    ---
    --- 
    ---
    config = nil,

    ---
    --- @type boolean
    ---
    --- `True` if the enemy player is in range of the current addon user. 
    --- Otherwise, `False`.
    ---
    inRange = true,

    ---
    --- @type PlayerInfo
    ---
    --- The `PlayerInfo` of the enemy player represented by this 
    --- `EnemyFrame`.
    ---
    player_info = nil,

    ---
    --- @type BackdropTemplate|Frame
    ---
    --- Indicates the current target of the player.
    ---
    player_target = nil,

    ---
    --- @type BackdropTemplate|Frame
    ---
    --- Indicates the current focus of the player.
    ---
    player_focus = nil,

    ---
    --- @type number
    ---
    --- The time of the last aura update ran for this `EnemyFrame`.
    ---
    last_aura_update = 0.0,

    ---
    --- @type number
    ---
    last_broadcast = 0.0,

    ---
    --- @type number
    ---
    --- The time of the last on update ran for this `EnemyFrame`.
    ---
    last_on_update = 0.0,

    ---
    --- @type PlayerInfo[]
    ---
    targeted_by = nil,

    ---
    --- @type EnemyModules
    ---
    --- The child module frames used by this `EnemyFrame`.
    ---
    modules = nil,
};

-----------------------------------------
--                 Private
-----------------------------------------

---
---
---
--- @param inputs any
--- @return table?
---
local function CopyInputsWithServerTime( inputs )

    if #inputs == 0 then
        return nil;
    end

    local copy = Vantage.DeepCopy( inputs );
    for i = 1, #copy do
        local current_item = copy[ i ];
        if current_item.expirationTime > 0 then
            local server_expiration = Vantage.LocalToServerTime( current_item.expirationTime );
            current_item.expirationTime = server_expiration;
        end
    end
    return copy;
end

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create a new `EnemyFrame`.
---
--- @param player_info PlayerInfo
--- @return EnemyFrame  # A new `EnemyFrame`.
---
function Vantage:NewEnemyFrame( player_info )
    ---@diagnostic disable-next-line: undefined-field
    local new_frame     = self.EnemyFramePool:Acquire();
    local enemy_frame   = Mixin( new_frame, EnemyFrame );
    enemy_frame:Initialize( player_info );
    return enemy_frame;
end

---
--- Release the `EnemyFrame` back to the frame pool. The frame pool will
--- hide and clear all frame points when resetting the frame.
---
--- @param enemy_frame EnemyFrame The `EnemyFrame` to release back to the frame pool.
---
function Vantage:ReleaseEnemyFrame( enemy_frame )
    ---@diagnostic disable-next-line: undefined-field
    self.EnemyFramePool:Release( enemy_frame );
end

-------------------------------------------------------------------------------
--                                   EnemyFrame
-------------------------------------------------------------------------------

---
--- Create the `EnemyFrame`'s modules.
---
function EnemyFrame:NewEnemyModules()
    self.modules =
    {
        buffs           = Vantage:NewEnemyAura( self, false ),
        castbar         = Vantage:NewEnemyCastBar( self ),
        class           = Vantage:NewEnemyClass( self ),
        combatindicator = Vantage:NewCombatIndicator( self ),
        debuffs         = Vantage:NewEnemyAura( self, true ),
        drtracker       = Vantage:NewDRTracker( self ),
        healthbar       = Vantage:NewHealthBar( self ),
        highestpriority = {},
        level           = Vantage:NewEnemyLevel( self ),
        name            = Vantage:NewEnemyName( self ),
        objective       = Vantage:NewEnemyObjective( self ),
        racial          = {},
        resource        = Vantage:NewEnemyResource( self ),
        targetcounter   = Vantage:NewTargetCounter( self ),
        targetindicator = Vantage:NewTargetIndicator( self ),
        trinket         = Vantage:NewTrinket( self )
    };

    self.modules.highestpriority    = Vantage:NewEnemyHighestPriority( self, self.modules.buffs, self.modules.debuffs, self.modules.class );
    self.modules.racial             = Vantage:NewEnemyRacial( self, self.modules.trinket );
end

---
--- Initialize the `EnemyFrame`.
---
--- This will create the children frames if this is the first time the EnemyFrame
--- has been used.
---
--- @param player_info PlayerInfo
---
function EnemyFrame:Initialize( player_info )

    self:RegisterForClicks( 'AnyUp' );
    self.player_info    = player_info;
    self.targeted_by    = {};

    --
    -- If this is the first time the enemy frame has been used, initialize
    -- the child frames of the enemy button.
    --
    if not self.modules then
        self:NewEnemyModules();
    end

    if not self.player_target then
        self.player_target = CreateFrame( 'Frame', nil, self.modules.healthbar, BackdropTemplateMixin and "BackdropTemplate" );
    end
    self.player_target:Hide();

    if not self.player_focus then
        self.player_focus = CreateFrame( 'Frame', nil, self.modules.healthbar, BackdropTemplateMixin and "BackdropTemplate" );
        ---@diagnostic disable-next-line: param-type-mismatch
        self.player_focus:SetBackdrop({
            bgFile      = "Interface/Buttons/WHITE8X8", -- drawlayer "BACKGROUND"
            edgeFile    = 'Interface/Buttons/WHITE8X8', -- drawlayer "BORDER"
            edgeSize    = 1
        });
        ---@diagnostic disable-next-line: param-type-mismatch
        self.player_focus:SetBackdropColor( 0, 0, 0, 0 );
    end
    self.player_focus:Hide();

    self:RegisterForDrag( 'LeftButton' );
	self:SetClampedToScreen( true );

    self:SetScript( 'OnDragStart', self.OnDragStart );
    self:SetScript( 'OnDragStop', self.OnDragStop );

    self:ApplyButtonSettings();

    if not self:IsShown() then
        self:Show();
    end
end

---
--- Set the `EnemyFrame`'s configuration based on the current battleground
--- size.
---
function EnemyFrame:ApplyConfigs()
    self.config     = Vantage.Database.profile.Enemies;
    self.bg_config  = self.config[ tostring( Vantage.BattleGroundSize ) ];
end

---
--- Apply battleground-based configurations and other settings to the `EnemyFrame`.
---
function EnemyFrame:ApplyButtonSettings()
    self:ApplyConfigs();
    self:SetWidth( self.bg_config.BarWidth );
    self:SetHeight( self.bg_config.BarHeight );
    self:ApplyRangeIndicatorSettings();

    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_target:SetBackdrop({
        bgFile      = "Interface/Buttons/WHITE8X8", --drawlayer "BACKGROUND"
        edgeFile    = 'Interface/Buttons/WHITE8X8', --drawlayer "BORDER"
        edgeSize    = Vantage.Database.profile.MyTarget_BorderSize
    });
    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_target:SetBackdropColor( 0, 0, 0, 0 );
    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_target:SetBackdropBorderColor( unpack( Vantage.Database.profile.MyTarget_Color ) );
    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_focus:SetBackdrop({
        bgFile      = "Interface/Buttons/WHITE8X8", --drawlayer "BACKGROUND"
        edgeFile    = 'Interface/Buttons/WHITE8X8', --drawlayer "BORDER"
        edgeSize    = Vantage.Database.profile.MyFocus_BorderSize
    });
    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_focus:SetBackdropColor( 0, 0, 0, 0 );
    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_focus:SetBackdropBorderColor( unpack( Vantage.Database.profile.MyFocus_Color ) );

end

---
--- Apply range indicator settings to the `EnemyFrame`.
---
function EnemyFrame:ApplyRangeIndicatorSettings()
    self:SetAlpha( 1 );
    if self.config.RangeIndicator_Enabled then
        --
        -- If it's testing mode, we'll set make it so enemies start "in range". Otherwise,
        -- we've just joined a BG and no enemies will be in range.
        --
	    self:UpdateRange( Vantage.TestingMode.active );
    end
end

---
---
---
function EnemyFrame:SetBindings()

    if InCombatLockdown() then
        return Vantage.QueueForUpdateAfterCombat( "SetBindings", self, nil );
    end

    --
    -- Use a table to track changes and compare them to GetAttribute
    --
    local new_state =
    {
        unit        = "",
        type1       = "macro", -- type1 = LEFT-Click
        type2       = "macro", -- type2 = Right-Click
        type3       = "macro", -- type3 = Middle-Click
        macrotext1  = "",
        macrotext2  = "",
        macrotext3  = ""
    };

    for i = 1, 3 do
        local binding_type = self.config[ MOUSE_BUTTONS[ i ] .. "Type" ];

        if binding_type == "Target" then
            new_state[ 'macrotext' .. i ] = '/cleartarget\n' .. '/targetexact ' .. self.player_info.name;

        elseif binding_type == "Focus" then
            new_state[ 'macrotext' .. i ] = '/targetexact ' .. self.player_info.name .. '\n' .. '/focus\n' .. '/targetlasttarget';

        else
            --
            -- Custom
            --
            ---@diagnostic disable-next-line: param-type-mismatch
            new_state[ 'macrotext' .. i ] = ( Vantage.Database.profile.Enemies[ MOUSE_BUTTONS[ i ] .. "Value" ] ):gsub( "%%n", self.player_info.name );
        end
    end

    --
    -- Check if there's been any changes before committing them.
    --
    local needs_update = false;
    for attribute, value in pairs( new_state ) do
        if self:GetAttribute( attribute ) ~= value then
            needs_update = true;
            break;
        end
    end
    if needs_update then
        if InCombatLockdown() then
            return Vantage.QueueForUpdateAfterCombat( "SetBindings", self, nil );
        end
        for attribute, value in pairs( new_state ) do
            self:SetAttribute( attribute, value );
        end
    end
end

---
--- Reset the `EnemyFrame`. 
--- 
--- Removes previous registrations and script handlers, and prepares
--- the frame for re-use.
---
function EnemyFrame:Reset()
    self:RegisterForClicks();
    self:RegisterForDrag();
    self:SetClampedToScreen( false );
    self:SetScript( 'OnDragStart', nil );
    self:SetScript( 'OnDragStop', nil );

    for _, frame in pairs( self.modules ) do
        if frame.Reset then
            frame:Reset();
        end
        frame.position_set = false;
    end

    self.player_info:Reset();
end

-----------------------------------------
--            Getters/Setters
-----------------------------------------

---
--- Get the module referred to by the relative point in
--- the config.
---
--- @param relative_name string
--- @return EnemyAura|Frame|VantageContainer|EnemyCastBar|EnemyClass|CombatIndicator|EnemyDRTracker|HealthBar|StatusBar|EnemyLevel|FontString|EnemyName|EnemyObjective|EnemyAura|EnemyResource|EnemyRacial|TargetCounter|TargetIndicator
---
function EnemyFrame:GetAnchor( relative_name )
    if relative_name == "button" then
        return self;
    end
    return self.modules[ relative_name ];
end

---
--- Set the module's configuration from the saved settings.
---
--- @param module_name string The name of the module.
---
function EnemyFrame:SetModuleConfig( module_name )
    local module        = self.modules[ module_name ];
    local module_config = self.bg_config.ButtonModules[ ( module_name:gsub( "^%l", strupper ) ) ];
    Vantage:Merge( module.config, module_config );
    module.enabled = module_config.Enabled;
end

---
--- Set all module configurations from the saved settings.
---
function EnemyFrame:SetAllModuleConfigs()
    for name in pairs( self.modules ) do
        self:SetModuleConfig( name );
    end
end

---
--- Sets the `EnemyFrame`'s child module's position. This will recursively
--- call itself for modules we depend on.
---
--- @param module_frame EnemyAura|Frame|VantageContainer|EnemyCastBar|EnemyClass|CombatIndicator|EnemyDRTracker|HealthBar|StatusBar|EnemyLevel|FontString|EnemyName|EnemyObjective|EnemyAura|EnemyResource|EnemyRacial|TargetCounter|TargetIndicator
--- @param clear_points boolean
---
function EnemyFrame:SetModulePosition( module_frame, clear_points )

    if module_frame.position_set then
        return;
    end

    local config = module_frame.config;
    if config.Points then

        local point_config, relative_frame;

        if clear_points then
            module_frame:ClearAllPoints();
        end

        for j = 1, config.ActivePoints do

            point_config = config.Points[ j ];

            if point_config and point_config.RelativeFrame then

                relative_frame  = self:GetAnchor( strlower( point_config.RelativeFrame ) );

                --
                -- The module we are depending on hasn't been set yet. Load it.
                --
                if relative_frame:GetNumPoints() == 0 then
                    self:SetModulePosition( relative_frame, false );
                end

                module_frame:SetPoint(
                    point_config.Point,
                    ---@diagnostic disable-next-line: param-type-mismatch
                    relative_frame,
                    point_config.RelativePoint,
                    point_config.OffsetX or 0,
                    point_config.OffsetY or 0
                );

            end
        end
    end

    if config.Parent then
        ---@diagnostic disable-next-line: param-type-mismatch
        module_frame:SetParent( self:GetAnchor( strlower( config.Parent ) ) );
    end

    --
    -- Set the width
    --
    if not module_frame.enabled and module_frame.flags and module_frame.flags.SetZeroWidthWhenDisabled then
        module_frame:SetWidth( 0.01 );

    elseif config.UseButtonHeightAsWidth then
        module_frame:SetWidth( self:GetHeight() );

    elseif config.Width and Vantage:ModuleFrameNeedsWidth( module_frame.flags, config ) then
        module_frame:SetWidth( config.Width );

    end

    --
    -- Set the height
    --
    if not module_frame.enabled and module_frame.flags and module_frame.flags.SetZeroHeightWhenDisabled then
        module_frame:SetHeight( 0.001 );

    elseif config.UseButtonHeightAsHeight then
        module_frame:SetHeight( self:GetHeight() );

    elseif config.Height and Vantage:ModuleFrameNeedsHeight( module_frame.flags, config ) then
        module_frame:SetHeight( config.Height );

    end

    ---@diagnostic disable-next-line: inject-field
    module_frame.position_set = true;
end

---
--- Sets the `EnemyFrame`'s module positions.
---
function EnemyFrame:SetModulePositions()

    self:SetAllModuleConfigs();

    for _, frame in pairs( self.modules ) do
        --
        -- Set the positions of each module on the frame
        --
        self:SetModulePosition( frame, true );

        if frame.enabled then
            if not frame:IsShown() then
                frame:Show();
            end
            frame:ApplyAllSettings();

        else
            if frame:IsShown() then
                frame:Hide();
            end
            if frame.Reset then
                frame:Reset();
            end
        end
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_target:SetParent( self.modules.healthbar );
    self.player_target:SetPoint( "TOPLEFT", self.modules.healthbar, "TOPLEFT" );
    self.player_target:SetPoint( "BOTTOMRIGHT", self.modules.resource, "BOTTOMRIGHT" );

    ---@diagnostic disable-next-line: param-type-mismatch
    self.player_focus:SetParent( self.modules.healthbar );
    self.player_focus:SetPoint( "TOPLEFT", self.modules.healthbar, "TOPLEFT" );
    self.player_focus:SetPoint( "BOTTOMRIGHT", self.modules.resource, "BOTTOMRIGHT" );

    self:PlayerDetailsChanged();
end

---
--- Set the `EnemyFrame`'s player information.
---
--- @param player_info PlayerInfo The player information of the player represented by this frame.
---
function EnemyFrame:SetPlayerInfo( player_info )
    self.player_info = player_info;
end

---
--- Set the `EnemyFrame`'s player GUID.
---
--- @param guid string The player GUID of the player represented by this frame.
---
function EnemyFrame:SetPlayerGUID( guid )
    if self.player_info then
        self.player_info.guid = guid;
    end
end

-----------------------------------------
--          Ally Target Management
-----------------------------------------

---
--- Return the index of the ally `name` in the target table.
---
--- @param name string
--- @return integer?
---
function EnemyFrame:GetTargetIndex( name )
    for i = 1, #self.targeted_by do
        if self.targeted_by[ i ].name == name then
            return i;
        end
    end
    return nil;
end

---
--- This `EnemyFrame` is now targeted by the ally `ally`.
---
--- @param ally PlayerInfo
---
function EnemyFrame:IsNowTargetedBy( ally )
    if not self:GetTargetIndex( ally.name ) then
        tinsert( self.targeted_by, ally );
    end
    self:UpdateTargetIndicators();
end

---
--- This `EnemyFrame` is no longer targeted by the ally `ally`.
---
--- @param ally PlayerInfo
---
function EnemyFrame:IsNoLongerTargeted( ally )
    local index = self:GetTargetIndex( ally.name );
    if index then
        tremove( self.targeted_by, index );
    end
    self:UpdateTargetIndicators();
end

-----------------------------------------
--               Updates
-----------------------------------------

---
--- Checks if the current enemy is channeling an interruptable spell.
---
--- @param unit_id UnitId
---
function EnemyFrame:CheckIsChanneling( unit_id )
    local is_channeling, _, _, _, _, _, _, not_interruptible = UnitChannelInfo( unit_id );
    self.is_channeling = is_channeling and not not_interruptible or false;
end

---
---
---
--- @param unit_id any
---
function EnemyFrame:RangeCheck( unit_id )
    if self.config.RangeIndicator_Enabled then
        ---@diagnostic disable-next-line: undefined-field
        local checker = LRC:GetHarmMaxChecker( self.config.RangeIndicator_Range, true );
        if not checker then
            self:UpdateRange( true );
            return;
        end
        self:UpdateRange( checker( unit_id ) )
    end
end

---
---
---
--- @param in_range boolean
---
function EnemyFrame:UpdateRange( in_range )
    if in_range ~= self.inRange then
        local alpha = in_range and 1 or self.config.RangeIndicator_Alpha;
        if self.config.RangeIndicator_Everything then
            self:SetAlpha( alpha );
        else
            for frame_name, enable_range in pairs( self.config.RangeIndicator_Frames ) do
                if enable_range then
                    self[ frame_name ]:SetAlpha( alpha );
                end
            end
        end
        self.inRange = in_range;
    end
end

-----------------------------------------
--            Vantage Events
-----------------------------------------

---
--- The enemy's name needs to be it's full name. That way the ally who recieves this message
--- won't have to track down the server name of this player, we can simply "Ambiguate" once
--- it's recieved.
---
--- @return string
---
function EnemyFrame:Ambiguate()
    local enemy_name    = self.player_info.name;
    local realm         = smatch( enemy_name, "-(.+)" );
    if not realm then
        enemy_name = enemy_name .. "-" .. GetRealmName();
    end
    return enemy_name;
end

---
---
---
--- @param timestamp number
---
function EnemyFrame:BroadcastState( timestamp )
    local now = GetTime();
    if now - self.last_broadcast >= 3 then
        --[[
        local buffs     = CopyInputsWithServerTime( self.modules.buffs.inputs );
        local debuffs   = CopyInputsWithServerTime( self.modules.debuffs.inputs );
        local highest   = self.modules.highestpriority.displayed_aura;
        if highest then

            if highest.expirationTime > 0 then
                local server_expiration = Vantage.LocalToServerTime( highest.expirationTime );
                highest.expirationTime  = server_expiration;
            end

            if highest.isHarmful then
                debuffs = debuffs or {};
                tinsert( debuffs, highest );
            else
                buffs = buffs or {};
                tinsert( buffs, highest );
            end
        end
        
        Vantage.Broadcast(
            Constants.MESSAGE_KINDS.MESSAGE_KIND_STATE,
            timestamp,
            self:Ambiguate(),
            self.modules.healthbar:GetValue(),
            select( 2, self.modules.healthbar:GetMinMaxValues() ),
            self.modules.resource:GetValue(),
            select( 2, self.modules.resource:GetMinMaxValues() ),
            self.modules.resource.power_token
            --buffs,
            --debuffs
        );
        ]]--
        self.last_broadcast = now;
    end
end

---
---
---
function EnemyFrame:ShouldBroadcast()

    --
    -- Addon comms in 40 mans is probably too much...
    --
    if Vantage.BattleGroundSize > 15 then
        return false;
    end

    local resource_factor;
    if self.modules.resource.power_token == "RUNIC_POWER" or self.modules.resource.power_token == "RAGE" then
        resource_factor = .1;
    else
        resource_factor = .9;
    end

    --
    -- There's nothing to really broadcast
    --
    if ( self.modules.healthbar:GetValue() / select( 2, self.modules.healthbar:GetMinMaxValues() ) == 1 ) and
       ( self.modules.resource:GetValue() / select( 2, self.modules.resource:GetMinMaxValues() ) >= resource_factor ) then
        return false;
    end

    return true;
end

---
--- Update the `EnemyFrame` with the new player's information.
---
function EnemyFrame:PlayerDetailsChanged()
    self:SetBindings();
    self.modules.class:PlayerDetailsChanged( self.player_info );
    self.modules.healthbar:PlayerDetailsChanged( self.player_info );
    self.modules.name:PlayerDetailsChanged( self.player_info );
    self.modules.racial:PlayerDetailsChanged( self.player_info );
    self.modules.resource:PlayerDetailsChanged( self.player_info );

    -- TODO: this should probably reset everything else
end

---
---
---
--- @param deaths number?
---
function EnemyFrame:PlayerDied( deaths )
    if self.player_info.alive then

        self.player_info.alive  = false;
        self.player_info.deaths = deaths or ( self.player_info.deaths + 1 );

        self:UpdateRange( false );
        self.modules.buffs:Reset();
        self.modules.combatindicator:Reset();
        self.modules.debuffs:Reset();
        self.modules.healthbar:UnitDied();
        self.modules.highestpriority:Reset();
        self.modules.objective:HideObjective();
        self.modules.resource:Reset();

    elseif deaths then
        --
        -- This player most likely was dead when we joined or reloaded so we had an incorrect number of 
        -- deaths. Just set it to the accurate number.
        --
        self.player_info.deaths = deaths;
    end
end

---
---
---
function EnemyFrame:PlayerRezzed()
    if not self.player_info.alive then
        self.player_info.alive = true;
        self.modules.healthbar:UnitAlive();
    end
end

---
---
---
function EnemyFrame:ToggleObjective()
    if self:IsShown() then
        local objective = self.modules.objective;
        if objective.has_objective then objective:Reset();
        else                            objective:ShowObjective();
        end
    end
end

---
--- 
---
--- @param temp_unit_id UnitId
--- 
function EnemyFrame:UpdateAll( temp_unit_id )
    --
    -- This frame can potentially be updated by multiple sources, so 
    -- we make sure that isn't the case.
    --
    local now = GetServerTime();
    if self:IsShown() and self.last_on_update ~= now then
        if UnitExists( temp_unit_id ) then
            --
            -- Heavy / time-sensitive updates should come first
            -- 
            self:UpdateAuras( temp_unit_id );
            self.modules.resource:UpdatePowerByUnitId( temp_unit_id );
            self:UNIT_HEALTH( temp_unit_id );

            --
            -- Updates that are less important
            --
            self:CheckIsChanneling( temp_unit_id );
            self.modules.level:UpdateLevel( temp_unit_id );

            --
            -- In case of same faction BG
            --
            if self.player_info.race == "" then
                self.player_info.race = UnitRace( temp_unit_id );
                self.modules.racial:PlayerDetailsChanged( self.player_info );
            end
        end
        self:RangeCheck( temp_unit_id );
        self.last_on_update = now;
    end
end

---
---
---
--- @param temp_unit_id UnitId
---
function EnemyFrame:UpdateAuras( temp_unit_id )
    --
    -- This event is called in OnUpdate 20 frames per second, so we should
    -- probably add some level of throttling. 
    --
    -- Let's go with 10 frames per second.
    --
    local now = GetTime();
    if now - self.last_aura_update < 0.1 then
        return;
    end

    --
    -- We only want to query auras if they're going to be used. Check if the modules
    -- that depend on aura scanning are enabled. If so, loop through auras available 
    -- on the unit. We only worry about inserting / updating auras that are within the
    -- defined threshold. Auras will remove themselves once their duration has ended or
    -- the CLEU has given us the SPELL_AURA_REMOVED event.
    --
    -- Note: In Lua, it's faster to declare a new variable in each loop iteration.
    --
    local priority          = BigDebuffs and Vantage.Database.profile.BigDebuffsPriorityThreshold or 1;
    local buffs             = self.modules.buffs;
    local debuffs           = self.modules.debuffs;
    local highestpriority   = self.modules.highestpriority;

    if ( buffs.enabled or highestpriority.enabled ) then
        for i = 1, 40 do
            local name, icon, count, debuffType, duration,
                  expirationTime, _, canStealOrPurge, _, spellId = UnitAura( temp_unit_id, i, "HELPFUL" );

            if not name then
                break;
            end

            local current_aura_priority = Vantage.GetSpellPriority( spellId ) or 0;
            if current_aura_priority >= priority then

                local current_aura_frame = buffs:FindChildFrameByAuraAttribute( "spellId", spellId );

                --
                -- Update the existing aura frame with new duration
                --
                if current_aura_frame then
                    current_aura_frame.input.timestamp = now;
                    if current_aura_frame.input.expirationTime ~= expirationTime then
                        current_aura_frame.cooldown:Clear();
                        current_aura_frame.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                --
                -- Check the highest_priority module, and update it if the expiration time differs
                -- from the current.
                -- 
                elseif highestpriority.enabled and highestpriority.displayed_aura and highestpriority.displayed_aura.spellId == spellId then
                    highestpriority.displayed_aura.timestamp = now;
                    if highestpriority.displayed_aura.expirationTime ~= expirationTime then
                        highestpriority.cooldown:Clear();
                        highestpriority.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                else
                    local new_aura = {
                        applications    = count,
                        dispelName      = debuffType,
                        duration        = duration,
                        expirationTime  = expirationTime,
                        icon            = icon,
                        isHarmful       = false,
                        isStealable     = canStealOrPurge,
                        name            = name,
                        spellId         = spellId,
                        priority        = current_aura_priority,
                        timestamp       = now
                    };
                    buffs:NewInput( new_aura );
                end
            end
        end

        --
        -- Remove all stale auras that weren't included in this latest update
        --
        buffs:RemoveAuraInputsByTimestamp( self.last_aura_update );
    end

    if ( debuffs.enabled or highestpriority.enabled ) then
        for i = 1, 40 do
            local name, icon, count, debuffType, duration,
                  expirationTime, _, canStealOrPurge, _, spellId = UnitAura( temp_unit_id, i, "HARMFUL" );

            if not name then
                break;
            end

            local current_aura_priority = Vantage.GetSpellPriority( spellId ) or 0;
            if current_aura_priority >= priority then

                local current_aura = debuffs:FindChildFrameByAuraAttribute( "spellId", spellId );

                --
                -- Update the existing aura frame with new duration
                --
                if current_aura then
                    current_aura.input.timestamp = now;
                    if current_aura.input.expirationTime ~= expirationTime then
                        current_aura.cooldown:Clear();
                        current_aura.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                --
                -- Check the highest_priority module, and update it if the expiration time differs
                -- from the current.
                -- 
                elseif highestpriority.enabled and highestpriority.displayed_aura and highestpriority.displayed_aura.spellId == spellId then
                    highestpriority.displayed_aura.timestamp = now;
                    if highestpriority.displayed_aura.expirationTime ~= expirationTime then
                        highestpriority.cooldown:Clear();
                        highestpriority.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                else
                    local new_aura = {
                        applications    = count,
                        auraInstanceID  = nil,
                        dispelName      = debuffType,
                        duration        = duration,
                        expirationTime  = expirationTime,
                        icon            = icon,
                        isHarmful       = true,
                        isStealable     = canStealOrPurge,
                        name            = name,
                        spellId         = spellId,
                        priority        = current_aura_priority,
                        timestamp       = now
                    };
                    debuffs:NewInput( new_aura );
                end
            end
        end

        --
        -- Remove all stale auras that weren't included in this latest update
        --
        debuffs:RemoveAuraInputsByTimestamp( self.last_aura_update );
    end

    if highestpriority.enabled then
        highestpriority:Update( now );
    end

    if buffs.enabled then
        buffs:Display();
    end

    if debuffs.enabled then
        debuffs:Display();
    end

    self.last_aura_update = now;
end

---
--- Dispatches the `UpdateTargetIndicators` event to the targeting modules
--- used by the `EnemyFrame`.
---
function EnemyFrame:UpdateTargetIndicators()
    self.modules.targetcounter:UpdateTargetIndicators();
    self.modules.targetindicator:UpdateTargetIndicators();
end

-----------------------------------------
--          Vantage Callbacks
-----------------------------------------

---
---
---
function EnemyFrame:OnDragStart()
    if not Vantage.Database.profile.Locked then
        if Vantage:IsMovable() then
            Vantage:StartMoving();
        end
    end
end

---
---
---
function EnemyFrame:OnDragStop()

    Vantage:StopMovingOrSizing();

    if not InCombatLockdown() then
        local scale = self:GetEffectiveScale();
        self.bg_config.Position_X = Vantage:GetLeft() * scale;
        self.bg_config.Position_Y = Vantage:GetTop() * scale;
    end
end

-------------------------------------------------------------------------------
--                             Blizzard Event Callbacks
-------------------------------------------------------------------------------

---
--- Resets the expiration timer of a buff/debuff on the unit.
---
--- @param src_name     string
--- @param dest_name    string
--- @param spell_id     number
--- @param spell_name   string
--- @param aura_type    string
---
function EnemyFrame:SPELL_AURA_REFRESH( src_name, dest_name, spell_id, spell_name, aura_type )
    self.modules.drtracker:AuraRemoved( spell_id );
end

---
--- Triggered when Buffs/Debuffs expire. The souce is the caster of the aura which faded,
--- and the destination is the target from which the aura faded (needs verifying). 
---
--- Notifies all potential containers of the removed aura.
---
--- @param src_name     string
--- @param dest_name    string
--- @param spell_id     number
--- @param spell_name   string
--- @param aura_type    string
---
function EnemyFrame:SPELL_AURA_REMOVED( src_name, dest_name, spell_id, spell_name, aura_type )
    local container = aura_type == "BUFF" and self.modules.buffs or self.modules.debuffs;
    container:AuraRemoved( spell_id );
    self.modules.highestpriority:AuraRemoved( spell_id );
    self.modules.drtracker:AuraRemoved( spell_id );

    --[[
    if not Vantage.TestingMode.active then
        Vantage.Broadcast(
            Constants.MESSAGE_KINDS.MESSAGE_KIND_AURA_REMOVED,
            GetServerTime(),
            self:Ambiguate(),
            spell_id,
            container.is_harmful
        );
    end
    ]]--
end

---
--- Triggered when an instant spell is cast or when a spellcast finishes and 
--- doesn't fail. This isn't triggered when the spell misses. On a miss SPELL_MISS 
--- will be triggered instead. 
---
--- @param src_name     string  The player that casted the spell.
--- @param dest_name    string? The target of the spell.
--- @param spell_id     number  The ID of the spell.
---
function EnemyFrame:SPELL_CAST_SUCCESS( src_name, dest_name, spell_id )

    local time = GetTime();

    if self.modules.racial:SPELL_CAST_SUCCESS( spell_id, time ) or
       self.modules.trinket:SPELL_CAST_SUCCESS( spell_id, time ) then
        return;
    end

    local is_src_ally = UnitExists( src_name );

    --
    -- If the enemy is the source, and they successfully completed a cast:
    --
    -- A) at their ally who is also in combat
    -- B) at an ally to the addon's user
    -- 
    -- Update their combat cooldown.
    --
    if not is_src_ally and dest_name then
        local is_dest_ally = UnitExists( dest_name );
        if not is_dest_ally then
            if Vantage.EnemyFrames[ dest_name ] and Vantage.EnemyFrames[ src_name ] and
               Vantage.EnemyFrames[ dest_name ].modules.combatindicator.combat then
                Vantage.EnemyFrames[ src_name ].modules.combatindicator:UpdateCombatCooldown( time );
            end
        elseif Vantage.EnemyFrames[ src_name ] then
            Vantage.EnemyFrames[ src_name ].modules.combatindicator:UpdateCombatCooldown( time );
        end
    end

    --
    -- We can check if the enemy got interrupted if the source was an ally. Since
    -- ally names are valid UnitIds, we simply check if that is the case.
    --
    -- If an ally casted a spell at an enemy, update their combat cooldown.
    --
    if is_src_ally then

        if dest_name and not UnitExists( dest_name ) and Vantage.EnemyFrames[ dest_name ] then
            Vantage.EnemyFrames[ dest_name ].modules.combatindicator:UpdateCombatCooldown( time );
        end

        local interrupt_duration = Constants.Interruptdurations[ spell_id ];
        if interrupt_duration and self.is_channeling then
            self.is_channeling = false;
            if self.modules.highestpriority.enabled then
                self.modules.highestpriority:UpdateActiveInterrupt( spell_id, interrupt_duration );
            end
        end

    end
end

---
---
---
--- @param src_name     string
--- @param dest_name    string
--- @param spell_id     number
---
function EnemyFrame:SPELL_INTERRUPT( src_name, dest_name, spell_id )
    local interrupt_duration = Constants.Interruptdurations[ spell_id ];
    if interrupt_duration then
        self.modules.highestpriority:UpdateActiveInterrupt( spell_id, interrupt_duration );
    end
end

---
--- Gets health of nameplates, player, target, focus, raid1 to raid40, partymember.
---
--- @param unit_id UnitId The `UnitId` of the enemy player relative to the current addon user.
---
function EnemyFrame:UNIT_HEALTH( unit_id )

    if UnitIsDead( unit_id ) then
        self:PlayerDied();
        return;
    end

    local health      = UnitHealth( unit_id );
    local max_health  = UnitHealthMax( unit_id );

    if health == 0 then
        self:PlayerDied();
        return;
    end

    self.modules.healthbar:UpdateHealth( unit_id, health, max_health );

end

---
--- Gets power of nameplates, player, target, focus, raid1 to raid40, partymember
---
---@param unit_id       UnitId
---@param power_token   string?
---
function EnemyFrame:UNIT_POWER_FREQUENT( unit_id, power_token )
    self.modules.resource:UpdatePowerByUnitId( unit_id );
end

--
-- TBC compability, IsTBCC
--
EnemyFrame.UNIT_HEALTH_FREQUENT              = EnemyFrame.UNIT_HEALTH
EnemyFrame.UNIT_MAXHEALTH                    = EnemyFrame.UNIT_HEALTH
EnemyFrame.UNIT_HEAL_PREDICTION              = EnemyFrame.UNIT_HEALTH
EnemyFrame.UNIT_ABSORB_AMOUNT_CHANGED        = EnemyFrame.UNIT_HEALTH
EnemyFrame.UNIT_HEAL_ABSORB_AMOUNT_CHANGED   = EnemyFrame.UNIT_HEALTH

-------------------------------------------------------------------------------
--                          Fake Blizzard Event Callbacks
-------------------------------------------------------------------------------

---
--- Fake UNIT_AURA for testing mode.
---
function EnemyFrame:FAKE_UNIT_AURA()

    local priority              = BigDebuffs and Vantage.Database.profile.BigDebuffsPriorityThreshold or 1;
    local fake_auras            = Vantage.TestingMode.fake_auras[ self.player_info.name ];
    local buffs                 = self.modules.buffs;
    local debuffs               = self.modules.debuffs;
    local highestpriority       = self.modules.highestpriority;

    for i = 1, 40 do
        local harmful_aura = fake_auras[ "HARMFUL" ][ i ];
        local helpful_aura = fake_auras[ "HELPFUL" ][ i ];

        if ( debuffs.enabled or highestpriority.enabled ) and harmful_aura then

            --
            -- Simulating how this will work in a live BG
            --
            local name, icon, count, debuffType, duration, expirationTime, canStealOrPurge, spellId = harmful_aura.name, harmful_aura.icon, harmful_aura.count, harmful_aura.debuffType, harmful_aura.duration, harmful_aura.expirationTime, harmful_aura.isStealable, harmful_aura.spellId;

            local current_aura_priority = Vantage.GetSpellPriority( spellId ) or 0;
            if current_aura_priority >= priority then

                local current_aura = debuffs:FindChildFrameByAuraAttribute( "spellId", spellId );

                --
                -- Update the existing aura frame with new duration
                --
                if current_aura then
                    if current_aura.input.expirationTime ~= expirationTime then
                        current_aura.cooldown:Clear();
                        current_aura.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                --
                -- Check the highest_priority module, and update it 
                -- 
                elseif highestpriority.enabled and highestpriority.displayed_aura and highestpriority.displayed_aura.spellId == spellId then
                    if highestpriority.displayed_aura.expirationTime ~= expirationTime then
                        highestpriority.cooldown:Clear();
                        highestpriority.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                else
                    local new_aura =
                    {
                        applications    = count,
                        auraInstanceID  = nil,
                        dispelName      = debuffType,
                        duration        = duration,
                        expirationTime  = expirationTime,
                        icon            = icon,
                        isHarmful       = true,
                        isStealable     = canStealOrPurge,
                        name            = name,
                        spellId         = spellId,
                        priority        = current_aura_priority;
                    };
                    debuffs:NewInput( new_aura );
                end
            end
        end

        if ( buffs.enabled or highestpriority.enabled ) and helpful_aura then
            local name, icon, count, debuffType, duration, expirationTime, canStealOrPurge, spellId = helpful_aura.name, helpful_aura.icon, helpful_aura.count, helpful_aura.debuffType, helpful_aura.duration, helpful_aura.expirationTime, helpful_aura.isStealable, helpful_aura.spellId;
            local current_aura_priority = Vantage.GetSpellPriority( spellId ) or 0;
            if current_aura_priority >= priority then

                local current_aura = buffs:FindChildFrameByAuraAttribute( "spellId", spellId );

                --
                -- Update the existing aura frame with new duration
                --
                if current_aura then
                    if current_aura.input.expirationTime ~= expirationTime then
                        current_aura.cooldown:Clear();
                        current_aura.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                --
                -- Check the highest_priority module, and update it 
                -- 
                elseif highestpriority.enabled and highestpriority.displayed_aura and highestpriority.displayed_aura.spellId == spellId then
                    if highestpriority.displayed_aura.expirationTime ~= expirationTime then
                        highestpriority.cooldown:Clear();
                        highestpriority.cooldown:SetCooldown( expirationTime - duration, duration );
                    end
                else
                    local new_aura =
                    {
                        applications    = count,
                        auraInstanceID  = nil,
                        dispelName      = debuffType,
                        duration        = duration,
                        expirationTime  = expirationTime,
                        icon            = icon,
                        isHarmful       = false,
                        isStealable     = canStealOrPurge,
                        name            = name,
                        spellId         = spellId,
                        priority        = current_aura_priority;
                    };
                    buffs:NewInput( new_aura );
                end
            end
        end
    end

    if highestpriority.enabled then
        highestpriority:Update();
    end

    if buffs.enabled then
        buffs:Display();
    end

    if debuffs.enabled then
        debuffs:Display();
    end
end

---
--- Fake UNIT_HEALTH for testing mode.
---
function EnemyFrame:FAKE_UNIT_HEALTH()
    local health       = Vantage:FakeUnitHealth( self );
    local max_health   = Vantage:FakeUnitHealthMax( self );
    self.modules.healthbar:UpdateHealth( nil, health, max_health );
end

---
--- Fake UNIT_POWER_FREQUENT for testing mode.
---
function EnemyFrame:FAKE_UNIT_POWER_FREQUENT()
    self.modules.resource:SetValue( mrand( 0, 100 ) / 100 );
end

-------------------------------------------------------------------------------
---@script: broadcast.lua
---@author: zimawhit3
---@desc:   This module implements message broadcasting over the addon channel.
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
local LibSerialize  = LibStub( "LibSerialize" )
local LibDeflate    = LibStub( "LibDeflate" )
local BigDebuffs    = LibStub( "BigDebuffs", true )

-----------------------------------------
--                Lua
-----------------------------------------
local fmt       = string.format
local tremove   = table.remove
local unpack    = unpack

-----------------------------------------
--              Blizzard
-----------------------------------------
local Ambiguate = Ambiguate
local GetTime   = GetTime
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid  = IsInRaid

-----------------------------------------
--                Ace3
-----------------------------------------

local AceComm = LibStub( "AceComm-3.0" )

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                             Message Broadcasting
-------------------------------------------------------------------------------

----------------------------------------
--              Constants
----------------------------------------

---
---
---
local VANTAGE_GITHUB_URI = "https://www.github.com/zimawhit3/VantageEnemyFrames";

---
---
---
local VANTAGE_CHANNEL_PREFIX = "VantageEnemies";

---
---
---
local VANTAGE_VERSION_PREFIX = "VantageVersion";

----------------------------------------
--                Locals
----------------------------------------

---
---
---
local next_warning_time = nil;

---
---
---
local outdated_sender = nil;

---
--- @type number
---
local version_major = nil;

---
--- @type number
---
local version_minor = nil;

----------------------------------------
--                Types
----------------------------------------

---
--- @enum MessageKinds
---
Constants.MESSAGE_KINDS =
{
    MESSAGE_KIND_STATE          = 1,
    MESSAGE_KIND_COOLDOWN       = 2,
    MESSAGE_KIND_AURA_STATE     = 3,
    MESSAGE_KIND_AURA_REMOVED   = 4,
};

----------------------------------------
--               Private
----------------------------------------

---
--- Decode, decompress, and deserialize the message recieved over the addon
--- channel.
---
--- @param payload any
--- @return table?
---
local function Deserialize( payload )

    ---@diagnostic disable-next-line: undefined-field
    local decoded = LibDeflate:DecodeForWoWAddonChannel( payload );
    if not decoded then
        return nil;
    end

    ---@diagnostic disable-next-line: undefined-field
    local decompressed = LibDeflate:DecompressDeflate( decoded );
    if not decompressed then
        return nil;
    end

    ---@diagnostic disable-next-line: undefined-field
    return { LibSerialize:Deserialize( decompressed ) };
end

---
---
---
--- @param ... any
--- @return string
---
local function Serialize( ... )
    ---@diagnostic disable-next-line: undefined-field
    local serialized_msg    = LibSerialize:Serialize( ... );
    ---@diagnostic disable-next-line: undefined-field
    local compressed_msg    = LibDeflate:CompressDeflate( serialized_msg );
    ---@diagnostic disable-next-line: undefined-field
    local encoded_msg       = LibDeflate:EncodeForWoWAddonChannel( compressed_msg );
    return encoded_msg;
end

---
---
---
--- @param version_string string
--- @return number
--- @return number
---
local function GetAddonVersion( version_string )
    local major_version, minor_version = version_string:match( "(%d+)%.(%d+)" );
    return ( tonumber( major_version ) or -1 ), ( tonumber( minor_version ) or -1 );
end

---
---
---
--- @return string
---
local function GetDefaultCommChannel()
    if IsInRaid() then      return IsInRaid( LE_PARTY_CATEGORY_INSTANCE ) and "INSTANCE_CHAT" or "RAID";
    elseif IsInGroup() then return IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) and "INSTANCE_CHAT" or "PARTY";
    elseif IsInGuild() then return "GUILD";
    else                    return "YELL";
    end
end

---
---
---
--- @param inputs           (AuraData|VantageAura)[]
--- @param container        EnemyAura|Frame|VantageContainer
--- @param highestpriority  EnemyHighestPriority|Frame
---
local function OnChannelUpdateAuraContainer( inputs, container, highestpriority )

    local priority = BigDebuffs and Vantage.Database.profile.BigDebuffsPriorityThreshold or 1;

    Vantage:Debug( Vantage.Dump( inputs ) );

    for i = 1, #inputs do

        local current_input = inputs[ i ];

        if current_input.expirationTime then

            local local_expiration          = Vantage.ServerTimeToLocalTime( current_input.expirationTime );
            current_input.expirationTime    = local_expiration

            if current_input.priority >= priority then

                local current_aura = container:FindChildFrameByAuraAttribute( "spellId", current_input.spellId );

                --
                -- Update the existing aura frame with new duration
                --
                if current_aura then
                    if current_aura.input.expirationTime ~= current_input.expirationTime then
                        current_aura.cooldown:Clear();
                        current_aura.cooldown:SetCooldown( current_input.expirationTime - current_input.duration, current_input.duration );
                    end
                --
                -- Check the highest_priority module, and update it if the expiration time differs
                -- from the curreent.
                -- 
                elseif highestpriority.enabled and highestpriority.displayed_aura and highestpriority.displayed_aura.spellId == current_input.spellId then
                    if highestpriority.displayed_aura.expirationTime ~= current_input.expirationTime then
                        highestpriority.cooldown:Clear();
                        highestpriority.cooldown:SetCooldown( current_input.expirationTime - current_input.duration, current_input.duration );
                    end
                else
                    Vantage:Debug( "[OnChannelUpdateAuraContainer] New aura input: " .. Vantage.Dump( current_input.name ) );
                    container:NewInput( current_input );
                end
            end
        end
    end
end

---
---
---
--- @param prefix   string  
--- @param payload  string  The message body
--- @param channel  string  The addon channel's chat type, e.g. "PARTY"
--- @param sender   string  Player who initiated the message
---
local function OnChannelUpdate( prefix, payload, channel, sender )

    if prefix ~= VANTAGE_CHANNEL_PREFIX or sender == Vantage.PlayerInfo.name then
        return;
    end

    local msg = Vantage.GetBroadcastMessage( payload );
    if not msg then
        return;
    end

    local message_kind  = tremove( msg, 1 );
    local timestamp     = tremove( msg, 1 );
    local player_name   = Ambiguate( tremove( msg, 1 ), "none" );
    local enemy_player  = Vantage:GetEnemyFrameByName( player_name );

    if enemy_player then

        --
        -- We only update if the last onupdate for this enemy is older than the timestamp of the
        -- broadcasted message for state updates.
        --
        if message_kind == Constants.MESSAGE_KINDS.MESSAGE_KIND_STATE and enemy_player.last_on_update < timestamp then
            Vantage:Debug( fmt( "[Vantage:OnChannelUpdate] State update from %s for enemy: %s", sender, player_name ) );
            local health, max_health, power, max_power, power_type, buffs, debuffs = unpack( msg );
            enemy_player.modules.healthbar:UpdateHealth( nil, health, max_health );
            enemy_player.modules.resource:UpdatePower( power_type, power, max_power );

            --[[
            enemy_player.modules.buffs:ResetInputs();
            enemy_player.modules.debuffs:ResetInputs();

            if buffs then
                OnChannelUpdateAuraContainer( buffs, enemy_player.modules.buffs, enemy_player.modules.highestpriority );
            end

            if debuffs then
                OnChannelUpdateAuraContainer( debuffs, enemy_player.modules.debuffs, enemy_player.modules.highestpriority );
            end

            if enemy_player.modules.highestpriority.enabled then
                enemy_player.modules.highestpriority:Update();
            end

            if enemy_player.modules.buffs.enabled and buffs then
                enemy_player.modules.buffs:Display();
            end

            if enemy_player.modules.debuffs.enabled and debuffs then
                enemy_player.modules.debuffs:Display();
            end
            ]]--
            enemy_player.last_on_update = timestamp;

        elseif message_kind == Constants.MESSAGE_KINDS.MESSAGE_KIND_COOLDOWN then
            local spell_id  = unpack( msg );
            local cast_time = Vantage.ServerTimeToLocalTime( timestamp );
            Vantage:Debug( fmt( "[Vantage:OnChannelUpdate] Cooldown update from %s for Enemy: %s | Spell: %s", sender, player_name, GetSpellInfo( spell_id ) ) );
            return enemy_player.modules.racial:SPELL_CAST_SUCCESS( spell_id, cast_time ) or
                   enemy_player.modules.trinket:SPELL_CAST_SUCCESS( spell_id, cast_time );

        elseif message_kind == Constants.MESSAGE_KINDS.MESSAGE_KIND_AURA_REMOVED then
            local aura_spell_id, aura_is_harmful = unpack( msg );
            local container = aura_is_harmful and enemy_player.modules.debuffs or enemy_player.modules.buffs;
            container:AuraRemoved( aura_spell_id );
            enemy_player.modules.highestpriority:AuraRemoved( aura_spell_id );
            enemy_player.modules.drtracker:AuraRemoved( aura_spell_id );

        end
    end
end

---
---
---
--- @param prefix   string  
--- @param payload  string  The message body
--- @param sender   string  Player who initiated the message
---
local function OnVersionCheck( prefix, payload, channel, sender )

    if prefix ~= VANTAGE_VERSION_PREFIX then
        return;
    end

    if not payload or type( payload ) ~= "string" then
        return;
    end

    local current_time = GetTime();
    if next_warning_time and next_warning_time > current_time then
        return;
    end

    local major, minor = GetAddonVersion( payload );
    if major < version_major or ( major == version_major and minor <= version_minor ) then
        return;
    end

    if not outdated_sender or outdated_sender == sender then
        outdated_sender = sender;
        return;
    end

    next_warning_time   = current_time + 1800;
    outdated_sender     = nil;

    Vantage:Notify( fmt( L.UPDATE_AVAILABLE, payload, VANTAGE_GITHUB_URI ) );
end


----------------------------------------
--               Public
----------------------------------------

---
---
---
--- @param ... any
---
function Vantage.Broadcast( ... )
    AceComm:SendCommMessage( VANTAGE_CHANNEL_PREFIX, Serialize( ... ), GetDefaultCommChannel() );
end

---
--- Check other user's addon versions for potential updates.
---
function Vantage:BroadcastVersionCheck()
    if self.version then
        AceComm:SendCommMessage( VANTAGE_VERSION_PREFIX, self.version, GetDefaultCommChannel() );
    end
end

---
---
---
--- @param payload any
--- @return table?
---
function Vantage.GetBroadcastMessage( payload )
    local result = Deserialize( payload );
    if not result or not result[ 1 ] then
        return nil;
    end
    tremove( result, 1 );
    return result;
end

---
--- Initializes the addon's communication channels for message passing.
---
function Vantage:InitializeBroadcast()

    version_major, version_minor = GetAddonVersion( self.version );

    ---@diagnostic disable-next-line: undefined-field
    AceComm:RegisterComm( VANTAGE_VERSION_PREFIX, OnVersionCheck );
    ---@diagnostic disable-next-line: undefined-field
    --AceComm:RegisterComm( VANTAGE_CHANNEL_PREFIX, OnChannelUpdate );
end

----------------------------------------
--               Callbacks
----------------------------------------
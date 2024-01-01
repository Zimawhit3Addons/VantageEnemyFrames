-------------------------------------------------------------------------------
---@script: config.lua
---@author: zimawhit3
---@desc:   This module implements shared configurations for modules.
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
local CreateFromMixins  = CreateFromMixins

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                            Vantage Module Configurations
-------------------------------------------------------------------------------

---
--- @class ModuleConfiguration
---
local ModuleConfiguration =
{
    ---
    ---
    ---
    name = "",

    ---
    ---
    ---
    localized_name = "",

    ---
    ---
    ---
    order = 0,

    ---
    ---
    ---
    flags = nil,

    ---
    ---
    ---
    default_settings = nil,

    ---
    --- @type function?
    ---
    ---
    ---
    options = nil,
};

----------------------------------------
--               Private
----------------------------------------

---
---
---
--- @param src  table
--- @param dest table?
--- @return table?
---
local function copySettingsWithoutOverwrite( src, dest )

    assert( src );

    if type( dest ) ~= "table" then
        dest = {};
    end

    for key, val in pairs( src ) do

        if type( val ) == "table" then
            dest[ key ] = copySettingsWithoutOverwrite( val, dest[ key ] );

        --
        -- Only overwrite if the type in dest is different
        --
        elseif type( val ) ~= type( dest[ key ] ) then
            dest[ key ] = val;

        end
    end

    return dest;
end

----------------------------------------
--               Public
----------------------------------------

---
---
---
--- @param name     string
--- @param defaults table
--- @param options  function?
--- @param flags    table?
--- @return ModuleConfiguration
--- 
function Vantage.NewModuleConfig( name, defaults, options, flags )
    local new_config = CreateFromMixins( ModuleConfiguration );
    new_config:Initialize( name, defaults, options, flags );
    return new_config;
end

---
---
---
--- @param name     string
--- @param defaults table
--- @param options  function?
--- @param flags    table?
---
function ModuleConfiguration:Initialize( name, defaults, options, flags )
    self.name               = name;
    self.localized_name     = L[name];
    self.default_settings   = defaults;
    self.flags              = flags or {};
    self.options            = options;

    local enemy_config = Vantage.Database.profile.Enemies;
    for _, size in pairs( { "10", "15", "40" } ) do
        enemy_config[ size ].ButtonModules[ name ] = enemy_config[ size ].ButtonModules[ name ] or {};
        copySettingsWithoutOverwrite( self.default_settings, enemy_config[ size ].ButtonModules[ name ] );
    end

end

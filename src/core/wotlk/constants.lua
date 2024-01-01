-------------------------------------------------------------------------------
---@script: constants.lua
---@author: zimawhit3
---@desc:   This module holds the WOTLK constants used by the addon.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...

-----------------------------------------
--            Game Constants
-----------------------------------------

--
-- Interruption Duration list
--
Constants.Interruptdurations =
{
    [6552]	    = 4, -- [Warrior] Pummel
    [34490]     = 3, -- [Hunter] Silencing Shot
    [1766]	    = 5, -- [Rogue] Kick
    [47528]	    = 4, -- [DK] Mind Freeze
    [57994]	    = 2, -- [Shaman] Wind Shear
    [19244]	    = 5, -- [Warlock] Spell Lock (Rank 1)
    [19647]	    = 6, -- [Warlock] Spell Lock (Rank 2)
    [2139]	    = 6, -- [Mage] Counterspell
};

---
---
---
Constants.PriorityAuras =
{
    HELPFUL =
    {
        --
        -- Death Knight
        --
        [48707] = 5.2,  -- Anti-Magic Shell
        [50461] = 5.2,  -- Anti-Magic Zone
        [48792] = 5,    -- Icebound Fortitude
        [49028] = 5,    -- Dancing Rune Weapon
        [55233] = 5,    -- Vampiric Blood
        [51271] = 4.9,  -- Pillar of Frost / Unbreakable Armor
        [63560] = 4.9,  -- Dark Transformation / Ghoul Frenzy

        --
        -- Druid
        --
        -- TODO: Starfall is hella confusing
        --
        [17116] = 5.2, -- Nature's Swiftness
        [22812] = 5.1, -- Barkskin
        [22842] = 5.1, -- Frenzied Regeneration
        [61336] = 5.1, -- Survival Instincts
        [50334] = 5.1, -- Berserk
        [5217]  = 4.9, -- Tiger's Fury
        [29166] = 4.9, -- Innervate
        [33891] = 4.9, -- Incarnation: Tree of Life

        --
        -- Hunter
        --
        [19574] = 5.2,  -- Bestial Wrath
        [136] 	= 5.1,  -- Mend Pet
        [5384]	= 5.1,  -- Feign Death
        [53480] = 5.1,  -- Roar of Sacrifice
        [54216] = 5.1,  -- Master's Call

        --
        -- Mage
        --
        [45438] = 5.2, -- Ice Block
        [47000] = 5.1, -- Improved Blink (15%)
        [46989] = 5.1, -- Improved Blink (30%)
        [12043] = 5.0, -- Presence of Mind
        [66]    = 4.9, -- Invisibility (Countdown)
        [32612] = 4.9, -- Invisibility
        [12042] = 4.9, -- Arcane Power
        [12051] = 4.9, -- Evocation
        [12472] = 4.9, -- Icy Veins
        [28682] = 4.9, -- Combustion

        --
        -- Paladin
        --
        [642] 	= 5.2, -- Divine Shield
        [498] 	= 5.2, -- Divine Protection
        [1022] 	= 5.1, -- Blessing of Protection
        [1044] 	= 5.1, -- Blessing of Freedom
        [6940] 	= 5.1, -- Blessing of Sacrifice
        [31821] = 5.1, -- Aura Mastery
        [31850] = 5.1, -- Ardent Defender
        [20216] = 5.1, -- Divine Favor
        [31884] = 5.0, -- Avenging Wrath
        [58597] = 4.9, -- Sacred Shield

        --
        -- Priest
        --
        [33206] = 5.2,  -- Pain Suppression
        [47585] = 5.2,  -- Dispersion
        [47788] = 5.2,  -- Guardian Spirit
        [64843] = 5.2,  -- Divine Hymn
        [10060] = 5.1 , -- Power Infusion
        [6346]  = 4.9,  -- Fear Ward
        [27827] = 5.1,  -- Spirit of Redemption
        [15286] = 5.1,  -- Vampiric Embrace

        --
        -- Rogue
        --
        [5277]  = 5.1, -- Evasion
        [11327] = 5.1, -- Vanish
        [45182] = 5.1, -- Cheating Death
        [13750] = 4.9, -- Adrenaline Rush
        [51690] = 4.9, -- Killing Spree

        --
        -- Shaman
        --
        [8178]  = 5.2,  -- Grounding Totem Effect
        [16188] = 5.2,  -- Nature's Swiftness

        --
        -- Warlock
        --
        [18708] = 5.1, -- Fel Domination

        -- 
        -- Warrior
        --
        [46924] = 5.2, -- Bladestorm
        [23920] = 5.2, -- Spell Reflection
        [871]   = 5.1, -- Shield Wall
        [12975] = 5.1, -- Last Stand
        [65932] = 5.1, -- Retaliation
        [3411]  = 5.1, -- Intervene
        [1719]  = 4.9, -- Recklessness

    },
    HARMFUL =
    {
        --
        -- Death Knight
        --
        [47476] = 5.2, -- Strangulate

        --
        -- Hunter
        --
        [19503] = 5.1, -- Scatter Shot

        --
        -- Mage
        --
        [   118] = 5.2, -- Polymorph
        [ 28272] = 5.2, -- Polymorph (pig)
        [ 28271] = 5.2, -- Polymorph (turtle)
        [ 61305] = 5.2, -- Polymorph (black cat)
        [ 61721] = 5.2, -- Polymorph (rabbit)
        [ 61780] = 5.2, -- Polymorph (turkey)

        --
        -- Paladin
        --
        [ 20066] = 5.2, -- Repentance

        --
        -- Priest
        --
        [ 64044] = 5.1, -- Psychic Horror (Horror effect)
        [ 15487] = 5.0, -- Silence

        --
        -- Rogue
        --
        [  6770] = 5.2, -- Sap
        [  1776] = 5.1, -- Gouge

        --
        -- Shaman
        --
        [ 51514] = 5.0, -- Hex

        --
        -- Warlock
        --
        [  6789] = 5.0, -- Mortal Coil

        --
        -- Warrior
        --
        [ 47486] = 4.9, -- Mortal Strike when applied with Sharpen Blade (50% healing reduc)

    }
};

--
-- Mapping between the Racial's SpellID to it's cooldown duration.
--
Constants.RacialSpellIDtoCooldown =
{
    [7744]      = { cd = 120, trinketCD = 45 }, -- Will of the Forsaken, Undead Racial, 45 sec cooldown trigger on trinket
    [20594]     = { cd = 120                 }, -- Stoneform, Dwarf Racial
    [58984]     = { cd = 120                 }, -- Shadowmeld, Night Elf Racial
    [59752]     = { cd = 120, trinketCD = 120 }, -- Every Man for Himself, Human Racial, Shared cooldown with trinket
    [28730]     = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Mage and Warlock,
    [50613]     = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Death Knight,
    [80483]     = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Hunter,
    [155145]    = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Paladin,
    [232633]    = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Priest,
    [25046]     = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Rogue,
    [69179]     = { cd = 120                 }, -- Arcane Torrent, Blood Elf Racial, Warrior,
    [20589]     = { cd = 90                  }, -- Escape Artist, Gnome Racial
    [26297]     = { cd = 180                 }, -- Berserkering, Troll Racial
    [33702]     = { cd = 120                 }, -- Blood Fury, Orc Racial, Mage, Warlock
    [20572]	    = { cd = 120                 }, -- Blood Fury, Orc Racial, Warrior, Hunter, Rogue, Death Knight
    [33697]     = { cd = 120                 }, -- Blood Fury, Orc Racial, Shaman, Monk
    [59545]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Death Knight
    [59543]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Hunter
    [59548]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Mage
    [59542]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Paladin
    [59544]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Priest
    [59547]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Shaman
    [28880]     = { cd = 180                 }, -- Gift of the Naaru, Draenei Racial, Warrior
    [20549]     = { cd = 120                 }, -- War Stomp, Tauren Racial
};

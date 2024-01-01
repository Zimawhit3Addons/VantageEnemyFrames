-------------------------------------------------------------------------------
---@script: constants.lua
---@author: zimawhit3
---@desc:   This module holds the Vanilla constants used by the addon.
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
    [6552]	    = 4,    -- [Warrior] Pummel
    [1766]	    = 5,    -- [Rogue] Kick
    [8042]	    = 2,    -- [Shaman] Earth Shock
    [19244]	    = 5,    -- [Warlock] Spell Lock (Rank 1)
    [19647]	    = 6,    -- [Warlock] Spell Lock (Rank 2)
    [2139]	    = 10,   -- [Mage] Counterspell
    -- [Paladin] Rebuke
};

---
---
---
Constants.PriorityAuras =
{
    HELPFUL =
    {
        --
        -- Druid
        --
        [17116] = 5.2, -- Nature's Swiftness
        [22812] = 5.1, -- Barkskin
        [22842] = 5.1, -- Frenzied Regeneration
        [5217]  = 4.9, -- Tiger's Fury
        [29166] = 4.9, -- Innervate

        --
        -- Hunter
        --
        [19574] = 5.2,  -- Bestial Wrath
        [136] 	= 5.1,  -- Mend Pet
        [5384]	= 5.1,  -- Feign Death

        --
        -- Mage
        --
        [45438] = 5.2, -- Ice Block
        [12043] = 5.0, -- Presence of Mind
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
        [20216] = 5.1, -- Divine Favor

        --
        -- Priest
        --
        [10060] = 5.1 , -- Power Infusion
        [6346]  = 4.9,  -- Fear Ward
        [27827] = 5.1,  -- Spirit of Redemption
        [15286] = 5.1,  -- Vampiric Embrace

        --
        -- Rogue
        --
        [5277]  = 5.1, -- Evasion
        [11327] = 5.1, -- Vanish
        [ 2983] = 5.0, -- Sprint (Rank 1)
        [ 8696] = 5.0, -- Sprint (Rank 2)
        [11305] = 5.0, -- Sprint (Rank 3)
        [13750] = 4.9, -- Adrenaline Rush

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
        [871]   = 5.1, -- Shield Wall
        [12975] = 5.1, -- Last Stand
        [1719]  = 4.9, -- Recklessness

    },
    HARMFUL =
    {
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

        --
        -- Paladin
        --
        [ 20066] = 5.2, -- Repentance

        --
        -- Priest
        --
        [ 15487] = 5.0, -- Silence

        --
        -- Rogue
        --
        [  6770] = 5.2, -- Sap
        [  1776] = 5.1, -- Gouge

        --
        -- Shaman
        --

        --
        -- Warlock
        --
        [  6789] = 5.0, -- Death Coil

        --
        -- Warrior
        --
        [ 12294] = 4.9, -- Mortal Strike
    }
};

--
-- Mapping between the Racial's SpellID to it's cooldown duration.
--
Constants.RacialSpellIDtoCooldown =
{
    [7744]      = { cd = 120    }, -- Will of the Forsaken, Undead Racial, 30 sec cooldown trigger on trinket
    [20594]     = { cd = 180    }, -- Stoneform, Dwarf Racial
    [20580]     = { cd = 10     }, -- Shadowmeld, Night Elf Racial
    [20600]     = { cd = 120    }, -- Perception, Human Racial
    [20589]     = { cd = 60     }, -- Escape Artist, Gnome Racial
    [26297]     = { cd = 180    }, -- Berserkering, Troll Racial
    [20572]     = { cd = 120    }, -- Blood Fury, Orc Racial
    [20549]     = { cd = 120    }, -- War Stomp, Tauren Racial
};

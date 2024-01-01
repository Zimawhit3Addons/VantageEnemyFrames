---------------------------------------------------------
---@script: defaults.lua
---@author: zimawhit3
---@desc:   This module implements default settings for the addon.
---------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local _, Constants  = ...

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------

-----------------------------------------
--                Ace3
-----------------------------------------


-------------------------------------------------------------------------------
--                                Profile Defaults
-------------------------------------------------------------------------------

---
--- @class VantageConfiguration
---
Constants.settings =
{
    profile =
    {
        Font = "PT Sans Narrow Bold",

        Locked  = false,
        Debug   = false,

        MyTarget_Color              = { 1, 1, 1, 1 },
        MyTarget_BorderSize         = 2,
        MyFocus_Color               = { 0, 0.988235294117647, 0.729411764705882, 1 },
        MyFocus_BorderSize          = 2,
        ShowTooltips                = true,
        UseBigDebuffsPriority       = true,
        BigDebuffsPriorityThreshold = 30,
        ConvertCyrillic             = true,

        RBG =
        {
            TargetCalling_SetMark               = false,
            TargetCalling_NotificationEnable    = false,
            EnemiesTargetingMe_Enabled          = false,
            EnemiesTargetingMe_Amount           = 5,
            EnemiesTargetingAllies_Enabled      = false,
            EnemiesTargetingAllies_Amount       = 5
        },

        Enemies =
        {
            Enabled = true,

            RangeIndicator_Enabled      = true,
            RangeIndicator_Range        = 40,
            RangeIndicator_Alpha        = 0.55,
            RangeIndicator_Everything   = true,
            RangeIndicator_Frames       = {},

            LeftButtonType      = "Target",
            LeftButtonValue     = "",
            RightButtonType     = "Focus",
            RightButtonValue    = "",
            MiddleButtonType    = "Custom",
            MiddleButtonValue   = "",

            ["10"] =
            {
                Enabled     = true,
                Position_X  = false,
                Position_Y  = false,
                BarWidth    = 220,
                BarHeight   = 28,
                BarVerticalGrowDirection = "downwards",
                BarVerticalSpacing = 3,
                BarColumns = 1,
                BarHorizontalGrowDirection = "rightwards",
                BarHorizontalSpacing = 100,

                PlayerCount =
                {
                    Enabled = true,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                BattlegroundRezTimer =
                {
                    Enabled = true,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                ButtonModules =
                {
                    Castbar =
                    {
                        Enabled = false,
                        Points =
                        {
                            {
                                Point = "RIGHT",
                                RelativeFrame = "Button",
                                RelativePoint = "LEFT",
                                OffsetX = -3
                            }
                        }
                    },
                    Drtracker =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "TOPRIGHT",
                                RelativeFrame = "Class",
                                RelativePoint = "TOPLEFT",
                                OffsetX= -2
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowDirection = "upwards",
                        }
                    },
                    Buffs =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Drtracker",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -2,
                                OffsetY = 1
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
						},
                    },
                    Debuffs =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Buffs",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -8
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
						},
                    },
                    Racial =
                    {
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    },
                    Trinket =
                    {
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    }
                },
                Framescale = 1,
            },

            ["15"] =
            {
                Enabled     = true,
                Position_X  = false,
                Position_Y  = false,
                BarWidth    = 220,
                BarHeight   = 28,
                BarVerticalGrowDirection = "downwards",
                BarVerticalSpacing = 3,
                BarColumns = 1,
                BarHorizontalGrowDirection = "rightwards",
                BarHorizontalSpacing = 100,

                PlayerCount =
                {
                    Enabled = true,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                BattlegroundRezTimer =
                {
                    Enabled = true,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                ButtonModules =
                {
                    Castbar =
                    {
                        Enabled = false,
                        Points =
                        {
                            {
                                Point = "RIGHT",
                                RelativeFrame = "Button",
                                RelativePoint = "LEFT",
                                OffsetX = -3
                            },
                        }
                    },
                    Drtracker =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "TOPRIGHT",
                                RelativeFrame = "Class",
                                RelativePoint = "TOPLEFT",
                                OffsetX= -2
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        }
                    },
                    Buffs =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Drtracker",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -2,
                                OffsetY = 1
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        }
                    },
                    Debuffs =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Buffs",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -8
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        },
                    },
                    Racial =
                    {
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    },
                    Trinket =
                    {
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    }
                },
                Framescale = 1,
            },

            ["40"] =
            {
                Enabled = true,
                Position_X = false,
                Position_Y = false,
                BarWidth = 220,
                BarHeight = 22,
                BarVerticalGrowDirection = "downwards",
                BarVerticalSpacing = 1,
                BarColumns = 1,
                BarHorizontalGrowDirection = "rightwards",
                BarHorizontalSpacing = 100,

                PlayerCount =
                {
                    Enabled = true,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                BattlegroundRezTimer =
                {
                    Enabled = false,
                    Text =
                    {
                        FontSize = 14,
                        FontOutline = "OUTLINE",
                        FontColor = {1, 1, 1, 1},
                        EnableShadow = false,
                        ShadowColor = {0, 0, 0, 1},
                    }
                },
                ButtonModules =
                {
                    Castbar =
                    {
                        Enabled = false,
                        Points =
                        {
                            {
                                Point = "RIGHT",
                                RelativeFrame = "Button",
                                RelativePoint = "LEFT",
                                OffsetX = -3
                            }
                        }
                    },
                    Drtracker =
                    {
                        Enabled = true,
                        Points =
                        {
                            {
                                Point = "TOPRIGHT",
                                RelativeFrame = "Class",
                                RelativePoint = "TOPLEFT",
                                OffsetX= -2
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        }
                    },
                    Buffs =
                    {
                        Enabled = false,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Drtracker",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -2,
                                OffsetY = 1
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        }
                    },
                    Debuffs =
                    {
                        Enabled = false,
                        Points =
                        {
                            {
                                Point = "BOTTOMRIGHT",
                                RelativeFrame = "Buffs",
                                RelativePoint = "BOTTOMLEFT",
                                OffsetX = -8
                            }
                        },
                        Container =
                        {
                            HorizontalGrowDirection = "leftwards",
                            VerticalGrowdirection = "upwards",
                        }
                    },
                    Racial =
                    {
                        Enabled = true,
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Trinket",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    },
                    Trinket =
                    {
                        Enabled = true,
                        ActivePoints = 2,
                        Points =
                        {
                            {
                                Point = "TOPLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "TOPRIGHT",
                                OffsetX = 1
                            },
                            {
                                Point = "BOTTOMLEFT",
                                RelativeFrame = "Button",
                                RelativePoint = "BOTTOMRIGHT",
                                OffsetX = 1
                            }
                        }
                    }
                },
                Framescale = 1,
            }
        }
    }
};

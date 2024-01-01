---------------------------------------------------------
---@script: locales.lua
---@author: zimawhit3
---@desc:       
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
local fmt = string.format

-----------------------------------------
--              Blizzard
-----------------------------------------
local C_Timer   = C_Timer
local GetLocale = GetLocale

-----------------------------------------
--              Constants
-----------------------------------------
local LOCALE_MISSING_NOTIFICATION = "Missing localizations for your ingame language. You can help translating this addon on https://www.curseforge.com/wow/addons/vantageenemyframes/localization";
local REPORT_MISSING_NOTIFICATION = "Missing localization entry for '%s'. Please report this to the addon author.";

-------------------------------------------------------------------------------
--                                   Locales
-------------------------------------------------------------------------------
local default_locale        = {};
local locales               = {};
local game_locale           = GetLocale();
local report_missing_locale = false;

local locales_mt =
{
    __index = function( _, k )
        if default_locale[k] then
            if ( game_locale ~= "enUS" or game_locale ~= "enGB" ) and
               not report_missing_locale then
                C_Timer.After( 3, function() print( LOCALE_MISSING_NOTIFICATION ); end );
                report_missing_locale = true;
            end
            return default_locale[k];

        else
            C_Timer.After( 3, function() print( fmt( REPORT_MISSING_NOTIFICATION, k ) ); end );
            return k;

        end
    end
};

-- 
-- The locales variable must be set to 'L' for curseforge's system.
-- 
Constants.L = setmetatable( locales, locales_mt );

local L = Constants.L

L["AddPoint"] = "Add Point"
L["Allies"] = "Allies"
L["allies"] = "allies"
L["ally"] = "ally"
L["Ally"] = "Ally"
L["AllyIsTargeted"] = "Ally is targeted"
L["AllyJoined"] = "An ally joined the battleground"
L["AllyLeft"] = "An ally left the battleground"
L["AND"] = "and"
L["AttachToObject"] = "Attach to object"
L["AttachToObject_Desc"] = "Note that not every object might be possible to select, depending on your positioning of the other frames. For example if you anchor the pvp talents at the racials and you are trying to anchor the racials at the pvp talents there will be a error message."
L["Auras_Buffs_Container_Color_Desc"] = "The border color of the container of the buff icons"
L["Auras_CustomFiltering_Conditions_All"] = "All"
L["Auras_CustomFiltering_Conditions_Any"] = "Any"
L["Auras_CustomFiltering_ConditionsMode"] = "Conditions mode"
L["Auras_CustomFiltering_ConditionsMode_Desc"] = [=[Here you can choose how the selected conditions should apply to the auras. 
If you choose "Any" the addon will show the aura as soon as one of your selected conditions is met.
If you choose "All" the addon will only show an aura if it mets all of your selected conditions.]=]
L["Auras_Debuffs_Container_Color_Desc"] = "The border color of the container of the debuff icons"
L["Auras_Enabled"] = "Enable Auras"
L["Auras_Enabled_Desc"] = "When enabled there will be aura icons. There will also be a number for the remaining time and one for the stacks applied"
L["Auras_Filtering_Mode"] = "Filtering mode"
L["Auras_Filtering_Mode_Desc"] = [=[Here you can choose which filter should be applied to the auras.
You can choose between a blizzlike filter which applys the same filter als Blizzard uses on the raid frame and custom filtering conditions]=]
L["Auras_ShowTooltips"] = "Show spell tooltips"
L["AurasCustomConditions"] = "Custom conditions"
L["AurasFiltering_AddSpellID"] = "SpellID"
L["AurasFiltering_AddSpellID_Desc"] = "Enter a spellID or multiple comma-seperated spellIDs. The spellIDs are getting added to your filter list. Only auras whose spellID is on the filter list are getting shown when the spellID filtering is enabled."
L["AurasFiltering_Enabled_Desc"] = "When this option is enabled you will only see %s which you added to the filtering list"
L["AurasFiltering_Filterlist_Desc"] = "Click to remove this %s"
L["AurasFilteringSettings_Desc"] = "Here you can control which aura gets shown"
L["AurasSettings"] = "Auras"
L["AurasSettings_Desc"] = "Settings about auras (buffs and debuffs)"
L["AurasStacktextSettings"] = "Stack text"
L["BarBackground"] = "Background Color"
L["BarHeight_Desc"] = "The height of each row. This setting is not available in combat due to Blizzard's combat protection."
L["BarSettings"] = "Bar settings"
L["BarSettings_Desc"] = "Here you can configure the rows"
L["BarTexture"] = "Bar texture"
L["BarWidth_Desc"] = "The width of each row."
L["BattlegroundSize"] = "Battleground size"
L["BattlegroundRezTimer"] = "Battleground Ressurection Timer"
L["BGSize_10"] = "10 players"
L["BGSize_10_Desc"] = "This settings apply for %s in a BG with 10 players per side"
L["BGSize_15"] = "15 Players"
L["BGSize_15_Desc"] = "This settings apply for %s in a BG with 15 players per side"
L["BGSize_40"] = "16–40 Players"
L["BGSize_40_Desc"] = "This settings apply for %s in a BG with 16–40 players per side"
L["BGSize_5"] = "Arena"
L["BGSize_5_Desc"] = "This settings apply for %s in arenas"
L["BlizzlikeAuraFiltering"] = "Use Blizzard's raidframe filter"
L["BorderSize"] = "Border size"
L["BorderThickness"] = "Border size"
L["BOTTOM"] = "Bottom"
L["BOTTOMLEFT"] = "Bottom left"
L["BOTTOMRIGHT"] = "Bottom right"
L["buff"] = "buff"
L["BuffContainer"] = "Buff container"
L["BuffIcon"] = "Buff icon"
L["Buffs"] = "Buffs"
L["Button"] = "Button"
L["CantAnchorToItself"] = "Can't anchor to itself!"
L["Castbar"] = "Castbar"
L["CENTER"] = "Center"
L["Class"] = "Class"
L["Color"] = "Color"
L["Coloring_Enabled"] = "Color by debuff type"
L["Coloring_Enabled_Desc"] = "When this option is enabled you can choose whether the frame's border or the countdown text should be colored by debuff type (Like its know from the default UI, poisons are green, diseases blue etc.)"
L["Columns"] = "Columns"
L["Columns_Desc"] = "In how many colums the players are displayed."
L["Combat"] = "In Combat"
L["CombatIndicator"] = "Combat indicator"
L["Combatindicator"] = "Combat indicator"
L["CombatLogScanningForEnemiesDisabled"] = "Disabled combat log scanning for enemies"
L["CombatLogScanningForEnemiesEnabled"] = "Combat log scanning to detect enemy players has been enabled."
L["ConfirmProfileOverride"] = "Are you sure that you want to override the subprofile %s with the subprofile %s"
L["Container_Color"] = "Container border color"
L["ContainerPosition"] = "Container position"
L["ContainerSettings"] = "Container settings"
L["ConvertCyrillic"] = "Convert Cyrillic"
L["ConvertCyrillic_Desc"] = "Converts cyrillic characters which makes it easier to read names if you are playing against russians"
L["CopySettings"] = "Copy settings from %s"
L["CopySettings_Desc"] = "Click here if you want to import the settings of the subprofile %s."
L["Countdowntext"] = "Countdown text"
L["Covenant"] = "Covenant"
L["CovenantIcon_Enabled"] = "Enable covenant icons"
L["CovenantIcon_Enabled_Desc"] = "Enable this option if you want to see a covenant icon on the health bar"
L["CovenantIcon_Size_Desc"] = "The size of the covenant icons (width and height)"
L["CovenantIconSettings_Desc"] = "Settings for the covenant icon which is shown on the health bar"
L["CurrentVersion"] = "Current version"
L["Curse"] = "Curse"
L["CustomMacro_Desc"] = [=[This enables you to set a custom macro. A empty field will lead to a empty macro.
Available substitutions: %n gets substituted with the enemy's name

Example: 
/targetexact %n
/cast Polymorph
/say Polymorph on %n
/targetlasttarget

This will target the enemy, cast Polymorph, write a message into the say channel and target your previous target.
Note that macros can only be 255 characters long (including substitutions).]=]
L["debuff"] = "debuff"
L["DebuffContainer"] = "Debuff container"
L["DebuffIcon"] = "Debuff icon"
L["Debuffs"] = "Debuffs"
L["DebuffType_Filtering"] = "Filter by debuff type"
L["DebuffType_Filtering_Desc"] = "When this option is enabled you will only see debuffs of the chose typ. This option is not simulated in the test mode since this would require a huge database with tons of spells and their debuff type."
L["DeletePoint"] = "Delete Point %s"
L["DisableArenaFramesInArena"] = "Disable arena frames in arena"
L["DisableArenaFramesInArena_Desc"] = "Disables the Arenaframes in a arena. Also works when sArena is installed"
L["DisableArenaFramesInBattleground"] = "Disable arena frames in battleground"
L["DisableArenaFramesInBattleground_Desc"] = "Disables the Arenaframes in a battleground. Also works when sArena is installed"
L["Disease"] = "Disease"
L["DispellFilter"] = "Filter by dispellability"
L["DisplayType"] = "Display type"
L["Downwards"] = "Downwards"
L["DR_Disorient"] = "Disorient"
L["DR_Incapacitate"] = "Incapacitate"
L["DR_Knockback"] = "Knockback"
L["DR_Root"] = "Root"
L["DR_Silence"] = "Silence"
L["DR_Stun"] = "Stun"
L["DRContainer"] = "DR container"
L["DRTracking"] = "DR Tracking"
L["Drtracker"] = "DR Tracking"
L["DrTracking_Container_Color_Desc"] = "The border color of the container of the DR icons"
L["DrTracking_DisplayType_Desc"] = "Here you can choose if the status of the DR should be indicated by a colored frame around the icon or by the textcolor of the countdown text. Note that the Countdown text setting will only work if you aren't using an addon like OmniCC that modifys the textcolor."
L["DrTracking_Enabled"] = "Enable DR Tracking"
L["DrTracking_Enabled_Desc"] = "When enabled there will be icons for DR Tracking next to the enemy row. Green Border: Next CC will be half duration. Yellow Border: Next CC will be quarter duration. Red Border: Next CC will not apply because the player is immune"
L["DrTracking_Spacing"] = "DR Spacing"
L["DrTracking_Spacing_Desc"] = "The spacing between each DR icon"
L["DrTrackingFiltering_Enabled_Desc"] = "When this option is enabled you will only see icons of spells whose category is checked on the filtering list."
L["DrTrackingFiltering_Filterlist_Desc"] = "Click to track/untrack this category"
L["DrTrackingFilteringSettings_Desc"] = "Here you can choose which DR category is getting shown."
L["DrTrackingSettings"] = "DR Tracking"
L["DrTrackingSettings_Desc"] = "Settings regarding DR Tracking"
L["DurationFilter"] = "Filter by duration"
L["DurationFilter_OnlyShowWhenDuration"] = "Only show when duration is smaller or equal than"
L["DurationFilter_OnlyShowWhenDuration_Desc"] = "Any auras whose duration is longer than the selected duration won't make it through the filter"
L["EnableClique"] = "Use Clique for keybindings"
L["EnableClique_Desc"] = "When this option is enabled Clique will handle all of the keybindings."
L["enemies"] = "enemies"
L["Enemies"] = "Enemies"
L["EnemiesTargetingAllies_Enabled_Desc"] = "When you enable this option you will be notified by a sound when a set amount of enemys are targeting an ally"
L["EnemiesTargetingMe_Enabled_Desc"] = "When you enable this option you will be notified by a sound when a set amount of enemys are targeting you "
L["enemy"] = "enemy"
L["Enemy"] = "Enemy"
L["EnemyJoined"] = "An enemy joined the battleground"
L["EnemyLeft"] = "An enemy left the battleground"
L["ExportButton"] = "Export profile"
L["ExportButton_Desc"] = "Click here to export your current active profile"
L["FakeEventsDisabled"] = "No longer creating fake events."
L["FakeEventsEnabled"] = "Now creating fake events for testing."
L["Filtering_Enabled"] = "Enable filtering"
L["Filtering_Filterlist"] = "Filter list"
L["FilterSettings"] = "Filter settings"
L["Font"] = "Font"
L["Font_Desc"] = "The main font used by this addon"
L["Font_Outline"] = "Font outline"
L["Font_Outline_Desc"] = "The font's outline"
L["Fontcolor"] = "Font color"
L["Fontcolor_Desc"] = "The color of the text"
L["FontShadow_Enabled"] = "Enable Font shadow"
L["FontShadow_Enabled_Desc"] = "When enabled there will be a shadow around the font. You can choose the color of that shadow"
L["FontShadowColor"] = "Shadow color"
L["FontShadowColor_Desc"] = "The color of the text shadow"
L["FontSize"] = "Font size"
L["FontSize_Desc"] = "The font size of the text"
L["Frame"] = "Frame"
L["Framescale"] = "Scale"
L["Framescale_Desc"] = "The scale of the mainframe. This setting is not available in combat due to Blizzard's combat protection."
L["General"] = "General"
L["GeneralSettings"] = "General settings"
L["GeneralSettings_Desc"] = "Some general settings"
L["GeneralSettingsAllies"] = "This settings apply to allies regardless of the size of the battleground"
L["GeneralSettingsEnemies"] = "This settings apply to enemies regardless of the size of the battleground"
L["HealthBar"] = "Healthbar"
L["Healthbar"] = "Healthbar"
L["HealthBar_Background_Desc"] = "Background Color for the health bar."
L["HealthBar_Texture_Desc"] = "The texture used for the health bars"
L["HealthBarSettings_Desc"] = "Settings for the health bar."
L["HealthTextEnabled"] = "Enable health text"
L["HealthTextSettings"] = "Health text settings"
L["HealthTextType"] = "Health text type"
L["Height"] = "Height"
L["HighestPriorityAura"] = "Highest priority aura"
L["Highestpriority"] = "Highest priority aura"
L["Highlight_Color"] = "Highlight Color"
L["Highlight_Color_Desc"] = "The color of the player frame your cursor is currently on"
L["HorizontalGrowdirection"] = "Horizontal grow direction"
L["HorizontalGrowdirection_Desc"] = "Lets you choose if the rows grow to the left or to the right side"
L["HorizontalSpacing"] = "Horizontal spacing"
L["IAmTargeted"] = "I am targeted"
L["Icon"] = "Icon"
L["IconSize"] = "Icon size"
L["IconsPerRow"] = "Icons per row"
L["Import"] = "Import"
L["ImportButton"] = "Import profile"
L["ImportButton_Desc"] = "Click here to import a profile from a string and overwrite your current active profile"
L["JustifyH"] = "Horizontal alignment"
L["JustifyH_Desc"] = "The horizontal alignment of the text"
L["JustifyV"] = "Vertical alignment"
L["JustifyV_Desc"] = "The vertical alignment of the text"
L["KeybindSettings_Desc"] = "Here you can configure what should happen on left- right- and middle click"
L["LEFT"] = "Left"
L["LeftToTargetCounter"] = "Left to target counter"
L["Leftwards"] = "Leftwards"
L["Level"] = "Level"
L["LevelText_Enabled"] = "Show player's level"
L["LevelText_OnlyShowIfNotMaxLevel"] = "Only show if not max level"
L["Locked"] = "Lock"
L["Locked_Desc"] = "Locks the frame in place"
L["Magic"] = "Magic"
L["MainFrameSettings"] = "Main frame settings"
L["MainFrameSettings_Desc"] = "Settings for the main frame which is used for %s"
L["MaxPlayers"] = "Maximum Enemys"
L["MaxPlayers_Desc"] = "The addon won't show enemys if there are more enemys than this number"
L["MIDDLE"] = "Middle"
L["ModuleSettings"] = "Module settings"
L["ModuleSpecificSettings"] = "Module specific settings"
L["MoreProfileOptions"] = "More Profile Options"
L["MyFocus"] = "My Focus"
L["MyFocus_Color"] = "Focus Color"
L["MyFocus_Color_Desc"] = "The color used for the border indicating your current focus"
L["MyTarget"] = "My target"
L["MyTarget_Color"] = "Target Color"
L["MyTarget_Color_Desc"] = "The color used for the border around the health bar indicating your current target"
L["MyVersion"] = "You are using Version"
L["Name"] = "Name"
L["name"] = "Name"
L["Name_Desc"] = "Settings for names on the health bar."
L["NewVersionAvailable"] = "A new version is available"
L["None"] = "None"
L["NonPriorityBuffs"] = "Non prioritized buffs"
L["NonPriorityDebuffs"] = "Non prioritized debuffs"
L["Normal"] = "Normal"
L["NormalCastingBar"] = "Normal Casting bar"
L["NotAvailableInCombat"] = [=[
This setting is not available while you are in combat due to Blizzard's combat restrictions.]=]
L["Notifications_Allies_Enabled_Desc"] = "When enabled you will be notified when an ally is leaving or joining the battleground."
L["Notifications_Enabled"] = "Enable Notifications"
L["Notifications_Enemies_Enabled_Desc"] = "When enabled you will be notified when an enemy is leaving or joining the battleground."
L["NoVersion"] = "No addon found"
L["NumericTargetindicator_Enabled_Desc"] = "Shows how many %s are targeting a player."
L["Objective"] = "Objective"
L["ObjectiveAndRespawn_ObjectiveEnabled"] = "Show Objectives"
L["ObjectiveAndRespawn_ObjectiveEnabled_Desc"] = "Shows in icon for flag, minecart and orb-carriers next to the enemy button"
L["ObjectiveAndRespawn_Position"] = "Position"
L["ObjectiveAndRespawn_Position_Desc"] = "If the icon should be shown left to the spec icon or right to the trinket/racial icons."
L["ObjectiveAndRespawn_RespawnEnabled"] = "Enable Respawn Timer"
L["ObjectiveAndRespawn_RespawnEnabled_Desc"] = "When enabled there will be an icon indicating the remaining time until the enemy is alive."
L["ObjectiveAndRespawn_Width_Desc"] = "Width of the Objective Icon"
L["ObjectiveAndRespawnSettings_Desc"] = "Settings regarding the objective of the battleground"
L["ObjectiveAndRespawnTimer"] = "Objective and respawn timer"
L["OffsetX"] = "Offset X"
L["OffsetY"] = "Offset Y"
L["OldVersion"] = "Old version"
L["OutOfCombat"] = "Out of combat"
L["PlayerCount_Enabled"] = "Player Count"
L["PlayerCount_Enabled_Desc"] = "If there should a text for the current number of players. Note that this count can be different than the current number of rows shown due to combat protection or leaving allies/enemies in a RBG"
L["BattlegroundRezTimer_Enabled"] = "Battleground Ressurection Timer"
L["BattlegroundRezTimer_Enabled_Desc"] = "If there should be text displaying the current ressurection timer in the battleground. Note: This only applies to 10 man BGs."
L["Point"] = "Point"
L["PointAtObject"] = "Point at object"
L["Poison"] = "Poison"
L["Position"] = "Position"
L["PowerBar"] = "Powerbar"
L["PowerBar_Background_Desc"] = "Background Color for the power bar."
L["PowerBar_Enabled"] = "Enable ressource bars"
L["PowerBar_Enabled_Desc"] = "Enable this option if you wan't to see bars for ressources like mana, rage etc."
L["PowerBar_Height_Desc"] = "The heigt of the ressource bar. Making the ressource bar higher will automatically make the health bar shorter"
L["PowerBar_Texture_Desc"] = "The texture used for the power bars"
L["PowerBarSettings_Desc"] = "Settings for the ressource bar"
L["PriorityBuffs"] = "Prioritized buffs"
L["PriorityDebuffs"] = "Prioritized debuffs"
L["Racial"] = "Racial"
L["Racial_Enabled"] = "Enable Racials"
L["Racial_Enabled_Desc"] = "When enabled there will be icons for used racials"
L["Racial_Width_Desc"] = "The width of the racial."
L["RacialFiltering_Enabled_Desc"] = "When this option is enabled you will only see racials which are checked on the filtering list."
L["RacialFiltering_Filterlist_Desc"] = "Click to track/untrack this racial"
L["RacialFilteringSettings_Desc"] = "Here you can select which racial you want to track"
L["RacialSettings"] = "Racials"
L["RacialSettings_Desc"] = "Settings regarding Racials"
L["RangeIndicator_Alpha"] = "Alpha"
L["RangeIndicator_Alpha_Desc"] = "The alpha of the enemy frame when the enemy is out of the chosen range"
L["RangeIndicator_Enabled"] = "Enable range indicator"
L["RangeIndicator_Enabled_Desc"] = "When tis option is enabled the frame will use the chosen alpha when an enemy is out of a chosen range"
L["RangeIndicator_Everything"] = "Modify the alpha of all elements"
L["RangeIndicator_Frames"] = "Modify alpha of"
L["RangeIndicator_Frames_Desc"] = "Set which parts of the enemy row should be shown with a higher transparency when the enemy is out of range."
L["RangeIndicator_Range"] = "Range"
L["RangeIndicator_Range_Desc"] = "When an enemy is more than this distance (in yards) away his frame will use the chosen alpha"
L["RangeIndicator_Settings"] = "Range indicator"
L["RangeIndicator_Settings_Desc"] = "Here you can configure the range indicator."
L["RBGSpecificSettings"] = "Rated Battleground"
L["RBGSpecificSettings_Desc"] = "This settings only apply in a RBG (Rated Battleground)"
L["ResetModule"] = "Reset Module"
L["ResetModule_Desc"] = "Click here to reset the settings of this module for %s:%s"
L["ResetModuleSettings"] = "Reset the settings of this module"
L["Resource"] = "Resource"
L["RIGHT"] = "Right"
L["Rightwards"] = "Rightwards"
L["RoleIcon_Enabled"] = "Enable role icons"
L["RoleIcon_Enabled_Desc"] = "Enable this option if you want to see a role icon on the health bar"
L["RoleIcon_Size_Desc"] = "The size of the role icons (width and height)"
L["RoleIconSettings"] = "Role icon"
L["RoleIconSettings_Desc"] = "Settings for the role icon which is shown on the health bar"
L["Scale"] = "Scale"
L["ShowDispellable"] = "Show dispellable"
L["ShowDispellable_Desc"] = [=[Show %s that i can remove by decursing, purging, etc.

]=]
L["ShowMine"] = "Show mine"
L["ShowMine_Desc"] = "Show %s that i applied"
L["ShowNumbers"] = "Show numbers"
L["ShowNumbers_Desc"] = "Show cooldown numbers, note that this option might not be working when you are using addons like OmniCC"
L["ShowRealmNames"] = "Show Realmnames"
L["ShowRealmNames_Desc"] = "Shows the enemy's realm"
L["ShowTooltips"] = "Show tooltips"
L["ShowTooltips_Desc"] = "Show tooltips when you move the mouse over objects like trinket and aura icons"
L["ShowUnusedIcons"] = "Show icons when they aren't being used."
L["Side"] = "Side"
L["SideAtObject"] = "Side at object"
L["Size"] = "Size"
L["SmallCastingBar"] = "Small casting bar"
L["SourceFilter"] = "Filter by Source"
L["Spec_AuraDisplay_Enabled"] = "Enable Aura display"
L["Spec_AuraDisplay_Enabled_Desc"] = "When this option is enabled you will see icons for crowd control and interrupts (when active) instead of the spec icon"
L["Spec_Enabled"] = "Enable specialization"
L["Spec_Enabled_Desc"] = "When enabled there will be icons for the players's specialization"
L["Spec_Width_Desc"] = "The Width of the spec icon."
L["SpecSettings"] = "Spec"
L["SpecSettings_Desc"] = "Settings changing the spec icon."
L["SpellID_Filtering"] = "Filter by spellID"
L["Style"] = "Style"
L["SymbolicTargetindicator_Enabled_Desc"] = "Shows a square class-colored icon for each %s that is targeting a player."
L["TargetAmount"] = "target amount"
L["TargetAmount_Ally"] = "The sound is played as soon as a group member is targeted by more than the set number of opponents."
L["TargetAmount_Me"] = "The sound is played as soon as a you are targeted by more than the set number of opponents."
L["TargetCallerUpdated"] = "is now the target caller"
L["TargetCalling"] = "Target Calling"
L["TargetCallingNotificationEnable"] = "Enable Sound Notification"
L["TargetCallingNotificationEnable_Desc"] = "Notifies you when there is a new target (detected via the raid target skull icon)"
L["TargetCallingSetMark"] = "Mark my target with skull icon"
L["TargetCallingSetMark_Desc"] = "Marks your current target automatically with the skull icon when you are the raid leader and there is no raid assistent in your group. It will also mark your curent target if you are not the raid leader but you are a assistant."
L["TargetCallingShowIcon"] = "Show icon on target caller's target"
L["TargetCallingShowIcon_Desc"] = "When enabled, you will see a icon on the frame which shows the target of the target caller"
L["TargetCallingSoundEnable"] = "Notify me on new target"
L["TargetCallingSoundEnable_Desc"] = "When enabled, there will be a sound when the target caller targets a new player"
L["TargetCallingSoundSound"] = "Notification sound"
L["Targetcounter"] = "Target Counter"
L["TargetIndicator"] = "Target Indicator"
L["Targetindicator"] = "Target Indicator"
L["TargetIndicator_Desc"] = "Numeric and symbolic Target Indicators"
L["TargetIndicatorNumeric"] = "Target Indicator Numeric"
L["TargetIndicatorSymbolic"] = "Target Indicator Symbolic"
L["Testmode_Toggle"] = "Toggle test mode"
L["Testmode_Toggle_Desc"] = [=[Enables/Disables the testing mode. This mode makes it easier to see what impact most of the options have. Its not possible to simulate all options but most of them are covered in this fancy test mode. 
The test mode is disabled if you are currently in a battleground.]=]
L["Testmode_ToggleAnimation"] = "Toggle animation"
L["Testmode_ToggleAnimation_Desc"] = "Enables/Disables the animation of the testmode so you can focus more on a specific setting without getting distracted by the animation."
L["Testmode_UseTeammates"] = "Use group members for testing"
L["Testmode_UseTeammates_Desc"] = "When enabled the testmode will use your current group members instead of fake ones"
L["TestmodeDisabled"] = "Testing mode disabled."
L["TestmodeEnabled"] = "Testing mode enabled."
L["TestModeSettings"] = "Test mode"
L["Text"] = "Text"
L["TextSettings"] = "Text settings"
L["Thick"] = "Thick"
L["TOP"] = "Top"
L["TOPLEFT"] = "Top left"
L["TOPRIGHT"] = "Top right"
L["Trinket"] = "Trinket"
L["Trinket_Enabled"] = "Enable Trinkets"
L["Trinket_Enabled_Desc"] = "When enabled there will be icons for Gladiator's Medallion, Adaptation and Relentless."
L["Trinket_Width_Desc"] = "The width of the trinket."
L["TrinketSettings_Desc"] = "Settings regarding Trinkets"
L["UPDATE_AVAILABLE"] = "A new version is available: v%s. The latest release can be found at %s"
L["UpdatePeriod"] = "Update period"
L["UpdatePeriod_Desc"] = "The time between combat checks, dont put this too low because this can potentially cause performance issues."
L["Upwards"] = "Upwards"
L["UseBarHeight"] = "Use bar height"
L["UseBigDebuffsPriority"] = "Use BigDebuffs"
L["UseBigDebuffsPriority_Desc"] = "If you enable this option, the addon will use the priorities from the addon BigDebuffs instead. The priorities are used for the modules %s, %s and %s "
L["UseButtonHeight"] = "Use button height"
L["UseButtonHeight_Desc"] = "If you enable this option, the module will use the buttons height. "
L["UserDefined"] = "User-defined"
L["VerticalGrowdirection"] = "Vertical grow direction"
L["VerticalGrowDirection"] = "Vertical grow direction"
L["VerticalGrowdirection_Desc"] = "Lets you choose if the bars grow upwards or downwards. "
L["VerticalPosition"] = "Vertical position"
L["VerticalSpacing"] = "Vertical spacing"
L["Width"] = "Width"

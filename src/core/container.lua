-------------------------------------------------------------------------------
---@script: container.lua
---@author: zimawhit3
---@desc:   This module implements containers for grouped, managed frames.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                                    Upvalues
-------------------------------------------------------------------------------

-----------------------------------------
--              Globals
-----------------------------------------
local LibStub		= LibStub

-----------------------------------------
--                Lua
-----------------------------------------

-----------------------------------------
--              Blizzard
-----------------------------------------
local CreateFrame   = CreateFrame
local Mixin         = Mixin

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                Vantage Containers
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class VantageContainer : Frame
---
--- A container to group and manage child frames.
---
local VantageContainer =
{
    ---
    --- @type ( EnemyAuraConfig | EnemyDRConfig )
    ---
    --- A shared reference to the module's config.
    ---
    config = nil,

    ---
    --- @type ( EnemyDRFrame | AuraFrame )[]
    ---
    --- Child frames that are managed by this container.
    ---
    child_frames = nil,

    ---
    --- @type fun( frame: EnemyFrame, container: VantageContainer ): EnemyDRFrame | AuraFrame
    ---
    --- The function used to create new child frames.
    ---
    create = nil,

    ---
    --- @type table
    ---
    --- Table to hold miscellaneous data for the children frames.
    ---
    inputs = nil,

    ---
    --- @type PriorityQueue
    ---
    ---
    ---
    aura_heap = nil,

    ---
    --- @type EnemyFrame
    ---
    --- The `EnemyFrame` this container is attatched to.
    ---
    parent_frame = nil,

    ---
    --- @type fun( container: VantageContainer, frame: ( EnemyDRFrame | AuraFrame ) )
    ---
    --- The function used to setup child frames.
    ---
    setup = nil,
};

-----------------------------------------
--                 Private
-----------------------------------------

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Creates a new `VantageContainer`.
---
--- @param frame    EnemyFrame The parent to the container.
--- @param config   EnemyAuraConfig|EnemyDRConfig The configuration of the container.
--- @param create   fun( frame: EnemyFrame, container: VantageContainer ): EnemyDRFrame | AuraFrame The child frame creation function.
--- @param setup    fun( container: VantageContainer, frame: ( EnemyDRFrame | AuraFrame ) )         The child frame setup function.
--- @return VantageContainer|Frame
---
function Vantage.NewContainer( frame, config, create, setup )
    local container_frame   = CreateFrame( "Frame", nil, frame );
    local container         = Mixin( container_frame, VantageContainer );
    container:Initialize( frame, config, create, setup );
    return container;
end

---
--- Displays and applies all settings to the underlying child frames
--- of the container.
---
function VantageContainer:ApplyAllSettings()
    self:Display();
    for i = 1, #self.child_frames do
        self.child_frames[ i ]:ApplyChildFrameSettings();
    end
end

---
--- Displays active child frames and hides inactive child frames.
---
--- This function will set any child frames on the container to 
--- their new input. 
---
function VantageContainer:Display()

    -- TODO: can we optimize here?
    local config = self.config.Container;
    if not config then
        return;
    end

    local horizontal_spacing        = config.HorizontalSpacing;
    local vertical_spacing          = config.VerticalSpacing;
    local icon_size                 = config.IconSize;

    if config.UseButtonHeightAsSize then
        icon_size = self.parent_frame:GetHeight();
    end

    self:Show();

    local widestRow     = 0;
    local highestColumn = 0;
    local num_inputs    = #self.inputs;

    local pointX, offsetX, offsetY, pointY, offsetDirectionX, offsetDirectionY;

    if config.HorizontalGrowDirection == "leftwards" then
        pointX              = "RIGHT";
        offsetDirectionX    = -1;
    else
        pointX              = "LEFT";
        offsetDirectionX    = 1;
    end

    if config.VerticalGrowDirection == "upwards" then
        pointY              = "BOTTOM";
        offsetDirectionY    = 1;
    else
        pointY              = "TOP";
        offsetDirectionY    = -1;
    end

    local point     = pointY .. pointX;
    local column    = 1;
    local row       = 1;
    local child_frame;
    local row_width;
    local column_height;

    for i = 1, num_inputs do
        child_frame = self.child_frames[ i ];
        if not child_frame then
            child_frame             = self.create( self.parent_frame, self );
            self.child_frames[ i ]  = child_frame;
        end

        child_frame:SetSize( icon_size, icon_size );
        child_frame.key     = i;
        child_frame.input   = self.inputs[ i ];
        self.setup( self, child_frame );

        child_frame:ClearAllPoints();

        if column > 1 then
            offsetX     = ( column - 1 ) * ( icon_size + horizontal_spacing ) * offsetDirectionX;
            row_width   =  column * ( icon_size + horizontal_spacing ) - horizontal_spacing;
        else
            offsetX     = 0;
            row_width   = icon_size;
        end

        if row > 1 then
            offsetY         = ( row - 1 ) * ( icon_size + vertical_spacing ) * offsetDirectionY;
            column_height   = row * ( icon_size + vertical_spacing ) - vertical_spacing;
        else
            offsetY         = 0;
            column_height   = icon_size;
        end

        if row_width > widestRow then
            widestRow = row_width;
        end
        if column_height > highestColumn then
            highestColumn = column_height;
        end

        child_frame:SetPoint( point, self, point, offsetX, offsetY );
        child_frame:Show();

        if column < config.IconsPerRow then
            column  = column + 1;
        else
            row     = row + 1;
            column  = 1;
        end
    end

    --
    -- Hide all unused frames
    --
    for i = num_inputs + 1, #self.child_frames do
        local unused_frame = self.child_frames[ i ];
        unused_frame.input = nil;
        unused_frame:Hide();
    end

    --
    -- This same as widestRow == 0 and highestColumn == 0
    --
    if num_inputs == 0 then
        self:SetWidth( 0.01 );
        self:SetHeight( icon_size );
        self:Hide();
    else
        if widestRow == 0 then
            self:SetWidth( 0.01 );
        else
            self:SetWidth( widestRow );
        end

        if highestColumn == 0 then
            self:SetHeight( icon_size );
        else
            self:SetHeight( highestColumn );
        end
    end
end

---
---
---
--- @param attr     string
--- @param value    any
--- @return any?
---
function VantageContainer:FindInputByAttribute( attr, value )
    for i = 1, #self.inputs do
        if self.inputs[ i ][ attr ] == value then
            return self.inputs[ i ];
        end
    end
    return nil;
end

---
---
---
--- @param attr any
--- @param value any
--- @return AuraFrame?
---
function VantageContainer:FindChildFrameByAuraAttribute( attr, value )
    for i = 1, #self.child_frames do
        local child_frame = self.child_frames[ i ];
        if child_frame.input and child_frame.input[ attr ] == value then
            return child_frame;
        end
    end
    return nil;
end

---
--- Initializes the `VantageContainer`.
---
--- @param parent   EnemyFrame
--- @param config   EnemyAuraConfig | EnemyDRConfig
--- @param create   function
--- @param setup    function
---
function VantageContainer:Initialize( parent, config, create, setup )
    self.aura_heap      = Vantage.NewPriorityQueue( "max" );
    self.child_frames   = {};
    self.config         = {};
    self.create         = create;
    self.inputs         = {};
    self.parent_frame   = parent;
    self.setup          = setup;
    Vantage:Merge( self.config, config );
end

---
--- Stores new data to the container.
---
--- @param data (AuraData|VantageAura)|VantageDR
--- @return table
---
function VantageContainer:NewInput( data )
    local key = #self.inputs + 1;

    data.key            = key;
    self.inputs[ key ]  = data;

    --
    -- If we're storing a new aura, add it to the heap.
    --
    if data.priority then
        self.aura_heap:enqueue( data, data.priority );
    end

    return self.inputs[ key ];
end

---
--- Resets the miscellaneous data stored by the container.
---
function VantageContainer:ResetInputs()
    wipe( self.inputs );
    self.aura_heap:wipe();
end

---
--- Resets the input and display of the container.
---
function VantageContainer:Reset()
    self:ResetInputs();
    self:Display();
end

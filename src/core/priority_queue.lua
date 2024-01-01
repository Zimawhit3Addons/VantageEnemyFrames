------------------------------------------------------------------------------
---@script: priority_queue.lua
---@author: Ilya Kolbin (iskolbin@gmail.com)
---@desc:   This module implements a priority queue with indirect binary heap.
-------------------------------------------------------------------------------
--[[
PriorityQueue - v1.0.1 - public domain Lua priority queue
implemented with indirect binary heap
no warranty implied; use at your own risk

based on binaryheap library (github.com/iskolbin/binaryheap)

author: Ilya Kolbin (iskolbin@gmail.com)
url: github.com/iskolbin/priorityqueue

See documentation in README file.

COMPATIBILITY

Lua 5.1, 5.2, 5.3, LuaJIT 1, 2

LICENSE

This software is dual-licensed to the public domain and under the following
license: you are granted a perpetual, irrevocable license to copy, modify,
publish, and distribute this file as you see fit.
--]]

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
local floor         = math.floor
local setmetatable  = setmetatable

-----------------------------------------
--              Blizzard
-----------------------------------------
local Mixin         = Mixin

-----------------------------------------
--                Ace3
-----------------------------------------

---
--- @class Vantage : AceAddon
---
local Vantage = LibStub( "AceAddon-3.0" ):GetAddon( "Vantage" );

-------------------------------------------------------------------------------
--                                    Heap
-------------------------------------------------------------------------------

-----------------------------------------
--               Constants
-----------------------------------------

-----------------------------------------
--                 Types
-----------------------------------------

---
--- @class PriorityQueue
--- @field _items table<any, any>
--- @field _priorities number[]
--- @field _indices table<any, integer>
--- @field _size integer
--- @field _higherpriority fun( a, b ): boolean
---
local PriorityQueue = {};

---
--- @type metatable
---
local PriorityQueueMt =
{
    __len = PriorityQueue.len,
};

-----------------------------------------
--                 Private
-----------------------------------------

---
---
---
--- @param self PriorityQueue
--- @param from integer
--- @return integer
---
local function siftup( self, from )

    local items, priorities, indices, higherpriority = self._items, self._priorities, self._indices, self._higherpriority;

    local index     = from
    local parent    = floor( index / 2 )
    while index > 1 and higherpriority( priorities[ index ], priorities[ parent ] ) do
        priorities[ index ], priorities[ parent ] = priorities[ parent ], priorities[ index ];
        items[ index ], items[ parent ] = items[ parent ] , items[ index ];
        indices[ items[ index ] ], indices[ items[ parent ] ] = index, parent;
        index = parent;
        parent = floor( index / 2 );
    end
    return index;
end

---
---
---
--- @param self PriorityQueue
--- @param limit integer
---
local function siftdown( self, limit )
    local items, priorities, indices, higherpriority, size = self._items, self._priorities, self._indices, self._higherpriority, self._size;
    for index = limit, 1, -1 do
        local left  = index + index;
        local right = left + 1;
        while left <= size do
            local smaller = left;
            if right <= size and higherpriority( priorities[ right ], priorities[ left ] ) then
                smaller = right;
            end
            if higherpriority( priorities[ smaller ], priorities[ index ] ) then
                items[ index ], items[ smaller ] = items[ smaller ], items[ index ];
                priorities[ index ], priorities[ smaller ] = priorities[ smaller ], priorities[ index ];
                indices[ items[ index ] ], indices[ items[ smaller ] ] = index, smaller;
            else
                break;
            end
            index   = smaller;
            left    = index + index;
            right   = left + 1;
        end
    end
end

---
---
---
--- @param a any
--- @param b any
--- @return boolean
---
local function minishigher( a, b )
    return a < b;
end

---
---
---
--- @param a any
--- @param b any
--- @return boolean
---
local function maxishigher( a, b )
    return a > b;
end

-----------------------------------------
--                 Public
-----------------------------------------

---
--- Create new priority queue.
--- 
--- You can pass array to initialize queue with O(n) complexity 
--- (implemented with batchenq, see below). First argument also could be an
--- ordering function defining higher priority or you can simply pass "min" 
--- for min-heap( default behavior ) or "max" for max-heap (also array can 
--- contain higherpriority field).
---
--- @param priority_or_array any
--- @return PriorityQueue
---
function PriorityQueue.new( priority_or_array )

    local t                 = type( priority_or_array );
    local higherpriority    = minishigher;

    if t == 'table' then
        higherpriority = priority_or_array.higherpriority or higherpriority;
    elseif t == 'function' or t == 'string' then
        higherpriority = priority_or_array;
    elseif t ~= 'nil' then
        local msg = 'Wrong argument type to PriorityQueue.new, it must be table or function or string, has: %q';
        error( msg:format( t ) );
    end

    if type( higherpriority ) == 'string' then
        if higherpriority == 'min' then
            higherpriority = minishigher;
        elseif higherpriority == 'max' then
            higherpriority = maxishigher;
        else
            local msg = 'Wrong string argument to PriorityQueue.new, it must be "min" or "max", has: %q';
            error( msg:format( tostring( higherpriority ) ) );
        end
    end


    local self = setmetatable( Mixin( {
        _items = {},
        _priorities = {},
        _indices = {},
        _size = 0,
        _higherpriority = higherpriority or minishigher
    }, PriorityQueue ), PriorityQueueMt );

    if t == 'table' then
        self:batchenq( priority_or_array );
    end

    return self;
end

---
--- Enqueue the item with the priority to the heap. 
--- 
--- The priority must be comparable if you use builtin comparators, i.e. it 
--- must be either number or string or a table with metatable with __lt metamethod 
--- defined. Otherwise you have to define custom comparator. 
--- 
--- Time complexity is O(logn).
---
--- @param item any
--- @param priority number
--- @return PriorityQueue
---
function PriorityQueue:enqueue( item, priority )
    local items, priorities, indices = self._items, self._priorities, self._indices;
    if indices[ item ] then
        error( 'Item (' .. tostring( item ) .. ') ' .. tostring( indices[ item ] ) .. ' is already in the heap: ' .. tostring( self ) );
    end

    local size = self._size + 1;
    self._size = size;

    items[ size ], priorities[ size ], indices[ item ] = item, priority, size;
    siftup( self, size );

    return self
end

---
--- Removes the item from the heap. Returns true if item was in the heap 
--- and false otherwise.
---
--- This operation is O(logn).
---
--- @param item any
--- @return boolean
---
function PriorityQueue:remove( item )
    local index = self._indices[ item ];
    if index then
        local items, priorities, indices = self._items, self._priorities, self._indices;
        local size      = self._size;
        indices[ item ] = nil;
        if size == index then
            items[ size ], priorities[ size ] = nil, nil;
            self._size = size - 1;
        else
            local lastitem = items[ size ];
            items[ index ], priorities[ index ] = items[ size ], priorities[ size ];
            items[ size ], priorities[ size ]   = nil, nil;
            indices[ lastitem ] = index;
            size = size - 1;
            self._size = size;
            if size > 1 then
                siftdown( self, siftup( self, index ) );
            end
        end
        return true;
    end
    return false;
end

---
--- Checking that heap contains the item. 
---
--- This operation is O(1).
---
--- @param item any
--- @return boolean
---
function PriorityQueue:contains( item )
    return self._indices[ item ] ~= nil;
end

---
--- Changes item priority. Returns true if item was in the queue 
--- (even if priority not changed) and false otherwise. 
---
--- This operation is O(logn), internally it's just remove followed by enqueue.
---
---@param item any
---@param priority any
---@return boolean
function PriorityQueue:update( item, priority )
    local ok = self:remove( item );
    if ok then
        self:enqueue( item, priority );
    end
    return ok;
end

---
--- Dequeue from the heap. Returns item and associated priority. 
--- 
--- If the heap is empty then an error will raise. Returns an item with highest priority. 
---
--- Time complexity is O(logn). 
---
--- @return any
--- @return number?
---
function PriorityQueue:dequeue()

    local size = self._size;

    assert( size > 0, 'Heap is empty' );

    local items, priorities, indices = self._items, self._priorities, self._indices;
    local item, priority = items[ 1 ], priorities[ 1 ];
    indices[ item ] = nil;

    if size > 1 then
        local newitem = items[ size ];

        items[ 1 ], priorities[ 1 ] = newitem, priorities[ size ];
        items[ size ], priorities[ size ] = nil, nil;

        indices[ newitem ] = 1;
        size = size - 1;
        self._size = size;

        siftdown( self, 1 );
    else
        items[ 1 ], priorities[ 1 ] = nil, nil;
        self._size = 0;
    end

    return item, priority;
end

---
--- Returns the item with minimal priority and priority itself for BinaryMinHeap
--- (maximal for BinaryMaxHeap) or nil if the heap is empty.
---
--- @generic T
--- @return T?
--- @return number?
---
function PriorityQueue:peek()
	return self._items[ 1 ], self._priorities[ 1 ];
end

---
--- Returns items count. Also you can use # operator for the same effect.
---
--- @return integer
---
function PriorityQueue:len()
    return self._size;
end

---
--- Returns true if the heap has no items and false otherwise.
---
--- @return boolean
---
function PriorityQueue:empty()
	return self._size <= 0;
end

---
--- Efficiently enqueues list of item-priority pairs into the heap. 
--- Note that this is efficient only when the amount of inserting elements 
--- greater or equal than the current length. 
---
--- Time complexity of this operation is O(n)(sequential approach is O(nlogn)).
---
--- @param iparray any
---
function PriorityQueue:batchenq( iparray )
	local items, priorities, indices = self._items, self._priorities, self._indices;
	local size = self._size;
	for i = 1, #iparray, 2 do
		local item, priority = iparray[ i ], iparray[ i + 1 ];
		if indices[ item ] then
			error( 'Item ' .. tostring( indices[ item ] ) .. ' is already in the heap in queue: ' .. tostring( self ) );
		end
		size = size + 1;
		items[ size ], priorities[ size ] = item, priority;
		indices[ item ] = size;
	end
	self._size = size;
	if size > 1 then
		siftdown( self, floor( size / 2 ) );
	end
end

---
---
---
function PriorityQueue:wipe()
    wipe( self._items );
    wipe( self._indices );
    wipe( self._priorities );
    self._size = 0;
end

---
---
---
--- @return PriorityQueue
---
function Vantage.NewPriorityQueue( ... )
    return PriorityQueue.new( ... );
end

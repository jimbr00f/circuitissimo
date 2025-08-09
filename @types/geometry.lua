---@alias Point MapPosition.0
---@alias Delta MapPosition.0
---@alias RadialSize MapPosition.0

---@class Size
---@field width number
---@field height number

---@class PartitionShape
---@field shape SimpleShape
---@field item_shape SimpleShape
---@field item_count integer

---@class OrientableEntityFormation : PartitionShape
---@field origin OrientableOrigin
---@field path OrientablePath

---@alias DirectionMapping table<defines.direction, defines.direction[]>

---@class SimpleShape
---@field left_top MapPosition.0
---@field right_bottom MapPosition.0
---@field box BoundingBox.0
---@field size Size
---@field radius RadialSize

---@class OriginPoint
---@field point Point
---@field delta Delta

---@alias Path Point[]
---@alias OrientablePath table<defines.direction, Point[]>
---@alias OrientableOrigin table<defines.direction, OriginPoint>

---@enum orientation
orientation = {
    vertical = 1 --[[@as orientation.vertical ]],
    horizontal = 2 --[[@as orientation.horizontal ]],
}
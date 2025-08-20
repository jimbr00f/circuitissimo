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

---@alias DirectionMapping table<defines.direction, defines.direction[]>
---@alias OrientationMapping table<orientation, orientation[]>

---@class SimpleShape
---@field left_top MapPosition.0
---@field right_bottom MapPosition.0
---@field box BoundingBox.0
---@field size Size
---@field radius RadialSize

---@class Origin
---@field point Point
---@field delta Delta

---@class Path 
---@field points Point[]

---@enum axis
axis = {
    vertical = 1 --[[@as axis.vertical ]],
    horizontal = 2 --[[@as axis.horizontal ]],
}

---@enum orientation
orientation = {
    r0 = 1 --[[@as orientation.r0]],
    r1 = 1 --[[@as orientation.r1]],
    r2 = 1 --[[@as orientation.r2]],
    r3 = 1 --[[@as orientation.r3]],
    mr0 = 1 --[[@as orientation.mr0]],
    mr1 = 1 --[[@as orientation.mr1]],
    mr2 = 1 --[[@as orientation.mr2]],
    mr3 = 1 --[[@as orientation.mr3]],
}

---@class OrientedPath : Path
---@field orientation orientation

---@class OrientedOrigin : Origin
---@field orientation orientation

---@alias OrientablePath table<orientation, OrientedPath>

---@alias OrientableOrigin table<orientation, OrientedOrigin>
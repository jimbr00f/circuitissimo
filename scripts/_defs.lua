---@class Picture
---@field filename string
---@field width int
---@field height int
---@field scale float
---@field x int


---@class ProcInfo
---@field entity LuaEntity           @ Processor object
---@field iopoints IOPoint[]          @ List of connected IOPoint entities
---@field mirroring boolean
---@field tags Tags

---@class IOPoint
---@field entity LuaEntity

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

---@class OrientableLayout : PartitionShape
---@field origin OrientableOrigin

---@class OrientableLayoutInstance : OrientableLayout
---@field path OrientablePath

---@alias DirectionMapping table<defines.direction, defines.direction[]>

---@class SimpleShape
---@field left_top MapPosition.0
---@field right_bottom MapPosition.0
---@field size Size
---@field radius RadialSize

---@class OriginPoint
---@field point Point
---@field delta Delta

---@alias Path Point[]
---@alias OrientablePath table<defines.direction, Point[]>
---@alias OrientableOrigin table<defines.direction, OriginPoint>

---@class EventListener
---@field handlers table<string, fun(EventData)>
---@field subscriptions table<defines.events, fun(EventData)>
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

---@class IOPointLayout
---@field positions table<defines.direction, MapPosition[]>
---@field count integer
---@field dx float
---@field dy float
---@field rx float
---@field ry float

---@class EventListener
---@field handlers table<string, fun(EventData)>
---@field subscriptions table<defines.events, fun(EventData)>
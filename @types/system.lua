---@class Picture
---@field filename string
---@field width int
---@field height int
---@field scale float
---@field x int

---@class EventListener
---@field handlers table<string, fun(EventData)>
---@field subscriptions table<defines.events, fun(EventData)>
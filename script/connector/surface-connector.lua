---@class SurfaceConnector
local SurfaceConnector = {}
SurfaceConnector.__index = SurfaceConnector


---@return SurfaceConnector
function SurfaceConnector:new()
    local instance = {} --[[@as Processor]]
    setmetatable(instance, self)
    return instance
end

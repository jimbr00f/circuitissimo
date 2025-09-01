---@class SurfaceConnector
local SurfaceConnector = {}
SurfaceConnector.__index = SurfaceConnector

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return SurfaceConnector
function SurfaceConnector:new(factory, cid, cpos, outside_entity, inside_entity, settings)
    local instance = {} --[[@as Processor]]
    setmetatable(instance, self)
    return instance
end

---@param force LuaForce
---@return boolean
function SurfaceConnector.unlocked(force)
    return false
end

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return BuildingConnection
function SurfaceConnector.connect(factory, cid, cpos, outside_entity, inside_entity, settings)
    return {}
end

---@return boolean
function SurfaceConnector:recheck()
    return true
end


---@return connection_mode, defines.direction
function SurfaceConnector:direction()
    return connection_mode.d0, defines.direction.north
end


---@return string, boolean
function SurfaceConnector:rotate()
    return factorissimo.beep()
end

---@param positive boolean
---@return string, boolean?
function SurfaceConnector:adjust(positive)
    return factorissimo.beep()
end

function SurfaceConnector:destroy()
end

---@return integer?
function SurfaceConnector:tick()
    return nil
end

---@param delay integer?
function SurfaceConnector:make_valid_delay(delay)
    delay = delay or self.default_delay
    for _, v in pairs(self.valid_delays) do
        if v == delay then return v end
    end
    return 0 -- Catchall
end
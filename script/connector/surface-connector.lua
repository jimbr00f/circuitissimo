---@class SurfaceConnector
local SurfaceConnector = {}
SurfaceConnector.__index = SurfaceConnector


---@return SurfaceConnector
function SurfaceConnector:new()
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
---@return BuildingConnection
function SurfaceConnector.connect(factory, cid, cpos, outside_entity, inside_entity)
    return {}
end

---@param conn BuildingConnection
---@return boolean
function SurfaceConnector.recheck(conn)
    return true
end


---@param conn BuildingConnection
---@return connection_mode, defines.direction
function SurfaceConnector.direction(conn)
    return connection_mode.d0, defines.direction.north
end


---@param conn BuildingConnection
---@return string, boolean
function SurfaceConnector.rotate(conn)
    return factorissimo.beep()
end

---@param conn BuildingConnection
---@param positive boolean
---@return string, boolean?
function SurfaceConnector.adjust(conn, positive)
    return factorissimo.beep()
end

---@param conn BuildingConnection
function SurfaceConnector.destroy(conn)
end

---@param conn BuildingConnection
---@return integer?
function SurfaceConnector.tick(conn)
    return nil
end
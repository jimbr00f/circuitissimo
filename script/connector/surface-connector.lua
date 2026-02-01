---@class SurfaceConnector
local SurfaceConnector = {}
SurfaceConnector.__index = SurfaceConnector

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
---@return SurfaceConnection
function SurfaceConnector.connect(factory, cid, cpos, outside_entity, inside_entity, settings)
    return {}
end

---@param conn SurfaceConnection
---@return boolean
function SurfaceConnector:recheck(conn)
    return true
end

---@param conn SurfaceConnection
---@return connection_mode, defines.direction
function SurfaceConnector:direction(conn)
    return connection_mode.d0, defines.direction.north
end


---@param conn SurfaceConnection
---@return string, boolean
function SurfaceConnector:rotate(conn)
    return factorissimo.beep()
end

---@param positive boolean
---@return string, boolean?
function SurfaceConnector:adjust(positive)
    return factorissimo.beep()
end

---@param conn SurfaceConnection
function SurfaceConnector:destroy(conn)
end

---@param conn SurfaceConnection
---@return integer?
function SurfaceConnector:tick(conn)
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
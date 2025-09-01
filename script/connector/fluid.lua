require '@types.surface'
local SurfaceConnector = require 'surface-connector'

---@class FluidConnector : SurfaceConnector
local FluidConnector = setmetatable({}, { __index = SurfaceConnector })
FluidConnector.__index = FluidConnector

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings ConnectionSettings
---@return FluidConnector
function FluidConnector:new(factory, cid, cpos, outside_entity, inside_entity, settings)
    ---@type FluidConnector
    local instance = FluidConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    setmetatable(instance, self)
    return instance
end

FluidConnector.color = {r = 167 / 255, g = 229 / 255, b = 255 / 255}
FluidConnector.entity_types = {"pipe", "pipe-to-ground", "pump", "storage-tank", "infinity-pipe", "offshore-pump", "elevated-pipe"}
function FluidConnector.unlocked(force) return force.technologies["factory-connection-type-fluid"].researched end

function FluidConnector.recheck(conn)
    return conn.inside_connector.valid and conn.outside_connector.valid and conn.inside.valid and conn.outside.valid
end

FluidConnector.indicator_settings = {connection_mode.d0}

function FluidConnector.direction(conn)
    if conn._settings.input_mode then
        return connection_mode.d0, conn._factory.layout.connections[conn._id].direction_in
    else
        return connection_mode.d0, conn._factory.layout.connections[conn._id].direction_out
    end
end

function FluidConnector.rotate(conn)
    conn._settings.input_mode = not conn._settings.input_mode

    if conn.inside_connector and conn.inside_connector.valid then
        conn.inside_connector.destroy()
    end
    if conn.outside_connector and conn.outside_connector.valid then
        conn.outside_connector.destroy()
    end

    local cpos = conn._factory.layout.connections[conn._id]
    conn.inside_connector, conn.outside_connector = FluidConnector._create_linked_connections(conn._factory, cpos, conn._settings)

    if conn._settings.input_mode then
        return {"factory-connection-text.input-mode"}
    else
        return {"factory-connection-text.output-mode"}
    end
end

---@param conn BuildingConnection
---@return string, boolean
function FluidConnector.adjust(conn)
    return factorissimo.beep()
end


function FluidConnector.destroy(conn)
    if conn.outside_connector.valid then conn.outside_connector.destroy() end
    if conn.inside_connector.valid then conn.inside_connector.destroy() end
end

function FluidConnector.tick() end

---@param factory Factory
---@param cpos ConnectionPosition
---@param settings ConnectionSettings
function FluidConnector._create_linked_connections(factory, cpos, settings)
    local inside_surface = factory.inside_surface
    local outside_surface = factory.outside_surface

    local inside_position = {factory.inside_x + cpos.inside_x + cpos.indicator_dx, factory.inside_y + cpos.inside_y + cpos.indicator_dy}
    local outside_position = {factory.outside_x + cpos.outside_x - cpos.indicator_dx, factory.outside_y + cpos.outside_y - cpos.indicator_dy}

    local inside_flow_direction, outside_flow_direction = "input", "output"
    if settings.input_mode then
        inside_flow_direction, outside_flow_direction = outside_flow_direction, inside_flow_direction
    end

    local inside_connector = inside_surface.create_entity {
        name = "factory-inside-pump-" .. inside_flow_direction,
        position = inside_position,
        direction = cpos.direction_in,
        quality = factory.quality,
    }
    if not inside_connector then
        error('Failed to create inside_connector for fluid connector.')
     end
    inside_connector.destructible = false
    inside_connector.operable = false
    inside_connector.rotatable = false

    local outside_connector = outside_surface.create_entity {
        name = "factory-outside-pump-" .. outside_flow_direction,
        position = outside_position,
        direction = cpos.direction_out,
        quality = factory.quality,
    }
    if not outside_connector then
        error('Failed to create outside_connector for fluid connector.')
    end
    outside_connector.destructible = false
    outside_connector.operable = false
    outside_connector.rotatable = false

    inside_connector.fluidbox.add_linked_connection(0, outside_connector, 0)

    return inside_connector, outside_connector
end

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings ConnectionSettings
---@return table
function FluidConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    if inside_entity == outside_entity then 
        error('Inside and outside entities must be distinct.')
    end

    local inside_connector, outside_connector = FluidConnector._create_linked_connections(factory, cpos, settings)

    return {
        inside = inside_entity,
        outside = outside_entity,
        inside_connector = inside_connector,
        outside_connector = outside_connector,
        do_tick_update = false
    }
end

return FluidConnector

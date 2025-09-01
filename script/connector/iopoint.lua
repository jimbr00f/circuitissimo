require '@types.surface'
local Formation = require 'lib.formation.formation'
local SurfaceConnector = require 'surface-connector'

---@class IoPointConnector : SurfaceConnector
local IoPointConnector = setmetatable({}, { __index = SurfaceConnector })
IoPointConnector.__index = IoPointConnector

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return IoPointConnector
function IoPointConnector:new(factory, cid, cpos, outside_entity, inside_entity, settings)
    ---@type IoPointConnector
    local instance = IoPointConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    setmetatable(instance, self)
    return instance
end

function IoPointConnector.unlocked(force) 
    return force.technologies["factory-connection-type-circuit"].researched
end

-- return true if the two poles are connected to each other
function IoPointConnector:recheck()
    local pole_1 = conn.inside_entity
    local pole_2 = conn.outside_entity

    if not pole_1 or not pole_2 then return false end
    if not pole_1.valid or not pole_2.valid then return false end

    local wire_counter = 0
    for _, connector_type in pairs {
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green,
    } do
        local connector_1 = pole_1.get_wire_connector(connector_type, true)
        local connector_2 = pole_2.get_wire_connector(connector_type, true)
        if connector_1.network_id == connector_2.network_id then wire_counter = wire_counter + 1 end
    end
    return wire_counter == 2
end

function IoPointConnector:direction()
    return connection_mode.b0, defines.direction.north
end

function IoPointConnector.rotate()
    return factorissimo.beep()
end

function IoPointConnector.adjust()
    return factorissimo.beep()
end

function IoPointConnector:destroy()
    if conn.inside_middleman and conn.inside_middleman.valid then conn.inside_middleman.destroy() end
    if conn.outside_middleman and conn.outside_middleman.valid then conn.outside_middleman.destroy() end
end

function IoPointConnector._connect_two_poles_with_circuit_wires(pole_1, pole_2)
    for _, connector_type in pairs {
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green,
    } do
        local connector_1 = pole_1.get_wire_connector(connector_type, true)
        local connector_2 = pole_2.get_wire_connector(connector_type, true)
        connector_1.connect_to(connector_2, false, defines.wire_origin.script)
    end
end

local expected_entity_name = "factory-circuit-connector"

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return IoPointConnector
function IoPointConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    if outside_entity.name ~= "factory-circuit-connector" then
        error(string.format('Could not create BeltConnector instance: bad outside entity "%s" (expected %s).', outside_entity.name, expected_entity_name))
    end
    if outside_entity.name ~= "factory-circuit-connector" or inside_entity.name ~= "factory-circuit-connector" then
        error(string.format('Could not create BeltConnector instance: bad inside entity "%s" (expected %s).', inside_entity.name, expected_entity_name))
    end

    local inside_middleman = inside_entity.surface.create_entity {
        name = "factory-circuit-connector-invisible",
        position = inside_entity.position,
        force = inside_entity.force,
    }
    inside_middleman.destructible = false
    inside_middleman.operable = false
    IoPointConnector._connect_two_poles_with_circuit_wires(inside_entity, inside_middleman)

    local outside_middleman = outside_entity.surface.create_entity {
        name = "factory-circuit-connector-invisible",
        position = outside_entity.position,
        force = outside_entity.force,
    }
    outside_middleman.destructible = false
    outside_middleman.operable = false
    IoPointConnector._connect_two_poles_with_circuit_wires(outside_entity, outside_middleman)

    IoPointConnector._connect_two_poles_with_circuit_wires(inside_middleman, outside_middleman)

    return {
        inside_entity = inside_entity,
        inside_middleman = inside_middleman,
        outside_entity = outside_entity,
        outside_middleman = outside_middleman,
        do_tick_update = false,
    }
end


function IoPointConnector._initialize_static()
    IoPointConnector.color = {r = 255 / 255, g = 61 / 255, b = 61 / 255}
    IoPointConnector.entity_types = {"factory-circuit-connector"}
    IoPointConnector.indicator_settings = {connection_mode.b0}
end

IoPointConnector._initialize_static()

return IoPointConnector

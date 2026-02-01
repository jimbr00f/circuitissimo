require '@types.surface'
local SurfaceConnector = require 'surface-connector'

---@class CircuitConnector : SurfaceConnector
local CircuitConnector = setmetatable({}, { __index = SurfaceConnector })
CircuitConnector.__index = CircuitConnector


---@return CircuitConnector
function CircuitConnector:new()
    local instance = SurfaceConnector.new(self) --[[@as CircuitConnector]]
    setmetatable(instance, self)
    return instance
end

function CircuitConnector.unlocked(force) 
    return force.technologies["factory-connection-type-circuit"].researched
end

-- return true if the two poles are connected to each other
---@param conn SurfaceConnection
function CircuitConnector:recheck(conn)
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



function CircuitConnector:direction()
    return connection_mode.b0, defines.direction.north
end

function CircuitConnector.rotate()
    return factorissimo.beep()
end

function CircuitConnector.adjust()
    return factorissimo.beep()
end

---@param conn SurfaceConnection
function CircuitConnector:destroy(conn)
    if conn.inside_middleman and conn.inside_middleman.valid then conn.inside_middleman.destroy() end
    if conn.outside_middleman and conn.outside_middleman.valid then conn.outside_middleman.destroy() end
end

function CircuitConnector._connect_two_poles_with_circuit_wires(pole_1, pole_2)
    for _, connector_type in pairs {
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green,
    } do
        local connector_1 = pole_1.get_wire_connector(connector_type, true)
        local connector_2 = pole_2.get_wire_connector(connector_type, true)
        connector_1.connect_to(connector_2, false, defines.wire_origin.script)
    end
end

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return CircuitConnector
function CircuitConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
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
    CircuitConnector._connect_two_poles_with_circuit_wires(inside_entity, inside_middleman)

    local outside_middleman = outside_entity.surface.create_entity {
        name = "factory-circuit-connector-invisible",
        position = outside_entity.position,
        force = outside_entity.force,
    }
    outside_middleman.destructible = false
    outside_middleman.operable = false
    CircuitConnector._connect_two_poles_with_circuit_wires(outside_entity, outside_middleman)

    CircuitConnector._connect_two_poles_with_circuit_wires(inside_middleman, outside_middleman)

    return {
        inside_entity = inside_entity,
        inside_middleman = inside_middleman,
        outside_entity = outside_entity,
        outside_middleman = outside_middleman,
        do_tick_update = false,
    }
end

function CircuitConnector._initialize_static()
    CircuitConnector.color = {r = 255 / 255, g = 61 / 255, b = 61 / 255}
    CircuitConnector.entity_types = {"factory-circuit-connector"}
    CircuitConnector.indicator_settings = {connection_mode.b0}
end

CircuitConnector._initialize_static()

return CircuitConnector

require '@types.surface'
local SurfaceConnector = require 'surface-connector'

---@class HeatConnector : SurfaceConnector
local HeatConnector = setmetatable({}, { __index = SurfaceConnector })
HeatConnector.__index = HeatConnector

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return HeatConnector
function HeatConnector:new(factory, cid, cpos, outside_entity, inside_entity, settings)
    ---@type HeatConnector
    local instance = HeatConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    setmetatable(instance, self)
    return instance
end

function HeatConnector.unlocked(force) return force.technologies["factory-connection-type-heat"].researched end

function HeatConnector:recheck()
    return conn.outside.valid and conn.inside.valid and conn.inside_link.valid and conn.outside_link.valid
end

function HeatConnector:direction(conn)
    return connection_mode['b' .. self:make_valid_delay(conn._settings.delay or self.default_delay)], defines.direction.north
end


---@return string, boolean
function HeatConnector:rotate()
    return factorissimo.beep()
end

---@return string, boolean
function HeatConnector:adjust(conn, positive)
    local delay = (conn._settings.delay or self.default_delay)
    if positive then
        for i = #self.valid_delays, 1, -1 do
            if self.valid_delays[i] < delay then
                delay = self.valid_delays[i]
                break
            end
        end
        conn._settings.delay = delay
        return "factory-connection-text.update-faster", (not not delay)
    else
        for i = 1, #self.valid_delays do
            if self.valid_delays[i] > delay then
                delay = self.valid_delays[i]
                break
            end
        end
        conn._settings.delay = delay
        return "factory-connection-text.update-slower", (not not delay)
    end
end

function HeatConnector:tick(conn)
    local outside = conn.outside
    local inside = conn.inside
    if not outside.valid or not inside.valid then return false end

    local temp_1, temp_2 = outside.temperature, inside.temperature
    if temp_1 == temp_2 then return conn._settings.delay or self.default_delay end

    local average_temp = (temp_1 + temp_2) / 2
    local max_temp_1 = outside.prototype.heat_buffer_prototype.max_temperature
    local max_temp_2 = inside.prototype.heat_buffer_prototype.max_temperature

    if max_temp_1 < average_temp then
        outside.temperature = max_temp_1
        inside.temperature = temp_2 - (max_temp_1 - temp_1)
    elseif max_temp_2 < average_temp then
        inside.temperature = max_temp_2
        outside.temperature = temp_1 - (max_temp_2 - temp_2)
    else
        outside.temperature = average_temp
        inside.temperature = average_temp
    end

    return conn._settings.delay or self.default_delay
end

function HeatConnector:destroy()
    if conn.outside_link.valid then conn.outside_link.destroy() end
    if conn.inside_link.valid then conn.inside_link.destroy() end
end

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
---@param outside_entity LuaEntity
---@param inside_entity LuaEntity
---@param settings? ConnectionSettings
---@return HeatConnector
function HeatConnector._initialize(factory, cid, cpos, outside_entity, inside_entity, settings)
    local inside_link = inside_entity.surface.create_entity {
        name = "factory-heat-dummy-connector",
        position = {factory.inside_x + cpos.inside_x + cpos.indicator_dx, factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        create_build_effect_smoke = false,
        raise_built = false,
        force = inside_entity.force
    }
    inside_link.destructible = false
    inside_link.active = false

    local outside_link = outside_entity.surface.create_entity {
        name = "factory-heat-dummy-connector",
        position = {outside_entity.position.x - cpos.indicator_dx, outside_entity.position.y - cpos.indicator_dy},
        create_build_effect_smoke = false,
        raise_built = false,
        force = outside_entity.force
    }
    outside_link.destructible = false
    outside_link.active = false

    return {
        outside = outside_entity,
        outside_link = outside_link,
        inside_link = inside_link,
        inside = inside_entity,
        do_tick_update = true
    }
end

function HeatConnector._initialize_static()
    HeatConnector.color = {r = 228 / 255, g = 236 / 255, b = 0}
    HeatConnector.entity_types = {"heat-pipe"}
    HeatConnector.valid_delays = {5, 10, 30, 120}
    HeatConnector.default_delay = 30

    HeatConnector.indicator_settings = {connection_mode.d0, connection_mode.b0}
    for _, v in pairs(HeatConnector.valid_delays) do
        local balance_mode = connection_mode['b' .. v]
        table.insert(HeatConnector.indicator_settings, balance_mode)
    end
end

HeatConnector._initialize_static()

return HeatConnector

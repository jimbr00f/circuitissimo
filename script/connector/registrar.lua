---@alias EntityId string
---@alias SurfaceConnectorId string
---@alias SurfaceConnectorEntityMap table<EntityId,SurfaceConnectorId>

---@class SurfaceConnectionRegistrar
local SurfaceConnectionRegistrar = {
    ---@type SurfaceConnectorEntityMap
    type_map = {},
    ---@type table<string,SurfaceConnector>
    connectors = {}
}

local connection_indicator_names = {}
factorissimo.connection_indicator_names = connection_indicator_names

---@param surface LuaSurface
---@param position MapPosition
---@return Factory?
function SurfaceConnectionRegistrar:find_surrounding_factory(surface, position)
    local factory = remote_api.find_surrounding_factory(surface, position)
    if not factory then return nil end
    for _, conn in pairs(factory.connections) do
        local class = self.connectors[conn._type]
        setmetatable(conn, class)
    end
    return factory
end


---@param ctype ConnectionType
---@param class SurfaceConnector
function SurfaceConnectionRegistrar:register_connection_type(ctype, class)
    self.connectors[ctype] = class
    for _, etype in pairs(class.entity_types) do
        self.type_map[etype] = ctype
    end
    for _, cmode in pairs(class.indicator_settings) do
        local name = connection_mode_names[cmode]
        connection_indicator_names["factory-connection-indicator-" .. ctype .. "-" .. name] = ctype
    end
end

---@param entity LuaEntity
---@return boolean
function SurfaceConnectionRegistrar:is_connectable(entity)
    return self.type_map[entity.type] ~= nil or self.type_map[entity.name] ~= nil
end

-- Connection data structure --

local CYCLIC_BUFFER_SIZE = 600
factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.connections = storage.connections or {}
    storage.delayed_connection_checks = storage.delayed_connection_checks or {}
    for i = 0, CYCLIC_BUFFER_SIZE - 1 do
        storage.connections[i] = storage.connections[i] or {}
    end
end)

---@param conn SurfaceConnection
function SurfaceConnectionRegistrar:add_connection_to_queue(conn)
    local current_pos = (math.floor(game.tick / CONNECTION_UPDATE_RATE) + 1) * CONNECTION_UPDATE_RATE % CYCLIC_BUFFER_SIZE
    table.insert(storage.connections[current_pos], conn)
end

-- Connection settings --

---@param factory Factory
---@param cid ConnectionId
---@param ctype ConnectionType
---@return ConnectionSettings
function SurfaceConnectionRegistrar:get_connection_settings(factory, cid, ctype)
    factory.connection_settings[cid] = factory.connection_settings[cid] or {}
    factory.connection_settings[cid][ctype] = factory.connection_settings[cid][ctype] or {}
    return factory.connection_settings[cid][ctype]
end

-- Connection indicators --

---@param factory Factory
---@param cid ConnectionId
---@param ctype ConnectionType
---@param cmode connection_mode
---@param dir defines.direction
function SurfaceConnectionRegistrar:set_connection_indicator(factory, cid, ctype, cmode, dir)
    local old_indicator = factory.connection_indicators[cid]
    if old_indicator and old_indicator.valid then old_indicator.destroy() end
    local cpos = factory.layout.connections[cid]
    local cmode_name = connection_mode_names[cmode]
    local new_indicator = factory.inside_surface.create_entity {
        name = "factory-connection-indicator-" .. ctype .. "-" .. cmode_name,
        force = factory.force,
        position = {x = factory.inside_x + cpos.inside_x + cpos.indicator_dx, y = factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        create_build_effect_smoke = false,
        direction = dir,
        quality = factory.quality
    }
    new_indicator.destructible = false
    factory.connection_indicators[cid] = new_indicator
end

function SurfaceConnectionRegistrar:delete_connection_indicator(factory, cid, ctype)
    local old_indicator = factory.connection_indicators[cid]
    if old_indicator and old_indicator.valid then old_indicator.destroy() end
end

-- Connection changes --

---@param factory Factory
---@param cid string
---@param ctype string
---@param conn SurfaceConnection
---@param settings ConnectionSettings
function SurfaceConnectionRegistrar:register_connection(factory, cid, ctype, conn, settings)
    conn._id = cid
    conn._type = ctype
    conn._factory = factory
    conn._settings = settings
    conn._valid = true
    factory.connections[cid] = conn
    if conn.do_tick_update then self:add_connection_to_queue(conn) end
    local connector = self.connectors[ctype]
    local setting, dir = connector:direction(conn)
    self:set_connection_indicator(factory, cid, ctype, setting, dir)
end

---@param factory Factory
---@param cid ConnectionId
---@param cpos ConnectionPosition
function SurfaceConnectionRegistrar:init_connection(factory, cid, cpos) -- Only call this when factory.connections[cid] == nil!
    if not factory.outside_surface.valid then return end
    if not factory.inside_surface.valid then return end

    local outside_entities = factory.outside_surface.find_entities_filtered {
        position = {cpos.outside_x + factory.outside_x, cpos.outside_y + factory.outside_y},
        force = factory.force
    }
    if outside_entities == nil or not outside_entities[1] then return end

    local inside_entities = factory.inside_surface.find_entities_filtered {
        position = {cpos.inside_x + factory.inside_x, cpos.inside_y + factory.inside_y},
        force = factory.force
    }
    if inside_entities == nil or not inside_entities[1] then return end

    for _, outside_entity in pairs(outside_entities) do
        local oct = self.type_map[outside_entity.type] or self.type_map[outside_entity.name]
        if oct ~= nil then
            for _, inside_entity in pairs(inside_entities) do
                local ict = self.type_map[inside_entity.type] or self.type_map[inside_entity.name]
                if oct == ict then
                    local cls = self.connectors[oct]
                    if cls:unlocked(factory.force) then
                        local settings = self:get_connection_settings(factory, cid, oct)
                        local conn = cls.connect(factory, cid, cpos, outside_entity, inside_entity, settings)
                        if conn then
                            factory.inside_surface.play_sound {path = "entity-close/assembling-machine-3", position = inside_entity.position}
                            factory.outside_surface.play_sound {path = "entity-close/assembling-machine-3", position = outside_entity.position}
                            self:register_connection(factory, cid, oct, conn, settings)
                            return
                        end
                    else
                        factorissimo.create_flying_text {position = inside_entity.position, text = {"research-required"}}
                        factorissimo.create_flying_text {position = outside_entity.position, text = {"research-required"}}
                    end
                end
            end
        end
    end
end

---@param conn SurfaceConnection
function SurfaceConnectionRegistrar:destroy_connection(conn)
    if conn._valid then
        local connector = self.connectors[conn._type]
        connector:destroy(conn)
        conn._valid = false                       -- _valid should be true iff conn._factory.connections[conn._id] == conn
        conn._factory.connections[conn._id] = nil -- Lua can handle this
        self:delete_connection_indicator(conn._factory, conn._id, conn._type)
    end
end

---@param x number
---@param y number
---@param area BoundingBox
function SurfaceConnectionRegistrar:in_area(x, y, area)
    return x >= area.left_top.x and x <= area.right_bottom.x and y >= area.left_top.y and y <= area.right_bottom.y
end

---@param factory Factory
---@param outside_area? BoundingBox
---@param inside_area? BoundingBox
function SurfaceConnectionRegistrar:recheck_factory_connections(factory, outside_area, inside_area) -- Areas are optional
    if not factory.built then return end
    for cid, cpos in pairs(factory.layout.connections) do
        if outside_area and not self:in_area(cpos.outside_x + factory.outside_x, cpos.outside_y + factory.outside_y, outside_area) then goto continue end
        if inside_area and not self:in_area(cpos.inside_x + factory.inside_x, cpos.inside_y + factory.inside_y, inside_area) then goto continue end

        local conn = factory.connections[cid]
        local connector = self.connectors[conn._type]
        if conn then
            if connector:recheck(conn) then
                -- Everything is fine
            else
                self:destroy_connection(conn)
                self:init_connection(factory, cid, cpos)
            end
        else
            self:init_connection(factory, cid, cpos)
        end

        ::continue::
    end
end

-- During deconstruction events of an entity that is part of a connection, the entity is still valid and built, so recheck_factory_connections would not destroy the connection involved.
-- Delaying the recheck causes these connections to be properly deconstructed immediately, instead of having to wait until the connection ticks again.
---@param factory Factory
---@param outside_area? BoundingBox
---@param inside_area? BoundingBox
function SurfaceConnectionRegistrar:recheck_factory_connections_delayed(factory, outside_area, inside_area)
    storage.delayed_connection_checks[1 + #(storage.delayed_connection_checks)] = {
        factory = factory,
        outside_area = outside_area,
        inside_area = inside_area
    }
end

function SurfaceConnectionRegistrar:disconnect_factory_connections(factory)
    for _, conn in pairs(factory.connections) do
        self:destroy_connection(conn)
    end
end

---@param box1_shift Vector
---@param box1 BoundingBox
---@param box2 BoundingBox
function SurfaceConnectionRegistrar:aabb_collision(box1_shift, box1, box2)
    local x_shift, y_shift = box1_shift.x, box1_shift.y
    return not (
        x_shift + box1.right_bottom.x < box2.left_top.x or -- box1 is to the left of box2
        box2.right_bottom.x < x_shift + box1.left_top.x or -- box2 is to the left of box1
        y_shift + box1.right_bottom.y < box2.left_top.y or -- box1 is above box2
        box2.right_bottom.y < y_shift + box1.left_top.y    -- box2 is above box1
    )
end

-- When a connection piece is placed or destroyed, check if can be connected to a factory building
---@param entity LuaEntity
---@param delayed? boolean
function SurfaceConnectionRegistrar:recheck_nearby_connections(entity, delayed)
    local surface = entity.surface
    local pos = entity.position

    local collision_box = entity.prototype.collision_box
    if orientation == 0 then        -- north
        -- collision_box is fine
    elseif orientation == 0.5 then  -- south
        collision_box.left_top.y, collision_box.right_bottom.y = -collision_box.right_bottom.y, -collision_box.left_top.y
    elseif orientation == 0.25 then -- east
        collision_box.left_top.y, collision_box.left_top.x, collision_box.right_bottom.x, collision_box.right_bottom.y = -collision_box.right_bottom.x, -collision_box.right_bottom.y, -collision_box.left_top.y, -collision_box.left_top.x
    elseif orientation == 0.75 then -- west
        collision_box.left_top.y, collision_box.right_bottom.y = -collision_box.right_bottom.y, -collision_box.left_top.y
        collision_box.left_top.y, collision_box.left_top.x, collision_box.right_bottom.x, collision_box.right_bottom.y = -collision_box.right_bottom.x, -collision_box.right_bottom.y, -collision_box.left_top.y, -collision_box.left_top.x
    end

    -- Expand collision box to grid-aligned
    collision_box.left_top.x = math.floor(collision_box.left_top.x)
    collision_box.left_top.y = math.floor(collision_box.left_top.y)
    collision_box.right_bottom.x = math.ceil(collision_box.right_bottom.x)
    collision_box.right_bottom.y = math.ceil(collision_box.right_bottom.y)

    -- Expand box to catch factories and also avoid illegal zero-area finds
    local bounding_box = {
        left_top = {x = pos.x - 0.3 + collision_box.left_top.x, y = pos.y - 0.3 + collision_box.left_top.y},
        right_bottom = {x = pos.x + 0.3 + collision_box.right_bottom.x, y = pos.y + 0.3 + collision_box.right_bottom.y}
    }

    for _, factory in pairs(storage.factories) do
        local building = factory.building
        if factory.built and factory.outside_surface == surface and building.valid and self:aabb_collision(building.position, building.prototype.collision_box, bounding_box) then
            if delayed then
                self:recheck_factory_connections_delayed(factory, bounding_box, nil)
            else
                self:recheck_factory_connections(factory, bounding_box, nil)
            end
            break
        end
    end

    local factory = self:find_surrounding_factory(surface, pos)
    if factory then
        if delayed then
            self:recheck_factory_connections_delayed(factory, nil, bounding_box)
        else
            self:recheck_factory_connections(factory, nil, bounding_box)
        end
    end
end

function SurfaceConnectionRegistrar:register_events()
    factorissimo.on_event(factorissimo.events.on_destroyed(), function(event)
        local entity = event.entity
        if entity.valid and self:is_connectable(entity) then
            self:recheck_nearby_connections(entity, true) -- Delay
        end
    end)

    factorissimo.on_event(factorissimo.events.on_built(), function(event)
        local entity = event.entity
        if not entity.valid or not self:is_connectable(entity) then return end
        local entity_name = entity.name

        if entity_name == "factory-circuit-connector" then
            entity.operable = false
        else
            local _, _, pipe_name_input = entity_name:find("^factory%-(.*)%-input$")
            local _, _, pipe_name_output = entity_name:find("^factory%-(.*)%-output$")
            local pipe_name = pipe_name_input or pipe_name_output
            if pipe_name then entity = remote_api.replace_entity(entity, pipe_name) end
        end

        self:recheck_nearby_connections(entity)
    end)

    -- Connection effects --

    CONNECTION_UPDATE_RATE = 5
    factorissimo.on_nth_tick(CONNECTION_UPDATE_RATE, function()
        -- First let's run all them delayed connection checks
        for _, check in pairs(storage.delayed_connection_checks) do
            self:recheck_factory_connections(check.factory, check.outside_area, check.inside_area)
        end
        storage.delayed_connection_checks = {}

        local current_pos = game.tick % CYCLIC_BUFFER_SIZE
        local connections = storage.connections
        local current_slot = connections[current_pos]
        connections[current_pos] = {}
        for _, conn in pairs(current_slot) do
            local connector = self.connectors[conn._type]
            local delay = conn._valid and connector:tick(conn)
            if delay then
                -- Reinsert connection after delay
                -- Not checking for inappropriate delays, so keep your delays civil
                local queue_pos = (current_pos + delay) % CYCLIC_BUFFER_SIZE
                local new_slot = connections[queue_pos]
                new_slot[1 + #new_slot] = conn
            elseif conn._valid then
                self:destroy_connection(conn)
                self:init_connection(conn._factory, conn._id, conn._factory.layout.connections[conn._id])
            end
        end
    end)


    factorissimo.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
        if not storage.factories then return end -- In case any mod or scenario script calls LuaForce.research_all_technologies() during its on_init
        if event.research.name:find("factory%-connection%-type%-") then
            for _, factory in pairs(storage.factories) do
                if factory.built then self:recheck_factory_connections(factory) end
            end
        end
    end)

    factorissimo.on_event("factory-rotate", function(event)
        local player = game.get_player(event.player_index)
        if not player then return end
        local indicator = player.selected
        if not indicator or not factorissimo.connection_indicator_names[indicator.name] then return end
        local factory = remote_api.find_surrounding_factory(indicator.surface, indicator.position)
        if not factory then return end
        self:rotate(factory, indicator)
    end)

    factorissimo.on_event(defines.events.on_player_flipped_entity, function(event)
        local entity = event.entity
        if not factorissimo.connection_indicator_names[entity.name] then return end
        entity.mirroring = false
        local factory = remote_api.find_surrounding_factory(entity.surface, entity.position)
        if not factory then return end
        self:rotate(factory, entity)
    end)

    factorissimo.on_event(defines.events.on_player_rotated_entity, function(event)
        local entity = event.entity
        if factorissimo.connection_indicator_names[entity.name] then
            entity.direction = event.previous_direction
        elseif self:is_connectable(entity) then
            self:recheck_nearby_connections(entity)
            if entity.valid and entity.type == "underground-belt" then
                local neighbour = entity.neighbours
                if neighbour then
                    self:recheck_nearby_connections(neighbour)
                end
            end
        end
    end)

    factorissimo.on_event("factory-increase", function(event)
        local entity = game.get_player(event.player_index).selected
        if not entity then return end
        if factorissimo.connection_indicator_names[entity.name] then
            local factory = self:find_surrounding_factory(entity.surface, entity.position)
            if factory then self:adjust(factory, entity, true) end
        end
    end)

    factorissimo.on_event("factory-decrease", function(event)
        local entity = game.get_player(event.player_index).selected
        if not entity then return end
        if factorissimo.connection_indicator_names[entity.name] then
            local factory = self:find_surrounding_factory(entity.surface, entity.position)
            if factory then self:adjust(factory, entity, false) end
        end
    end)

end

---@param factory Factory 
---@param indicator LuaEntity
function SurfaceConnectionRegistrar:rotate(factory, indicator)
    for cid, ind2 in pairs(factory.connection_indicators) do
        if ind2 and ind2.valid then
            if (ind2.unit_number == indicator.unit_number) then
                local conn = factory.connections[cid]
                local cls = SurfaceConnectionRegistrar.connectors[conn._type]
                local text, noop = cls:rotate(conn)
                factorissimo.create_flying_text {position = indicator.position, color = self.connectors[conn._type].color, text = text}
                if noop then return end
                local connector = self.connectors[conn._type]
                local setting, dir = connector:direction(conn)
                self:set_connection_indicator(factory, cid, conn._type, setting, dir)
                return
            end
        end
    end
end


---@param factory Factory
---@param indicator LuaEntity
---@param positive boolean
function SurfaceConnectionRegistrar:adjust(factory, indicator, positive)
    for cid, ind2 in pairs(factory.connection_indicators) do
        if ind2 and ind2.valid then
            if (ind2.unit_number == indicator.unit_number) then
                local conn = factory.connections[cid]
                local connector = self.connectors[conn._type]
                local text, noop = connector:adjust(conn, positive)
                factorissimo.create_flying_text {position = indicator.position, text = text}
                if noop then return end
                local setting, dir = connector:direction(conn)
                self:set_connection_indicator(factory, cid, conn._type, setting, dir)
                return
            end
        end
    end
end

local beeps = {"Beep", "Boop", "Beep", "Boop", "Beeple"}
factorissimo.beep = function()
    local t = game.tick
    return beeps[t % 5 + 1], true
end

function SurfaceConnectionRegistrar:init()
    self:register_connection_type("belt", require("belt"))
    self:register_connection_type("chest", require("chest"))
    self:register_connection_type("fluid", require("fluid"))
    self:register_connection_type("circuit", require("circuit"))
    self:register_connection_type("heat", require("heat"))
end

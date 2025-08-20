local Formation = require "lib.formation"
local processor = require "scripts.processor.processor"
local exports = {}

local wire_types = { 
    defines.wire_connector_id.circuit_red, 
    defines.wire_connector_id.circuit_green 
}

---@param procinfo Processor
local function update_connections(procinfo)
    -- TODO: invoke Factorissimo connection builders
end

---@param info IoPoint
---@return IoPointWireConnection[]
local function get_iopoint_connections(info)
    ---@type IoPointWireConnection[]
    local connections = {}
    if not info.entity.valid then return connections end
    local source_connectors = info.entity.get_wire_connectors(false)
    for source_id, source_connector in pairs(source_connectors) do
        for i, connection in ipairs(source_connector.connections) do
            local dest_name = connection.target.owner.name
            if dest_name == "ghost-entity" then
                dest_name = connection.target.owner.ghost_name
            end
            local conn = {
                source_connector_id = source_id,
                target_connector_id = connection.target.wire_connector_id,
                target_unit_number = connection.target.owner.unit_number,
            } --[[@as IoPointWireConnection]]
            store_entity(connection.target.owner)
            game.print('iopoint#' .. tostring(info.index) .. ': creating conn #' .. tostring(i) .. ': ' .. tostring(conn.source_connector_id) .. ' => ' .. tostring(conn.target_connector_id) .. ' with owner: ' .. tostring(connection.target.owner.unit_number))
            table.insert(connections, conn)
        end
    end
    return connections
end

---@param info IoPoint
local function load_iopoint_connections(info)
    info.connections = get_iopoint_connections(info)
end

---@param info Processor
local function load_processor_connections(info)
    if not info.iopoints then return end
    ---@type IoPointWireConnection
    for _, iopoint in ipairs(info.iopoints) do
        load_iopoint_connections(iopoint)
    end
end

---@param info Processor
local function refresh_processor_info(info)
    load_processor_connections(info)
end

---@param source IoPoint
---@param destination IoPoint
---@param transfer_type connection_transfer_type
local function transfer_iopoint_connections(source, destination, transfer_type)
    local reach_check = (transfer_type == connection_transfer_type.reorient)
    for i, conn in ipairs(source.connections) do
        game.print('handling conn #' .. tostring(i) .. ': ' .. tostring(conn.source_connector_id) .. ' => ' .. tostring(conn.target_connector_id) .. ' with owner id: ' .. tostring(conn.target_unit_number))
        local destination_connector = destination.entity.get_wire_connector(conn.source_connector_id, true)
        local target_owner = load_entity(conn.target_unit_number)
        if target_owner then
            local target_connector = target_owner.get_wire_connector(conn.target_connector_id, true)
            destination_connector.connect_to(target_connector, reach_check)
        end
    end
end

---@param entity LuaEntity
---@return IoPoint
local function create_iopoint(entity, index)
    return { 
        entity = entity,
        index = index,
        connections = {}
    }
end

---@param entity LuaEntity
---@return Processor
local function create_processor(entity)
    return { 
        entity = entity,
        iopoints = {},
        mirroring = false,
        unit_number = entity.unit_number,
        locked = false
    }
end

---@param info Processor
---@return IoPoint[]
local function build_iopoints(info)
    local entity = info.entity
    local target_direction = entity.direction
    if info.mirroring and Geometry.direction_orientation[entity.direction] == axis.horizontal then
        -- In this case we perform the equivalent of a vertical flip on the iopoints by
        -- rotating by 180 degrees and then performing a horizontal flip.
        target_direction = Geometry.flipped_direction[target_direction]
    end
    local positions = processor.iopoint_formation.path[target_direction]
    ---@type IoPoint[]
    local iopoints = {}
    for i, iop in ipairs(positions) do
        local pos = { x = entity.position.x, y = entity.position.y }
        local offset = { x = iop.x, y = iop.y }
        if info.mirroring then
            offset.x = -offset.x
        end

        local iopoint_entity = entity.surface.create_entity {
            name = processor.iopoint_name,
            position = { pos.x + offset.x, pos.y + offset.y },
            force = entity.force
        }
        if iopoint_entity then
            iopoint_entity.destructible = false
            iopoint_entity.minable = false
            
            local iopoint = create_iopoint(iopoint_entity, i)
            table.insert(iopoints, iopoint)
        end
    end
    return iopoints
end


---@param info Processor
---@param clone_source Processor?
---@param transfer_type connection_transfer_type?
local function update_processor_connections(info, clone_source, transfer_type)
    local source_iopoints
    if clone_source and clone_source.iopoints then
        if transfer_type == nil then
            if clone_source.entity and clone_source.entity.valid then
                transfer_type = connection_transfer_type.reapply
            else
                transfer_type = connection_transfer_type.rebuild
            end
        end
        source_iopoints = clone_source.iopoints
        
    else
        source_iopoints = info.iopoints
        transfer_type = connection_transfer_type.replace
    end

    if transfer_type == connection_transfer_type.replace then
        game.print('updating processor connections; replacing iopoints')
    elseif transfer_type == connection_transfer_type.rebuild then
        game.print('updating processor connections; rebuilding iopoints')
    else
        game.print('updating processor connections; reapplying iopoints')
    end
    
    local destination_iopoints = build_iopoints(info)
    for i, source_iopoint in ipairs(source_iopoints) do
        if source_iopoint.connections then
            for j, conn in ipairs(source_iopoint.connections) do
                game.print('handling conn #' .. tostring(j) .. ': ' .. tostring(conn.source_connector_id) .. ' => ' .. tostring(conn.target_connector_id) .. ' with owner id: ' .. tostring(conn.target_unit_number))
            end
        end
        local destination_iopoint = destination_iopoints[i]
        transfer_iopoint_connections(source_iopoint, destination_iopoint, transfer_type)
        if source_iopoint.entity and source_iopoint.entity.valid then
            source_iopoint.entity.destroy()
        end
    end
    info.iopoints = destination_iopoints
end

---@param info Processor
function exports.destroy_processor(info)
    for _, iopoint in ipairs(info.iopoints) do
        iopoint.entity.destroy()
    end
    info.locked = true
end


---@param info Processor
---@param clone_source Processor?
function exports.build_processor(info, clone_source)
    update_processor_connections(info, clone_source)
end

---@param info Processor
---@param mirroring orientation?
function exports.reorient_processor(info, mirroring)
    if mirroring then
        info.mirroring = not info.mirroring
    end
    update_processor_connections(info)
end

---@param source Processor
---@param destination Processor
---@param duplicative boolean?
function exports.clone_processor(source, destination, duplicative)
    game.print('cloning processor, duplicative = ' .. tostring(duplicative))
    local transfer_type = nil --[[@as connection_transfer_type]]
    if duplicative then
        transfer_type = connection_transfer_type.reapply
    end
    update_processor_connections(destination, source, transfer_type)
end

---@param tags Tags
---@return Processor?
local function extract_processor_tags(tags)
    local processor_tags = nil
    if tags and tags[processor.tag_prefix] then 
        processor_tags = tags[processor.tag_prefix]  --[[@as Processor]]
        game.print('extracted tags[' .. processor.tag_prefix .. ']')
    end
    if processor_tags and not processor_tags.valid then
        game.print('invalid processor tags extracted')
    end
    return processor_tags
end

---@param event? EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive | EventData.on_built_entity | EventData.on_space_platform_built_entity
---         | EventData.on_entity_settings_pasted
---         | EventData.on_entity_cloned
---         | EventData.on_robot_pre_mined
---         | EventData.on_pre_player_mined_item
---         | EventData.on_space_platform_mined_entity
---@return Processor?
local function read_event_tags(event)
    if not event or not event.tick then return nil end
    ---@type Processor?
    local processor_tags = extract_processor_tags(event.tags)
    if not processor_tags then
        local stack_tags = event.stack and event.stack.is_item_with_tags and event.stack.tags --[[@as Tags]]
        processor_tags = extract_processor_tags(stack_tags)
    end
    return processor_tags
end

---@param entity? LuaEntity
---@return Processor?
local function read_entity_tags(entity)
    if not entity or not entity.unit_number then return nil end
    ---@type Processor?
    local processor_tags = extract_processor_tags(entity.tags)
    return processor_tags
end


---@param entity? LuaEntity
---@param event? EventData
---         | EventData.on_robot_built_entity 
---         | EventData.script_raised_built
---         | EventData.script_raised_revive 
---         | EventData.on_built_entity 
---         | EventData.on_space_platform_built_entity
---         | EventData.on_entity_settings_pasted
---         | EventData.on_entity_cloned
---         | EventData.on_robot_pre_mined
---         | EventData.on_pre_player_mined_item
---         | EventData.on_space_platform_mined_entity
---@return Processor?
local function read_processor_tags(entity, event)
    ---@diagnostic disable-next-line
    local processor_tags = read_event_tags(event)
    if processor_tags then
        game.print('got processor info from event tags')
        return processor_tags
    end
    processor_tags = read_entity_tags(entity)
    if processor_tags then
        game.print('got processor tags from entity')
        return processor_tags
    end
    return nil
end

---@param entity LuaEntity
---@param create boolean?
---@param event? EventData
---         | EventData.on_robot_built_entity 
---         | EventData.script_raised_built
---         | EventData.script_raised_revive 
---         | EventData.on_built_entity 
---         | EventData.on_space_platform_built_entity
---         | EventData.on_entity_settings_pasted
---         | EventData.on_entity_cloned
---         | EventData.on_robot_pre_mined
---         | EventData.on_pre_player_mined_item
---         | EventData.on_space_platform_mined_entity
---@return Processor
function exports.load_stored_processor(entity, create, event)
    game.print("loading stored info for entity: " .. tostring(entity.unit_number))
    if not storage.processors then storage.processors = {} end
    local info = storage.processors[entity.unit_number]
    if info and not info.locked then
        game.print('refreshing entity info')
        refresh_processor_info(info)
    elseif create then
        game.print('creating new entity info')
        info = create_processor(entity)
        storage.processors[entity.unit_number] = info
    end
    if event then
        local tag_info = read_processor_tags(entity, event)
        if tag_info then 
            info.mirroring = tag_info.mirroring
            info.iopoints = tag_info.iopoints
        end
    end
    return info
end

---@param entity LuaEntity
function store_entity(entity)
    if not storage.entities then storage.entities = {} end
    storage.entities[entity.unit_number] = entity
end

---@param unit_number uint64
function load_entity(unit_number)
    if not storage.entities then storage.entities = {} end
    local entity = storage.entities[unit_number]
    return entity
end


return exports
local ProcessorConfig = require "scripts.processor.processor"
local logic = require "scripts.processor.logic"

local handlers = {
    ---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive
    on_built = function(event)
        if event.name == defines.events.on_built_entity then
            game.print("processor:on_built(on_built_entity)")
        end
        if event.name == defines.events.on_robot_built_entity    then
            game.print("processor:on_built(on_robot_built_entity)")
        end
        if event.name == defines.events.script_raised_built then
            game.print("processor:on_built(script_raised_built)")
        end
        if event.name == defines.events.script_raised_revive then
            game.print("processor:on_built(script_raised_revive)")
        end
        
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        local info = logic.load_stored_processor(entity, true, event)
        if event.stack then
            local stack = event.stack
            if stack.is_blueprint then
                game.print('stack is bp')
            elseif stack.is_item_with_entity_data then
                game.print('stack is item with entity')
            elseif stack.is_item_with_tags then
                game.print('stack is item with tags')
            end
        end
        if event.player_index then
        local player = game.players[event.player_index]
        if player then
        local cursor_stack = game.players[event.player_index].cursor_stack
        if cursor_stack then
            local stack = cursor_stack
            if stack.is_blueprint then
                game.print('cursor stack is bp')
                local entity = event.entity
            elseif stack.is_item_with_entity_data then
                game.print('cursor stack is item with entity')
            elseif stack.is_item_with_tags then
                game.print('cursor stack is item with tags')
            end
        end
    end
    end
        logic.build_processor(info)
    end,
    ---@param event EventData.script_raised_destroy | EventData.on_robot_mined_entity | EventData.on_player_mined_entity | EventData.on_entity_died
    on_destroyed = function(event)
        game.print("processor:on_destroyed")
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        local info = logic.load_stored_processor(event.entity, true, event)
        logic.destroy_processor(info)
    end,
    ---@param event EventData.on_pre_player_mined_item | EventData.on_robot_pre_mined
    on_destroying = function(event)
        game.print('processor:on_pre_mined')
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        logic.load_stored_processor(event.entity, true, event)
    end,
    ---@param event EventData.on_entity_settings_pasted | EventData.on_entity_cloned
    on_cloned = function(event)
        game.print("processor:on_cloned")
        local entities = { event.source, event.destination }
        local infos = {}
        for i, entity in ipairs(entities) do
            if not entity or not entity.valid then return end
            if entity.name ~= ProcessorConfig.processor_name then return end
            local info = logic.load_stored_processor(entity, true, event)
            table.insert(infos, info)
        end
        local duplicative = event.name == defines.events.on_entity_cloned
        logic.clone_processor(infos[1], infos[2], duplicative)
    end,
    ---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
    on_reoriented = function(event)
        game.print("processor:on_rotated")
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        ---@type axis?
        local mirroring = nil
        if event.name == defines.events.on_player_flipped_entity then
            if event.horizontal then 
                mirroring = axis.horizontal
            else
                mirroring = axis.vertical
            end
        end
        local info = logic.load_stored_processor(entity, true)
        logic.reorient_processor(info, mirroring)
    end,
        ---@param event EventData.on_player_setup_blueprint
    on_player_setup_blueprint = function(event)
        local bp = event.stack
        if not bp then return end
        local bp_count = bp.get_blueprint_entity_count()
        local entities = bp.get_blueprint_entities()
        if not entities then return end
        local mapping = event.mapping.get()
        game.print('initial bp entity count: ' .. tostring(#entities))
        for index = 1, bp_count do
            local mapped_entity = mapping[index]
            if mapped_entity and mapped_entity.valid then
                if string.find(mapped_entity.name, ProcessorConfig.processor_pattern) then
                    local info = logic.load_stored_processor(mapped_entity, false)
                    local tags = { [ProcessorConfig.tag_prefix] = {
                        iopoints = info.iopoints,
                        mirroring = info.mirroring,
                        unit_number = info.unit_number
                    }}
                    for iop_index, iop in ipairs(info.iopoints) do
                        local entity_number = #entities + 1
                        local wires = {}
                        for _, conn in ipairs(iop.connections) do
                            table.insert(wires, { entity_number, conn.source_connector_id, conn.target_unit_number, conn.target_connector_id })
                            mapping[conn.target_unit_number] = storage.entities[conn.target_unit_number]
                        end
                        
                        mapping[entity_number] = iop.entity
                        table.insert(entities, {
                            entity_number = entity_number,
                            name = iop.entity.name,
                            position = iop.entity.position,
                            direction = iop.entity.direction,
                            tags = { [ProcessorConfig.tag_prefix] = {
                                index = iop.index,
                                connections = iop.connections
                            }},
                            wires = wires
                        })
                        if #wires > 0 then
                            game.print('added bp entity from iopoint #' .. tostring(iop_index) .. ' with ' .. tostring(#wires) .. 'wires')
                        end
                    end
                    bp.set_blueprint_entity_tags(index, tags)
                end
            end
        end
        bp.set_blueprint_entities(entities)
        game.print('final bp entity count: ' .. tostring(#entities))
    end,

    default_handler = function(event)
        game.print('event fired: ' .. tostring(event.name))
    end
}

local subscriptions = {
    [defines.events.on_built_entity] = handlers.on_built,
    [defines.events.on_robot_built_entity] = handlers.on_built,
    [defines.events.script_raised_built] = handlers.on_built,
    [defines.events.script_raised_revive] = handlers.on_built,

    -- [defines.events.on_player_mined_entity] = handlers.on_destroyed,
    -- [defines.events.on_robot_mined_entity] = handlers.on_destroyed,
    -- [defines.events.script_raised_destroy] = handlers.on_destroyed,
    -- [defines.events.on_entity_died] = handlers.on_destroyed,

    -- [defines.events.on_entity_cloned] = handlers.on_cloned,
    -- [defines.events.on_entity_settings_pasted] = handlers.on_cloned,

    [defines.events.on_player_rotated_entity] = handlers.on_reoriented,
    [defines.events.on_player_flipped_entity] = handlers.on_reoriented,
    -- [defines.events.on_player_setup_blueprint] = handlers.on_player_setup_blueprint,

    -- [defines.events.on_pre_entity_settings_pasted] = handlers.default_handler,
    -- [defines.events.on_player_cursor_stack_changed] = handlers.default_handler,
    -- [defines.events.on_player_mined_item] = handlers.default_handler,
    -- [defines.events.on_player_configured_blueprint] = handlers.default_handler,
    -- [defines.events.on_entity_spawned] = handlers.default_handler,
    -- [defines.events.on_area_cloned] = handlers.default_handler,
}

local exports = {
    handlers = handlers,
    subscriptions = subscriptions
}

return exports
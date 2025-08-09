local processor = require "scripts.processor.processor"
local logic = require "scripts.processor.logic"

local handlers = {
    ---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive
    on_built = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        local info = logic.load_stored_info(entity, true, event)
        game.print("processor:on_built")
        logic.build_processor(info)
    end,
    ---@param event EventData.script_raised_destroy | EventData.on_robot_mined_entity | EventData.on_player_mined_entity | EventData.on_entity_died
    on_destroyed = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        local info = logic.load_stored_info(event.entity, true, event)
        game.print("processor:on_destroyed")
        logic.destroy_processor(info)
    end,
    ---@param event EventData.on_pre_player_mined_item | EventData.on_robot_pre_mined
    on_destroying = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        logic.load_stored_info(event.entity, true, event)
    end,
    ---@param event EventData.on_entity_settings_pasted | EventData.on_entity_cloned
    on_cloned = function(event)
        local entities = { event.source, event.destination }
        local infos = {}
        for i, entity in ipairs(entities) do
            if not entity or not entity.valid then return end
            if entity.name ~= processor.processor_name then return end
            local info = logic.load_stored_info(entity, true, event)
            table.insert(infos, info)
        end
        game.print("processor:on_cloned")
        local duplicative = event.name == defines.events.on_entity_cloned
        logic.clone_processor(infos[1], infos[2], duplicative)
    end,
    ---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
    on_reoriented = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        game.print("processor:on_rotated")
        ---@type orientation?
        local mirroring = nil
        if event.name == defines.events.on_player_flipped_entity then
            if event.horizontal then 
                mirroring = orientation.horizontal
            else
                mirroring = orientation.vertical
            end
        end
        local info = logic.load_stored_info(entity, true)
        logic.reorient_processor(info, mirroring)
    end,
        ---@param event EventData.on_player_setup_blueprint
    on_player_setup_blueprint = function(event)
        game.print('setting bp')
        local bp = event.stack
        if not bp then return end
        local bp_count = bp.get_blueprint_entity_count()
        local entities = bp.get_blueprint_entities()
        if not entities then return end
        local mapping = event.mapping.get()
        game.print('mapping and bp: ' .. tostring(bp_count))
        for index = 1, bp_count do
            game.print('at index: ' .. tostring(index))
            local bp_entity = entities[index]
            local tagValue = event.stack.get_blueprint_entity_tag(index, "mirroring")
            game.print("tag value:")
            game.print(tagValue)
            game.print(bp_entity.entity_number)
            local mapped_entity = mapping[index]
            if mapped_entity and mapped_entity.valid then
                game.print('on_player_setup_blueprint: mapped entity is valid, name = ' .. mapped_entity.name)
                if string.find(mapped_entity.name, processor.processor_pattern) then
                    game.print('on_player_setup_blueprint: mapped entity is processor, loading info')
                    local info = logic.load_stored_info(mapped_entity, false)
                    local tags = { [processor.tag_prefix] = {
                        entity = info.entity,
                        iopoints = info.iopoints,
                        mirroring = info.mirroring,
                        unit_number = info.unit_number
                    }}
                    for iop_index, iop in ipairs(info.iopoints) do
                        for conn_index, conn in ipairs(iop.connections) do
                            game.print('blueprint entity connection: iop#' .. tostring(iop_index) .. ',conn#' .. tostring(conn_index) .. ', src_id:' .. tostring(conn.source_connector_id) .. ', tgt_id:' .. tostring(conn.target_connector_id))
                        end
                    end
                    game.print('setting the blueprint stuffos')
                    bp.set_blueprint_entity_tags(index, tags)
                end
            end
        end
    end
}

local subscriptions = {
    [defines.events.on_built_entity] = handlers.on_built,
    [defines.events.on_robot_built_entity] = handlers.on_built,
    [defines.events.script_raised_built] = handlers.on_built,
    [defines.events.script_raised_revive] = handlers.on_built,

    [defines.events.on_player_mined_entity] = handlers.on_destroyed,
    [defines.events.on_robot_mined_entity] = handlers.on_destroyed,
    [defines.events.script_raised_destroy] = handlers.on_destroyed,
    [defines.events.on_entity_died] = handlers.on_destroyed,

    [defines.events.on_entity_cloned] = handlers.on_cloned,
    [defines.events.on_entity_settings_pasted] = handlers.on_cloned,

    [defines.events.on_player_rotated_entity] = handlers.on_reoriented,
    [defines.events.on_player_flipped_entity] = handlers.on_reoriented,
    [defines.events.on_player_setup_blueprint] = handlers.on_player_setup_blueprint,
}

local exports = {
    handlers = handlers,
    subscriptions = subscriptions
}

return exports
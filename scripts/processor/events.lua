local processor = require "scripts.processor.processor"
local logic = require "scripts.processor.logic"

local handlers = {
    ---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive
    on_built = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        local info = logic.load_stored_info(entity, true)
        logic.build_processor(info)
    end,
    ---@param event EventData.script_raised_destroy | EventData.on_robot_mined_entity | EventData.on_player_mined_entity | EventData.on_entity_died
    on_destroyed = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        local info = logic.load_stored_info(event.entity)
        logic.destroy_processor(info)
    end,
    ---@param event EventData.on_entity_settings_pasted | EventData.on_entity_cloned
    on_cloned = function(event)
        local entities = { event.source, event.destination }
        local infos = {}
        for _, entity in ipairs(entities) do
            if not entity or not entity.valid then return end
            if entity.name ~= processor.processor_name then return end
            local info = logic.load_stored_info(entity, true)
            table.insert(infos, info)
        end
        logic.clone_processor(infos[1], infos[2])
    end,
    ---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
    on_reoriented = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= processor.processor_name then return end
        ---@type orientation?
        local mirroring = nil
        if event.name == defines.events.on_player_flipped_entity then
            if event.horizontal then 
                mirroring = orientation.horizontal
            else
                mirroring = orientation.vertical
            end
        end
        local info = logic.load_stored_info(entity, false)
        logic.reorient_processor(info, mirroring)
    end,
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
}

local exports = {
    handlers = handlers,
    subscriptions = subscriptions
}

return exports
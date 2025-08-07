local common = require('scripts.common')
local processor = require('scripts.processor')

---@param e EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive | EventData.on_built_entity | EventData.on_space_platform_built_entity
---@return Tags?
local function get_processor_tags(e)
    local event_tags = e.tags
    local processor_tags = event_tags
    if event_tags and event_tags[common.tag_prefix] then 
        processor_tags = event_tags[common.tag_prefix]  --[[@as ProcInfo]]
    end
    if not processor_tags then
        processor_tags = (e.stack and e.stack.is_item_with_tags and e.stack.tags) --[[@as ProcInfo]]
    end
    return processor_tags
end

---@param entity LuaEntity
---@param create boolean?
---@return ProcInfo
local function load_stored_processor_info(entity, create)
    if not storage.processors then storage.processors = {} end
    local info = storage.processors[entity.unit_number]
    if not info and create then
        info = {
            entity = entity,
            unit_number = entity.unit_number,
            iopoints = {}, -- external io point
        }
        storage.processors[entity.unit_number] = info
    end
    return info
end

local processor_handlers = {
    ---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive
    on_built = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= common.processor_name then return end
        game.print('processor:on_built')
        local info = load_stored_processor_info(entity, true)
        processor.build_processor(info)
    end,
    ---@param event EventData.script_raised_destroy | EventData.on_robot_mined_entity | EventData.on_player_mined_entity | EventData.on_entity_died
    on_destroyed = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= common.processor_name then return end
        game.print('processor:on_destroyed')
        local info = load_stored_processor_info(event.entity)
        processor.destroy_processor(info)
    end,
    ---@param event EventData.on_entity_settings_pasted | EventData.on_entity_cloned
    on_cloned = function(event)
        local entities = { event.source, event.destination }
        local infos = {}
        for _, entity in ipairs(entities) do
            if not entity or not entity.valid then return end
            if entity.name ~= common.processor_name then return end
            local info = load_stored_processor_info(entity, true)
            table.insert(infos, info)
        end
        game.print('processor:on_cloned')
        processor.clone_processor(infos[1], infos[2])
    end,
    ---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
    on_reoriented = function(event)
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= common.processor_name then return end
        if event.name == defines.events.on_player_flipped_entity then
            common.unrotate_and_mirror(entity, event.horizontal)
        end
        game.print('processor:on_transformed: ' .. event.name)
        local info = load_stored_processor_info(entity, false)
        processor.reorient_processor(info)
    end,
}

local processor_events = {
    [defines.events.on_built_entity] = processor_handlers.on_built,
    [defines.events.on_robot_built_entity] = processor_handlers.on_built,
    [defines.events.script_raised_built] = processor_handlers.on_built,
    [defines.events.script_raised_revive] = processor_handlers.on_built,

    [defines.events.on_player_mined_entity] = processor_handlers.on_destroyed,
    [defines.events.on_robot_mined_entity] = processor_handlers.on_destroyed,
    [defines.events.script_raised_destroy] = processor_handlers.on_destroyed,
    [defines.events.on_entity_died] = processor_handlers.on_destroyed,

    [defines.events.on_entity_cloned] = processor_handlers.on_cloned,
    [defines.events.on_entity_settings_pasted] = processor_handlers.on_cloned,

    [defines.events.on_player_rotated_entity] = processor_handlers.on_reoriented,
    [defines.events.on_player_flipped_entity] = processor_handlers.on_reoriented,
}

for event_type, event_handler in pairs(processor_events) do
    script.on_event(event_type, event_handler)
end
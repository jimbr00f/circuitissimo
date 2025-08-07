local common = require('scripts.common')
local processor = require('scripts.processor')

local build_events = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
}

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

local function on_processor_built(event)
    local entity = event.created_entity or event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= common.processor_name then return end
    local info = load_stored_processor_info(entity, true)
    processor.build_processor(info)
end

for _, event in pairs(build_events) do
    script.on_event(event, on_processor_built)
end

---@param event EventData.on_player_rotated_entity
local function on_processor_rotated(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= common.processor_name then return end

    local info = load_stored_processor_info(entity, false)
    processor.rotate_processor(info)
end

script.on_event(defines.events.on_player_rotated_entity, on_processor_rotated)
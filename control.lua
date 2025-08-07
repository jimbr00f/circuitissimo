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

---@param info ProcInfo
---@param tags Tags
---@param entity LuaEntity
local function update_processor_info(info, tags, entity)
    info.wires = tags.wires --[[@as WireDefinition[] ]]
    if tags.blueprint then
        info.blueprint = tags.blueprint --[[@as string]]
    elseif tags.circuits then
        info.circuits = tags.circuits and
            helpers.json_to_table(tags.circuits --[[@as string]]) --[[@as Circuit[]]
    else
        return
    end
    info.model = tags.model --[[@as string]]
    info.sprite1 = tags.sprite1 --[[@as string]]
    info.sprite2 = tags.sprite2 --[[@as string]]
    info.label = tags.label --[[@as string]]
    info.is_packed = true
    info.tick = tags.tick --[[@as integer]]
    info.value_id = tags.value_id --[[@as integer?]]
    if tags.input_values then
        info.input_values =
            helpers.json_to_table(tags.input_values --[[@as string]]) --[[@as table<string, any> ]]
    end
    -- if info.model then
    --     local model = build.get_model(entity.force, entity.name,
    --         info.model)

    --     if model and info.tick and model.tick > info.tick then
    --         info.sprite1 = model.sprite1
    --         info.sprite2 = model.sprite2
    --         info.blueprint = model.blueprint
    --         info.tick = game.tick
    --     end
    -- end
end

---Get info from processor
---@param entity LuaEntity
---@param create boolean?
---@return ProcInfo
local function load_stored_processor_info(entity, create)
    if not storage.procinfos then storage.procinfos = {} end
    local info = storage.procinfos[entity.unit_number]
    if not info and create then
        info = {
            processor = entity,
            unit_number = entity.unit_number,
            iopoints = {}, -- external io point
            iopoint_infos = {} -- map: unit_number of internal iopoint => information on point
        }
        storage.procinfos[entity.unit_number] = info
    end
    return info
end

---@return integer
local function get_id()
    local id = storage.id or 1
    storage.id = id + 1
    return id
end

---@param newid integer?
---@return integer?
local function upgrade_id(newid)
    if not newid then
        return
    end
    local id = storage.id or 1
    if id <= newid then
        storage.id = newid + 1
    end
end

local function on_processor_built(event)
    local entity = event.created_entity or event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= common.processor_name then return end
    local tags = get_processor_tags(event)
    local stored_info = load_stored_processor_info(entity, true)
    if tags then update_processor_info(stored_info, tags, entity) end
    -- if not IsProcessorRebuilding then
    --     stored_info.value_id = get_id()
    -- else
    --     upgrade_id(stored_info.value_id)
    -- end
    processor.build_processor(stored_info)
end

for _, event in pairs(build_events) do
    script.on_event(event, on_processor_built)
end
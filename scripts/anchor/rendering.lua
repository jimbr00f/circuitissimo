local AnchorConfig = require 'scripts.anchor.config'
local Anchor = require 'scripts.anchor.anchor'
local ProcessorConfig = require 'scripts.processor.config'
local Processor = require 'scripts.processor.processor'
local Formation = require 'lib.formation.formation'

local function local_to_world(proc_pos, local_pos)
    return {x = proc_pos.x + local_pos.x, y = proc_pos.y + local_pos.y}
end

local function dist_sq(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx*dx + dy*dy
end

---@param player LuaPlayer
local function refund_item(player, name, count)
    if not (player and player.valid) then return end
    local inserted = player.insert{name = name, count = count}
    if inserted < count then
        player.surface.spill_item_stack{
            position = player.position, 
            stack = {name = name, count = count - inserted}, 
            enable_looted = true
        }
    end
end

-- Render helpers --------------------------------------------------------------

---@param player_index integer
---@return AnchorPreviewData
local function init_preview(player_index)
    return {
        cursor_has_iopoint = false,
        player_index = player_index,
        render_ids = {},
    }
end

---@param player_index integer
---@return AnchorPreviewData
local function load_preview(player_index)
    local pdata = storage.anchor_preview[player_index]
    if not pdata then
        pdata = init_preview(player_index)
        storage.anchor_preview[player_index] = pdata
    end
    return pdata
end

---@param player_index integer
---@return AnchorPreviewData
local function clear_preview(player_index)
    local pdata = storage.anchor_preview[player_index]
    if pdata then
        for _, id in ipairs(pdata.render_ids) do
            local render = rendering.get_object_by_id(id)
            if render then
                render.destroy()
            end
        end
    end
    pdata = init_preview(player_index)
    storage.anchor_preview[player_index] = pdata
    return pdata
end

---@param surface LuaSurface
---@param force string|integer|LuaForce
---@param player_index integer
---@param anchor_world MapPosition
---@param is_free boolean
---@param final_dir defines.direction
local function draw_anchor(surface, force, player_index, anchor_world, final_dir)
    game.print(string.format('drawing anchor at %.1f, %.1f [%s]', anchor_world.x, anchor_world.y, tostring(final_dir)))
    local is_free = surface.can_place_entity{
        name = ProcessorConfig.iopoint_name, position = world, direction = slot.direction, force = player.force
    }
    local shape = ProcessorConfig.iopoint_formation.item_shape
    local ids = storage.anchor_preview[player_index].render_ids
    local color = is_free and {g=1, a=0.35} or {r=0.6, g=0.6, b=0.6, a=0.25}
    local box = rendering.draw_rectangle{
        color = color,
        width = 1,
        filled = false,
        left_top = {
            x = anchor_world.x + shape.left_top.x,
            y = anchor_world.y + shape.left_top.y
        },
        right_bottom = {
            x = anchor_world.x + shape.right_bottom.x,
            y = anchor_world.y + shape.right_bottom.y
        },
        surface = surface,
        forces = {force},
        players = {player_index}
    }
    table.insert(ids, box.id)
    
    -- draw a direction arrow on top for clarity (like station helpers)
    local arrow = rendering.draw_sprite{
        sprite = "utility/indication_arrow", -- vanilla arrow
        surface = surface,
        target = {anchor_world.x, anchor_world.y - 0.2},
        orientation = Formation.convert.direction.to_rotation[final_dir],
        x_scale = 0.55,
        y_scale = 0.55,
        render_layer = "entity-info-icon-above",
        forces = {force},
        players = {player_index},
        tint = is_free and {g=1, a=0.8} or {r=0.8, g=0.8, b=0.8, a=0.5},
    }
    table.insert(ids, arrow.id)
end

-- Preview update --------------------------------------------------------------

local function is_holding_connector(player)
    local cs = player.cursor_stack
    return (cs and cs.valid_for_read and cs.name == ProcessorConfig.iopoint_name)
end


---@param player LuaPlayer
---@return Anchor[]
local function find_anchor_points(player)
    local surface = player.surface
    local pos = player.position
    
    local area = {
        {pos.x - AnchorConfig.find_radius, pos.y - AnchorConfig.find_radius},
        {pos.x + AnchorConfig.find_radius, pos.y + AnchorConfig.find_radius}
    }
    local processor_entities = surface.find_entities_filtered{area = area, name = ProcessorConfig.processor_name, force = player.force}
    
    local anchors = {}
    for _, proc_entity in ipairs(processor_entities) do
        ---@type Processor
        local proc = Processor.load_from_storage(proc_entity)
        local slots = proc:get_active_formation_slots()
        for _, slot in ipairs(slots) do
            local anchor = Anchor:new(player, proc, slot)
            table.insert(anchors, anchor)
        end
    end
    return anchors
end


---@param player LuaPlayer
---@param pdata AnchorPreviewData
local function update_player_preview(player, pdata)
    clear_preview(player.index)
    if not pdata.cursor_has_iot then return end
    
    local anchors = find_anchor_points(player)
    for _, anchor in ipairs(anchors) do
        anchor:draw()
    end
end

-- Snap/Reject on build --------------------------------------------------------

---@param entity LuaEntity
---@param player? LuaPlayer
local function try_snap_or_reject(entity, player)
    if not (entity and entity.valid and entity.name == ProcessorConfig.iopoint_name) then return end
    if not player then return end
    local anchors = find_anchor_points(player)
    local best_d2, target = 1/0, nil
    for _, anchor in ipairs(anchors) do
        local d2 = anchor:sq_distance_from(entity)
        if d2 < best_d2 then
            best_d2 = d2
            target = {
                pos = anchor:world_position(), 
                dir = anchor.slot.direction,
            }
        end
    end
    
    if target then
        entity.teleport(target.pos)
        entity.direction = target.dir
    else
        entity.destroy{raise_destroy = true}
        if player then
            refund_item(player, ProcessorConfig.iopoint_name, 1)
        end
    end
end

-- Events ---------------------------------------------------------------------

---@param e EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built
local function on_built(e)
    local ent = e.entity
    if not (ent and ent.valid and ent.name == ProcessorConfig.iopoint_name) then return end
    local player = game.players[e.player_index]
    try_snap_or_reject(ent, player)
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.on_entity_cloned, function(e)
    if e.destination and e.destination.valid and e.destination.name == ProcessorConfig.iopoint_name then
        try_snap_or_reject(e.destination)
    end
end)

script.on_init(function()
    storage.anchor_preview = storage.anchor_preview or {}
end)

script.on_configuration_changed(function()
    storage.anchor_preview = storage.anchor_preview or {}
end)

-- Clean up previews when players leave/changes happen
script.on_event(defines.events.on_player_left_game, function(e)
    clear_preview(e.player_index)
end)

---@param e EventData.on_player_cursor_stack_changed
script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
    local pdata = load_preview(e.player_index)
    local player = game.players[e.player_index]
    local cs = player.cursor_stack
    if cs and cs.valid_for_read and cs.name == ProcessorConfig.iopoint_name then
        pdata.cursor_has_iopoint = true
    end
    update_player_preview(player, pdata)
end
)

script.on_nth_tick(Anchor.tick_interval, function(e)
    for player_index, pdata in pairs(storage.anchor_preview) do
        if pdata.cursor_has_iopoint then
            local player = game.get_player(player_index)
            if player then
                update_player_preview(player, pdata)
            end
        end
    end
end)
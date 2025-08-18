-- control.lua
local CONNECTOR_NAME  = "your-connector"
local CONNECTOR_ITEM  = "your-connector-item"
local PROCESSOR_NAME  = "your-processor"

local MAX_FIND_RADIUS = 6.0     -- search for processors within this many tiles of the cursor
local HOVER_RADIUS    = 0.6     -- how close the cursor must be to “hover” an anchor
local TICK_INTERVAL   = 10      -- preview update throttle (every 10 ticks ~= 6x/sec)

-- anchors are positions relative to the processor’s position for each processor direction
local processor_anchors = {
    [defines.direction.north] = {
        {pos = {x = 0,   y = -1}, dir = defines.direction.north},
        {pos = {x = -1,  y =  0}, dir = defines.direction.west},
        {pos = {x = 1,   y =  0}, dir = defines.direction.east},
        {pos = {x = 0,   y =  1}, dir = defines.direction.south},
    },
    [defines.direction.east] = {
        {pos = {x = 1,   y =  0}, dir = defines.direction.east},
        {pos = {x = 0,   y = -1}, dir = defines.direction.north},
        {pos = {x = 0,   y =  1}, dir = defines.direction.south},
        {pos = {x = -1,  y =  0}, dir = defines.direction.west},
    },
    [defines.direction.south] = {
        {pos = {x = 0,   y =  1}, dir = defines.direction.south},
        {pos = {x = 1,   y =  0}, dir = defines.direction.east},
        {pos = {x = -1,  y =  0}, dir = defines.direction.west},
        {pos = {x = 0,   y = -1}, dir = defines.direction.north},
    },
    [defines.direction.west] = {
        {pos = {x = -1,  y =  0}, dir = defines.direction.west},
        {pos = {x = 0,   y =  1}, dir = defines.direction.south},
        {pos = {x = 0,   y = -1}, dir = defines.direction.north},
        {pos = {x = 1,   y =  0}, dir = defines.direction.east},
    }
}

local function local_to_world(proc_pos, local_pos)
    return {x = proc_pos.x + local_pos.x, y = proc_pos.y + local_pos.y}
end

local function dist_sq(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx*dx + dy*dy
end

local function refund_item(player, name, count)
    if not (player and player.valid) then return end
    local inserted = player.insert{name = name, count = count}
    if inserted < count then
        player.surface.spill_item_stack(player.position, {name = name, count = count - inserted}, true)
    end
end

-- Render helpers --------------------------------------------------------------

---@param player_index integer
---@return PreviewData
local function init_preview(player_index)
    return {
        cursor_has_connector = false,
        player_index = player_index,
        render_ids = {},
        nearest_anchor = nil
    }
end

---@param player_index integer
---@return PreviewData
local function load_preview(player_index)
    local pdata = storage.preview[player_index]
    if not pdata then
        pdata = init_preview(player_index)
        storage.preview[player_index] = pdata
    end
    return pdata
end

---@param player_index integer
---@return PreviewData
local function clear_preview(player_index)
    local pdata = storage.preview[player_index]
    if pdata then
        for _, id in ipairs(pdata.render_ids) do
            local render = rendering.get_object_by_id(id)
            if render then
                render.destroy()
            end
        end
    end
    pdata = init_preview(player_index)
    storage.preview[player_index] = pdata
    return pdata
end

local dir_to_orientation = {
    [defines.direction.north] = 0.00,  -- sprite “up”
    [defines.direction.east]  = 0.25,
    [defines.direction.south] = 0.50,
    [defines.direction.west]  = 0.75,
}

---@param surface LuaSurface
---@param force string|integer|LuaForce
---@param player_index integer
---@param anchor_world MapPosition
---@param is_free boolean
---@param is_hovered boolean
---@param final_dir defines.direction
local function draw_anchor(surface, force, player_index, anchor_world, is_free, is_hovered, final_dir)
    local ids = storage.preview[player_index].render_ids
    local color = is_free and {g=1, a=0.35} or {r=0.6, g=0.6, b=0.6, a=0.25}
    local box = rendering.draw_rectangle{
        color = color,
        width = is_hovered and 2 or 1,
        filled = true,
        left_top = {anchor_world.x - 0.5, anchor_world.y - 0.5},
        right_bottom = {anchor_world.x + 0.5, anchor_world.y + 0.5},
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
        orientation = dir_to_orientation[final_dir] or 0,
        x_scale = is_hovered and 0.7 or 0.55,
        y_scale = is_hovered and 0.7 or 0.55,
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
    return (cs and cs.valid_for_read and cs.name == CONNECTOR_ITEM)
end

---@param player LuaPlayer
---@param pdata PreviewData
local function update_player_preview(player, pdata)
    local player_index = player.index
    if not pdata.cursor_has_connector then
        clear_preview(player_index)
        return
    end
    
    local surface = player.surface
    local pos = player.physical_position
    
    local area = {
        {pos.x - MAX_FIND_RADIUS, pos.y - MAX_FIND_RADIUS},
        {pos.x + MAX_FIND_RADIUS, pos.y + MAX_FIND_RADIUS}
    }
    local processors = surface.find_entities_filtered{area = area, name = PROCESSOR_NAME, force = player.force}
    clear_preview(player_index)
    
    pdata.nearest_anchor = nil
    local best_hover_d2 = HOVER_RADIUS * HOVER_RADIUS
    
    for _, proc in ipairs(processors) do
        local anchors = processor_anchors[proc.direction] or processor_anchors[defines.direction.north]
        for idx, a in ipairs(anchors) do
            local world = local_to_world(proc.position, a.pos)
            
            -- Is placeable there?
            local free = surface.can_place_entity{
                name = CONNECTOR_NAME, position = world, direction = a.dir, force = player.force
            }
            
            -- hover selection by proximity to cursor position
            local d2 = dist_sq(world, player.hand_location)
            local is_hover = free and d2 <= best_hover_d2
            if is_hover then
                pdata.nearest_anchor = {entity = proc, anchor_index = idx, pos = world, dir = a.dir}
                best_hover_d2 = d2
            end
            
            draw_anchor(surface, player.force, player_index, world, free, is_hover, a.dir)
        end
    end
end

-- Snap/Reject on build --------------------------------------------------------

---@param entity LuaEntity
---@param player? LuaPlayer
local function try_snap_or_reject(entity, player)
    if not (entity and entity.valid and entity.name == CONNECTOR_NAME) then return end
    local surface = entity.surface
    local force = entity.force
    
    -- If this came from a player who had a hovered anchor, prefer that.
    local target = nil
    if player then
        local rec = load_preview(player.index)
        target = rec and rec.nearest_anchor
    end
    
    -- Fallback: choose closest *valid* anchor near the entity position
    if not target then
        local pos = entity.position
        local area = {{pos.x - MAX_FIND_RADIUS, pos.y - MAX_FIND_RADIUS},
        {pos.x + MAX_FIND_RADIUS, pos.y + MAX_FIND_RADIUS}}
        local processors = surface.find_entities_filtered{area = area, name = PROCESSOR_NAME, force = force}
        local best_d2, best = 1/0, nil
        for _, proc in ipairs(processors) do
            local anchors = processor_anchors[proc.direction] or processor_anchors[defines.direction.north]
            for idx, a in ipairs(anchors) do
                local world = local_to_world(proc.position, a.pos)
                if surface.can_place_entity{name = CONNECTOR_NAME, position = world, direction = a.dir, force = force} then
                    local d2 = dist_sq(world, pos)
                    if d2 < best_d2 then
                        best_d2 = d2
                        best = {entity = proc, pos = world, dir = a.dir, anchor_index = idx}
                    end
                end
            end
        end
        target = best
    end
    
    if not target then
        if player then
            refund_item(player, CONNECTOR_ITEM, 1)
            player.create_local_flying_text{position = entity.position, text = {"", "[img=utility/warning_icon] Place next to a Processor"}}
        end
        entity.destroy{raise_destroy = true}
        return
    end
    
    -- final check + snap
    if surface.can_place_entity{name = entity.name, position = target.pos, direction = target.dir, force = force} then
        entity.teleport(target.pos)
        entity.direction = target.dir
    else
        if player then
            refund_item(player, CONNECTOR_ITEM, 1)
            player.create_local_flying_text{position = entity.position, text = {"", "[img=utility/warning_icon] Anchor blocked"}}
        end
        entity.destroy{raise_destroy = true}
    end
end

-- Events ---------------------------------------------------------------------

---@param e EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built
local function on_built(e)
    local ent = e.entity
    if not (ent and ent.valid and ent.name == CONNECTOR_NAME) then return end
    local player = game.players[e.player_index]
    try_snap_or_reject(ent, player)
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.on_entity_cloned, function(e)
    if e.destination and e.destination.valid and e.destination.name == CONNECTOR_NAME then
        try_snap_or_reject(e.destination)
    end
end)

script.on_init(function()
    storage.preview = storage.preview or {}
end)

script.on_configuration_changed(function()
    storage.preview = storage.preview or {}
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
    if cs and cs.valid_for_read and cs.name == CONNECTOR_ITEM then
        pdata.cursor_has_connector = true
    end
    update_player_preview(player, pdata)
end
)

script.on_nth_tick(TICK_INTERVAL, function(e)
    for player_index, pdata in pairs(storage.preview) do
        if pdata.is_holding_connector then
            local player = game.get_player(player_index)
            if player then
                update_player_preview(player, pdata)
            end
        end
    end
end)
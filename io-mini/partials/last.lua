---@diagnostic disable
-- Updated Processor IO Mini-Mod with blueprint injection and external wire preview
-- This is an updated version of the earlier mini-mod that:
-- 1. Injects helper ghosts and ghost wires into blueprints so they show in the cursor preview.
-- 2. Draws temporary preview lines to external map entities when holding a processor or blueprint.

-- For brevity, only changes/additions are shown; the base mod structure from before is kept.

-- CONTROL: Additions to control.lua

-- Store external connections for preview + restore
local function snapshot_external_links(processor)
    if not (processor and processor.valid) then return end
    local data = storage.processors[processor.unit_number]
    if not data then return end
    storage.external_links = storage.external_links or {}
    local links = {}
    for idx, io in ipairs(data.io) do
        if io and io.valid then
            for _, conn in pairs(io.get_wire_connectors()) do
                for _, c in pairs(conn.connections) do
                    local target = c.connector and c.connector.owner
                    if target and target.valid then
                        if target.unit_number ~= processor.unit_number then
                            table.insert(links, {
                                helper_index = idx,
                                helper_conn_id = conn.wire_connector_id,
                                target_unit = target.unit_number,
                                target_pos = target.position,
                                target_name = target.name,
                                target_conn_id = c.connector.wire_connector_id,
                                wire_type = conn.wire_type
                            })
                        end
                    end
                end
            end
        end
    end
    storage.external_links[processor.unit_number] = links
end

-- Render API preview lines to external targets when holding processor/blueprint
local function start_external_preview(player, processor_unit)
    if not (storage.external_links and storage.external_links[processor_unit]) then return end
    local ids = {}
    local links = storage.external_links[processor_unit]
    for _, link in ipairs(links) do
        local target = nil
        for _, surf in pairs(game.surfaces) do
            local ents = surf.find_entities_filtered{position = link.target_pos, name = link.target_name}
            if #ents > 0 then target = ents[1] break end
        end
        if target and target.valid then
            local color = (link.wire_type == defines.wire_type.red) and {1,0,0} or {0,1,0}
            table.insert(ids, rendering.draw_line{
                surface = target.surface,
                from = player.character or player.position,
                to = target,
                color = color,
                width = 2,
                players = {player.index},
                draw_on_ground = false
            })
        end
    end
    storage.preview = storage.preview or {}
    storage.preview[player.index] = {render_ids = ids}
end

local function stop_external_preview(player)
    if not storage.preview or not storage.preview[player.index] then return end
    for _, id in ipairs(storage.preview[player.index].render_ids) do
        if rendering.is_valid(id) then rendering.destroy(id) end
    end
    storage.preview[player.index] = nil
end

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    stop_external_preview(player)
    local stack = player.cursor_stack
    if stack and stack.valid_for_read then
        if stack.name == "processor" then
            -- For simplicity, just preview the first processor in global
            for unit,_ in pairs(storage.external_links or {}) do
                start_external_preview(player, unit)
                break
            end
        elseif stack.is_blueprint then
            local ents = stack.get_blueprint_entities()
            if ents then
                for _, e in ipairs(ents) do
                    if e.name == "processor" then
                        for unit,_ in pairs(storage.external_links or {}) do
                            start_external_preview(player, unit)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- Inject helpers + ghost wires into blueprints
script.on_event(defines.events.on_player_setup_blueprint, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local bp = player.blueprint_to_setup
    if not (bp and bp.valid_for_read) then return end
    local ents = bp.get_blueprint_entities()
    if not ents then return end
    local max_num = 0
    for _, e in ipairs(ents) do
        if e.entity_number > max_num then max_num = e.entity_number end
    end
    local new_ents = table.deepcopy(ents)
    for _, e in ipairs(ents) do
        if e.name == "processor" then
            local base_num = max_num
            for i, off in ipairs(IO_OFFSETS) do
                max_num = max_num + 1
                table.insert(new_ents, {
                    entity_number = max_num,
                    name = "processor-io-helper",
                    position = {x = e.position.x + off.x, y = e.position.y + off.y},
                    direction = 0,
                    connections = {}
                })
                -- Example: link helper to main processor with red wire
                new_ents[#new_ents].connections[1] = { red = {{e.entity_number,1}} }
            end
        end
    end
    bp.set_blueprint_entities(new_ents)
end)

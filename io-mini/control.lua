-- ### CONTROL: control.lua
-- Place at: processor-io-mini/control.lua
local Event = script.on_event

-- ==========================
-- Config
-- ==========================
local IO_OFFSETS = {
  {x=1.5, y=0},
  {x=-1.5, y=0},
  {x=0, y=1.5},
  {x=0, y=-1.5}
}

-- ==========================
-- Global init
-- ==========================
local function init_storage()
  storage.processors      = storage.processors      or {}   -- unit_number -> {main=LuaEntity, io={LuaEntity,...}}
  storage.saved_wires     = storage.saved_wires     or {}   -- unit_number -> revive snapshot
  storage.external_links  = storage.external_links  or {}   -- unit_number -> { {helper_index, connector_id, wire_type, target_unit, target_conn_id} }
  storage.preview         = storage.preview         or {}   -- player_index -> {render_ids={...}}
end

script.on_init(init_storage)
script.on_configuration_changed(init_storage)

-- ==========================
-- Helpers: lifecycle
-- ==========================
local function create_helpers_for(processor)
  if not (processor and processor.valid) then return end
  if storage.processors[processor.unit_number] then return end

  local io_entities = {}
  for _, off in ipairs(IO_OFFSETS) do
    local pos = {x = processor.position.x + off.x, y = processor.position.y + off.y}
    local io = processor.surface.create_entity{
      name = "processor-io-helper",
      position = pos,
      force = processor.force,
      create_build_effect_smoke = false
    }
    if io then
      io.minable = false
      io.operable = false
      table.insert(io_entities, io)
    end
  end
  storage.processors[processor.unit_number] = {main = processor, io = io_entities}
end

local function destroy_helpers_for(unit_number)
  local data = storage.processors[unit_number]
  if not data then return end
  for _, io in pairs(data.io) do
    if io and io.valid then
      for _, conn in pairs(io.get_wire_connectors()) do
        conn.disconnect_all(defines.wire_origin.script)
      end
      io.destroy()
    end
  end
  storage.processors[unit_number] = nil
  storage.saved_wires[unit_number] = nil
  storage.external_links[unit_number] = nil
end

-- ==========================
-- Wire snapshots (world ↔ revive/preview)
-- ==========================
local function snapshot_world_wires(processor)
  if not (processor and processor.valid) then return end
  local pdata = storage.processors[processor.unit_number]
  if not pdata then return end

  local external = {}
  local revive_snapshot = {main_position = processor.position, surface = processor.surface.name, entries = {}}

  for idx, io in ipairs(pdata.io) do
    if io.valid then
      for _, c in pairs(io.get_wire_connectors()) do
        for _, connection in pairs(c.connections) do
          local tgt = connection.connector
          if tgt and tgt.valid then
            local target_entity = tgt.owner

            -- for revive-in-place restore
            table.insert(revive_snapshot.entries, {
              from_index = idx,
              from_connector_id = c.wire_connector_id,
              wire_type = c.wire_type,
              target_pos = target_entity.position,
              target_name = target_entity.name,
              target_connector_id = tgt.wire_connector_id
            })

            -- for external preview (skip our own helpers)
            local is_helper = (target_entity.valid and target_entity.name == "processor-io-helper")
            if not is_helper then
              table.insert(external, {
                helper_index = idx,
                connector_id = c.wire_connector_id,
                wire_type = c.wire_type,
                target_unit = target_entity.unit_number,
                target_conn_id = tgt.wire_connector_id
              })
            end
          end
        end
      end
    end
  end

  storage.saved_wires[processor.unit_number] = revive_snapshot
  storage.external_links[processor.unit_number] = external
end

local function try_restore_revive_wires(processor)
  local snap = storage.saved_wires[processor.unit_number]
  if not snap then return end
  local pdata = storage.processors[processor.unit_number]
  if not pdata then return end

  for _, entry in ipairs(snap.entries) do
    local from_io = pdata.io[entry.from_index]
    if from_io and from_io.valid then
      local from_conn
      for _, c in pairs(from_io.get_wire_connectors()) do
        if c.wire_connector_id == entry.from_connector_id then from_conn = c break end
      end
      if from_conn then
        local targets = processor.surface.find_entities_filtered{position = entry.target_pos, name = entry.target_name}
        local target = targets[1]
        if target and target.valid then
          local tconn
          for _, tc in pairs(target.get_wire_connectors()) do
            if tc.wire_connector_id == entry.target_connector_id then tconn = tc break end
          end
          if tconn then pcall(function() from_conn.connect_to(tconn, true, defines.wire_origin.script) end) end
        end
      end
    end
  end
  storage.saved_wires[processor.unit_number] = nil
end

-- ==========================
-- Blueprint injection (helpers + internal ghost wires)
-- ==========================

local function inject_helpers_into_blueprint(player)
  local bp = player.blueprint_to_setup
  if not (bp and bp.valid_for_read) then return end
  local ents = bp.get_blueprint_entities()
  if not ents then return end

  -- next entity number
  local next_num = 1
  for _, e in ipairs(ents) do if e.entity_number and e.entity_number >= next_num then next_num = e.entity_number + 1 end end

  local new_ents = {}
  for _, e in ipairs(ents) do table.insert(new_ents, e) end

  for _, e in ipairs(ents) do
    if e.name == "processor" then
      for _, off in ipairs(IO_OFFSETS) do
        local hpos = {x = e.position.x + off.x, y = e.position.y + off.y}
        table.insert(new_ents, {
          entity_number = next_num,
          name = "processor-io-helper",
          position = hpos,
          direction = 0
        })
        next_num = next_num + 1
      end
    end
  end

  -- NOTE: this mini injects helper ghosts but doesn’t reconstruct detailed helper-to-entity connections
  -- inside the blueprint; Factorio will still show helpers and their ports in the cursor preview.
  -- You can extend this by scanning the world helpers during setup and generating 'connections' tables.

  bp.set_blueprint_entities(new_ents)
end

-- ==========================
-- Events
-- ==========================
local function on_built(event)
  local entity = event.created_entity or event.entity
  if not (entity and entity.valid) then return end
  if entity.name == "processor" then
    create_helpers_for(entity)
    try_restore_revive_wires(entity)
    snapshot_world_wires(entity) -- keep external link info fresh
  end
end

local function on_pre_removed(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == "processor" then
    snapshot_world_wires(entity)
  end
end

local function on_removed(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == "processor" then
    destroy_helpers_for(entity.unit_number)
  end
end

local function on_settings_pasted(event)
  local s,d = event.source, event.destination
  if s and d and s.valid and d.valid and s.name == "processor" and d.name == "processor" then
    -- copy any custom settings here
  end
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
        local render = rendering.get_object_by_id(id)
        if render and render.valid then render.destroy() end
    end
    storage.preview[player.index] = nil
end


-- Blueprint setup: inject helpers and refresh a snapshot for preview
script.on_event(defines.events.on_player_setup_blueprint, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local bp = player.blueprint_to_setup
  if not (bp and bp.valid_for_read) then return end
  inject_helpers_into_blueprint(player)

  -- try to snapshot a nearby processor so preview lines look current
  local near = player.surface.find_entities_filtered{position = player.position, radius = 20, name = "processor", force = player.force}
  if near[1] and near[1].valid then snapshot_world_wires(near[1]) end
end)


-- Cursor changes: start/stop preview lines for external connections
script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    stop_external_preview(player)
    local stack = player.cursor_stack
    if stack and stack.valid_for_read then
        if stack.name == "processor" then
            -- For simplicity, just preview the first processor in storage
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

-- Build/destroy pipelines
Event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, on_built)
Event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, on_pre_removed)
Event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.script_raised_destroy}, on_removed)
Event(defines.events.on_entity_settings_pasted, on_settings_pasted)

-- No-op tick (leave room for future smooth cursor following, if you want to interpolate)
script.on_event(defines.events.on_tick, function() end)

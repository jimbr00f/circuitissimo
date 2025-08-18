-- control.lua
local CONNECTOR_NAME  = "your-connector"
local PROCESSOR_NAME  = "your-processor"
local CONNECTOR_ITEM  = "your-connector-item"
local MAX_SNAP_RANGE  = 1.5  -- how close the cursor/place must be to the processor

-- Define snap anchors relative to the processor for each processor direction.
-- Coordinates are TILE positions in processor-local coords.
-- You can have multiple anchors; we’ll pick the nearest free one.
local processor_anchors = {
  -- for processor.direction = defines.direction.north/east/south/west
  [defines.direction.north] = {
    {pos = {x = 0.0, y = -1.0}, dir = defines.direction.north},
    {pos = {x = -1.0, y = 0.0}, dir = defines.direction.west},
    {pos = {x = 1.0,  y = 0.0}, dir = defines.direction.east},
    {pos = {x = 0.0,  y = 1.0}, dir = defines.direction.south},
  },
  [defines.direction.east] = {
    {pos = {x = 1.0, y = 0.0}, dir = defines.direction.east},
    {pos = {x = 0.0, y = -1.0}, dir = defines.direction.north},
    {pos = {x = 0.0, y = 1.0},  dir = defines.direction.south},
    {pos = {x = -1.0, y = 0.0}, dir = defines.direction.west},
  },
  [defines.direction.south] = {
    {pos = {x = 0.0, y = 1.0}, dir = defines.direction.south},
    {pos = {x = 1.0, y = 0.0}, dir = defines.direction.east},
    {pos = {x = -1.0, y = 0.0}, dir = defines.direction.west},
    {pos = {x = 0.0, y = -1.0}, dir = defines.direction.north},
  },
  [defines.direction.west] = {
    {pos = {x = -1.0, y = 0.0}, dir = defines.direction.west},
    {pos = {x = 0.0, y = 1.0},  dir = defines.direction.south},
    {pos = {x = 0.0, y = -1.0}, dir = defines.direction.north},
    {pos = {x = 1.0, y = 0.0},  dir = defines.direction.east},
  }
}

local function distance_sq(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return dx*dx + dy*dy
end

local function refund_item(player, name, count)
  if player and player.valid then
    local inserted = player.insert{name = name, count = count}
    if inserted < count then
      player.surface.spill_item_stack(player.position, {name = name, count = count - inserted}, true)
    end
  end
end

-- Convert an anchor from processor local coords to world coords
local function local_to_world(proc, local_pos)
  return {x = proc.position.x + local_pos.x, y = proc.position.y + local_pos.y}
end

-- Find the best snap target (processor + anchor) given a tentative connector position.
local function choose_snap(surface, pos)
  -- First: find a nearby processor (within MAX_SNAP_RANGE + a cushion)
  local processors = surface.find_entities_filtered{
    name = PROCESSOR_NAME,
    area = {{pos.x - MAX_SNAP_RANGE, pos.y - MAX_SNAP_RANGE},
            {pos.x + MAX_SNAP_RANGE, pos.y + MAX_SNAP_RANGE}}
  }
  if #processors == 0 then return nil end

  -- Pick the processor whose anchor can accept the connector & is closest to the player’s placement
  local best = nil
  local best_d2 = 1/0

  for _, proc in ipairs(processors) do
    local anchors = processor_anchors[proc.direction] or processor_anchors[defines.direction.north]
    for _, anchor in ipairs(anchors) do
      local world_pos = local_to_world(proc, anchor.pos)
      local d2 = distance_sq(world_pos, pos)
      if d2 <= (MAX_SNAP_RANGE * MAX_SNAP_RANGE) then
        if d2 < best_d2 then
          best = {processor = proc, pos = world_pos, dir = anchor.dir}
          best_d2 = d2
        end
      end
    end
  end

  return best
end

local function try_snap_or_reject(entity, player)
  if not (entity and entity.valid and entity.name == CONNECTOR_NAME) then return end
  local surface = entity.surface
  local original_pos = entity.position

  local snap = choose_snap(surface, original_pos)
  if not snap then
    -- No processor in range: reject
    if player then
      refund_item(player, CONNECTOR_ITEM, 1)
      player.create_local_flying_text{position = original_pos, text = {"", "[img=utility/warning_icon] Must place next to a Processor"}}
    end
    entity.destroy{raise_destroy = true}
    return
  end

  -- Check if the snapped position/orientation is actually placeable
  -- (Use can_place_entity with the same force and collision rules)
  if not surface.can_place_entity{
    name = entity.name,
    position = snap.pos,
    direction = snap.dir,
    force = entity.force
  } then
    if player then
      refund_item(player, CONNECTOR_ITEM, 1)
      player.create_local_flying_text{position = original_pos, text = {"", "[img=utility/warning_icon] Anchor blocked"}}
    end
    entity.destroy{raise_destroy = true}
    return
  end

  -- All good: snap the entity into place
  entity.teleport(snap.pos)         -- precise position
  entity.direction = snap.dir       -- snapped orientation

  -- Optional: store association if you want “one connector per anchor” rules later.
  -- Example: storage.anchors[processor.unit_number][anchor_id] = connector.unit_number
end

-- Handle all build avenues: player, robot, and script-raised.
local function on_built(e)
  local ent = e.created_entity or e.entity
  if not (ent and ent.valid and ent.name == CONNECTOR_NAME) then return end
  local player = (e.player_index and game.get_player(e.player_index)) or nil
  try_snap_or_reject(ent, player)
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)

-- If connectors can be revived from ghosts, handle that too:
script.on_event(defines.events.on_entity_cloned, function(e)
  if e.destination and e.destination.valid and e.destination.name == CONNECTOR_NAME then
    try_snap_or_reject(e.destination, nil)
  end
end)

script.on_init(function()
  storage.anchors = storage.anchors or {}
end)

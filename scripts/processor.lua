local common = require('scripts.common')

---@param x1 number
---@param y1 number
---@param count number
---@returns table<defines.direction, MapPosition[]>
local function create_iopoint_positions(x1, y1, count)
  local offset = 2*math.abs(x1) / (count - 1)
  local iter_params = {
    [defines.direction.north] = {x=x1, y=-y1, dx=-offset, dy=0},
    [defines.direction.south] = {x=-x1, y=y1, dx=offset, dy=0},
    [defines.direction.east] = {x=x1, y=y1, dx=0, dy=-offset},
    [defines.direction.west] = {x=-x1, y=-y1, dx=0, dy=offset},
  }
  local side_positions = {}
  for dir, dp in pairs(iter_params) do
    positions = {}
    for i = 1, count do
      table.insert(positions, { x = dp.x, y = dp.y})
      dp.x = dp.x + dp.dx
      dp.y = dp.y + dp.dy
    end
    side_positions[dir] = positions
  end
  local direction_side_pairs = {
    [defines.direction.north] = { defines.direction.west, defines.direction.east},
    [defines.direction.south] = { defines.direction.east, defines.direction.west},
    [defines.direction.east] = { defines.direction.north, defines.direction.south},
    [defines.direction.west] = { defines.direction.south, defines.direction.north},
  }
  local final_positions = {}
  for dir, pair in pairs(direction_side_pairs) do
    final_positions[dir] = {}
    for _, p in pairs(side_positions[pair[1]]) do
      table.insert(final_positions[dir], p)
    end
    for _, p in pairs(side_positions[pair[2]]) do
      table.insert(final_positions[dir], p)
    end
  end
  return final_positions
end


---@param procinfo ProcInfo
local function update_connections(procinfo)
    -- TODO: invoke Factorissimo connection builders
end

--- Initialize processor
---@param procinfo ProcInfo
function init_procinfo(procinfo)
    local processor = procinfo.processor
    if not processor.valid then return end
    local position = processor.position
    local procX = position.x
    local procY = position.y
    local surface = processor.surface
    ---@type LuaEntity[]
    local iopoints = {}

    local find_count = 0

    local iop_position_list = create_iopoint_positions(0.8, 0.8, 4)
    local iop_positions = iop_position_list[processor.direction]

    for _, iop in pairs(iop_positions) do
        local x1 = procX + iop.x
        local y1 = procY + iop.y
        local area = { { x1 - 0.05, y1 - 0.05 }, { x1 + 0.05, y1 + 0.05 } }
        local point
        local points = surface.find_entities_filtered {
            name = common.iopoint_name,
            area = area
        }
        if #points == 0 then
            point = surface.create_entity {
                name = common.iopoint_name,
                position = { x1, y1 },
                force = processor.force
            }
        else
            point = points[1]
            find_count = find_count + 1
        end

        point.destructible = false
        point.minable = false
        table.insert(iopoints, point)
    end

    procinfo.iopoints = iopoints
    processor.rotatable = false
    procinfo.draw_version = 1

    update_connections(procinfo)

    if procinfo.wires then
        for _, def in pairs(procinfo.wires) do
            local iopoint = procinfo.iopoints[def.iopoint_index]
            if iopoint then
                local connector1 = iopoint.get_wire_connector(def.src_connector, true)

                local entities = iopoint.surface.find_entities_filtered { name = def.dst_name, position = def.dst_pos }
                if #entities == 0 then
                    entities = iopoint.surface.find_entities_filtered { name = "entity-ghost", ghost_name = def.dst_name, position = def.dst_pos }
                end
                if #entities == 1 then
                    local target_owner = entities[1]
                    if target_owner then
                        local connector2 = target_owner.get_wire_connector(def.dst_connector, true)
                        connector1.connect_to(connector2, false)
                    end
                end
            end
        end
        procinfo.wires = nil
    end
end
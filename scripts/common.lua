local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"


---@param x1 number
---@param y1 number
---@param count number
---@returns IOPointLayout
local function create_iopoint_layout(x1, y1, count)
    ---@type IOPointLayout
    local layout = {
        dx = 2*math.abs(x1) / (count - 1),
        dy = 2*math.abs(y1) / (count - 1),
        count = count,
        positions = {}
    }
    layout.rx = layout.dx / 2
    layout.ry = layout.dy / 2
  local iter_params = {
    [defines.direction.north] = {x=x1, y=-y1, dx=-layout.dx, dy=0},
    [defines.direction.south] = {x=-x1, y=y1, dx=layout.dx, dy=0},
    [defines.direction.east] = {x=x1, y=y1, dx=0, dy=-layout.dy},
    [defines.direction.west] = {x=-x1, y=-y1, dx=0, dy=layout.dy},
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
  for dir, pair in pairs(direction_side_pairs) do
    layout.positions[dir] = {}
    for _, p in pairs(side_positions[pair[1]]) do
      table.insert(layout.positions[dir], p)
    end
    for _, p in pairs(side_positions[pair[2]]) do
      table.insert(layout.positions[dir], p)
    end
  end
  return layout
end

local common = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    png = function(name) return ('__circuitissimo__/graphics/%s.png'):format(name) end,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_with_tags = prefix .. "-processor_with_tags",
    iopoint_name = prefix .. "-iopoint",
    tag_prefix = '__' .. prefix,
    directions = {
        cardinal = {
            defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west
        }
    },
    ---@enum cardinal_direction
    cardinal_direction = {
        north = 0, --[[@as cardinal_direction.north]]
        east  = 2, --[[@as cardinal_direction.east]]
        south = 4, --[[@as cardinal_direction.south]]
        west  = 6, --[[@as cardinal_direction.west]]
    },
    iopoint_layout = create_iopoint_layout(0.8, 0.8, 4)
}


return common
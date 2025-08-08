local iopoint = require('scripts.iopoint')

local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"

local common = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    mod_prefix = '__' .. prefix .. '__',
    tag_prefix = '__' .. prefix,
    png = function(name) return ('__circuitissimo__/graphics/%s.png'):format(name) end,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_with_tags = prefix .. "-processor_with_tags",
    iopoint_name = prefix .. "-iopoint",
    wire_types = { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green },
    flipped_direction = {},
    iopoint_layout = iopoint.create_iopoint_layout(0.8, 0.8, 4)
}

---@enum cardinal_direction
common.cardinal_direction = {
    north = defines.direction.north, --[[@as cardinal_direction.north]]
    east  = defines.direction.east, --[[@as cardinal_direction.east]]
    south = defines.direction.south, --[[@as cardinal_direction.south]]
    west  = defines.direction.west, --[[@as cardinal_direction.west]]
}

common.direction_name = {
    [defines.direction.north] = "north",
    [defines.direction.east] = "east",
    [defines.direction.south] = "south",
    [defines.direction.west] = "west",
}

common.flipped_direction = {
    [defines.direction.north] = defines.direction.south,
    [defines.direction.south] = defines.direction.north,
    [defines.direction.east] = defines.direction.west,
    [defines.direction.west] = defines.direction.east,
}

---@enum orientation
common.orientation = {
    vertical=1 --[[@as orientation.vertical ]],
    horizontal=2 --[[@as orientation.horizontal ]],
}

common.direction_orientation = {
    [defines.direction.north] = common.orientation.vertical,
    [defines.direction.south] = common.orientation.vertical,
    [defines.direction.east] = common.orientation.horizontal,
    [defines.direction.west] = common.orientation.horizontal,
}


return common
local formation = require "lib.formation"

local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"
local tag_prefix = '__' .. prefix
local mod_prefix = '__' .. prefix .. '__'

local common = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    mod_prefix = mod_prefix,
    tag_prefix = tag_prefix,
    png = function(name) return ('%s/graphics/%s.png'):format(mod_prefix, name) end,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_with_tags = prefix .. "-processor_with_tags",
    iopoint_name = prefix .. "-iopoint"
}

common.wire_types = { 
    defines.wire_connector_id.circuit_red, 
    defines.wire_connector_id.circuit_green 
}

common.cardinal_direction = {
    north = defines.direction.north,
    east  = defines.direction.east,
    south = defines.direction.south,
    west  = defines.direction.west,
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

common.orthogonal_directions = {
    [defines.direction.north] = { defines.direction.west, defines.direction.east},
    [defines.direction.south] = { defines.direction.east, defines.direction.west},
    [defines.direction.east] = { defines.direction.north, defines.direction.south},
    [defines.direction.west] = { defines.direction.south, defines.direction.north},
}

common.direction_orientation = {
    [defines.direction.north] = orientation.vertical,
    [defines.direction.south] = orientation.vertical,
    [defines.direction.east] = orientation.horizontal,
    [defines.direction.west] = orientation.horizontal,
}


common.iopoint_formation = formation.build_oriented_formation({ x = 0.8, y = 0.8}, 4, common.orthogonal_directions)

return common
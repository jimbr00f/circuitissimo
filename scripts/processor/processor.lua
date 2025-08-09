local formation = require "lib.formation"

local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"
local tag_prefix = '__' .. prefix
local mod_prefix = '__' .. prefix .. '__'

local exports = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    mod_prefix = mod_prefix,
    tag_prefix = tag_prefix,
    png = function(name) return ('%s/graphics/processor/%s.png'):format(mod_prefix, name) end,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_with_tags = prefix .. "-processor_with_tags",
    iopoint_name = prefix .. "-iopoint",
    iopoint_formation = formation.build_oriented_formation({ x = 0.8, y = 0.8}, 4, formation.orthogonal_directions),
}

return exports
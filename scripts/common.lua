local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"

local common = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    png = function(name) return ('__circuitissimo__/graphics/%s.png'):format(name) end,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_with_tags = prefix .. "-processor_with_tags",
    iopoint_name = prefix .. "-iopoint",
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
    }
}



return common
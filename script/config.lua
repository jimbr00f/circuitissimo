local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"
local tag_prefix = '__' .. prefix
local mod_prefix = '__' .. prefix .. '__'

---@class CircuitissimoConfig
---@field prefix string
---@field prefix_pattern string
---@field tag_prefix string
---@field mod_prefix string
local CircuitissimoConfig = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    tag_prefix = tag_prefix,
    mod_prefix = mod_prefix,

    -- search for processors within this many tiles of the cursor
    attach_radius = 1.0,
    search_radius = 10.0,
    rendering_interval = 10
}
CircuitissimoConfig.__index = CircuitissimoConfig

return CircuitissimoConfig
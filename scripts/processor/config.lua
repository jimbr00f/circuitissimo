local Formation = require "lib.formation.formation"

local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"
local tag_prefix = '__' .. prefix
local mod_prefix = '__' .. prefix .. '__'

local formation = Formation:new({ x = 1.5, y = 1.5}, 2, 1)
formation:map_paths(Formation.convert.orientation.to_circular_orientation)

---@class ProcessorConfig
---@field prefix string
---@field prefix_pattern string
---@field mod_prefix string
---@field tag_prefix string
---@field processor_name string
---@field processor_pattern string
---@field processor_name_tagged string
---@field iopoint_name string
---@field iopoint_pattern string
---@field iopoint_name_tagged string
---@field iopoint_formation Formation
local ProcessorConfig = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    mod_prefix = mod_prefix,
    tag_prefix = tag_prefix,
    processor_name = prefix .. "-processor",
    processor_pattern = "^" .. prefix_pattern .. "%-processor",
    processor_name_tagged = prefix .. "-processor-tagged",
    iopoint_name = prefix .. "-iopoint",
    iopoint_name_tagged = prefix .. "-iopoint-tagged",
    iopoint_pattern = "^" .. prefix_pattern .. "%-iopoint",
    iopoint_formation = formation,
    iopoint_built_error_text = prefix .. "-iopoint-built-error"
}
ProcessorConfig.__index = ProcessorConfig

---@param subpath string
---@return string
function ProcessorConfig.png_path(subpath)
    return ('%s/graphics/processor/%s.png'):format(ProcessorConfig.mod_prefix, subpath)
end

return ProcessorConfig
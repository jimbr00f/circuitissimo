local Formation = require 'lib.formation'
local ProcessorConfig = require 'scripts.processor.processor'
local Geometry = require 'lib.geometry'

---@return Picture[]
function get_cardinal_pictures(path)
    local pictures = {}
    for name, i in pairs(Geometry.cardinal_direction) do
        ---@type Picture
        pictures[name] = {
            filename = ProcessorConfig.png_path(path),
            width = 128,
            height = 128,
            scale = 0.5,
            x = i/4 * 128
        }
    end
    return pictures
end

local processor_entity = {
    type = "simple-entity-with-owner",
    name = ProcessorConfig.processor_name,
    picture = get_cardinal_pictures("entity/processor"),
    minable = { mining_time = 1, result = ProcessorConfig.processor_name },
    max_health = 250,
    icons = { { icon_size = 64, icon = ProcessorConfig.png_path('icons/processor'), icon_mipmaps = 4 } },
    collision_box = { { -0.95, -0.95 }, { 0.95, 0.95 } },
    selection_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_priority = 60,
    collision_mask = { layers = { floor = true, object = true, water_tile = true }},
    flags = { "placeable-neutral", "player-creation" }
}


local processor_prototypes = {
    processor_entity,
    {
        type = 'item',
        name = ProcessorConfig.processor_name,
        icon_size = 64,
        icon = ProcessorConfig.png_path('icons/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = ProcessorConfig.processor_name,
        stack_size = 50,
        weight = 200000
    }, {
        type = "item-with-tags",
        name = ProcessorConfig.processor_name_tagged,
        icon_size = 64,
        icon = ProcessorConfig.png_path('icons/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = ProcessorConfig.processor_name,
        stack_size = 1,
        flags = { "not-stackable" }
    }
}

data:extend(processor_prototypes)
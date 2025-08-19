local formation = require 'lib.formation'
local processor = require 'scripts.processor.processor'

---@return Picture[]
function get_cardinal_pictures(path)
    local pictures = {}
    for name, i in pairs(formation.cardinal_direction) do
        ---@type Picture
        pictures[name] = {
            filename = processor.png(path),
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
    name = processor.processor_name,
    picture = get_cardinal_pictures("entity/processor"),
    minable = { mining_time = 1, result = processor.processor_name },
    max_health = 250,
    icons = { { icon_size = 64, icon = processor.png('icons/processor'), icon_mipmaps = 4 } },
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
        name = processor.processor_name,
        icon_size = 64,
        icon = processor.png('icons/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.processor_name,
        stack_size = 50,
        weight = 200000
    }, {
        type = "item-with-tags",
        name = processor.processor_name_tagged,
        icon_size = 64,
        icon = processor.png('icons/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.processor_name,
        stack_size = 1,
        flags = { "not-stackable" }
    }
}

data:extend(processor_prototypes)
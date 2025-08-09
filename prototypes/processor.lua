local formation = require "lib.formation"
local processor = require "scripts.processor.processor"

local iopoint_sprite = {
    count = 1,
    filename = processor.png("entity/invisible"),
    width = 1,
    height = 1,
    direction_count = 4
}

local electric_pole = table.deepcopy(data.raw["electric-pole"]["medium-electric-pole"])
local connection_points = {
    wire = { red = { 0, 0 }, green = { 0, 0 }, copper = { 0, 0} }, 
    shadow = { red = { 0, 0 }, green = { 0, 0 }, copper = {0, 0} } 
}

local iopoint_entity = table.merge(electric_pole,  {
    name = processor.iopoint_name,
    icon = processor.png('entity/iopoint'),
    icon_size = 16,
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = processor.iopoint_formation.item_shape.box,
    selection_priority = 70,
    minable = nil,
    flags = { "player-creation", "placeable-off-grid", "placeable-neutral", "hide-alt-info", "not-deconstructable", "not-upgradable", "not-on-map" },
    circuit_wire_max_distance = 64,
    maximum_wire_distance = 9,
    supply_area_distance = 0,
    drawing_box_vertical_extension = 0,
    auto_connect_up_to_n_wires = 0,
    draw_copper_wires = false,
    draw_circuit_wires = true,
    connection_points = { connection_points, connection_points, connection_points, connection_points },
    pictures = { layers = { iopoint_sprite, iopoint_sprite }},
  }
)

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
    icons = { { icon_size = 64, icon = processor.png('item/processor'), icon_mipmaps = 4 } },
    collision_box = { { -0.95, -0.95 }, { 0.95, 0.95 } },
    selection_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_priority = 60,
    collision_mask = { layers = { ["floor"]=true, ["object"]=true, ["water_tile"]=true } },
    flags = { "placeable-neutral", "player-creation" }
}

data:extend{iopoint_entity}

local processor_items = { 
    {
        type = 'item',
        name = processor.processor_name,
        icon_size = 64,
        icon = processor.png('item/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.processor_name,
        stack_size = 50,
        weight = 200000
    }, {
        type = "item-with-tags",
        name = processor.processor_with_tags,
        icon_size = 64,
        icon = processor.png('item/processor'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.processor_name,
        stack_size = 1,
        flags = { "not-stackable" }
    }
}

data:extend{iopoint_entity, processor_entity}
data:extend(processor_items)
local formation = require 'lib.formation'
local processor = require 'scripts.processor.processor'
local proto = require 'lib.prototypes'
require '__base__.prototypes.entity.entities'
local iopoint_sprite = {
    count = 1,
    filename = processor.png("entity/invisible"),
    width = 1,
    height = 1,
    direction_count = 4
}

local constant_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

---@type WireConnectionOrigin
local iopoint_connection_origin = {
    entity = { x = 0, y = -8 },
    shadow = { x = 8, y = -1 }
}
---@type WireConnectionOffsets
local iopoint_connection_offsets = {
    entity = {
        { x = 2, y = -2 },
        { x = -2, y = -2 },
        { x = -6, y = 6 },
        { x = 6, y = -6 },
    },
    shadow = {
        { x = -2, y = -6 },
        { x = -7, y = -6 },
        { x = -6, y = 5 },
        { x = 6, y = 5 },
    }
}

local connection_points = proto.create_wire_connection_points(iopoint_connection_origin, iopoint_connection_offsets)


local iopoint_entity = table.merge(constant_combinator,  {
    name = processor.iopoint_name,
    icon = processor.png('icons/iopoint'),
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
    selection_priority = 70,
    flags = { "player-creation", "placeable-off-grid", "placeable-neutral" },
    circuit_wire_max_distance = 64,
    connection_points = connection_points,

    corpse = "small-remnants",
    dying_explosion = "explosion",
    fast_replaceable_group = processor.iopoint_name,
    icon_draw_specification = {scale = 0.7},
    sprites = make_4way_animation_from_spritesheet({layers =
    {
        {
            scale = 0.5,
            filename = processor.png('entity/iopoint'),
            width = 48,
            height = 48,
            shift = util.by_pixel(-1, -6)
        },
        {
            scale = 0.5,
            filename = processor.png('entity/iopoint-shadow'),
            width = 64,
            height = 48,
            shift = util.by_pixel(9, -2),
            draw_as_shadow = true,
        }
    }}),
    activity_led_light_offsets =
    {
        util.by_pixel(0, 4),
        util.by_pixel(0, 4),
        util.by_pixel(0, 4),
        util.by_pixel(0, 4),
    },
  }
)

local circuit_wire_pole = {
  type = "item",
  name = "circuit-wire-pole",
  icon = "__circuit-wire-poles__/graphics/circuit-wire-pole-item.png",
  icon_size = 64,
  subgroup = "circuit-network",
  order = "b[wires]-c[circuit-wire-pole]",
  place_result = "circuit-wire-pole",
  stack_size = 50
}

local iopoint_items = {
    {
        type = 'item',
        name = processor.iopoint_name,
        icon_size = 48,
        icon = processor.png('icons/iopoint'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.iopoint_name,
        stack_size = 50,
        weight = 200000
    }, 
    {
        type = "item-with-tags",
        name = processor.iopoint_name_tagged,
        icon_size = 48,
        icon = processor.png('icons/iopoint'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = processor.iopoint_name,
        stack_size = 1,
        flags = { "not-stackable" }
    }
}

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
    collision_mask = { layers = { ["floor"]=true, ["object"]=true, ["water_tile"]=true } },
    flags = { "placeable-neutral", "player-creation" }
}


local processor_items = { 
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

data:extend{iopoint_entity, processor_entity}
data:extend(processor_items)
data:extend(iopoint_items)
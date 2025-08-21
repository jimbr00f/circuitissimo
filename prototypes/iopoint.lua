local ProcessorConfig = require 'scripts.processor.config'
local proto_lib = require 'lib.prototypes'
require '__base__.prototypes.entity.entities'

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

local connection_points = proto_lib.create_wire_connection_points(iopoint_connection_origin, iopoint_connection_offsets)


local iopoint_entity = table.merge(constant_combinator,  {
    name = ProcessorConfig.iopoint_name,
    icon = ProcessorConfig.png_path('icons/iopoint'),
    icon_size = 64,
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
    selection_priority = 70,
    flags = { "player-creation", "placeable-neutral" },
    circuit_wire_max_distance = 64,
    -- connection_points = connection_points,
    corpse = "small-remnants",
    dying_explosion = "explosion",
    fast_replaceable_group = ProcessorConfig.iopoint_name,
    icon_draw_specification = {scale = 0.7},
    sprites = make_4way_animation_from_spritesheet({layers =
    {
        {
            scale = 0.5,
            filename = ProcessorConfig.png_path('entity/iopoint'),
            width = 48,
            height = 48,
            shift = util.by_pixel(-1, -6)
        },
        {
            scale = 0.5,
            filename = ProcessorConfig.png_path('entity/iopoint-shadow'),
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

local iopoint_prototypes = {
    iopoint_entity,
    {
        type = 'item',
        name = ProcessorConfig.iopoint_name,
        icon_size = 64,
        icon = ProcessorConfig.png_path('icons/iopoint'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = ProcessorConfig.iopoint_name,
        stack_size = 50,
        weight = 200000
    }, 
    {
        type = "item-with-tags",
        name = ProcessorConfig.iopoint_name_tagged,
        icon_size = 64,
        icon = ProcessorConfig.png_path('icons/iopoint'),
        subgroup = 'circuit-network',
        order = 'p[rocessor]',
        place_result = ProcessorConfig.iopoint_name,
        stack_size = 1,
        flags = { "not-stackable" }
    }
}

data:extend(iopoint_prototypes)
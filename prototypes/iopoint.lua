local ProcessorConfig = require 'scripts.processor.config'
local proto_lib = require 'lib.prototypes'
require '__base__.prototypes.entity.entities'

local constant_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

local pixel_connection_points = {
    {
        wire = {
            red = { x = -2, y = -4 },
            green = { x = 3, y = -2 }
        },
        shadow = {
            red = { x = 0, y = 0 },
            green = { x = 0, y = 0 }
        }
    },
    {
        wire = {
            red = { x = 4, y = -4 },
            green = { x = -2, y = -2 }
        },
        shadow = {
            red = { x = 0, y = 0 },
            green = { x = 0, y = 0 }
        }
    },
    {
        wire = {
            red = { x = 9, y = -1 },
            green = { x = -7, y = -7 }
        },
        shadow = {
            red = { x = 0, y = 0 },
            green = { x = 0, y = 0 }
        }
    },
    {
        wire = {
            red = { x = -6, y = -1 },
            green = { x = 8, y = -7 }
        },
        shadow = {
            red = { x = 0, y = 0 },
            green = { x = 0, y = 0 }
        }
    },
}

local connection_points = proto_lib.convert_pixels_to_tiles(pixel_connection_points)

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
            height = 48
        },
        {
            scale = 0.5,
            filename = ProcessorConfig.png_path('entity/iopoint-shadow'),
            width = 64,
            height = 48,
            shift = util.by_pixel(12, 4),
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
    circuit_wire_connection_points = connection_points
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
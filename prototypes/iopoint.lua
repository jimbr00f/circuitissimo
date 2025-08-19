require("util")
local hit_effects = require ("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")
local base_entities = require("__base__.prototypes.entity.entities")
local processor = require "scripts.processor.processor"
local connector = require "__core__.lualib.circuit-connector-sprites"
local proto = require "lib.prototypes"

local default_combinator_graphics = {
    sprites = base_entities.make_4way_animation_from_spritesheet({layers =
    {
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/constant-combinator.png",
            width = 114,
            height = 102,
            shift = util.by_pixel(0, 5)
        },
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
            width = 98,
            height = 66,
            shift = util.by_pixel(8.5, 5.5),
            draw_as_shadow = true
        }
    }
    }),
    activity_led_sprites =
    {
        north = util.draw_as_glow
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/activity-leds/constant-combinator-LED-N.png",
            width = 14,
            height = 12,
            shift = util.by_pixel(9, -11.5)
        },
        east = util.draw_as_glow
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/activity-leds/constant-combinator-LED-E.png",
            width = 14,
            height = 14,
            shift = util.by_pixel(7.5, -0.5)
        },
        south = util.draw_as_glow
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/activity-leds/constant-combinator-LED-S.png",
            width = 14,
            height = 16,
            shift = util.by_pixel(-9, 2.5)
        },
        west = util.draw_as_glow
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/activity-leds/constant-combinator-LED-W.png",
            width = 14,
            height = 16,
            shift = util.by_pixel(-7, -15)
        }
    },
    circuit_wire_connection_points =
    {
        {
            shadow =
            {
                red = util.by_pixel(7, -6),
                green = util.by_pixel(23, -6)
            },
            wire =
            {
                red = util.by_pixel(-8.5, -17.5),
                green = util.by_pixel(7, -17.5)
            }
        },
        {
            shadow =
            {
                red = util.by_pixel(32, -5),
                green = util.by_pixel(32, 8)
            },
            wire =
            {
                red = util.by_pixel(16, -16.5),
                green = util.by_pixel(16, -3.5)
            }
        },
        {
            shadow =
            {
                red = util.by_pixel(25, 20),
                green = util.by_pixel(9, 20)
            },
            wire =
            {
                red = util.by_pixel(9, 7.5),
                green = util.by_pixel(-6.5, 7.5)
            }
        },
        {
            shadow =
            {
                red = util.by_pixel(1, 11),
                green = util.by_pixel(1, -2)
            },
            wire =
            {
                red = util.by_pixel(-15, -0.5),
                green = util.by_pixel(-15, -13.5)
            }
        }
    }
}

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


local iopoint_connection_points = proto.create_wire_connection_points(iopoint_connection_origin, iopoint_connection_offsets)

local iopoint_entity = {
    type = "constant-combinator",
    name = processor.iopoint_name,
    icon = processor.png('icons/iopoint'),
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 0.1, result = "circuit-wire-pole"},
    max_health = 100,
    corpse = "small-remnants",
    dying_explosion = "explosion",
    collision_box = { {-0.35, -0.35}, {0.35, 0.35} },
    selection_box = { {-0.5, -0.5}, {0.5, 0.5} },
    damaged_trigger_effect = hit_effects.entity(),
    vehicle_impact_sound = sounds.generic_impact,
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    circuit_wire_max_distance = 32.5,
    circuit_wire_connection_points = iopoint_connection_points,
    activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
    sprites = base_entities.make_4way_animation_from_spritesheet({layers={
        {
            filename = processor.png("entity/iopoint"),
            width = 48,
            height = 48,
            shift = util.by_pixel(-1, -13),
            scale = 0.5
        },
        {
            filename = processor.png("entity/iopoint-shadow"),
            width = 64,
            height = 48,
            draw_as_shadow = true,
            shift = util.by_pixel(19, -2),
            scale = 0.5
        }
    }})
}

---@type data.ConstantCombinatorPrototype
local builtin_constant_combinator =
{
    type = "constant-combinator",
    name = "constant-combinator",
    icon = "__base__/graphics/icons/constant-combinator.png",
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 0.1, result = "constant-combinator"},
    max_health = 120,
    corpse = "constant-combinator-remnants",
    dying_explosion = "constant-combinator-explosion",
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    damaged_trigger_effect = hit_effects.entity(),
    fast_replaceable_group = "constant-combinator",
    open_sound = sounds.combinator_open,
    close_sound = sounds.combinator_close,
    icon_draw_specification = {scale = 0.7},
    activity_led_light =
    {
        intensity = 0,
        size = 1,
        color = {r = 1.0, g = 1.0, b = 1.0}
    },
    
    activity_led_light_offsets =
    {
        {0.296875, -0.40625},
        {0.25, -0.03125},
        {-0.296875, -0.078125},
        {-0.21875, -0.46875}
    },
    
    circuit_wire_max_distance = connector.combinator_circuit_wire_max_distance
}
local common = require("scripts.common")

local iopoint_sprite = {
    count = 1,
    filename = common.png("invisible"),
    width = 1,
    height = 1,
    direction_count = 1
}

local iopoint = {
    type = "lamp",
    name = common.prefix .. "-iopoint",
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_priority = 70,
    minable = nil,
    maximum_wire_distance = 9,
    max_health = 10,
    icon_size = 16,
    icon = common.png('entity/iopoint'),
    flags = { "placeable-off-grid", "placeable-neutral", "player-creation" },
    circuit_wire_max_distance = 9,

    picture_on = iopoint_sprite,
    picture_off = iopoint_sprite,
    energy_source = { type = "void" },
    energy_usage_per_tick = "1J"
}

data:extend{iopoint}
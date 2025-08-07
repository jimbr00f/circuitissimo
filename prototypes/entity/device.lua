local commons = require("scripts.commons")

local invisible_sprite = {
    count = 1,
    filename = commons.png("invisible"),
    width = 1,
    height = 1,
    direction_count = 1
}

local device = {
    type = "lamp",
    name = commons.device_name,
    icons = { { icon_size = 64, icon = commons.png('item/processor'), icon_mipmaps = 4 } },
    minable = { mining_time = 0.5, result = commons.processor_name },
    collision_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    selection_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    selection_priority = 50,
    picture_on = { layers = { invisible_sprite } },
    picture_off = { layers = { invisible_sprite } },
    always_on = false,
    max_health = 1000,
    collision_mask = { layers={} },
    flags = {
        "hide-alt-info", "not-upgradable", "not-blueprintable",
        "placeable-off-grid"
    },
    energy_usage_per_tick = "1kJ",
    energy_source = { type = "electric", usage_priority = "secondary-input" },
    circuit_wire_connection_point = nil,
    selectable_in_game = false
}

data:extend{device}
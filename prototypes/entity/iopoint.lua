local common = require("scripts.common")
local utility = require("scripts.utility")

local iopoint_layout = common.iopoint_layout

local iopoint_sprite = {
    count = 1,
    filename = common.png("invisible"),
    width = 1,
    height = 1,
    direction_count = 4
}

local electric_pole = table.deepcopy(data.raw["electric-pole"]["medium-electric-pole"])
local connection_points = {
    wire = { red = { 0, 0 }, green = { 0, 0 }, copper = { 0, 0} }, 
    shadow = { red = { 0, 0 }, green = { 0, 0 }, copper = {0, 0} } 
}

local iopoint = utility.coalesce_tables({ electric_pole,  {
    name = common.iopoint_name,
    icon = common.png('entity/iopoint'),
    icon_size = 16,
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = { { -iopoint_layout.rx, -iopoint_layout.ry }, { iopoint_layout.rx, iopoint_layout.ry } },
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
    connection_points = {connection_points, connection_points, connection_points, connection_points},
    pictures = { layers = { iopoint_sprite, iopoint_sprite }},
  },
})

data:extend{iopoint}
local common = require("scripts.common")

local iopoint_layout = common.iopoint_layout

local iopoint_sprite = {
    count = 1,
    filename = common.png("invisible"),
    width = 1,
    height = 1,
    direction_count = 1
}

local wire_conn = { 
    wire = { red = { 0, 0 }, green = { 0, 0 } }, 
    shadow = { red = { 0, 0 }, green = { 0, 0 } } 
}

function merge_table(dst, sources)
	for _, src in pairs(sources) do
		for name, value in pairs(src) do
			dst[name] = value
		end
	end
	return dst
end
local function table_add(t, e)
	for _, s in ipairs(t) do
		if s == e then return end
	end
	table.insert(t, e)
end

local function insert_flags(flags)
    table_add(flags, "hide-alt-info")
    table_add(flags, "not-on-map")
    table_add(flags, "not-upgradable")
    table_add(flags, "not-deconstructable")
    table_add(flags, "not-blueprintable")
end
local invisible_sprite = { filename = common.png('invisible'), width = 1, height = 1 }
	local commons_attr = {
		flags = { 'placeable-off-grid' },
		collision_mask = { layers = {} },
		minable = nil,
		selectable_in_game = false,
		circuit_wire_max_distance = 64,
		sprites = invisible_sprite,
		activity_led_sprites = invisible_sprite,
		activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
		circuit_wire_connection_points = { wire_conn, wire_conn, wire_conn, wire_conn },
		draw_circuit_wires = true,
		collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
		created_smoke = nil,
		selection_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
		maximum_wire_distance = 2

	}

local cc_iopoint = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
cc_iopoint = merge_table(cc_iopoint, { commons_attr, {
    name = common.iopoint_name
} })
insert_flags(cc_iopoint.flags)

local iopoint = {
    type = "lamp",
    name = common.iopoint_name,
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    collision_mask = { layers={} },
    selection_box = { { -iopoint_layout.rx, -iopoint_layout.ry }, { iopoint_layout.rx, iopoint_layout.ry } },
    selection_priority = 70,
    minable = nil,
    maximum_wire_distance = 9,
    max_health = 10,
    icon_size = 16,
    icon = common.png('entity/iopoint'),
    flags = { "placeable-off-grid", "placeable-neutral", "hide-alt-info", "not-deconstructable", "not-upgradable", "not-on-map", "not-selectable-in-game"},
    circuit_wire_max_distance = 64,

    picture_on = iopoint_sprite,
    picture_off = iopoint_sprite,
    energy_source = { type = "void" },
    energy_usage_per_tick = "1J"
}
data:extend{iopoint}
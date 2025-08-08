local common = require("scripts.common")
local utility = require("scripts.utility")

local processor = {
    type = "simple-entity-with-owner",
    name = common.processor_name,
    picture = utility.get_cardinal_pictures("entity/processor"),
    minable = { mining_time = 1, result = common.processor_name },
    max_health = 250,
    icons = { { icon_size = 64, icon = common.png('item/processor'), icon_mipmaps = 4 } },
    collision_box = { { -0.95, -0.95 }, { 0.95, 0.95 } },
    selection_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_priority = 60,
    collision_mask = { layers = { ["floor"]=true, ["object"]=true, ["water_tile"]=true } },
    flags = { "placeable-neutral", "player-creation" }
}

data:extend{processor}
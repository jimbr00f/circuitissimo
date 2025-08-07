local commons = require("scripts.commons")

---@return Picture[]
function get_processor_pictures()
    local pictures = {}
    for i = 1, 4 do
        --@type Picture
        local picture = {
            filename = commons.png("entity/processor"),
            width = 128,
            height = 128,
            scale = 0.5,
            x = (i - 1) * 128
        }
        table.insert(pictures, picture)
    end
    return pictures
end

local processor = {
    type = "simple-entity-with-owner",
    name = commons.processor_name,
    picture = get_processor_pictures(),
    minable = { mining_time = 1, result = commons.processor_name },
    max_health = 250,
    icons = { { icon_size = 64, icon = commons.png('item/processor'), icon_mipmaps = 4 } },
    collision_box = { { -0.95, -0.95 }, { 0.95, 0.95 } },
    selection_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_priority = 60,
    collision_mask = { layers = { ["floor"]=true, ["object"]=true, ["water_tile"]=true } },
    flags = { "placeable-neutral", "player-creation" }
}

data:extend{processor}
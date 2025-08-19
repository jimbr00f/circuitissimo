---@class Geometry
---@field cardinal_direction table<string, defines.direction>
---@field flipped_direction table<defines.direction, defines.direction>
---@field orthogonal_directions table<defines.direction, defines.direction[]>
---@field orientable_directions table<defines.direction, defines.direction[]>
---@field direction_orientation table<defines.direction, orientation>
local Geometry = {}

---@param entity LuaEntity
---@param radius number
---@return BoundingBox
function Geometry.get_search_area(entity, radius)
    local box = entity.selection_box
    ---@type BoundingBox
    local area = {
        left_top = { x = box.left_top.x - radius, y = box.left_top.y - radius },
        right_bottom = { x = box.right_bottom.x + radius, y = box.right_bottom.y + radius }
    }
    return area
end

Geometry.cardinal_direction = {
    north = defines.direction.north,
    east  = defines.direction.east,
    south = defines.direction.south,
    west  = defines.direction.west,
}

Geometry.flipped_direction = {
    [defines.direction.north] = defines.direction.south,
    [defines.direction.east] = defines.direction.west,
    [defines.direction.south] = defines.direction.north,
    [defines.direction.west] = defines.direction.east,
}

Geometry.orthogonal_directions = {
    [defines.direction.north] = { defines.direction.west, defines.direction.east },
    [defines.direction.east] = { defines.direction.north, defines.direction.south },
    [defines.direction.south] = { defines.direction.east, defines.direction.west },
    [defines.direction.west] = { defines.direction.south, defines.direction.north },
}

Geometry.orientable_directions = {
    [defines.direction.north] = { defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west },
    [defines.direction.east] = { defines.direction.east, defines.direction.south, defines.direction.west, defines.direction.north },
    [defines.direction.south] = { defines.direction.south, defines.direction.west, defines.direction.north, defines.direction.east },
    [defines.direction.west] = { defines.direction.west, defines.direction.north, defines.direction.east, defines.direction.south },
}

Geometry.direction_orientation = {
    [defines.direction.north] = orientation.vertical,
    [defines.direction.east] = orientation.horizontal,
    [defines.direction.south] = orientation.vertical,
    [defines.direction.west] = orientation.horizontal,
}

return Geometry
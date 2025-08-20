---@class Geometry
---@field cardinal_direction table<string, defines.direction>
---@field flipped_direction table<defines.direction, defines.direction>
---@field orthogonal_directions table<defines.direction, defines.direction[]>
---@field orientable_directions table<defines.direction, defines.direction[]>
---@field direction_axis table<defines.direction, axis>
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

Geometry.canonical_direction_orientation = {
    [defines.direction.north] = orientation.r0,
    [defines.direction.east] = orientation.r1,
    [defines.direction.south] = orientation.r2,
    [defines.direction.west] = orientation.r3,
}

Geometry.mirror_direction_orientation = {
    [defines.direction.north] = orientation.mr0,
    [defines.direction.east] = orientation.mr3,
    [defines.direction.south] = orientation.mr2,
    [defines.direction.west] = orientation.mr1,
}

Geometry.circular_orientations = {
    [orientation.r0] = { orientation.r0,orientation.r1,orientation.r2,orientation.r3, },
    [orientation.r1] = { orientation.r1,orientation.r2,orientation.r3,orientation.r0, },
    [orientation.r2] = { orientation.r2,orientation.r3,orientation.r0,orientation.r1 },
    [orientation.r3] = { orientation.r3,orientation.r0,orientation.r1,orientation.r2, },
    [orientation.mr0] = { orientation.mr0,orientation.mr1,orientation.mr2,orientation.mr3, },
    [orientation.mr1] = { orientation.mr1,orientation.mr2,orientation.mr3,orientation.mr0, },
    [orientation.mr2] = { orientation.mr2,orientation.mr3,orientation.mr0,orientation.mr1 },
    [orientation.mr3] = { orientation.mr3,orientation.mr0,orientation.mr1,orientation.mr2, },
}

Geometry.direction_axis = {
    [defines.direction.north] = axis.vertical,
    [defines.direction.east] = axis.horizontal,
    [defines.direction.south] = axis.vertical,
    [defines.direction.west] = axis.horizontal,
}

return Geometry
local FormationSlot = require 'lib.formation.slot'

---@class FormationShape
local FormationShape = {}

---@param radial_size RadialSize
---@return SimpleShape
function FormationShape.convert_size_to_shape(radial_size)
    radial_size = { x = math.abs(radial_size.x), y = math.abs(radial_size.y) }
    local left_top = { x = -radial_size.x, y = -radial_size.y }
    local right_bottom = { x = radial_size.x, y = radial_size.y }
    ---@type SimpleShape
    local shape = { 
        left_top = left_top,
        right_bottom = right_bottom,
        box = { left_top = left_top, right_bottom = right_bottom }, 
        size = {
            width = 2 * radial_size.x, 
            height = 2 * radial_size.y
        },
        radius = radial_size
    }
    return shape
end

---@param boundary_size RadialSize
---@param item_count integer
---@return PartitionShape
function FormationShape.get_partition_shape(boundary_size, item_count)
    local container_shape = FormationShape.convert_size_to_shape(boundary_size)
    ---@type RadialSize
    local item_boundary_size = { 
        x = boundary_size.x / (item_count - 1), 
        y = boundary_size.y / (item_count - 1) 
    }
    local item_shape = FormationShape.convert_size_to_shape(item_boundary_size)
    return {
        shape = container_shape,
        item_shape = item_shape,
        item_count = item_count
    }
end

---@param container_shape SimpleShape
---@param item_shape SimpleShape
---@return OrientableOrigin
function FormationShape.build_orientable_origin(container_shape, item_shape)
    local lt = container_shape.left_top
    local rb = container_shape.right_bottom
    local isize = item_shape.size
    local origin = {
        [orientation.r0] = { point = { x = lt.x, y = lt.y }, delta = { x = isize.width, y = 0 } },
        [orientation.r1] = { point = { x = rb.x, y = lt.y }, delta = { x = 0, y = isize.height } },
        [orientation.r2] = { point = { x = rb.x, y = rb.y }, delta = { x = -isize.width, y = 0 } },
        [orientation.r3] = { point = { x = lt.x, y = rb.y }, delta = { x = 0, y = -isize.height } },
        [orientation.mr0] = { point = { x = -lt.x, y = lt.y }, delta = { x = -isize.width, y = 0 } },
        [orientation.mr1] = { point = { x = -rb.x, y = lt.y }, delta = { x = 0, y = isize.height } },
        [orientation.mr2] = { point = { x = -rb.x, y = rb.y }, delta = { x = isize.width, y = 0 } },
        [orientation.mr3] = { point = { x = -lt.x, y = rb.y }, delta = { x = 0, y = -isize.height } },
    }
    return origin
end

---@param origin OrientableOrigin
---@return OrientablePath
function FormationShape.build_orientable_path(origin, count)
    ---@type OrientablePath
    local path = {}
    for orientation, pv in pairs(origin) do
        ---@type OrientedPath
        local opath = { orientation = orientation, points = {} }
        local p = { x = pv.point.x, y = pv.point.y }
        for _ = 1, count do
            table.insert(opath.points, p)
            p = {
                x = p.x + pv.delta.x,
                y = p.y + pv.delta.y
            }
        end
        path[orientation] = opath
    end
    return path
end

---@param path OrientablePath
---@param map OrientationMapping
---@returns table<orientation, FormationPath>
function FormationShape.build_formation_paths(path, map)
    ---@type table<orientation, FormationPath>
    local formation_paths = {}
    for orientation, path_keys in pairs(map) do
        ---@type FormationSlot[]
        local slots = {}
        for _, path_key in ipairs(path_keys) do
            local subpath = path[path_key]
            for _, point in ipairs(subpath.points) do
                ---@type FormationSlot
                table.insert(slots, FormationSlot:new(#slots + 1, point))
            end
        end
        ---@type FormationPath
        formation_paths[orientation] = { 
            orientation = orientation, 
            slots = slots
        }
    end
    return formation_paths
end

return FormationShape
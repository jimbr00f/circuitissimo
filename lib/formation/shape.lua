local FormationConversion = require 'conversion'
local FormationSlot = require 'slot'

---@class FormationShape
local FormationShape = {}
FormationShape.__index = FormationShape

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

---@param margin integer|MapPosition|nil
---@return MapPosition
function FormationShape.normalize_margin(margin)
    if not margin then
        return { x = 0, y = 0 }
    elseif type(margin) == "number" then 
        return { x = margin, y = margin } 
    else
        return { 
            x = margin.x or margin[1] , 
            y = margin.y or margin[2] 
        }
    end
end

---@param boundary_size RadialSize
---@param item_count integer
---@param margin MapPosition
---@return PartitionShape
function FormationShape.get_partition_shape(boundary_size, item_count, margin)
    local container_shape = FormationShape.convert_size_to_shape(boundary_size)

    ---@type RadialSize
    local item_boundary_size = { 
        x = (boundary_size.x - 2 * margin.x) / (item_count - 1), 
        y = (boundary_size.y - 2 * margin.y) / (item_count - 1) 
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
---@param margin MapPosition
---@return OrientableOrigin
function FormationShape.build_orientable_origin(container_shape, item_shape, margin)
    local lt = container_shape.left_top
    local rb = container_shape.right_bottom
    local isize = item_shape.size
    local points = {
        n = { x = lt.x + margin.x, y = lt.y },
        e = { x = rb.x, y = lt.y + margin.y },
        s = { x = rb.x - margin.x, y = rb.y },
        w = { x = lt.x, y = rb.y - margin.y }
    }
    local origin = {
        [orientation.r0] = { point = points.n, delta = { x = isize.width, y = 0 } },
        [orientation.r1] = { point = points.e, delta = { x = 0, y = isize.height } },
        [orientation.r2] = { point = points.s, delta = { x = -isize.width, y = 0 } },
        [orientation.r3] = { point = points.w, delta = { x = 0, y = -isize.height } },
        [orientation.mr0] = { point = { x = -(points.n.x), y = points.n.y }, delta = { x = -isize.width, y = 0 } },
        [orientation.mr1] = { point = { x = -(points.e.x), y = points.e.y }, delta = { x = 0, y = isize.height } },
        [orientation.mr2] = { point = { x = -(points.s.x), y = points.s.y }, delta = { x = isize.width, y = 0 } },
        [orientation.mr3] = { point = { x = -(points.w.x), y = points.w.y }, delta = { x = 0, y = -isize.height } },
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

return FormationShape
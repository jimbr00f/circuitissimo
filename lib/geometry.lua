local tables = require('lib.tables')
local exports = {}

---@param radial_size RadialSize
---@return SimpleShape
local function convert_radial_to_rect(radial_size)
    radial_size = { x = math.abs(radial_size.x), y = math.abs(radial_size.y) }
    ---@type SimpleShape
    local bounds = { 
        left_top = { x = -radial_size.x, y = -radial_size.y },
        right_bottom = { x = radial_size.x, y = radial_size.y },
        size = {
            width = 2 * radial_size.x, 
            height = 2 * radial_size.y
        },
        radius = radial_size
    }
    return bounds
end

---@param boundary_size RadialSize
---@param item_count integer
---@return PartitionShape
local function get_partition_shape(boundary_size, item_count)
    local container_shape = convert_radial_to_rect(boundary_size)
    ---@type RadialSize
    local item_boundary_size = { 
        x = boundary_size.x / (item_count - 1), 
        y = boundary_size.y / (item_count - 1) 
    }
    local item_shape = convert_radial_to_rect(item_boundary_size)
    return {
        shape = container_shape,
        item_shape = item_shape,
        item_count = item_count
    }
end

---@param container_shape SimpleShape
---@param item_shape SimpleShape
---@return OrientableOrigin
local function build_orientable_origin(container_shape, item_shape)
    local lt = container_shape.left_top
    local rb = container_shape.right_bottom
    local isize = item_shape.size
    local origin = {
        [defines.direction.north] = { point = { x = rb.x, y = lt.y }, delta = { x = -isize.width, y = 0 } },
        [defines.direction.south] = { point = { x = lt.x, y = rb.y }, delta = { x = isize.width, y = 0 } },
        [defines.direction.east] =  { point = { x = rb.x, y = rb.y }, delta = { x = 0, y = -isize.height } },
        [defines.direction.west] =  { point = { x = lt.x, y = lt.y }, delta = { x = 0, y = isize.height } },
    }
    return origin
end

---@param origin OrientableOrigin
---@return OrientablePath
local function build_orientable_path(origin, count)
    ---@type OrientablePath
    local path = {}
    for dir, pv in pairs(origin) do
        ---@type Point[]
        local positions = {}
        local p = { x = pv.point.x, y = pv.point.y }
        for _ = 1, count do
            table.insert(positions, p)
            p = {
                x = p.x + pv.delta.x,
                y = p.y + pv.delta.y
            }
        end
        path[dir] = positions
    end
    return path
end

---@param size RadialSize
---@param count integer
---@returns OrientableLayoutInstance
function exports.build_orientable_layout(size, count)
    local instance = get_partition_shape(size, count) --[[@as OrientableLayoutInstance]]
    instance.origin = build_orientable_origin(instance.shape, instance.item_shape)
    instance.path = build_orientable_path(instance.origin, count)
    return instance
end

---@param path OrientablePath
---@param map DirectionMapping
---@returns OrientablePath
function exports.reorient_path(path, map)
    ---@type OrientablePath
    local reoriented = {}
    for dir, path_keys in pairs(map) do
        ---@type Path[]
        local subpaths = {}
        for _, path_key in ipairs(path_keys) do
            local subpath = path[path_key]
            table.insert(subpaths, subpath)
        end
        reoriented[dir] = tables.concat_arrays(subpaths)
    end
    return reoriented
end

return exports
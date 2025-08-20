local Geometry = require 'lib.geometry'
---@param radial_size RadialSize
---@return SimpleShape
local function convert_size_to_shape(radial_size)
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
local function get_partition_shape(boundary_size, item_count)
    local container_shape = convert_size_to_shape(boundary_size)
    ---@type RadialSize
    local item_boundary_size = { 
        x = boundary_size.x / (item_count - 1), 
        y = boundary_size.y / (item_count - 1) 
    }
    local item_shape = convert_size_to_shape(item_boundary_size)
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
local function build_orientable_path(origin, count)
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
---@returns OrientablePath
local function reorient_path(path, map)
    ---@type OrientablePath
    local reoriented = {}
    for orientation, path_keys in pairs(map) do
        ---@type Path[]
        local subpaths = {}
        for _, path_key in ipairs(path_keys) do
            local subpath = path[path_key]
            table.insert(subpaths, subpath)
        end
        reoriented[orientation] = table.array_combine(table.unpack(subpaths))
    end
    return reoriented
end



---@class FormationSlot
---@field position MapPosition
---@field index integer
local FormationSlot = { }
FormationSlot.__index = FormationSlot

---@param position MapPosition
---@param index integer
function FormationSlot:new(position, index)
    local instance = { position = position, index = index }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@class Formation : PartitionShape
---@field origin OrientableOrigin
---@field path OrientablePath
---@field lookup_radius number
local Formation = {}
Formation.__index = Formation


function FormationSlot:__tostring()
    return string.format("slot #%d at (%.1f, %.1f)", self.index, self.position.x, self.position.y)
end

---@param size RadialSize
---@param count integer
---@param map OrientationMapping
---@returns Formation
function Formation:new(size, count, map)
    local instance = get_partition_shape(size, count) --[[@as Formation]]
    instance.origin = build_orientable_origin(instance.shape, instance.item_shape)
    local path = build_orientable_path(instance.origin, count)
    instance.path = reorient_path(path, map)
    instance.lookup_radius = 1
    setmetatable(instance, self)
    return instance
end

---@param position MapPosition
---@param orientation defines.direction
---@return integer?
function Formation:get_position_index(position, orientation)
    local opath = self.path[orientation]
    for i, p in ipairs(opath) do
        if math.abs(p.x - position.x) <= self.lookup_radius and math.abs(p.y - position.y) <= self.lookup_radius then
            return i
        end
    end
    return nil
end

---@param direction defines.direction
---@param mirroring boolean
---@return orientation
local function get_orientation(direction, mirroring)
    if mirroring then 
        return Geometry.mirror_direction_orientation[direction]
    else 
        return Geometry.canonical_direction_orientation[direction] 
    end
end

---@param position MapPosition
---@param direction defines.direction
---@param mirroring boolean
---@return FormationSlot?
function Formation:get_formation_slot(position, direction, mirroring)
    local orientation = get_orientation(direction, mirroring)
    local opath = self.path[orientation]
    for i, p in ipairs(opath.points) do
        if math.abs(p.x - position.x) <= self.lookup_radius and math.abs(p.y - position.y) <= self.lookup_radius then
            return { position = p, index = i }
        end
    end
    return nil
end


--[[
    4   3   2   1
1                   4
2                   3
3                   2
4                   1

]]



return Formation
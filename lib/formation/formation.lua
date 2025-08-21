local FormationSearch = require 'search'
local FormationShape = require 'shape'
local FormationConversion = require 'conversion'

---@class FormationPath
---@field slots FormationSlot[]
---@field orientation orientation

---@class Formation : PartitionShape
---@field paths table<orientation, FormationPath>
---@field lookup_radius number
---@field convert FormationConversion
---@field search FormationSearch
local Formation = {
    convert = FormationConversion,
    search = FormationSearch
}
Formation.__index = Formation

---@param size RadialSize
---@param count integer
---@param map OrientationMapping
---@returns Formation
function Formation:new(size, count, map)
    local instance = FormationShape.get_partition_shape(size, count) --[[@as Formation]]
    local origin = FormationShape.build_orientable_origin(instance.shape, instance.item_shape)
    local path = FormationShape.build_orientable_path(origin, count)
    instance.paths = FormationShape.build_formation_paths(path, map)
    instance.lookup_radius = 1
    setmetatable(instance, self)
    return instance
end

---@param position MapPosition
---@param direction defines.direction
---@param mirroring boolean
---@return FormationSlot?
function Formation:get_formation_slot(position, direction, mirroring)
    local orientation = Formation.convert.direction.to_orientation(direction, mirroring)
    local path = self.paths[orientation]
    for _, slot in pairs(path.slots) do
        if slot:matches_position(position, self.lookup_radius) then return slot end
    end
    return nil
end

return Formation
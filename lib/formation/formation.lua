local FormationSearch = require 'search'
local FormationShape = require 'shape'
local FormationConversion = require 'conversion'
local FormationSlot = require 'slot'

---@class Formation
local Formation = {
    convert = FormationConversion,
    search = FormationSearch
}
Formation.__index = Formation

---@param path OrientablePath
---@return table<orientation, FormationPath>
local function convert_orientable_to_formation_paths(path)
    ---@type table<orientation, FormationPath>
    local fpaths = {}
    for orientation, opath in pairs(path) do
        ---@type FormationPath
        local fpath = {
            slots = {},
            orientation = orientation
        }
        local direction = FormationConversion.orientation.to_direction[orientation]
        for _, point in ipairs(opath.points) do
            local slot = FormationSlot:new(#fpath.slots + 1, point, direction)
            table.insert(fpath.slots, slot)
        end
        fpaths[orientation] = fpath
    end
    return fpaths
end

---@param size RadialSize
---@param count integer
---@param margin? integer|MapPosition
---@returns Formation
function Formation:new(size, count, margin)
    local n_margin = FormationShape.normalize_margin(margin)
    local instance = FormationShape.get_partition_shape(size, count, n_margin) --[[@as Formation]]
    local origin = FormationShape.build_orientable_origin(instance.shape, instance.item_shape, n_margin)
    local path = FormationShape.build_orientable_path(origin, count)
    instance.paths = convert_orientable_to_formation_paths(path)
    instance.lookup_radius = 1
    setmetatable(instance, self)
    return instance
end

---@param map OrientationMapping
function Formation:map_paths(map)
    ---@type table<orientation, FormationPath>
    local mapped_paths = {}
    for orientation, mapped_orientations in pairs(map) do
        ---@type FormationPath
        local mapped_path = {
            slots = {},
            orientation = orientation
        }
        for _, mapped_orientation in ipairs(mapped_orientations) do
            local path = self.paths[mapped_orientation]
            for _, slot in ipairs(path.slots) do
                local mapped_slot = FormationSlot:new(#mapped_path.slots + 1, slot.position, slot.direction)
                table.insert(mapped_path.slots, mapped_slot)
            end
        end
        mapped_paths[orientation] = mapped_path
    end
    self.paths = mapped_paths
end


---@param position MapPosition
---@param direction defines.direction
---@param mirroring boolean
---@return FormationSlot?
function Formation:get_formation_slot(position, direction, mirroring)
    local orientation = Formation.convert.direction.to_orientation(direction, mirroring)
    local path = self.paths[orientation]
    game.print(string.format('getting formation slot matching position: %.1f,%.1f, dir: %s, mir: %s', position.x, position.y, tostring(direction), tostring(mirroring)))
    for _, slot in pairs(path.slots) do
        if slot:matches_position(position, self.lookup_radius) then 
            game.print(string.format('MATCH AT %.1f,%.1f', slot.position.x, slot.position.y))
            return slot 
        else
            game.print(string.format('no match: %.1f,%.1f', slot.position.x, slot.position.y))
        end
    end
    return nil
end

return Formation
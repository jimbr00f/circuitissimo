local Formation = require 'lib.formation.formation'

---@class EntityInfo
---@field entity LuaEntity
---@field unit_number uint64
---@field direction defines.direction
---@field mirroring boolean
---@field orientation orientation
---@field locked boolean
---@field destroyed boolean
local EntityInfo = {}
EntityInfo.__index = EntityInfo

---@param entity LuaEntity
---@return EntityInfo
function EntityInfo:new(entity)
    local instance = {
        entity = entity,
        unit_number = entity.unit_number,
        locked = false,
        destroyed = false
    }
    setmetatable(instance, self)
    EntityInfo.refresh_orientation(instance)
    return instance
end

---@param direction defines.direction
---@param mirroring boolean
---@param orientation orientation
function EntityInfo:reorient(direction, mirroring, orientation)
    self.entity.direction = direction
    self.entity.mirroring = mirroring
    self.direction = direction
    self.mirroring = mirroring
    self.orientation = orientation
end


function EntityInfo:refresh_orientation()
    self:set_orientation(self.entity.direction, self.entity.mirroring)
end

---@param mirroring? axis
function EntityInfo:infer_orientation(mirroring)
    self:set_orientation(self.entity.direction, mirroring and true or false)
end

function EntityInfo:apply_orientation()
    self.entity.direction = self.direction
    self.entity.mirroring = self.mirroring
end

---@param direction defines.direction
---@param mirroring boolean
function EntityInfo:set_orientation(direction, mirroring)
    self.direction = direction
    self.mirroring = mirroring
    self.orientation = Formation.convert.direction.to_orientation(self.direction, self.mirroring)
end

---@param info EntityInfo
function EntityInfo:sync_orientation(info)
    self.direction = info.direction
    self.mirroring = info.mirroring
    self.orientation = info.orientation
end

return EntityInfo
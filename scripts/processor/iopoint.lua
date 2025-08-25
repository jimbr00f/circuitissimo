local EntityInfo = require 'lib.entity-info'

---@class IoPoint : EntityInfo
---@field index integer
local IoPoint = setmetatable({}, { __index = EntityInfo })
IoPoint.__index = IoPoint

---@param entity LuaEntity The existing game entity for this IoPoint
---@param index number The index corresponding to the IoPoint's ordered FormationSlot
---@return IoPoint
function IoPoint:new(entity, index)
    local instance = EntityInfo.new(self, entity) --[[@as IoPoint]]
    instance.index = index
    setmetatable(instance, self)
    storage.iopoints[entity.unit_number] = instance
    return instance
end

function IoPoint.initialize()
    ---@type table<uint64, IoPoint>
    storage.iopoints = storage.iopoints or {}
end

function IoPoint:destroy()
    self.entity.destroy()
    self.locked = true
end

function IoPoint:__tostring()
    return string.format("%s #%d at (%.1f, %.1f)", self.entity.name, self.index, self.entity.position.x, self.entity.position.y)
end

function IoPoint:refresh()
end

---@param entity LuaEntity
---@param index integer
---@return IoPoint
function IoPoint.load(entity, index)
    local iopoint = IoPoint.load_from_storage(entity, index, true)
    if not iopoint then
        error('Expected a non-null iopoint but received nil.')
    end
    return iopoint
end

---@param entity LuaEntity
---@param index? integer
---@param create? boolean
---@return IoPoint?
function IoPoint.load_from_storage(entity, index, create)
    local iopoint = storage.iopoints[entity.unit_number]
    if iopoint then
        setmetatable(iopoint, IoPoint)
    elseif create and index then
        iopoint = IoPoint:new(entity, index)
    end
    if iopoint and not iopoint.locked then
        iopoint:refresh()
    end
    return iopoint
end

factorissimo.handle_init(function()
    IoPoint.initialize()
end)

return IoPoint
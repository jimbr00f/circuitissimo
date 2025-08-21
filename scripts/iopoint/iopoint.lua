local Formatting = require 'lib.formatting'
local EntityInfo = require 'lib.entity_info'

---@class IoPoint : EntityInfo
---@field index integer
local IoPoint = setmetatable({}, { __index = EntityInfo })
IoPoint.__index = IoPoint

---@param entity LuaEntity
---@param index number
---@return IoPoint
function IoPoint:new(entity, index)
    game.print(string.format('creating new iopoint #%d from entity: %s', index, Formatting.format_entity(entity)))
    local instance = EntityInfo.new(self, entity) --[[@as IoPoint]]
    instance.index = index
    setmetatable(instance, self)
    storage.iopoints[entity.unit_number] = instance
    return instance
end

function IoPoint.initialize()
    game.print('initializing IoPoint class storage')
    ---@type table<uint64, IoPoint>
    storage.iopoints = storage.iopoints or {}
end

function IoPoint:destroy()
    game.print(string.format('destroying iopoint #%d from entity: %s', self.index, Formatting.format_entity(self.entity)))
    self.entity.destroy()
    self.locked = true
end

function IoPoint:__tostring()
    return string.format("%s #%d at (%.1f, %.1f)", self.entity.name, self.index, self.entity.position.x, self.entity.position.y)
end

function IoPoint:refresh()
    game.print('refreshing iopoint')
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
---@param create boolean?
---@return IoPoint?
function IoPoint.load_from_storage(entity, index, create)
    game.print("loading stored iopoint for entity: " .. tostring(entity.unit_number))
    local iopoint = storage.iopoints[entity.unit_number]
    if iopoint then
        setmetatable(iopoint, IoPoint)
    elseif create then
        iopoint = IoPoint:new(entity, index)
    end
    if iopoint and not iopoint.locked then
        iopoint:refresh()
    end
    return iopoint
end

return IoPoint
local EntityInfo = require 'lib.entity-info'

---@class ProcessorIoPoint : EntityInfo
local ProcessorIoPoint = setmetatable({}, { __index = EntityInfo })
ProcessorIoPoint.__index = ProcessorIoPoint

---@param entity LuaEntity The existing game entity for this ProcessorIoPoint
---@param index number The index corresponding to the ProcessorIoPoint's ordered FormationSlot
---@return ProcessorIoPoint
function ProcessorIoPoint:new(entity, index)
    local instance = EntityInfo.new(self, entity) --[[@as ProcessorIoPoint]]
    instance.index = index
    setmetatable(instance, self)
    storage.iopoints[entity.unit_number] = instance
    return instance
end

function ProcessorIoPoint.initialize()
    ---@type table<uint64, ProcessorIoPoint>
    storage.iopoints = storage.iopoints or {}
end

function ProcessorIoPoint:destroy()
    self.entity.destroy()
    self.locked = true
end

function ProcessorIoPoint:__tostring()
    return string.format("%s #%d at (%.1f, %.1f)", self.entity.name, self.index, self.entity.position.x, self.entity.position.y)
end

function ProcessorIoPoint:refresh()
end

---@param entity LuaEntity
---@param index integer
---@return ProcessorIoPoint
function ProcessorIoPoint.load(entity, index)
    local iopoint = ProcessorIoPoint.load_from_storage(entity, index, true)
    if not iopoint then
        error('Expected a non-null iopoint but received nil.')
    end
    return iopoint
end

---@param entity LuaEntity
---@param index? integer
---@param create? boolean
---@return ProcessorIoPoint?
function ProcessorIoPoint.load_from_storage(entity, index, create)
    local iopoint = storage.iopoints[entity.unit_number]
    if iopoint then
        setmetatable(iopoint, ProcessorIoPoint)
    elseif create and index then
        iopoint = ProcessorIoPoint:new(entity, index)
    end
    if iopoint and not iopoint.locked then
        iopoint:refresh()
    end
    return iopoint
end

factorissimo.handle_init(function()
    ProcessorIoPoint.initialize()
end)

return ProcessorIoPoint
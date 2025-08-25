local EntityInfo = require 'lib.entity-info'
local IoPoint = require 'scripts.processor.iopoint'
local ProcessorConfig = require 'scripts.processor.config'
local Utility = require 'scripts.processor.utility'

---@class Processor : EntityInfo
---@field iopoints table<uint64, IoPoint>
---@field indexed_iopoints table<integer, uint64>
local Processor = setmetatable({}, { __index = EntityInfo })
Processor.__index = Processor


---@param entity LuaEntity
---@return Processor
function Processor:new(entity)
    local instance = EntityInfo.new(self, entity) --[[@as Processor]]
    instance.iopoints = {}
    instance.indexed_iopoints = {}
    setmetatable(instance, self)
    storage.processors[entity.unit_number] = instance
    return instance
end

function Processor.initialize()
    ---@type table<uint64, IoPoint>
    storage.processors = storage.processors or {}
end

function Processor:destroy()
    for _, iopoint in pairs(self.iopoints) do
        iopoint:destroy()
    end
    self.locked = true
end

function Processor:__tostring()
    return string.format("%s at (%.1f, %.1f)", self.entity.name, self.entity.position.x, self.entity.position.y)
end


---@param mirroring? axis
function Processor:reorient(mirroring)
    self:refresh()
    self:infer_orientation(mirroring)
    self:reorient_iopoints()
end

function Processor:refresh()
    self.iopoints = self:load_iopoints()
    self.indexed_iopoints = {}
    for _, iopoint in pairs(self.iopoints) do
        self.indexed_iopoints[iopoint.index] = iopoint.unit_number
    end
end

---@param entity LuaEntity
---@return FormationSlot?
function Processor:get_formation_slot(entity)
    local position = {
        x = entity.position.x - self.entity.position.x,
        y = entity.position.y - self.entity.position.y,
    }
    local slot = ProcessorConfig.iopoint_formation:get_formation_slot(position, self.direction, self.mirroring)
    return slot
end

---@return FormationSlot[]
function Processor:get_available_formation_slots()
    local path = ProcessorConfig.iopoint_formation.paths[self.orientation]
    ---@type FormationSlot[]
    local available = {}
    for _, slot in ipairs(path.slots) do
        if self.indexed_iopoints[slot.index] == nil then
            table.insert(available, slot)
        end
    end
    return available
end

---@return IoPoint[]
function Processor:load_iopoints()
    local entities = Utility.find_nearest_entities(self.entity, ProcessorConfig.attach_radius, ProcessorConfig.iopoint_name)
    local iopoints = {}
    for _, entity in ipairs(entities) do
        local slot = self:get_formation_slot(entity)
        if not slot then
            goto continue
        end
        local iopoint = self.iopoints[entity.unit_number]
        if not iopoint then
            iopoint = IoPoint.load(entity, slot.index)
        end
        if iopoint.index ~= slot.index then
            game.print(string.format('ERROR: loaded %s but matched with %s', iopoint, slot))
        end
        iopoints[entity.unit_number] = iopoint
        ::continue::
    end
    return iopoints
end

function Processor:reorient_iopoints()
    local path = ProcessorConfig.iopoint_formation.paths[self.orientation]
    for _, iopoint in pairs(self.iopoints) do
        local slot_target = path.slots[iopoint.index]
        local target_position = {
            x = self.entity.position.x + slot_target.position.x,
            y = self.entity.position.y + slot_target.position.y
        }
        iopoint.entity.teleport(target_position)
        iopoint:sync_orientation(self)
    end
end

---@param entity LuaEntity
function Processor.try_attach_iopoint(entity)
    local processor_entities = Utility.find_nearest_entities(entity, ProcessorConfig.attach_radius, ProcessorConfig.processor_name)
    for _, proc_entity in ipairs(processor_entities) do
        ---@type Processor
        local proc = Processor.load_from_storage(proc_entity)
        local slot = proc:get_formation_slot(entity)
        if slot then
            local iopoint = proc:set_iopoint(entity, slot)
            return iopoint
        end
    end
    return nil
end

---@param entity LuaEntity
---@param slot FormationSlot
---@return IoPoint?
function Processor:set_iopoint(entity, slot)
    local slot_taken = self.indexed_iopoints[slot.index] ~= nil
    if slot_taken then
        return nil 
    end
    local iopoint = IoPoint.load_from_storage(entity)
    if iopoint then
        self.indexed_iopoints[iopoint.index] = nil
        iopoint.index = slot.index
    else
        iopoint = IoPoint:new(entity, slot.index)
        self.iopoints[entity.unit_number] = iopoint
    end
    self.indexed_iopoints[slot.index] = entity.unit_number
    return iopoint
end

---@param entity LuaEntity
---@return Processor
function Processor.load(entity)
    local processor = Processor.load_from_storage(entity, true)
    if not processor then
        error('Expected a non-null iopoint but received nil.')
    end
    return processor
end

---@param entity LuaEntity
---@param create boolean?
---@return Processor
function Processor.load_from_storage(entity, create)
    ---@type Processor
    local processor = storage.processors[entity.unit_number]
    if processor then
        setmetatable(processor, Processor)
        for _, io in pairs(processor.iopoints) do
            setmetatable(io, IoPoint)
        end
    elseif create then
        processor = Processor:new(entity)
        processor:refresh()
    end
    return processor
end

factorissimo.handle_init(function()
    Processor.initialize()
end)

return Processor
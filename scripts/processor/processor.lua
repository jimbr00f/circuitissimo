local Formation = require 'lib.formation.formation'
local IoPoint = require 'scripts.iopoint.iopoint'
local Formatting = require 'lib.formatting'
local ProcessorConfig = require "scripts.processor.config"
local EntityInfo = require 'lib.entity-info'

---@class Processor : EntityInfo
---@field iopoints table<uint64, IoPoint>
---@field indexed_iopoints table<integer, uint64>
local Processor = setmetatable({}, { __index = EntityInfo })
Processor.__index = Processor


---@param entity LuaEntity
---@return Processor
function Processor:new(entity)
    game.print(string.format('creating new processor from entity: %s', Formatting.format_entity(entity)))
    local instance = EntityInfo.new(self, entity) --[[@as Processor]]
    instance.iopoints = {}
    instance.indexed_iopoints = {}
    setmetatable(instance, self)
    storage.processors[entity.unit_number] = instance
    return instance
end

function Processor.initialize()
    game.print('initializing Processor class storage')
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
    game.print(string.format('reorient.begin: d: %s, m: %s, o: %s', self.direction, self.mirroring, self.orientation))
    self:refresh()
    game.print(string.format('reorient.refresh: d: %s, m: %s, o: %s', self.direction, self.mirroring, self.orientation))
    self:infer_orientation(mirroring)
    game.print(string.format('reorient.infer: d: %s, m: %s, o: %s', self.direction, self.mirroring, self.orientation))
    self:reorient_iopoints()
    game.print(string.format('reorient.iopoints: d: %s, m: %s, o: %s', self.direction, self.mirroring, self.orientation))
end

function Processor:refresh()
    game.print('refreshing processor')
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
function Processor:get_active_formation_slots()
    local path = ProcessorConfig.iopoint_formation.paths[self.orientation]
    return path.slots
end

---@return IoPoint[]
function Processor:load_iopoints()
    local filter = {
        name = ProcessorConfig.iopoint_name,
        area = Formation.search.get_search_area(self.entity, 1)
    }
    local entities = self.entity.surface.find_entities_filtered(filter)
    local iopoints = {}
    for _, entity in ipairs(entities) do
        game.print(string.format('loading iopoints: found entity at %0.1f, %0.1f', entity.position.x, entity.position.y))
        local slot = self:get_formation_slot(entity)
        if not slot then
            game.print(string.format('ERROR: No formation slot matches this entity: %s', Formatting.format_entity(entity)))
            goto continue
        end
        game.print(string.format('found a matching iopoint slot at %0.1f, %0.1f', slot.position.x, slot.position.y))
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
---@param slot FormationSlot
---@return IoPoint?
function Processor:set_iopoint(entity, slot)
    game.print(string.format('setting iopoint to slot #%d', slot.index))
    local slot_taken = self.indexed_iopoints[slot.index] ~= nil
    if slot_taken then 
        game.print(string.format('attempted to place %d, but slot #%d taken by %d', entity.unit_number, slot.index, self.indexed_iopoints[slot.index]))
        return nil 

    end
    local iopoint = IoPoint.load_from_storage(entity)
    if iopoint then
        game.print(string.format('removing iopoint from previous slot #%d', iopoint.index))
        self.indexed_iopoints[iopoint.index] = nil
        iopoint.index = slot.index
    else
        iopoint = IoPoint:new(entity, slot.index)
        self.iopoints[entity.unit_number] = iopoint
        game.print(string.format('created new iopoint at slot #%d', iopoint.index))
    end
    game.print(string.format('finalized iopoint index at slot #%d', slot.index))
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
    game.print(string.format("%s stored processor for entity: %s", create and "loading/creating" or "loading", Formatting.format_entity(entity)))
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
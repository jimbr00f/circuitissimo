local Formation = require 'lib.formation.formation'
local IoPoint = require 'scripts.iopoint.iopoint'
local Formatting = require 'lib.formatting'
local ProcessorConfig = require "scripts.processor.config"
local EntityInfo = require 'lib.entity_info'

---@class Processor : EntityInfo
---@field iopoints table<uint64, IoPoint>
local Processor = setmetatable({}, { __index = EntityInfo })
Processor.__index = Processor


---@param entity LuaEntity
---@return Processor
function Processor:new(entity)
    game.print(string.format('creating new processor from entity: %s', Formatting.format_entity(entity)))
    local instance = EntityInfo.new(self, entity) --[[@as Processor]]
    instance.iopoints = {}
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
    game.print(string.format('reorienting processor; start = '))
    self:refresh()
    self:infer_orientation(mirroring)
    self:reorient_iopoints()
end

function Processor:refresh()
    game.print('refreshing processor')
    self.iopoints = self:load_iopoints()
end

---@return IoPoint[]
function Processor:load_iopoints()
    local filter = {
        name = ProcessorConfig.iopoint_name,
        area = Formation.search.get_search_area(self.entity, 1)
    }
    local entities = self.entity.surface.find_entities_filtered(filter)
    local formation = ProcessorConfig.iopoint_formation
    local iopoints = {}
    for _, entity in ipairs(entities) do
        local slot = formation:get_formation_slot(entity.position, self.direction, self.mirroring)
        if not slot then
            game.print(string.format('ERROR: No formation slot matches this entity: %s', Formatting.format_entity(entity)))
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
    local path = ProcessorConfig.iopoint_formation.paths[orientation]
    for _, iopoint in pairs(self.iopoints) do
        local slot_target = path.slots[iopoint.index]
        iopoint.entity.teleport(slot_target.position)
        iopoint:sync_orientation(self)
    end
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
    local processor = storage.processors[entity.unit_number]
    if not processor and create then
        processor = Processor:new(entity)
    end
    if processor and not processor.locked then
        processor:refresh()
    end
    return processor
end


return Processor
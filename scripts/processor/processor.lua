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

---@return IoPoint[]
function Processor:load_iopoints()
    local filter = {
        name = ProcessorConfig.iopoint_name,
        area = Formation.search.get_search_area(self.entity, 1)
    }
    local entities = self.entity.surface.find_entities_filtered(filter)
    local iopoints = {}
    for _, entity in ipairs(entities) do
        local slot = self:get_formation_slot(entity)
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
    game.print(string.format("orientation: %s", tostring(self.orientation)))
    local all_paths = ProcessorConfig.iopoint_formation.paths
    game.print(string.format("# paths: %d", #all_paths))
    local pathf = all_paths[self.orientation]
    game.print(string.format("# path nil? %s", pathf == nil and "ya" or "ne" ))
    for pk, pv in pairs(all_paths) do
        game.print(string.format('key: %s', tostring(pk)))
    end
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
    end
    if processor and not processor.locked then
        processor:refresh()
    end
    return processor
end


return Processor
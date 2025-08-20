local IoPoint = require 'scripts.iopoint.iopoint'
local Geometry = require 'lib.geometry'
local Formatting = require 'lib.formatting'
local ProcessorConfig = require "scripts.processor.config"


---@class Processor : EntityInfo
---@field iopoints table<uint64, IoPoint>
---@field mirroring boolean
---@field locked boolean
---@field direction defines.direction
local Processor = {}
Processor.__index = Processor

---@param entity LuaEntity
---@return Processor
function Processor:new(entity)
    local instance = { 
        entity = entity,
        iopoints = {},
        mirroring = false,
        direction = defines.direction.north,
        unit_number = entity.unit_number,
        locked = false
    }
    setmetatable(instance, self)
    storage.processors[entity.unit_number] = instance
    return instance
end

function Processor.initialize()
    ---@type table<uint64, IoPoint>
    storage.processors = storage.processors or {}
end

function Processor:__tostring()
    return string.format("%s at (%.1f, %.1f)", self.entity.name, self.entity.position.x, self.entity.position.y)
end

---@param procinfo Processor
local function update_connections(procinfo)
    -- TODO: invoke Factorissimo connection builders
end


function Processor:load_connections()
    if not self.iopoints then return end
    ---@type IoPointWireConnection
    for _, iopoint in ipairs(self.iopoints) do
        iopoint:load_connections()
    end
end

function Processor:refresh()
    self:load_connections()
end



---@return IoPoint[]
function Processor:refresh_iopoints()
    local filter = {
        name = ProcessorConfig.iopoint_name,
        area = Geometry.get_search_area(self.entity, 1)
    }
    local entities = self.entity.surface.find_entities_filtered(filter)
    local formation = ProcessorConfig.iopoint_formation
    local iopoints = {}
    for _, entity in ipairs(entities) do
        local slot = formation:get_formation_slot(entity.position, self.direction)
        if not slot then
            game.print(string.format('ERROR: No formation slot matches this entity: %s', Formatting.format_entity(entity)))
        end
        local iopoint = self.iopoints[entity.unit_number]
        if not iopoint then
            iopoint = IoPoint.load(entity, slot.index)
        end
        if iopoint.index ~= slot.index then
            game.print(string.format('ERROR: loaded %s but matched with %s', iopoint, slot))
        end
        iopoints[entity.unit_number] = iopoint
    end
    return iopoints
end

function Processor:reorient_iopoints()
    local target_formation = ProcessorConfig.iopoint_formation
    for _, iopoint in self.iopoints do
        
    end
end


function Processor:destroy()
    for _, iopoint in pairs(self.iopoints) do
        iopoint:destroy()
    end
    self.locked = true
end

---@param mirroring orientation?
function Processor:reorient(mirroring)
    if mirroring then
        self.mirroring = not self.mirroring
    end
    self:refresh_iopoints()
end

---@param entity LuaEntity
---@param create boolean?
---@return Processor
function Processor.load_from_storage(entity, create)
    game.print("loading stored processor info for entity: " .. tostring(entity.unit_number))
    local processor = storage.processors[entity.unit_number]
    if processor and not processor.locked then
        game.print('refreshing processor info')
        processor.refresh()
    elseif not processor and create then
        game.print('creating new processor info')
        processor = Processor:new(entity)
    end
    return processor
end


return Processor
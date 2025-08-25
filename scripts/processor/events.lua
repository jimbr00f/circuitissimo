local ProcessorConfig = require 'scripts.processor.config'
local Processor = require 'scripts.processor.processor'
local IoPoint = require 'scripts.processor.iopoint'
local PlayerRenderingState = require 'scripts.processor.rendering'

factorissimo.on_event(factorissimo.events.on_oriented(),
---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
function(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= ProcessorConfig.processor_name then return end
    local processor = Processor.load_from_storage(entity)
    ---@type axis?
    local mirroring = nil
    if event.name == defines.events.on_player_flipped_entity then
        if event.horizontal then 
            mirroring = axis.horizontal
        else
            mirroring = axis.vertical
        end
    end
    processor:reorient(mirroring)
end)

factorissimo.on_event(factorissimo.events.on_built(),
function(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name == ProcessorConfig.processor_name then
        Processor.load(entity)    
    elseif entity.name == ProcessorConfig.iopoint_name then
        Processor.try_attach_iopoint(entity)
    end
end)

factorissimo.on_event(factorissimo.events.on_init(),
function()
    IoPoint.initialize()
    Processor.initialize()
    PlayerRenderingState.initialize()
end)
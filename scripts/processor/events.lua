local ProcessorConfig = require "scripts.processor.config"
local Processor = require 'scripts.processor.processor'

factorissimo.on_event(factorissimo.events.on_oriented(), function(event --[[@as (EventData.on_player_rotated_entity | EventData.on_player_flipped_entity)]])
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
        game.print(string.format('mirroring processor from %s to %s', processor.mirroring, mirroring))
    else
        game.print(string.format('reorienting processor from %s to %s', processor.direction, processor.entity.direction))
    end
    processor:reorient(mirroring)
    game.print(string.format('post-reorient: d: %s, m: %s, o: %s', processor.direction, processor.mirroring, processor.orientation))
end)

factorissimo.on_event(factorissimo.events.on_built(), function(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= ProcessorConfig.processor_name then return end
    if event.name == defines.events.on_built_entity then
        game.print("processor:on_built(on_built_entity)")
    end
    if event.name == defines.events.on_robot_built_entity    then
        game.print("processor:on_built(on_robot_built_entity)")
    end
    if event.name == defines.events.script_raised_built then
        game.print("processor:on_built(script_raised_built)")
    end
    if event.name == defines.events.script_raised_revive then
        game.print("processor:on_built(script_raised_revive)")
    end
    Processor.load(entity)
end)
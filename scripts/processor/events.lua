local ProcessorConfig = require "scripts.processor.processor"
local logic = require "scripts.processor.logic"

local handlers = {
    ---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_built | EventData.script_raised_revive
    on_built = function(event)
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
        
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        local info = logic.load_stored_processor(entity, true)
        if event.stack then
            local stack = event.stack
            if stack.is_blueprint then
                game.print('stack is bp')
            elseif stack.is_item_with_entity_data then
                game.print('stack is item with entity')
            elseif stack.is_item_with_tags then
                game.print('stack is item with tags')
            end
        end
        if event.player_index and game.players[event.player_index] then
            local stack = game.players[event.player_index].cursor_stack
            if stack then
                if stack.is_blueprint then
                    game.print('cursor stack is bp')
                elseif stack.is_item_with_entity_data then
                    game.print('cursor stack is item with entity')
                elseif stack.is_item_with_tags then
                    game.print('cursor stack is item with tags')
                end
            end
        end
        logic.build_processor(info)
    end,


    ---@param event EventData.on_player_rotated_entity | EventData.on_player_flipped_entity
    on_reoriented = function(event)
        game.print("processor:on_rotated")
        local entity = event.entity
        if not entity or not entity.valid then return end
        if entity.name ~= ProcessorConfig.processor_name then return end
        ---@type axis?
        local mirroring = nil
        if event.name == defines.events.on_player_flipped_entity then
            if event.horizontal then 
                mirroring = axis.horizontal
            else
                mirroring = axis.vertical
            end
        end
        local info = logic.load_stored_processor(entity, true)
        logic.reorient_processor(info, mirroring)
    end,
}

local subscriptions = {
    [defines.events.on_built_entity] = handlers.on_built,
    [defines.events.on_robot_built_entity] = handlers.on_built,
    [defines.events.script_raised_built] = handlers.on_built,
    [defines.events.script_raised_revive] = handlers.on_built,

    [defines.events.on_player_rotated_entity] = handlers.on_reoriented,
    [defines.events.on_player_flipped_entity] = handlers.on_reoriented,
}

local exports = {
    handlers = handlers,
    subscriptions = subscriptions
}

return exports
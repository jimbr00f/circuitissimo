local Formation = require 'lib.formation.formation'
local FormationSlot = require 'lib.formation.slot'
local Utility = require 'scripts.processor.utility'
local Processor = require 'scripts.processor.processor'
local ProcessorConfig = require 'scripts.processor.config'

---@class ProcessorSlot : FormationSlot
local ProcessorSlot = setmetatable({}, { __index = FormationSlot })
ProcessorSlot.__index = ProcessorSlot

---@param slot FormationSlot
---@param player LuaPlayer
---@param processor Processor
---@return ProcessorSlot
function ProcessorSlot:new(slot, player, processor)
    local instance = FormationSlot.new(self, slot.index, slot.position, slot.direction) --[[@as ProcessorSlot]]
    instance.player = player
    instance.processor = processor
    setmetatable(instance, self)
    return instance
end

function ProcessorSlot:__tostring()
    return string.format("%s, attached to %s", FormationSlot.__tostring(self), self.processor)
end

function ProcessorSlot:world_position()
    local proc_pos = self.processor.entity.position
    local slot_pos = self.position
    return {
        x = proc_pos.x + slot_pos.x,
        y = proc_pos.y + slot_pos.y
    }
end

---@param player LuaPlayer
---@return ProcessorSlot[]
function ProcessorSlot.find_available_slots(player)
    local p_slots = {}
    local p_entities = Utility.find_nearest_entities(player, ProcessorConfig.search_radius, ProcessorConfig.processor_name)
    for _, proc_entity in ipairs(p_entities) do
        ---@type Processor
        local proc = Processor.load_from_storage(proc_entity)
        local f_slots = proc:get_available_formation_slots()
        for _, f_slot in ipairs(f_slots) do
            local p_slot = ProcessorSlot:new(f_slot, player, proc)
            table.insert(p_slots, p_slot)
        end
    end
    return p_slots
end

---@return integer[]
function ProcessorSlot:draw()
    local ids = {}
    local world = self:world_position()
    local is_free = self.player.surface.can_place_entity{
        name = ProcessorConfig.iopoint_name, position = world, direction = self.direction, force = self.player.force
    }
    local shape = ProcessorConfig.iopoint_formation.item_shape
    local color = is_free and {g=1, a=0.35} or {r=0.6, g=0.6, b=0.6, a=0.25}
    local box = rendering.draw_rectangle{
        color = color,
        width = 1,
        filled = false,
        left_top = {
            x = world.x + shape.left_top.x,
            y = world.y + shape.left_top.y
        },
        right_bottom = {
            x = world.x + shape.right_bottom.x,
            y = world.y + shape.right_bottom.y
        },
        surface = self.player.surface,
        forces = {self.player.force},
        players = {self.player.index}
    }
    table.insert(ids, box.id)

    local text = rendering.draw_text{
        text = tostring(self.index),
        target = { x = world.x + shape.left_top.x + 0.2, y = world.y + shape.left_top.y + 0.2},
        surface = self.player.surface,
        forces = {self.player.force},
        players = {self.player.index},
        color = { r=0, g=1, b=1}
    }
    table.insert(ids, text.id)
    
    -- draw a direction arrow on top for clarity (like station helpers)
    local arrow = rendering.draw_sprite{
        sprite = "utility/indication_arrow", -- vanilla arrow
        surface = self.player.surface,
        target = {world.x, world.y - 0.2},
        orientation = Formation.convert.direction.to_rotation[self.direction],
        x_scale = 0.55,
        y_scale = 0.55,
        render_layer = "entity-info-icon-above",
        forces = {self.player.force},
        players = {self.player.index},
        tint = is_free and {g=1, a=0.8} or {r=0.8, g=0.8, b=0.8, a=0.5},
    }
    table.insert(ids, arrow.id)
    return ids
end

return ProcessorSlot
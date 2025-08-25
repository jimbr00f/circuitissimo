local Processor = require 'scripts.processor.processor'
local AnchorConfig = require 'scripts.anchor.config'
local Formation = require 'lib.formation.formation'
local ProcessorConfig = require 'scripts.processor.config'

---@class Anchor
---@field player LuaPlayer
---@field processor Processor
---@field slot FormationSlot
local Anchor = {}
Anchor.__index = Anchor

---@param player LuaPlayer
---@param processor Processor
---@param slot FormationSlot
---@return Anchor
function Anchor:new(player, processor, slot)
    ---@type Anchor
    local instance = {
        player = player,
        processor = processor,
        slot = slot
    }
    setmetatable(instance, self)
    return instance
end

function Anchor:__tostring()
    return string.format('anchor for %s', self.processor, self.slot)
end

function Anchor:world_position()
    local p_proc = self.processor.entity.position
    local p_slot = self.slot.position
    return {
        x = p_proc.x + p_slot.x,
        y = p_proc.y + p_slot.y
    }
end

---@param player LuaPlayer
---@return Anchor[]
function Anchor.find_anchors(player)
    local anchors = {}
    local pos = player.position
    
    local area = {
        {pos.x - AnchorConfig.find_radius, pos.y - AnchorConfig.find_radius},
        {pos.x + AnchorConfig.find_radius, pos.y + AnchorConfig.find_radius}
    }
    local processor_entities = player.surface.find_entities_filtered{area = area, name = ProcessorConfig.processor_name, force = player.force}
    for _, proc_entity in ipairs(processor_entities) do
        ---@type Processor
        local proc = Processor.load_from_storage(proc_entity)
        local slots = proc:get_available_formation_slots()
        for _, slot in ipairs(slots) do
            local anchor = Anchor:new(player, proc, slot)
            table.insert(anchors, anchor)
        end
    end
    return anchors
end

---@return integer[]
function Anchor:draw()
    local ids = {}
    local world = self:world_position()
    local is_free = self.player.surface.can_place_entity{
        name = ProcessorConfig.iopoint_name, position = world, direction = self.slot.direction, force = self.player.force
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
        text = tostring(self.slot.index),
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
        orientation = Formation.convert.direction.to_rotation[self.slot.direction],
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

return Anchor
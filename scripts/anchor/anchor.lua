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
    game.print(string.format('creating new anchor for processor %s, slot %s', processor, slot))
    ---@type Anchor
    local instance = {
        player = player,
        processor = processor,
        slot = slot
    }
    setmetatable(instance, self)
    return instance
end

function Anchor.initialize()
    game.print('initializing IoPoint class storage')
    ---@type table<integer, AnchorPreviewData>
    storage.anchor_preview = storage.anchor_preview or {}
    ---@type table<integer, integer[]>
    storage.anchor_renders = storage.anchor_renders or {}
end

function Anchor:destroy()
    game.print(string.format('destroying anchor for processor %s, slot %s', self.processor, self.slot))
end

function Anchor:__tostring()
    return string.format('anchor for processor %s, slot %s', self.processor, self.slot)
end

function Anchor:world_position()
    local p_proc = self.processor.entity.position
    local p_slot = self.slot.position
    return {
        x = p_proc.x + p_slot.x,
        y = p_proc.y + p_slot.y
    }
end

---@param entity LuaEntity
function Anchor:distance_from(entity)
    local world = self:world_position()
    local p = entity.position
    local dist = (p.x - world.x)^2 + (p.y - world.y)^2
    return dist
end

function Anchor:draw()
    storage.anchor_renders[self.player.index] = storage.anchor_renders[self.player.index] or {}
    local ids = storage.anchor_renders[self.player.index]
    local world = self:world_position()
    game.print(string.format('drawing anchor at %.1f, %.1f [%s]', world.x, world.y, self.slot.direction))
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
end

return Anchor
local AnchorConfig = require 'scripts.anchor.config'
local Anchor = require 'scripts.anchor.anchor'
local ProcessorConfig = require 'scripts.processor.config'
local Processor = require 'scripts.processor.processor'
local IoPoint = require 'scripts.iopoint.iopoint'
local Formation = require 'lib.formation.formation'

---@class PlayerAnchorRenderingState
local PlayerAnchorRenderingState = {}
PlayerAnchorRenderingState.__index = PlayerAnchorRenderingState

---@param player_index int
---@return PlayerAnchorRenderingState
function PlayerAnchorRenderingState:new(player_index)
    game.print(string.format('creating a new anchor rendering state for player %d', player_index))
    local instance = {
        player_index = player_index,
        render_ids = {} --[[ @as table<integer,integer[]> ]],
        anchors = {} --[[ @as Anchor[] ]]
    }
    setmetatable(instance, self)
    storage.player_anchor_rendering_state[player_index] = instance
    return instance
end

function PlayerAnchorRenderingState.initialize()
    game.print('initializing IoPoint class storage')
    ---@type table<integer, PlayerAnchorRenderingState>
    storage.player_anchor_rendering_state = storage.player_anchor_rendering_state or {}
end

function PlayerAnchorRenderingState:__tostring()
    return string.format('PA rendering state for player %d: %d anchors, %d renders', self.player_index, #self.anchors, #self.render_ids)
end

---@return LuaPlayer
function PlayerAnchorRenderingState:get_player()
    local player = game.get_player(self.player_index)
    if not player then
        error(string.format('No player found matching index %d', self.player_index))
    end
    return player
end

---@class AnchorEventFlags
---@field player_changed boolean
---@field cursor_changed boolean
---@field cursor_has_iopoint boolean
---@field iopoint_built boolean

---@param player LuaPlayer
---@return boolean
local function is_player_holding_iopoint(player)
    if player and player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == ProcessorConfig.iopoint_name then
        return true
    end
    return false
end

---@param player? LuaPlayer
---@return AnchorEventFlags
local function create_event_flags(player)
    local flags = {
        player_changed = false,
        cursor_changed = false,
        cursor_has_iopoint = false,
        iopoint_built = false
    }
    if player then
        flags.cursor_has_iopoint = is_player_holding_iopoint(player)
    end
    return flags
end

---@param flags AnchorEventFlags
function PlayerAnchorRenderingState:refresh(flags)
    if flags.player_changed or flags.cursor_changed or flags.iopoint_built then
        self:clear_anchors()
        if flags.cursor_has_iopoint or flags.iopoint_built then
            self.anchors = Anchor.find_anchors(self.player_index)
        end
    end
end

function PlayerAnchorRenderingState:draw_anchors()
    game.print('drawing PARS anchors')
    for _, anchor in ipairs(self.anchors) do
        local render_ids = anchor:draw()
        self.render_ids = table.array_combine(self.render_ids, render_ids)
    end
end

function PlayerAnchorRenderingState:clear_anchors()
    game.print('clearing PARS anchors')
    self.anchors = {}
    self:clear_renders()
end

function PlayerAnchorRenderingState:clear_renders()
    game.print('clearing PARS')
    for _, id in ipairs(self.render_ids) do
        local render = rendering.get_object_by_id(id)
        if render then
            render.destroy()
        end
    end
    self.render_ids = {} --[[@as table<integer,integer[]>]]
end

---@param player LuaPlayer
local function refund_item(player, name, count)
    if not (player and player.valid) then return end
    local inserted = player.insert{name = name, count = count}
    if inserted < count then
        player.surface.spill_item_stack{
            position = player.position, 
            stack = {name = name, count = count - inserted}, 
            enable_looted = true
        }
    end
end

---@param player_index integer
---@param flags AnchorEventFlags
---@return PlayerAnchorRenderingState
function PlayerAnchorRenderingState.load(player_index, flags)
    game.print(string.format("loading/creating PA Rendering State for player %s", player_index))
    ---@type PlayerAnchorRenderingState
    local pars = storage.player_anchor_rendering_state[player_index] --[[@as PlayerAnchorRenderingState]]
    if pars then
        setmetatable(pars, PlayerAnchorRenderingState)
    else
        pars = PlayerAnchorRenderingState:new(player_index)
    end
    if pars then
        for _, anchor in ipairs(pars.anchors) do
            setmetatable(anchor, Anchor)
        end
        pars:refresh(flags)
    end
    return pars
end

---@param entity LuaEntity
---@param player LuaPlayer
function PlayerAnchorRenderingState:try_snap_iopoint(entity, player)
    local anchor = Anchor.select_match(entity, self.anchors)
    local error_text = nil
    if anchor then
        -- game.print(string.format('teleporting iopoint to %s', anchor))
        -- entity.teleport(anchor:world_position())
        entity.direction = anchor.slot.direction
        -- game.print(string.format('setting iopoint to anchor slot #%d', anchor.slot.index))
        local iopoint = anchor.processor:set_iopoint(entity, anchor.slot)
        if not iopoint then
            error_text = ProcessorConfig.iopoint_exists_error_text
        end
    end
    if error_text then
        refund_item(player, ProcessorConfig.iopoint_name, 1)
        player.create_local_flying_text{
            text = { error_text },
            position = entity.position,
            surface = entity.surface,
            create_at_cursor = true
        }
        entity.destroy{raise_destroy = true}
    end
end

-- Events ---------------------------------------------------------------------

factorissimo.handle_built(function(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.name == ProcessorConfig.iopoint_name) then return end
    local player = game.players[event.player_index]
    if not player then return end
    local flags = create_event_flags()
    flags.iopoint_built = true

    local pars = PlayerAnchorRenderingState.load(event.player_index, flags)
    pars:try_snap_iopoint(entity, player)
end)

factorissimo.handle_player_changed(function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local flags = create_event_flags(player)
    flags.player_changed = true
    local pars = PlayerAnchorRenderingState.load(event.player_index, flags)
    pars:draw_anchors()
end)

factorissimo.on_event(defines.events.on_player_cursor_stack_changed,
    ---@param event EventData.on_player_cursor_stack_changed]
    function(event)
        local player = game.get_player(event.player_index)
        if not player then return end
        local flags = create_event_flags(player)
        flags.cursor_changed = true
        local pars = PlayerAnchorRenderingState.load(event.player_index, flags)
        pars:draw_anchors()
    end
)


-- -- why do we need to keep doing this?? dont the renders just stick around?
-- script.on_nth_tick(AnchorConfig.tick_interval, function(e)
--     for player_index, pdata in pairs(storage.anchor_preview) do
--         if pdata.cursor_has_iopoint then
--             local player = game.get_player(player_index)
--             if player then
--                 update_player_preview(player, pdata)
--             end
--         end
--     end
-- end)

return PlayerAnchorRenderingState
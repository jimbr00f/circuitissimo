local AnchorConfig = require 'scripts.anchor.config'
local Anchor = require 'scripts.anchor.anchor'
local ProcessorConfig = require 'scripts.processor.config'
local Processor = require 'scripts.processor.processor'
local Formation = require 'lib.formation.formation'

---@class PlayerAnchorRenderingState
local PlayerAnchorRenderingState = {}
PlayerAnchorRenderingState.__index = PlayerAnchorRenderingState

---@param player LuaPlayer
---@return PlayerAnchorRenderingState
function PlayerAnchorRenderingState:new(player)
    game.print(string.format('creating a new anchor rendering state for player %d', player.index))
    local instance = {
        enable_rendering = false,
        player_index = player.index,
        render_ids = {} --[[ @as table<integer,integer[]> ]],
        anchors = {} --[[ @as Anchor[] ]]
    }
    setmetatable(instance, self)
    storage.player_anchor_rendering_state[player.index] = instance
    return instance
end

function PlayerAnchorRenderingState.initialize()
    game.print('initializing IoPoint class storage')
    ---@type table<integer, PlayerAnchorRenderingState>
    storage.player_anchor_rendering_state = storage.player_anchor_rendering_state or {}
end

function PlayerAnchorRenderingState:__tostring()
    return string.format('anchor rendering state for player %d: rendering %s for %d render objects', self.player_index, self.enable_rendering and 'enabled' or 'disabled', #self.render_ids)
end

---@return LuaPlayer
function PlayerAnchorRenderingState:get_player()
    local player = game.get_player(self.player_index)
    if not player then
        error(string.format('No player found matching index %d', self.player_index))
    end
    return player
end

function PlayerAnchorRenderingState:refresh()
    local player = self:get_player()
    local cs = player.cursor_stack
    if cs and cs.valid_for_read and cs.name == ProcessorConfig.iopoint_name then
       self.enable_rendering = true
    end

    self:clear_anchors()
    if not self.enable_rendering then return end
    
    self.anchors = self:find_anchor_points()
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
    for _, id in self.render_ids do
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

---@param player LuaPlayer
---@return PlayerAnchorRenderingState
function PlayerAnchorRenderingState.load(player)
    local pars = PlayerAnchorRenderingState.load_from_storage(player, true)
    if not pars then
        error('Expected a non-null Player-Anchor Rendering State but received nil.')
    end
    return pars
end


---@param player LuaPlayer
---@param create boolean?
---@return PlayerAnchorRenderingState
function PlayerAnchorRenderingState.load_from_storage(player, create)
    game.print(string.format("%s PA Rendering State for player %s", create and "loading/creating" or "loading", player.index))
    ---@type PlayerAnchorRenderingState
    local pars = storage.player_anchor_rendering_state[player.index] --[[@as PlayerAnchorRenderingState]]
    if pars then
        setmetatable(pars, PlayerAnchorRenderingState)
    elseif create then
        pars = PlayerAnchorRenderingState:new(player)
    end
    if pars then
        for _, anchor in pars.anchors do
            setmetatable(anchor, Anchor)
        end
        pars:refresh()
    end
    return pars
end


---@param player? LuaPlayer
---@return Anchor[]
function PlayerAnchorRenderingState:find_anchor_points(player)
    player = player or self:get_player()
    local surface = player.surface
    local pos = player.position
    
    local area = {
        {pos.x - AnchorConfig.find_radius, pos.y - AnchorConfig.find_radius},
        {pos.x + AnchorConfig.find_radius, pos.y + AnchorConfig.find_radius}
    }
    local processor_entities = surface.find_entities_filtered{area = area, name = ProcessorConfig.processor_name, force = player.force}
    
    local anchors = {}
    for _, proc_entity in ipairs(processor_entities) do
        ---@type Processor
        local proc = Processor.load_from_storage(proc_entity)
        local slots = proc:get_active_formation_slots()
        for _, slot in ipairs(slots) do
            local anchor = Anchor:new(player, proc, slot)
            table.insert(anchors, anchor)
        end
    end
    return anchors
end

---@param entity LuaEntity
---@param anchors Anchor[]
---@return Anchor?
local function get_nearest_anchor_point(entity, anchors)
    local nearest = nil
    for _, anchor in ipairs(anchors) do
        local d2 = anchor:sq_distance_from(entity)
        if d2 < best_d2 then
            best_d2 = d2
            nearest = anchor
        end
    end
end

-- Snap/Reject on build --------------------------------------------------------

---@param entity LuaEntity
---@param player? LuaPlayer
local function try_snap_or_reject(entity, player)
    if not (entity and entity.valid and entity.name == ProcessorConfig.iopoint_name) then return end
    if not player then return end
    local pars = PlayerAnchorRenderingState.load(player)
    local anchor = get_nearest_anchor_point(entity, pars.anchors)

    if anchor then
        entity.teleport(anchor:world_position())
        entity.direction = anchor.slot.direction
    else
        entity.destroy{raise_destroy = true}
        if player then
            refund_item(player, ProcessorConfig.iopoint_name, 1)
        end
    end
end

-- Events ---------------------------------------------------------------------

factorissimo.handle_built(function(e)
    local ent = e.entity
    if not (ent and ent.valid and ent.name == ProcessorConfig.iopoint_name) then return end
    local player = game.players[e.player_index]
    try_snap_or_reject(ent, player)
end)


script.on_init(function()
    storage.anchor_preview = storage.anchor_preview or {}
end)

script.on_configuration_changed(function()
    storage.anchor_preview = storage.anchor_preview or {}
end)

-- Clean up previews when players leave/changes happen
script.on_event(defines.events.on_player_left_game, function(e)
    clear_preview(e.player_index)
end)

---@param e EventData.on_player_cursor_stack_changed
script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
    local player = game.get_player(e.player_index)
    local cs = player.cursor_stack
    if cs and cs.valid_for_read and cs.name == ProcessorConfig.iopoint_name then
        pdata.cursor_has_iopoint = true
    end
    update_player_preview(player, pdata)
end
)

script.on_nth_tick(AnchorConfig.tick_interval, function(e)
    for player_index, pdata in pairs(storage.anchor_preview) do
        if pdata.cursor_has_iopoint then
            local player = game.get_player(player_index)
            if player then
                update_player_preview(player, pdata)
            end
        end
    end
end)

factorissimo.handle_player_changed(function(event)
end)

return PlayerAnchorRenderingState
local ProcessorConfig = require 'scripts.processor.config'
local ProcessorSlot = require 'scripts.processor.slot'

---@class ProcessorRenderingState
local ProcessorRenderingState = {}
ProcessorRenderingState.__index = ProcessorRenderingState

---@param player_index int
---@return ProcessorRenderingState
function ProcessorRenderingState:new(player_index)
    local instance = {
        player_index = player_index,
        render_ids = {} --[[ @as table<integer,integer[]> ]],
        refresh_required = false
    }
    setmetatable(instance, self)
    storage.player_anchor_rendering_state[player_index] = instance
    return instance
end

function ProcessorRenderingState.initialize()
    ---@type table<integer, ProcessorRenderingState>
    storage.player_anchor_rendering_state = storage.player_anchor_rendering_state or {}
end

function ProcessorRenderingState:__tostring()
    return string.format('PA rendering state for player %d:%d renders', self.player_index, #self.render_ids)
end

---@return LuaPlayer
function ProcessorRenderingState:get_player()
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
    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == ProcessorConfig.iopoint_name then
        return true
    end
    return false
end

---@param slots ProcessorSlot[]
function ProcessorRenderingState:render_slots(slots)
    if #self.render_ids > 0 then
        self:clear_renders()
    end
    for _, slot in ipairs(slots) do
        local render_ids = slot:draw()
        self.render_ids = table.array_combine(self.render_ids, render_ids)
    end
end

function ProcessorRenderingState:clear_renders()
    for _, id in ipairs(self.render_ids) do
        local render = rendering.get_object_by_id(id)
        if render then
            render.destroy()
        end
    end
    self.render_ids = {} --[[@as table<integer,integer[]>]]
end

---@param player_index integer
---@return ProcessorRenderingState
function ProcessorRenderingState.load(player_index)
    ---@type ProcessorRenderingState
    local pars = storage.player_anchor_rendering_state[player_index] --[[@as ProcessorRenderingState]]
    if pars then
        setmetatable(pars, ProcessorRenderingState)
    else
        pars = ProcessorRenderingState:new(player_index)
    end
    return pars
end


---@return ProcessorRenderingState[]
function ProcessorRenderingState.load_refreshes()
    ---@type ProcessorRenderingState[]
    local refreshes = {}
    for _, pars in pairs(storage.player_anchor_rendering_state) do
        if pars.refresh_required then
            setmetatable(pars, ProcessorRenderingState)
            table.insert(refreshes, pars)
        end
    end
    return refreshes
end


factorissimo.handle_built(function(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.name == ProcessorConfig.iopoint_name) then return end
    local pars = ProcessorRenderingState.load(event.player_index)
    pars.refresh_required = true
end)

factorissimo.handle_player_changed(function(event)
    local pars = ProcessorRenderingState.load(event.player_index)
    pars.refresh_required = true
end)

factorissimo.on_event(defines.events.on_player_cursor_stack_changed,
    ---@param event EventData.on_player_cursor_stack_changed]
    function(event)
        local pars = ProcessorRenderingState.load(event.player_index)
        pars.refresh_required = true
    end
)

factorissimo.on_nth_tick(ProcessorConfig.rendering_interval, function()
    local pars_list = ProcessorRenderingState.load_refreshes()
    for _, pars in ipairs(pars_list) do
        pars:clear_renders()
        local player = game.get_player(pars.player_index)
        if player and is_player_holding_iopoint(player) then
            local slots = ProcessorSlot.find_available_slots(player)
            pars:render_slots(slots)
        end
        pars.refresh_required = false
    end
end)

return ProcessorRenderingState
---@class Anchor
---@field find_radius number
---@field hover_radius number
---@field tick_interval integer
local Anchor = {
    -- search for processors within this many tiles of the cursor
    find_radius = 6.0,
    -- how close the cursor must be to “hover” an anchor
    hover_radius = 0.6,
    -- preview update throttle (every 10 ticks ~= 6x/sec)
    tick_interval = 10
}
Anchor.__index = Anchor

function Anchor.initialize()
    game.print('initializing IoPoint class storage')
    ---@type table<integer, AnchorPreviewData>
    storage.anchor_preview = storage.anchor_preview or {}
end

return Anchor
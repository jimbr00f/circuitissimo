---@class AnchorConfig
---@field find_radius number
---@field hover_radius number
---@field tick_interval integer
local AnchorConfig = {
    -- search for processors within this many tiles of the cursor
    find_radius = 6.0,
    -- how close the cursor must be to “hover” an anchor
    hover_radius = 10.0,
    -- preview update throttle (every 10 ticks ~= 6x/sec)
    tick_interval = 10
}
AnchorConfig.__index = AnchorConfig

return AnchorConfig
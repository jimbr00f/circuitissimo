---@class AnchorConfig
---@field find_radius number
---@field hover_radius number
---@field tick_interval integer
local AnchorConfig = {
    -- search for processors within this many tiles of the cursor
    find_radius = 6.0,
    -- match anchor points that are up to this distance away from the placement position
    placement_radius = 0.1,
    -- preview update throttle (every 10 ticks ~= 6x/sec)
    tick_interval = 10
}
AnchorConfig.__index = AnchorConfig

return AnchorConfig
local common = require('scripts.common')
local iopoint_layout = common.iopoint_layout
local processor = {}

---@param procinfo ProcInfo
local function update_connections(procinfo)
    -- TODO: invoke Factorissimo connection builders
end

---@param info ProcInfo
function processor.build_processor(info)
    local processor = info.processor
    local pos = processor.position
    local surface = processor.surface
    local iopoint_positions = iopoint_layout.positions[processor.direction]
    local iopoints = {}
    for _, iop in pairs(iopoint_positions) do
        local x1 = pos.x + iop.x
        local y1 = pos.y + iop.y
        local area = { { x1 - 0.05, y1 - 0.05 }, { x1 + 0.05, y1 + 0.05 } }

        ---@type LuaEntity?
        local iopoint = surface.create_entity {
            name = common.iopoint_name,
            position = { x1, y1 },
            force = processor.force
        }
        iopoint.destructible = false
        iopoint.minable = false
        table.insert(iopoints, iopoint)
    end
    info.iopoints = iopoints
    update_connections(info)
end

return processor
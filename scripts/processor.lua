local common = require('scripts.common')
local iopoint_layout = common.iopoint_layout
local processor = {}

---@param procinfo ProcInfo
local function update_connections(procinfo)
    -- TODO: invoke Factorissimo connection builders
end

---@param source IOPoint
---@param target IOPoint
local function transfer_connections(source, target)
    for _, wire_type in ipairs(common.wire_types) do
        local src_conn = source.entity.get_wire_connector(wire_type, true)
        local tgt_conn = target.entity.get_wire_connector(wire_type, true)
        if src_conn and tgt_conn then
            for _, conn in ipairs(src_conn.connections) do
                tgt_conn.connect_to(conn.target, false)
            end
        end
    end
end

---@param entity LuaEntity
---@return IOPoint
local function create_iopoint(entity)
    return { entity = entity }
end

---@param info ProcInfo
---@return IOPoint[]
local function build_iopoints(info)
    local entity = info.entity
    local positions = iopoint_layout.positions[entity.direction]
    ---@type IOPoint[]
    local iopoints = {}
    for _, iop in pairs(positions) do
        local pos = { x = entity.position.x, y = entity.position.y }
        local offset = { x = iop.x, y = iop.y }
        if entity.mirroring then
            if entity.direction == defines.direction.north or entity.direction == defines.direction.south then
                offset.x = -offset.x
            else
                offset.y = -offset.y
            end
        end

        local iopoint_entity = entity.surface.create_entity {
            name = common.iopoint_name,
            position = { pos.x + offset.x, pos.y + offset.y },
            force = entity.force
        }
        if iopoint_entity then
            iopoint_entity.destructible = false
            iopoint_entity.minable = false
            
            local iopoint = create_iopoint(iopoint_entity)
            table.insert(iopoints, iopoint)
        end
    end
    return iopoints
end

---@param info ProcInfo
function processor.destroy_processor(info)
    game.print('processor destroyed')
    for _, iopoint in ipairs(info.iopoints) do
        iopoint.entity.destroy()
    end
end


---@param info ProcInfo
function processor.build_processor(info)
    game.print('processor built')
    info.iopoints = build_iopoints(info)
    update_connections(info)
end

---@param info ProcInfo
function processor.reorient_processor(info)
    game.print('processor reoriented')
    game.print('direction: ')
    game.print(info.entity.direction)
    game.print('mirroring: ')
    game.print(info.entity.mirroring)
    local new_iopoints = build_iopoints(info)
    for i, old_iopoint in ipairs(info.iopoints) do
        if old_iopoint.entity and old_iopoint.entity.valid then
            local new_iopoint = new_iopoints[i]
            transfer_connections(old_iopoint, new_iopoint)
            old_iopoint.entity.destroy()
        end
    end
    info.iopoints = new_iopoints
end

---@param source ProcInfo
---@param destination ProcInfo
function processor.clone_processor(source, destination)
    game.print('processor cloned')
end

return processor
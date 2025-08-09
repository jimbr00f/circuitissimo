local common = require('scripts.common')
local utility = require('scripts.utility')
local exports = {}

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
    local target_direction = entity.direction
    if info.mirroring and common.direction_orientation[entity.direction] == common.orientation.horizontal then
        -- In this case we perform the equivalent of a vertical flip on the iopoints by
        -- rotating by 180 degrees and then performing a horizontal flip.
        target_direction = common.flipped_direction[target_direction]
    end
    local positions = common.iopoint_formation.path[target_direction]
    ---@type IOPoint[]
    local iopoints = {}
    for _, iop in pairs(positions) do
        local pos = { x = entity.position.x, y = entity.position.y }
        local offset = { x = iop.x, y = iop.y }
        if info.mirroring then
            offset.x = -offset.x
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
function exports.destroy_processor(info)
    utility.log('processor:destroy_processor')
    for _, iopoint in ipairs(info.iopoints) do
        iopoint.entity.destroy()
    end
end


---@param info ProcInfo
function exports.build_processor(info)
    utility.log('processor:build_processor')
    info.iopoints = build_iopoints(info)
    update_connections(info)
end

---@param info ProcInfo
---@param mirroring orientation?
function exports.reorient_processor(info, mirroring)
    utility.log('processor:reorient_processor')
    if mirroring then
        utility.log('invoked reorient_processor; initial direction: '..common.direction_name[info.entity.direction])
        info.mirroring = not info.mirroring
        utility.log('updated info.mirroring: ' .. tostring(not info.mirroring) .. ' => ' .. tostring(info.mirroring))
    end
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
function exports.clone_processor(source, destination)
    utility.log('processor:clone_processor')
end


---@param entity LuaEntity
---@param create boolean?
---@return ProcInfo
function exports.load_stored_info(entity, create)
    if not storage.processors then storage.processors = {} end
    local info = storage.processors[entity.unit_number]
    if not info and create then
        info = {
            entity = entity,
            unit_number = entity.unit_number,
            iopoints = {},
            mirroring = false
        }
        storage.processors[entity.unit_number] = info
    end
    return info
end


return exports
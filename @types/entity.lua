---@class EntityInfo
---@field entity LuaEntity
---@field unit_number uint64

---@class ProcInfo : EntityInfo
---@field iopoints IoPointInfo[]
---@field mirroring boolean
---@field locked boolean
---@field direction defines.direction

---@class IoPointInfo : EntityInfo
---@field index integer
---@field connections IoPointWireConnection[]

---@class IoPointWireConnection
---@field source_unit_number uint64
---@field source_connector_id defines.wire_connector_id
---@field target_unit_number uint64
---@field target_connector_id defines.wire_connector_id
---@field wire_type defines.wire_type

---@enum connection_transfer_type
connection_transfer_type = {
    update = 1 --[[@as connection_transfer_type.update]],
    rebuild = 2 --[[@as connection_transfer_type.rebuild]],
    reapply = 3 --[[@as connection_transfer_type.reapply]],
}
---@class EntityInfo
---@field entity LuaEntity

---@class ProcInfo : EntityInfo
---@field iopoints IoPointInfo[]
---@field mirroring boolean
---@field unit_number uint64
---@field locked boolean

---@class IoPointInfo : EntityInfo
---@field index integer
---@field connections IoPointWireConnection[]

---@class IoPointWireConnection
---@field source_connector_id defines.wire_connector_id
---@field target_connector_id defines.wire_connector_id
---@field target_unit_number uint64

---@enum connection_transfer_type
connection_transfer_type = {
    replace = 1 --[[@as connection_transfer_type.replace]],
    rebuild = 2 --[[@as connection_transfer_type.rebuild]],
    reapply = 3 --[[@as connection_transfer_type.reapply]],
}
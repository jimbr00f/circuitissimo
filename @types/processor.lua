---@class IoPoint : EntityInfo
---@field index integer

---@class Processor : EntityInfo
---@field iopoints table<uint64, IoPoint>
---@field indexed_iopoints table<integer, uint64>

---@class ProcessorRenderingState
---@field player_index integer
---@field render_ids integer[]
---@field refresh_required boolean

---@class ProcessorSlot : FormationSlot
---@field player LuaPlayer
---@field processor Processor
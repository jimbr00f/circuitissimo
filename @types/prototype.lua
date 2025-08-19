---@class WireConnectionOrigin
---@field entity MapPosition
---@field shadow MapPosition

---@class DirectionalOffsets.0
---@field north MapPosition
---@field east MapPosition
---@field south MapPosition
---@field west MapPosition

---@alias DirectionalOffsets DirectionalOffsets.0|MapPosition[]

---@class WireConnectionOffsets.0
---@field entity DirectionalOffsets
---@field shadow DirectionalOffsets

---@alias WireConnectionOffsets WireConnectionOffsets.0|DirectionalOffsets[]

---@class WireConnectionPointPrototype
---@field red MapPosition
---@field green MapPosition

---@class EntityWireConnectionPointPrototype
---@field wire WireConnectionPointPrototype
---@field shadow WireConnectionPointPrototype
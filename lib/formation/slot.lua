---@class FormationSlot
---@field index integer
---@field position MapPosition
local FormationSlot = { }
FormationSlot.__index = FormationSlot

---@param position MapPosition
---@param index integer
---@return FormationSlot
function FormationSlot:new(index, position)
    local instance = { index = index, position = position }
    setmetatable(instance, self)
    return instance
end

function FormationSlot:__tostring()
    return string.format("slot #%d at (%.1f, %.1f)", self.index, self.position.x, self.position.y)
end

---@param position MapPosition
---@param radius number
---@return boolean
function FormationSlot:matches_position(position, radius)
    if math.abs(position.x - self.position.x) > radius then return false end
    if math.abs(position.y - self.position.y) > radius then return false end
    return true
end

return FormationSlot
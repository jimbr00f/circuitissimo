---@class Formatting
local Formatting = {}

---@param entity LuaEntity
---@return string
function Formatting.format_entity(entity)
    return string.format("%s at (%.1f, %.1f)", entity.name, entity.position.x, entity.position.y)
end

return Formatting
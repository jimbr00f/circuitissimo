---@class FormationSearch
local FormationSearch = {}
FormationSearch.__index = FormationSearch

---@param entity LuaEntity
---@param radius number
---@return BoundingBox
function FormationSearch.get_search_area(entity, radius)
    local box = entity.selection_box
    ---@type BoundingBox
    local area = {
        left_top = { x = box.left_top.x - radius, y = box.left_top.y - radius },
        right_bottom = { x = box.right_bottom.x + radius, y = box.right_bottom.y + radius }
    }
    return area
end

return FormationSearch
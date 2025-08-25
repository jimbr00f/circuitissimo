---@class FormationSearch
local FormationSearch = {}
FormationSearch.__index = FormationSearch

---@param origin LuaEntity|LuaControl
---@param radius number
---@return BoundingBox
function FormationSearch.get_search_area(origin, radius)
    local box = origin.selection_box or {
        left_top = origin.position,
        right_bottom = origin.position
    }
    ---@type BoundingBox
    local area = {
        left_top = { x = box.left_top.x - radius, y = box.left_top.y - radius },
        right_bottom = { x = box.right_bottom.x + radius, y = box.right_bottom.y + radius }
    }
    return area
end

return FormationSearch
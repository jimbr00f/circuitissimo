local Formation = require 'lib.formation.formation'

---@class ProcessorUtility
local ProcessorUtility = {}
ProcessorUtility.__index = {}

---@param origin LuaEntity|LuaControl
---@param radius number
---@param name string
---@return LuaEntity[]
function ProcessorUtility.find_nearest_entities(origin, radius, name)
    local area = Formation.search.get_search_area(origin, radius)
    local entities = origin.surface.find_entities_filtered{
        area = area,
        name = name,
        force = origin.force
    }
    return entities
end

return ProcessorUtility
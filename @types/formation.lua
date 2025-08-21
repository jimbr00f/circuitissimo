---@class FormationSearch
---@field get_search_area fun(entity: LuaEntity, radius: number) : BoundingBox

---@class OrientationConversion
---@field to_circular_orientation table<orientation, orientation[]>

---@class DirectionConversion
---@field to_mirror_direction table<defines.direction, defines.direction>
---@field to_canonical_orientation table<defines.direction, orientation>
---@field to_mirror_orientation table<defines.direction, orientation>
---@field to_axis table<defines.direction, axis>
---@field to_orientation fun(direction : defines.direction, mirroring: boolean) : orientation

---@class FormationConversion
---@field direction DirectionConversion
---@field orientation OrientationConversion

---@class FormationSlot
---@field index integer
---@field position MapPosition


---@class FormationPath
---@field slots FormationSlot[]
---@field orientation orientation

---@class Formation : PartitionShape
---@field paths table<orientation, FormationPath>
---@field lookup_radius number
---@field convert FormationConversion
---@field search FormationSearch
---@class DirectionConversion
---@field cardinal_direction table<string, defines.direction>
---@field to_mirror_direction table<defines.direction, defines.direction>
---@field to_canonical_orientation table<defines.direction, orientation>
---@field to_mirror_orientation table<defines.direction, orientation>
---@field to_axis table<defines.direction, axis>
local DirectionConversion = {
    cardinal_direction = {
        north = defines.direction.north,
        east  = defines.direction.east,
        south = defines.direction.south,
        west  = defines.direction.west,
    },

    to_mirror_direction = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.east] = defines.direction.west,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.west] = defines.direction.east,
    },

    to_canonical_orientation = {
        [defines.direction.north] = orientation.r0,
        [defines.direction.east] = orientation.r1,
        [defines.direction.south] = orientation.r2,
        [defines.direction.west] = orientation.r3,
    },

    to_mirror_orientation = {
        [defines.direction.north] = orientation.mr0,
        [defines.direction.east] = orientation.mr3,
        [defines.direction.south] = orientation.mr2,
        [defines.direction.west] = orientation.mr1,
    },
    
    to_axis = {
        [defines.direction.north] = axis.vertical,
        [defines.direction.east] = axis.horizontal,
        [defines.direction.south] = axis.vertical,
        [defines.direction.west] = axis.horizontal,
    },
}

---@param direction defines.direction
---@param mirroring boolean
---@return orientation
function DirectionConversion.to_orientation(direction, mirroring)
    if mirroring then 
        return DirectionConversion.to_mirror_orientation[direction]
    else
        return DirectionConversion.to_canonical_orientation[direction]
    end
end

---@class OrientationConversion
---@field to_circular_orientation table<orientation, orientation[]>
local OrientationConversion = {
    to_circular_orientation = {
        [orientation.r0] = { orientation.r0,orientation.r1,orientation.r2,orientation.r3, },
        [orientation.r1] = { orientation.r1,orientation.r2,orientation.r3,orientation.r0, },
        [orientation.r2] = { orientation.r2,orientation.r3,orientation.r0,orientation.r1 },
        [orientation.r3] = { orientation.r3,orientation.r0,orientation.r1,orientation.r2, },
        [orientation.mr0] = { orientation.mr0,orientation.mr1,orientation.mr2,orientation.mr3, },
        [orientation.mr1] = { orientation.mr1,orientation.mr2,orientation.mr3,orientation.mr0, },
        [orientation.mr2] = { orientation.mr2,orientation.mr3,orientation.mr0,orientation.mr1 },
        [orientation.mr3] = { orientation.mr3,orientation.mr0,orientation.mr1,orientation.mr2, },
    }
}

---@class FormationConversion
---@field direction DirectionConversion
---@field orientation OrientationConversion
FormationConversion = {
    direction = DirectionConversion,
    orientation = OrientationConversion
}

return FormationConversion
local exports = {}

---@param origin WireConnectionOrigin
---@param offsets WireConnectionOffsets
---@return EntityWireConnectionPointPrototype
function exports.create_wire_connection_points(origin, offsets)

    ---@type EntityWireConnectionPointPrototype[]
    local wire_connection_points = {}

    for i = 1, 4 do
        local eo = offsets.entity[i]
        ---@type WireConnectionPointPrototype
        local wire_point = {
            red = util.by_pixel(origin.entity.x + eo.x, origin.entity.y + eo.y),
            green = util.by_pixel(origin.entity.x - eo.x, origin.entity.y - eo.y)
        }
        local so = offsets.shadow[i]
        ---@type WireConnectionPointPrototype
        local shadow_point = {
            red = util.by_pixel(origin.shadow.x + so.x, origin.shadow.y + so.y),
            green = util.by_pixel(origin.shadow.x - so.x, origin.shadow.y - so.y)
        }
        ---@type EntityWireConnectionPointPrototype
        local connection_points = { wire = wire_point, shadow = shadow_point }
        table.insert(wire_connection_points, connection_points)
    end
    return wire_connection_points
end

---@param connection_points  EntityWireConnectionPointPrototype[]
function exports.convert_pixels_to_tiles(connection_points)
    local converted = {}
    for _, item in ipairs(connection_points) do
        ---@type EntityWireConnectionPointPrototype
        local converted_item = {
            wire = {
                red = util.by_pixel(item.wire.red.x, item.wire.red.y),
                green = util.by_pixel(item.wire.green.x, item.wire.green.y)
            },
            shadow = {
                red = util.by_pixel(item.shadow.red.x, item.shadow.red.y),
                green = util.by_pixel(item.shadow.green.x, item.shadow.green.y)
            }
        }
        table.insert(converted, converted_item)
    end
    return converted
end

return exports
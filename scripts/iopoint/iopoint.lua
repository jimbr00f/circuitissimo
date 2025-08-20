---@class IoPoint : EntityInfo
---@field index integer
---@field connections IoPointWireConnection[]
local IoPoint = {}
IoPoint.__index = IoPoint

---@param entity LuaEntity
---@param index number
---@return IoPoint
function IoPoint:new(entity, index)
    local instance = { 
        entity = entity,
        index = index,
        connections = {}
    }
    setmetatable(instance, self)
    storage.iopoints[entity.unit_number] = instance
    return instance
end

function IoPoint.initialize()
    ---@type table<uint64, IoPoint>
    storage.iopoints = storage.iopoints or {}
end

function IoPoint:destroy()
    self.entity.destroy()
    self.locked = true
end

function IoPoint:__tostring()
    return string.format("%s #%d at (%.1f, %.1f)", self.entity.name, self.index, self.entity.position.x, self.entity.position.y)
end


---@return IoPointWireConnection[]
function IoPoint:get_connections()
    ---@type IoPointWireConnection[]
    local connections = {}
    if not self.entity.valid then return connections end
    local source_connectors = self.entity.get_wire_connectors(false)
    for source_id, source_connector in pairs(source_connectors) do
        for i, connection in ipairs(source_connector.connections) do
            local dest_name = connection.target.owner.name
            if dest_name == "ghost-entity" then
                dest_name = connection.target.owner.ghost_name
            end
            local conn = {
                source_unit_number = self.unit_number,
                source_connector_id = source_id,
                target_connector_id = connection.target.wire_connector_id,
                target_unit_number = connection.target.owner.unit_number,
                wire_type = source_connector.wire_type
            } --[[@as IoPointWireConnection]]
            store_entity(connection.target.owner)
            game.print('iopoint#' .. tostring(self.index) .. ': creating conn #' .. tostring(i) .. ': ' .. tostring(conn.source_connector_id) .. ' => ' .. tostring(conn.target_connector_id) .. ' with owner: ' .. tostring(connection.target.owner.unit_number))
            table.insert(connections, conn)
        end
    end
    return connections
end

function IoPoint:refresh()
    self:load_connections()
end

function IoPoint:load_connections()
    self.connections = self:get_connections()
end

---@param entity LuaEntity
---@return IoPoint
function IoPoint.load(entity, index)
    local iopoint = IoPoint.load_from_storage(entity, index, true)
    if not iopoint then
        error('Expected a non-null iopoint but received nil.')
    end
    return iopoint
end

---@param entity LuaEntity
---@param create boolean?
---@return IoPoint?
function IoPoint.load_from_storage(entity, index, create)
    game.print("loading stored iopoint for entity: " .. tostring(entity.unit_number))
    local info = storage.iopoints[entity.unit_number]
    if info and not info.locked then
        game.print('refreshing iopoint')
        info.refresh()
    elseif not info and create then
        game.print('creating new iopoint')
        info = IoPoint:new(entity, index)
    end
    return info
end

return IoPoint
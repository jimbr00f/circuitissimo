---@class LayoutRect
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number
---@field tile string

---@class LayoutMosaic : LayoutRect
---@field pattern string[]


---@class SurfaceConduit
---@field inside_x number
---@field inside_y number
---@field outside_x number
---@field outside_y number
---@field indicator_dx number
---@field indicator_dy number
---@field direction_in defines.direction
---@field direction_out defines.direction

---@alias ConnectionPosition SurfaceConduit

---@class LayoutConnection : SurfaceConduit
---@field id string
---@field quality number?

---@class LayoutOverlay
---@field outside_x number
---@field outside_y number
---@field outside_w number
---@field outside_h number
---@field inside_x number
---@field inside_y number

---@class Layout
---@field name string
---@field tier integer
---@field inside_size integer
---@field outside_size integer
---@field inside_door_x number
---@field inside_door_y number
---@field outside_door_x number
---@field outside_door_y number
---@field outside_energy_receiver_type string
---@field inside_energy_x number
---@field inside_energy_y number
---@field overlay_x integer
---@field overlay_y integer
---@field rectangles LayoutRect[]
---@field mosaics LayoutMosaic[]
---@field connection_tile string
---@field connections table<string, LayoutConnection>
---@field overlays LayoutOverlay
---@field cerys_radiative_towers Vector[]

---@alias ConnectionId string
---@alias ConnectionType string

---@class BuildingConnection
---@field _id ConnectionId
---@field _type ConnectionType
---@field _factory Factory
---@field _settings ConnectionSettings
---@field _valid boolean
---@field from LuaEntity
---@field to LuaEntity
---@field from_link LuaEntity
---@field to_link LuaEntity
---@field facing defines.direction
---@field spill_location MapPosition
---@field do_tick_update boolean

---@class ConnectionSettings
---@field delay integer
---@field mode integer
---@field input_mode boolean

---@class SurfaceConnector
---@field color Color
---@field entity_types string[]
---@field unlocked fun(force: LuaForce) : boolean
---@field connect fun(factory: any, cid: any, cpos: MapPosition, outside_entity: LuaEntity, inside_entity: LuaEntity)
---@field recheck fun(conn: BuildingConnection) : boolean
---@field direction fun(conn: BuildingConnection) : connection_mode, defines.direction
---@field rotate fun(conn: BuildingConnection) : string, boolean
---@field adjust fun(conn: BuildingConnection) : string, boolean
---@field destroy fun(conn: BuildingConnection)

---@class SurfaceBuilding
---@field force LuaForce|string|integer
---@field quality LuaQualityPrototype
---@
---@field inside_x number
---@field inside_y number
---@field inside_door_x number
---@field inside_door_y number
---@field inside_surface LuaSurface
---@
---@field outside_x number
---@field outside_y number
---@field outside_door_x number
---@field outside_door_y number
---@field outside_surface LuaSurface
---@
---@field stored_pollution number
---@field radar LuaEntity?
---@field connections table<ConnectionId, BuildingConnection>
---@field connection_settings table<ConnectionId, ConnectionSettings>
---@field connection_indicators table<ConnectionId, LuaEntity>
---@field outside_energy_receiver LuaEntity?
---@field outside_overlay_displays integer[]
---@field outside_port_markers integer[]
---@field building LuaEntity
---@field layout Layout
---@field built boolean

---@alias Factory SurfaceBuilding


---@class FactorySearchParams
---@field area BoundingBox
---@field surface LuaSurface
---@field position MapPosition?

---@enum transfer_mode
transfer_mode = {
    d0 = 1 --[[@as transfer_mode.d0 ]],
    d10 = 2 --[[@as transfer_mode.d10 ]],
    d20 = 3 --[[@as transfer_mode.d20 ]],
    d60 = 4 --[[@as transfer_mode.d60 ]],
    d180 = 5 --[[@as transfer_mode.d180 ]],
    d600 = 6 --[[@as transfer_mode.d600 ]],
}

---@enum balance_mode
balance_mode = {
    b0 = 1 --[[@as balance_mode.b0 ]],
    b10 = 2 --[[@as balance_mode.b10 ]],
    b20 = 3 --[[@as balance_mode.b20 ]],
    b60 = 4 --[[@as balance_mode.b60 ]],
    b180 = 5 --[[@as balance_mode.b180 ]],
    b600 = 6 --[[@as balance_mode.b600 ]],
}

---@enum connection_mode
connection_mode = {
    d0 = transfer_mode.d0 --[[@as connection_mode.d0 ]],
    d10 = transfer_mode.d10 --[[@as connection_mode.d10 ]],
    d20 = transfer_mode.d20 --[[@as connection_mode.d20 ]],
    d60 = transfer_mode.d60 --[[@as connection_mode.d60 ]],
    d180 = transfer_mode.d180 --[[@as connection_mode.d180 ]],
    d600 = transfer_mode.d600 --[[@as connection_mode.d600 ]],

    b0 = balance_mode.b0 --[[@as connection_mode.b0 ]],
    b10 = balance_mode.b10 --[[@as connection_mode.b10 ]],
    b20 = balance_mode.b20 --[[@as connection_mode.b20 ]],
    b60 = balance_mode.b60 --[[@as connection_mode.b60 ]],
    b180 = balance_mode.b180 --[[@as connection_mode.b180 ]],
    b600 = balance_mode.b600 --[[@as connection_mode.b600 ]],
}

connection_mode_names = {}
for name, value in pairs(connection_mode) do
    connection_mode_names[value] = name
end
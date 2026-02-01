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
---@field outside LuaEntity
---@field inside LuaEntity

---@class SurfaceConnection
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
---@field outside LuaEntity
---@field outside_entity LuaEntity # replace these with 'outside'
---@field outside_middleman LuaEntity
---@field inside LuaEntity 
---@field inside_entity LuaEntity  # replace these with 'inside'
---@field inside_middleman LuaEntity

---@class ConnectionSettings
---@field delay integer
---@field mode integer
---@field input_mode boolean

---@class SurfaceConnector : BuildingConnection
---@field color Color
---@field entity_types string[]
---@field indicator_settings connection_mode[]
---@field default_delay integer?
---@field valid_delays integer[]?
---@field unlocked fun(self: SurfaceConnector, force: LuaForce|string|integer) : boolean
---@field recheck fun(self: SurfaceConnector, conn: SurfaceConnection) : boolean
---@field direction fun(self: SurfaceConnector, conn: SurfaceConnection) : connection_mode, defines.direction
---@field rotate fun(self: SurfaceConnector, conn: SurfaceConnection) : string, boolean
---@field adjust fun(self: SurfaceConnector, conn: SurfaceConnection, positive: boolean) : string, boolean
---@field destroy fun(self: SurfaceConnector, conn: SurfaceConnection)
---@field tick fun(self: SurfaceConnector, conn: SurfaceConnection) : integer?

---@class SurfaceBuilding
---@field force LuaForce|string|integer
---@field quality LuaQualityPrototype
---@field inactive boolean
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
---@field connections table<ConnectionId, SurfaceConnection>
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
---@field area BoundingBox?
---@field surface LuaSurface
---@field position MapPosition?

---@enum connection_mode
connection_mode = {
    d0 = #{} --[[@as connection_mode.d0 ]],
    d10 = #{} --[[@as connection_mode.d10 ]],
    d20 = #{} --[[@as connection_mode.d20 ]],
    d60 = #{} --[[@as connection_mode.d60 ]],
    d180 = #{} --[[@as connection_mode.d180 ]],
    d600 = #{} --[[@as connection_mode.d600 ]],

    b0 = #{} --[[@as connection_mode.b0 ]],
    b5 = #{} --[[@as connection_mode.b5 ]],
    b10 = #{} --[[@as connection_mode.b10 ]],
    b20 = #{} --[[@as connection_mode.b20 ]],
    b30 = #{} --[[@as connection_mode.b30 ]],
    b60 = #{} --[[@as connection_mode.b60 ]],
    b120 = #{} --[[@as connection_mode.b120 ]],
    b180 = #{} --[[@as connection_mode.b180 ]],
    b600 = #{} --[[@as connection_mode.b600 ]],
}

connection_mode_names = {}
for name, value in pairs(connection_mode) do
    connection_mode_names[value] = name
end
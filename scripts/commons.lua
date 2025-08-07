local prefix = "circuitissimo"
local prefix_pattern = "circuitissimo"

local commons = {
    prefix = prefix,
    prefix_pattern = prefix_pattern,
    png = function(name) return ('__circuitissimo__/graphics/%s.png'):format(name) end
}

commons.processor_name = prefix .. "-processor"
commons.processor_pattern = "^" .. prefix_pattern .. "%-processor"
commons.surface_name_pattern = "^proc%_%d+"

commons.processor_with_tags = prefix .. "-processor_with_tags"
commons.iopoint_name = prefix .. "-iopoint"
commons.internal_iopoint_name = prefix .. "-internal_iopoint"
commons.internal_connector_name = prefix .. "-internal_connector"
commons.device_name = prefix .. "-device"

commons.debug_mode = false

commons.display_all = 0
commons.display_one_line = 1
commons.display_none = 2
commons.boxsize = 0.0001
commons.EDITOR_SIZE = 32

commons.io_red  = 1
commons.io_green  = 2
commons.io_red_and_green  = 3

commons.io_input  = 1
commons.io_output  = 2
commons.io_input_and_output  = 3

return commons
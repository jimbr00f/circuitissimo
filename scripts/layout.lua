local common = require('scripts.common')
local geometry = require('lib.geometry')
local exports = {}

---@param size RadialSize
---@param count integer
---@returns OrientableLayoutInstance
local function create_iopoint_layout(size, count)
  local layout = geometry.build_orientable_layout(size, count)
  layout.path = geometry.reorient_path(layout.path, common.orthogonal_directions)
  return layout
end

exports.iopoint = create_iopoint_layout({ x = 0.8, y = 0.8}, 4)

return exports
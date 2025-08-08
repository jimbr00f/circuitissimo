local common = require('scripts.common')

local exports = {}

---@return Picture[]
function exports.get_cardinal_pictures(path)
    local pictures = {}
    for name, i in pairs(common.cardinal_direction) do
        ---@type Picture
        pictures[name] = {
            filename = common.png(path),
            width = 128,
            height = 128,
            scale = 0.5,
            x = i/4 * 128
        }
    end
    return pictures
end


function exports.log(message)
end

return exports
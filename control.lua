require "lib.lib"
local processor = require "scripts.processor.processor"

---@type EventListener[]
local listeners = { processor.event_listeners }

for _, listener in ipairs(listeners) do
    for event_type, event_handler in pairs(listener.subscriptions) do
        script.on_event(event_type, event_handler)
    end
end
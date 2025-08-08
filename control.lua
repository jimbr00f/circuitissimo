local processor_events = require('scripts.processor.events')

---@type EventListener[]
local listeners = { processor_events }

for _, listener in ipairs(listeners) do
    for event_type, event_handler in pairs(listener.subscriptions) do
        script.on_event(event_type, event_handler)
    end
end
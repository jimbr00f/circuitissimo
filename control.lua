require "lib.lib"
local processor_events = require "scripts.processor.events"

for event_type, event_handler in pairs(processor_events.subscriptions) do
    script.on_event(event_type, event_handler)
end
local IoPoint = require 'scripts.iopoint.iopoint'
local Processor = require 'scripts.processor.processor'
local processor_events = require "scripts.processor.events"
require 'scripts.anchor.rendering'
local Anchor = require 'scripts.anchor.anchor'

factorissimo.on_event(factorissimo.events.on_init(), function()
    game.print('called circuitissimo.on_init() handler')
    IoPoint.initialize()
    Processor.initialize()
    Anchor.initialize()
end)

for event_type, event_handler in pairs(processor_events.subscriptions) do
    script.on_event(event_type, event_handler)
end
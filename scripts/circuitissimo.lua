local IoPoint = require 'scripts.iopoint.iopoint'
local Processor = require 'scripts.processor.processor'
---@class Circuitissimo
local Circuitissimo = {}

factorissimo.on_event(factorissimo.events.on_init(), function()
    IoPoint.initialize()
    Processor.initialize()
end)

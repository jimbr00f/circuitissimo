local IoPoint = require 'scripts.iopoint.iopoint'
local Processor = require 'scripts.processor.processor'

factorissimo.on_event(factorissimo.events.on_init(), function()
    game.print('called circuitissimo.on_init() handler')
    IoPoint.initialize()
    Processor.initialize()
end)
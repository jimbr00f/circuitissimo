local IoPoint = require 'scripts.iopoint.iopoint'
local Processor = require 'scripts.processor.processor'
require "scripts.processor.events"
require 'scripts.anchor.rendering'
local Anchor = require 'scripts.anchor.anchor'
local PlayerAnchorRenderingState = require 'scripts.anchor.rendering'

factorissimo.on_event(factorissimo.events.on_init(), function()
    game.print('called circuitissimo.on_init() handler')
    IoPoint.initialize()
    Processor.initialize()
    Anchor.initialize()
    PlayerAnchorRenderingState.initialize()
end)
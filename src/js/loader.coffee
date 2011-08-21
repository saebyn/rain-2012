
gamejs = require 'gamejs'
scene = require 'scene'

# A loading screen...
# Preload the level sprites, etc, create a game scene, and switch the
# director to it.

exports.Loader = class Loader
  constructor: (@director, @levelFilename) ->

  update: (msDuration) ->
    level = gamejs.http.load(@levelFilename)
    scene = new scene.Scene(@director, level)
    @director.replaceScene(scene)

  #draw: (display) ->

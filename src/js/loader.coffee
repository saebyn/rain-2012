
gamejs = require 'gamejs'
scene = require 'scene'

# A loading screen...
# Preload the level sprites, etc, create a game scene, and switch the
# director to it.

exports.Loader = class Loader
  constructor: (@director, @levelFilename) ->
    @level = gamejs.http.load(@levelFilename)
    @getLoadProgress = @load(@extractResources())
    @loaded = false

  # extract the relative urls to the resources in @level
  extractResources: ->
    resources = []
    for name, sprite of @level.solids
      if sprite.image?
        resources.push(sprite.image)

    for name, sprite of @level.npcs
      if sprite.image?
        resources.push(sprite.image)

    resources

  resourcesLoaded: =>
    @loaded = true

  load: (resources) ->
    gamejs.preload(resources)
    gamejs.ready(@resourcesLoaded)

  progress: ->
    (@getLoadProgress() * 100) + '%'

  update: (msDuration) ->
    if @loaded
      scene = new scene.Scene(@director, @level)
      @director.replaceScene(scene)

  draw: (display) ->
    # draw progress
    console.log @progress()

gamejs = require 'gamejs'
event = require 'event'


exports.Director = class Director extends event.Event
  constructor: (width, height) ->
    @viewport = new gamejs.Rect(0, 0, width, height)
    @display = gamejs.display.setMode([width, height])
    @activeScene = false
    @live = false
    gamejs.time.fpsCallback(@tick, this, 30)

  tick: (msDuration) ->
    if @live
      if @activeScene.handleEvent?
        gamejs.event.get().forEach(@activeScene.handleEvent)
      else
        gamejs.event.get()  # discard unused events
    
      @activeScene.update?(msDuration)
      @activeScene.draw?(@display)

  start: (scene) ->
    @live = true
    @replaceScene(scene)

  replaceScene: (scene) ->
    @activeScene = scene

  getScene: ->
    @activeScene

  getViewport: ->
    @viewport

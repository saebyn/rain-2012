gamejs = require 'gamejs'
scene = require 'scene'
loader = require 'loader'

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 400


class Director
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


gamejs.ready ->
  director = new Director(SCREEN_WIDTH, SCREEN_HEIGHT)
  director.start(new loader.Loader(director, 'level1.json'))

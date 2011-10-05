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
      gamejs.event.get().forEach (event) =>
        switch event.type
          when gamejs.event.MOUSE_DOWN then @trigger('mousedown', event)
          when gamejs.event.MOUSE_UP then @trigger('mouseup', event)
          when gamejs.event.KEY_DOWN then @trigger('keydown', event)
          when gamejs.event.KEY_UP then @trigger('keyup', event)

      @trigger('update', msDuration)
      @trigger('draw', @display)
    else
      gamejs.event.get()  # discard unused events

  start: (scene) ->
    @live = true
    @replaceScene(scene)

  replaceScene: (scene) ->
    # remove all existing event bindings
    if @activeScene
      @unbind()

    @activeScene = scene
    @activeScene.start()

  getScene: ->
    @activeScene

  getViewport: ->
    @viewport

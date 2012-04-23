#
# Copyright (c) 2012 John David Weaver
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

gamejs = require 'gamejs'
event = require 'event'


exports.Director = class Director extends event.Event
  constructor: (width, height) ->
    @viewport = new gamejs.Rect(0, 0, width, height)
    @display = gamejs.display.setMode([width, height])
    @activeScene = false
    @sceneStack = []
    @hovers = {}
    @live = false
    gamejs.time.fpsCallback(@tick, this, 30)
    gamejs.time.fpsCallback(->
      @trigger('time')
    , this, 1)

  tick: (msDuration) ->
    if @live
      gamejs.event.get().forEach (event) =>
        switch event.type
          when gamejs.event.MOUSE_DOWN then @trigger('mousedown', event)
          when gamejs.event.MOUSE_MOTION then @mousemotion(event)
          when gamejs.event.MOUSE_UP then @trigger('mouseup', event)
          when gamejs.event.KEY_DOWN then @trigger('keydown', event)
          when gamejs.event.KEY_UP then @trigger('keyup', event)

      # Reverse order that we trigger these events so that callbacks
      # are executed in the order the scene was added to the director
      @triggerReverse('update', msDuration)
      @display.clear()
      @triggerReverse('draw', @display)
    else
      gamejs.event.get()  # discard unused events

  mousemotion: (event) ->
    @trigger('mousemove', event.pos)
    for name, group of @hovers
      sprites = group.collidePoint(event.pos)
      if sprites.length > 0
        @trigger('hover:' + name, sprites)

  addHover: (name, group) ->
    @hovers[name] = group

  removeHover: (name) ->
    @hovers[name] = undefined

  start: (scene) ->
    @live = true
    @replaceScene(scene)

  addScene: (scene) ->
    if @activeScene
      @sceneStack.push(@activeScene)

    @activeScene = scene
    @activeScene.start()

  discardScene: ->
    if @activeScene
      @activeScene.stop()

    @activeScene = @sceneStack.pop()

  replaceScene: (scene) ->
    # remove all existing event bindings
    if @activeScene
      @activeScene.stop()
      @unbind()

    @activeScene = scene
    @activeScene.start()

  getScene: ->
    @activeScene

  getViewport: ->
    @viewport.clone()

  # Return a new rect that has its coordinates converted from the position
  # relative to the canvas to an absolute position within the HTML5 document.
  canvasRectToDocumentRect: (rect) ->
    canvas = $ '#gjs-canvas'
    canvasPadding = 2  # fudge factor for our canvas border/padding/margin
    rect.move canvas.offset().left + canvasPadding, canvas.offset().top + canvasPadding

  # Create an HTML element at the canvas-relative rectangle, positioned
  # absolutly and sized to match the rect, above the canvas.
  createHTMLElement: (rect) ->
    el$ = $ document.createElement('div')
    rect = @canvasRectToDocumentRect(rect)

    # set positioning, position, size, z-index
    el$.css(
      position: 'absolute'
      top: rect.top
      left: rect.left
      width: rect.width
      height: rect.height
      zIndex: 1000
      backgroundColor: '#ffffff'
    )
    # insert element into DOM
    $('body').append(el$[0])
    el$

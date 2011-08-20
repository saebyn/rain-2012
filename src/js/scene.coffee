
gamejs = require 'gamejs'
pathfinding = require 'pathfinding'

exports.Scene = class Scene
  # viewportRect is in screen coordinates.
  constructor: (@viewportRect, @worldWidth, @worldHeight) ->
    @solids = new gamejs.sprite.Group()
    @characters = new gamejs.sprite.Group()

  setPlayer: (@player) ->
    @characters.add(@player)

  getPathfindingMap: (character) ->
    # character capabilities and location of solids needs to be passed in
    new pathfinding.Map(character, this)

  center: (worldPosition) ->
    @viewportRect.center = worldPosition
    if @viewportRect.bottom > @worldHeight
      @viewportRect.bottom = @worldHeight

    if @viewportRect.left < 0
      @viewportRect.left = 0
      
    if @viewportRect.right > @worldWidth
      @viewportRect.right = @worldWidth

  toWorldRect: (rect) ->
    # convert screen coordinates to world coordinates
    rect.move(@viewportRect)

  toScreenRect: (rect) ->
    # convert world coordinates to screen coordinates
    rect.move(-@viewportRect.left, -@viewportRect.top)

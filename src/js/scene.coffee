
gamejs = require 'gamejs'

exports.Scene = class Scene
  # viewportRect is in screen coordinates.
  constructor: (@screenWidth, @screenHeight, @viewportRect,\
                @worldWidth, @worldHeight) ->
    @solids = new gamejs.sprite.Group()
    @centerRect = new gamejs.Rect(0, 0, @screenWidth / 2, @screenHeight /2)

  ###
  # 
  # World coordinates:
  #
  # /\
  #  y  x>
  #
  # Screen coordinates:
  #
  # y  x>
  # \/
  #
  ###

  center: (worldPosition) ->
    @viewportRect.center = [worldPosition[0], @screenHeight - worldPosition[1]]
    if @viewportRect.bottom > @worldHeight
      @viewportRect.bottom = @worldHeight

    if @viewportRect.left < 0
      @viewportRect.left = 0
      
    if @viewportRect.right > @worldWidth
      @viewportRect.right = @worldWidth

  toWorldCoord: (rect) ->
    rectCopy = rect.clone()
    # convert screen coordinates to world coordinates
    rectCopy.moveIp(@viewportRect)
    rectCopy.top = @screenHeight - rectCopy.top
    [rectCopy.left, rectCopy.top]

  toScreenRect: (worldCoord, size) ->
    # convert world coordinates to a screen rectangle
    rect = new gamejs.Rect(worldCoord[0], @screenHeight - worldCoord[1], size[0], size[1])
    rect.move(-@viewportRect.left, -@viewportRect.top)


gamejs = require 'gamejs'

exports.Scene = class Scene
  # viewportRect is in screen coordinates.
  constructor: (@screenWidth, @screenHeight, @viewportRect) ->
    @solids = new gamejs.sprite.Group()

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

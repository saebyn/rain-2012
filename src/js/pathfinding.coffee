gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

exports.Map = class Map
  constructor: (char, @scene) ->

  canJump: (origin) ->
    # Can the character jump at its present location, i.e. is the character
    # standing on something?
    # Create a rectangle 1 unit high below the character
    rect = @rect.clone
    rect.topleft = origin
    rect.top = rect.bottom
    rect.height = 1
    # Is there anything underneath the character?
    (sprite for sprite in @scene.solids when sprite.worldRect.collideRect(rect)).length == 0

  availableVectors: (origin) ->
    # returns list of vectors, deals with whether the char can jump right now
    vectors = []
    xIncrement = (@maxSpeed - @minSpeed) / 10
    for xStep in [-10..10]
      x = if xStep == 0 then 0 else @minSpeed + (xStep * xIncrement)

      if @canJump(origin)
        yIncrement = @maxJumpSpeed / 10
        for yStep in [0..10]
          y = yStep * yIncrement
          vectors.push([x, y])
      else
        vectors.push([x, 0])

    vectors

  adjacent: (origin) ->

  estimatedDistance: (pointA, pointB) ->
    $v.distance(pointA, pointB)

  actualDistance: (pointA, pointB) ->
    # meh
    @estimatedDistance(pointA, pointB)

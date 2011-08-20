gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

exports.Map = class Map
  constructor: (char, @scene) ->
    # use screen coordinates, so that later collision detection will work right
    @rect = char.rect.clone()

    # collect stats
    @minSpeed = char.speed
    @maxSpeed = char.maxSpeed
    @maxJumpSpeed = char.jumpSpeed

  # TODO consider how much of this we can move to the Character class?

  canJump: (origin) ->
    # Can the character jump at its present location, i.e. is the character
    # standing on something?

  availableVectors: (origin) ->
    # TODO returns list of vectors, deals with whether the char can jump right now

  adjacent: (origin) ->
    # TODO iterates over available vectors, makes temporary rects
    # does collision detection (can move that direction, is there nothing below us so we fall)
    # applies gravity to each rect

    # returns top-lefts of non-colliding rects, in world coordinates

  estimatedDistance: (pointA, pointB) ->
    $v.distance(pointA, pointB)

  actualDistance: (pointA, pointB) ->
    # meh
    @estimatedDistance(pointA, pointB)

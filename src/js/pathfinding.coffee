gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

exports.Map = class Map
  constructor: (@char, @scene) ->

  availableVectors: (origin) ->
    # returns list of vectors, deals with whether the char can jump right now

  adjacent: (origin) ->

  estimatedDistance: (pointA, pointB) ->
    $v.distance(pointA, pointB)

  actualDistance: (pointA, pointB) ->
    # meh
    @estimatedDistance(pointA, pointB)

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

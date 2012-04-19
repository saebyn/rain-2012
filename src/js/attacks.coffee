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
Sprite = require('sprite').Sprite


# make a sprite (possibly animated) that hurts (possibly not the creating entity) and might move, or be drawn (arc)

exports.buildAttack = (name, rect, facing) ->
  if facing == 'right'
    vector = [1, 0]
  else if facing == 'left'
    vector = [-1, 0]
  else
    vector = [0, 0]  # TODO something?

  new MeleeAttack(rect, vector)


class MeleeAttack extends Sprite
  # here rect should be in world coordinates
  constructor: (rect, @vector) ->
    super()
    @rect = rect

  setScene: (@scene) ->

  update: (ms) ->
    super(ms)

  draw: (surface) ->
    # convert our world coordinate rect into screen coordinates
    rect = @scene.toScreenRect(@rect)

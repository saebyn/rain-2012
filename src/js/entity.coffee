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
$o = require 'gamejs/utils/objects'

Sprite = require('sprite').Sprite


exports.Entity = class Entity extends Sprite
  trigger: (event, args...) ->
    console.log 'Entity got event', event, 'with args', args


exports.Item = class Item extends Entity
  activate: ->
    # TODO create an InventoryItem from this Item
    # TODO add the inventory item to the players inventory


exports.BackgroundSprite = class BackgroundSprite extends Entity
  constructor: (scene, rect, @distance) ->
    super(scene, rect)

    rectGet = ->
      if @distance == 0
        return @scene.toScreenRect(@worldRect)

      playerRect = @scene.player.rect
      # get x distance from player to this rect
      dx = @worldRect.center[0] - playerRect.center[0]
      # calculate offset based on @distance
      # apply offset to rect
      offset = dx * (@distance / (12000.0))
      @scene.toScreenRect(@worldRect.move(-offset, 0))

    rectSet = (rect) ->
      @worldRect = @scene.toWorldRect(rect)
      return

    $o.accessor(this, 'rect', rectGet, rectSet)


exports.Portal = class Portal extends Entity
  constructor: (scene, rect, @destination) ->
    super(scene, rect)
    @image = new gamejs.Surface(rect)
    @image.fill("#ffaaaa")
    @image.setAlpha(0.1)

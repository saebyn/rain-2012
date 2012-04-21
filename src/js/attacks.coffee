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
sprite = require 'sprite'


# make a sprite (possibly animated) that hurts (possibly not the creating entity) and might move, or be drawn (arc)

exports.buildAttack = (scene, source, name, rect, facing) ->
  if facing == 'right'
    vector = [1, 0]
    attackSpriteName = 'meleeAttack1Right'
  else if facing == 'left'
    vector = [-1, 0]
    attackSpriteName = 'meleeAttack1Left'
  else
    return

  # move rect towards vector
  rect = rect.move($v.multiply(vector, rect.width / 2))

  attack = new MeleeAttack(scene, rect, source)
  sprite.loadSpriteSpec(attack, {sprite: 'base.' + attackSpriteName}, scene.spritesheets)
  scene.attacks.add(attack)


class MeleeAttack extends sprite.Sprite
  constructor: (scene, rect, @source) ->
    super(scene, rect)
    @startPositionX = @worldRect.left - @source.worldRect.left
    @startPositionY = @worldRect.top - @source.worldRect.top
    @lifetime = 200  # how long the attack lasts
    @hp = 5  # how many hit points to take

    # ignore these entities for collision purposes
    @hasHit = [@scene.getPlayer()]

  update: (ms) ->
    super(ms)
    @worldRect.left = @startPositionX + @source.worldRect.left
    @worldRect.top = @startPositionY + @source.worldRect.top

    # collide! with @scene.characters
    # hit! what we collide with
    hits = (hit for hit in gamejs.sprite.spriteCollide(@, @scene.characters, false) when hit not in @hasHit)
    @hasHit = @hasHit.concat(hits)
    hit.hit(@hp) for hit in hits

    @lifetime -= ms
    if @lifetime <= 0
      @kill()

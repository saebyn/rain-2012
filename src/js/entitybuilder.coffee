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

entities = require 'entity'
sprite = require 'sprite'


exports.EntityBuilder = class EntityBuilder
  constructor: (@scene, @group, @type, @spritesheets) ->

  newPlayer: (rect, spriteName) ->
    player = new entities.Player(@scene, rect)
    sprite.setupSprite(player, spriteName, @spritesheets)
    @group.add(player)
    @scene.player = player
    player

  newEntity: (parameters={}) ->
    rect = @scene.toScreenRect(new gamejs.Rect(parameters.x, parameters.y, parameters.width, parameters.height))
    behavior = parameters.behavior or []
    distance = parameters.distance or 0
    destination = parameters.destination or ''

    entity = switch @type
      when 'solids' then new entities.Entity(@scene, rect)
      when 'npcs' then new entities.NPCharacter(@scene, rect, parameters.dialog, behavior)
      when 'backgrounds' then new entities.BackgroundSprite(@scene, rect, distance)
      when 'portals' then new entities.Portal(@scene, rect, destination)

    if @type != 'portals'
      sprite.loadSpriteSpec(entity, parameters, @spritesheets)

    @group.add(entity)

    # a bit of a hack to ensure proper sprite order for backgrounds
    if @type == 'backgrounds'
      @group._sprites.sort (a,b) ->
        if a.distance > b.distance
          -1
        else if a.distance < b.distance
          1
        else
          0

    entity

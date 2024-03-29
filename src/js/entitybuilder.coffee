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
character = require 'character'
sprite = require 'sprite'


exports.vivifyPlayer = (serialization) ->
  {
    copyLevelInvariantData: (player) ->
      for key, value of serialization
        player[key] = value
  }


exports.EntityBuilder = class EntityBuilder
  constructor: (@world, @scene, @group, @type, @spritesheets) ->

  newPlayer: (rect, spriteName) ->
    player = new character.Player(@scene, rect)
    sprite.setupSprite(player, spriteName, @spritesheets)
    @world.loadPlayer(player)
    @group.add(player)
    @scene.player = player
    player

  newEntity: (id, parameters) ->
    rect = @scene.toScreenRect(new gamejs.Rect(parameters.x, parameters.y, parameters.width, parameters.height))
    behavior = parameters.behavior or []
    distance = parameters.distance or 0
    destination = parameters.destination or ''

    entity = switch @type
      when 'solids' then new entities.Entity(@scene, rect, id)
      when 'npcs' then new character.NPCharacter(@scene, rect, id, parameters.dialog, behavior)
      when 'backgrounds' then new entities.BackgroundSprite(@scene, rect, id, distance)
      when 'portals' then new entities.Portal(@scene, rect, id, destination)
      when 'items' then new entities.Item(@scene, rect, id, parameters)

    # if we have entities cached in the @world
    if @world.hasEntities()
      # discard entities that don't exist in world
      if not @world.hasEntity(@type, id)
        return

      # load values for this entity from world
      @world.loadEntity(@type, id, entity)

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

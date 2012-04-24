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


exports.World = class World
  constructor: ->
    @gameTime = 0
    @levels = {}

  # Target the cache at a new level
  selectLevel: (name) ->
    @name = name

  setLevelSize: (@size) ->

  # Have any entities been loaded into the cache?
  hasEntities: ->
    false

  # Has an entity with this type and id been added to the cache?
  hasEntity: (type, id) ->

  # Remove all cached entities.
  clearEntities: ->

  # Add a new entity to the cache
  addEntity: (type, entity) ->

  # Update the entity with values from the cache
  loadEntity: (id, entity) ->

  # Synchronize the player
  loadPlayer: (player) ->
    # TODO don't override position
    # TODO override parameters with values for this entity from level
    # TODO load player inventory
    @player = player

  # Save the cache of all levels to storage, indicating which level
  # is the current.
  save: (name) ->
    # TODO save a serialization of the player to the level

  # Load a saved cache and return the current level name.
  load: (name) ->

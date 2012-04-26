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

entitybuilder = require 'entitybuilder'


exports.World = class World
  constructor: ->
    @gameTime = 0
    @levels = {}

  # Target the cache at a new level
  selectLevel: (name) ->
    @name = name
    if not @levels[@name]?
      @levels[@name] = {}

  setLevelSize: (@size) ->

  # Have any entities been loaded into the cache?
  hasEntities: ->
    @levels[@name]?.entities?

  # Has an entity with this type and id been added to the cache?
  hasEntity: (type, id) ->
    if not @levels[@name]?.entities[type]?
      true
    else
      @levels[@name]?.entities[type]?[id]?

  # Remove all cached entities.
  clearEntities: ->
    @levels[@name]?.entities = undefined

  # Add a new entity to the cache
  addEntity: (type, entity) ->
    if not @levels[@name].entities?
      @levels[@name].entities = {}

    if not @levels[@name].entities[type]
      @levels[@name].entities[type] = {}

    @levels[@name].entities[type][entity.id] = entity

  # Update the entity with values from the cache
  # This should not be called if @hasEntities() returns false
  loadEntity: (type, id, entity) ->
    @levels[@name].entities[type]?[id]?.copyData?(entity)

  getPlayerPosition: ->
    @levels[@name]?.player?.position

  # Load the player with cached values
  loadPlayer: (player) ->
    # update the player's position to that within the current level
    position = @getPlayerPosition()
    if position?
      player.position = position
    
    if @player?
      @player.copyLevelInvariantData(player)

    @player = player

  # Update the cache with player values
  updatePlayer: (player) ->
    @levels[@name].player = {position: player.position}

  # Set up the storage if not already
  ensureStorageConfigured: (force) ->
    # TODO make sure rain.version matches current version, else throw exception

  serializeEntities: (entities) ->
    serializedEntities = {}
    for id, entity of entities
      serialization = {}
      entity.copyData(serialization)
      serializedEntities[id] = serialization

    serializedEntities

  deserializeEntities: (serializedEntities) ->
    entities = {}
    for id, entity of serializedEntities
      entities[id] = entitybuilder.vivifyEntity(entity)

    entities

  # Save the cache of all levels to storage, indicating which level
  # is the current.
  # This expects to been executed within a running game, so that a level
  # is already selected (selectLevel() has been called at least once).
  save: (name, force=false) ->
    @ensureStorageConfigured(force)
    # save serialization of player to world save
    serializedPlayer = {}
    @player.copyLevelInvariantData(serializedPlayer)

    # write out player
    localStorage['rain.savedGames.' + name + '.player'] = serializedPlayer

    save = {}
    for levelName, level of @levels
      levelSave = {}
      # save player position in level
      levelSave.player = level.player

      levelSave.entities = {}
      # save each entity in level
      levelSave.entities.npcs = @serializeEntities(level.entities.npcs)
      levelSave.entities.items = @serializeEntities(level.entities.items)

      save[levelName] = levelSave

    localStorage['rain.savedGames.' + name] = JSON.stringify(save)
    @updateSavedGames(name, @name)

  updateSavedGames: (name, lastLevel) ->
    if localStorage['rain.savedGames']?
      saves = JSON.parse(localStorage['rain.savedGames'])
    else
      saves = {}

    saves[name] = [Date.now(), lastLevel]

    localStorage['rain.savedGames'] = JSON.stringify(saves)

  getSavedGames: ->
    if localStorage['rain.savedGames']?
      saves = JSON.parse(localStorage['rain.savedGames'])
    else
      saves = {}

  # Load a saved cache and return the current level name.
  # Returns false if the save could not be found.
  load: (name) ->
    saves = @getSavedGames()
    if name not of saves
      return false

    [lastSaved, @name] = saves[name]
    @levels = {}

    savedGame = JSON.parse(localStorage['rain.savedGames.' + name])

    for levelName, level of savedGame
      @levels[levelName] = {entities: {}}
      @levels[levelName].entities.npcs = @deserializeEntities(level.entities.npcs)
      @levels[levelName].entities.items = @deserializeEntities(level.entities.items)

      # get the player data for level and copy it out
      @levels[levelName].player = level.player

    # load level invariant data into @player
    serializedPlayer = JSON.parse(localStorage['rain.savedGames.' + name + '.player'])
    @player = entitybuilder.vivifyPlayer(serializedPlayer)
    @name

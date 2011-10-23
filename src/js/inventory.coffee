event = require 'event'

# inventory item class [converts to entity.Item class, and vis versa]

# Inventory class used by Character to contain items.
exports.Inventory = class Inventory extends event.Event
  constructor: (@scene) ->
    @items = []
    @callbacks = {}
    @bind('drop', @drop)

  add: (item) ->
    @trigger('add', item)
    @items.push(item)

  remove: (item) ->
    @trigger('remove', item)
    @_remove(item)

  drop: (item) =>
    # TODO move item from inventory to scene
    @_remove(item)

  _remove: (item) ->
    # TODO remove item from @items


# inventory UI overlay (takes inventory as param, subscribes to its events)
exports.InventoryUI = class InventoryUI
  constructor: (@inventory) ->

  render: ->
    # TODO create root element, render templates, hook up events (both ways)

  destroy: ->
    #if @element?
      # TODO destroy element
      # TODO remove event hooks



# inventory item class [converts to entity.Item class, and vis versa]

# Inventory class used by Character to contain items.
# TODO extract the event methods if useful elsewhere into an `Event` class
exports.Inventory = class Inventory
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

  # `bind`, `unbind`, and `trigger` inspired by Backbone.js
  #
  # Bind an event, specified by a string name, ev, to a callback function.
  # Passing "all" will bind the callback to all events fired.
  bind: (ev, callback) ->
    # TODO

  # Remove one or many callbacks. If callback is null, removes all callbacks
  # for the event. If ev is null, removes all bound callbacks for all events.
  unbind: (ev=null, callback=null) ->
    # TODO

  # Trigger an event, firing all bound callbacks. Callbacks are passed the
  # same arguments as trigger is, apart from the event name. Listening for
  # "all" passes the true event name as the first argument.
  trigger: (ev, args...) ->
    # TODO


# inventory UI overlay (takes inventory as param, subscribes to its events)
exports.InventoryUI = class InventoryUI
  constructor: (@inventory) ->

  render: ->
    # TODO create root element, render templates, hook up events (both ways)

  destroy: ->
    if @element?
      # TODO destroy element
      # TODO remove event hooks

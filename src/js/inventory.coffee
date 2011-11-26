event = require 'event'
entity = require 'entity'


class Item
  constructor: (@name, @id, @type, @description, @entitySprite) ->


# Inventory items are held in inventory. They may be activatable, and send events
exports.InventoryItem = class InventoryItem
  constructor: (@item, @scene) ->

  toInventoryItem: ->
    new EntityItem(@item, @scene)


exports.EntityItem = class EntityItem extends entity.Entity
  constructor: (@item, @scene) ->

  toInventoryItem: ->
    new InventoryItem(@item, @scene)


# Inventory class used by Character to contain items.
exports.Inventory = class Inventory extends event.Event
  constructor: (@scene) ->
    @items = []
    @callbacks = {}
    @bind('drop', @drop)

  add: (entityItem) ->
    item = entityItem.toInventoryItem()
    @trigger('add', item)
    @items.push(item)

  remove: (item) ->
    @trigger('remove', item)
    @_remove(item)

  drop: (item) =>
    @_remove(item)
    @scene.items.add(item.toEntityItem())

  _remove: (item) ->
    # TODO remove item from @items


# inventory UI overlay (takes inventory as param, subscribes to its events)
exports.InventoryUI = class InventoryUI
  itemTemplate: _.template '<div class="<%= type => item-<%= id %>"><%= name %></div>'

  constructor: (@inventory) ->

  render: ->
    # TODO
    # if root element (@element) is not set
    #   create root element with id 'inventory'
    #   set @element
    #
    # for each item in @inventory, render itemTemplate into @element
    # add event to clicking item, showing detals
    # add events to buttons to drop/equip/use item
    # hook inventory add/remove events, update rendered output on callback

  destroy: ->
    if @element?
      # TODO destroy element
      # TODO remove event hooks

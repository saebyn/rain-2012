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
entity = require 'entity'


exports.Inventory = Inventory = Backbone.Collection.extend(
)


# Inventory items are held in inventory. They may be activatable
exports.InventoryItem = InventoryItem = Backbone.Model.extend(
)


InventoryItemView = Backbone.View.extend(
  tagName: 'li'
  className: 'item'
  template: _.template('An item')

  initialize: ->
    @model.bind 'change', @render, this

  render: ->
    @$el.html(this.template())
    @$el.attr({id: @model.cid})
    @
)


InventoryView = Backbone.View.extend(
  events:
    'click .close': 'close'

  template: _.template('<ul></ul><button class="close">Return to Game</button>')

  initialize: ->
    @collection.bind 'add', @addItem, this
    @collection.bind 'remove', @removeItem, this
    @collection.bind 'reset', @render, this

  close: ->
    @trigger('destroy')

  addItem: (model, collection, options) ->
    # add the model to the DOM as the options.index'th item
    @.$('li').eq(options.index).after(new InventoryItemView({model: model}).render().el)

  removeItem: (model) ->
    # remove the model
    @.$('#' + model.cid).remove()

  render: ->
    @$el.html(this.template());
    @collection.each((model) =>
      @$('ul').append(new InventoryItemView({model: model}).render().el)
    )
    @
)


exports.InventorySprite = class InventorySprite extends gamejs.sprite.Sprite
  constructor: (director, inventory, callback) ->
    super()
    @rect = director.getViewport().inflate(-50, -50)
    el$ = director.createHTMLElement(@rect)
    el$.attr({id: 'inventory'}).addClass('rounded-bottom').addClass('rounded-top')

    @view = new InventoryView({el: el$, collection: inventory})
    @view.render()

    @view.bind 'destroy', =>
      @kill()
      callback()

  draw: ->

  kill: ->
    @view.remove()
    super()

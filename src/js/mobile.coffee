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


exports.MobileDisplay = class MobileDisplay
  constructor: (@director) ->
    width = 200
    height = 266
    marginRight = 10
    marginBottom = 10
    @rect = new gamejs.Rect(@director.viewport.right-width-marginRight,
                            @director.viewport.bottom-height-marginBottom,
                            width, height)
    el$ = @director.createHTMLElement(@rect.inflate(-4, -4))
    el$.attr({id: 'game-mobile'})
    @model = new MobileModel();
    @view = new MobileView({el: el$, model: @model})

    @view.render()

  setTime: (time) ->
    @model.set({time: time})

  start: ->
    @director.bind 'mousedown', @click
    # TODO here is where we'll tie game events into a mobile backbone model
    # that model will be used in by the MobileView below to drive its
    # functionality

  stop: ->
    @director.unbind 'mousedown', @click

  click: (event) =>
    if event.button == 0 and @rect.collidePoint(event.pos)
      return false

  update: (ms) ->

  draw: (display) ->


MobileModel = Backbone.Model.extend({})


# TODO contact app, sms app, browser app
MobileView = Backbone.View.extend
  template: _.template($('#mobile-device-tmpl').html())

  initialize: ->
    @model.bind('change:time', @updateTime, @)

  events:
    'click h1': 'click'
    'click .bar': 'toggleNotifications'

  click: =>
    @.$('.summary').text('coming soon')

  toggleNotifications: =>
    @.$('.status-bar .notifications').toggleClass('collapsed')

  updateTime: (model, val) ->
    h = val.getHours()
    m = val.getMinutes()
    s = val.getSeconds()

    if m < 10
      m = '0' + m

    if s < 10
      s = '0' + s

    displayTime = h + ':' + m + ':' + s
    @.$('.status-bar .time').text(displayTime)

  render: ->
    @$el.html(@template())

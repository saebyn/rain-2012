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

loader = require 'scenes/loader'


exports.StartScene = Backbone.View.extend(
  template: _.template('<button class="start">Start New Game</button>
                        <ul class="saved-games">
                         <% _.each(saves, function (s) { %>
                         <li>
                          <span class="name"><%= s.name %></span>
                          <span class="date"><%= s.date %></span>
                          <button class="load" id="game-<%= s.id %>">Load Save</button>
                         </li>
                         <% }); %>
                        </ul>')

  events:
    'click .start': 'startNewGame'
    'click .load': 'loadSavedGame'

  initialize: (@director) ->
    @rect = @director.getViewport()
    @rect.topleft = [0, 0]
    _.bindAll(this)
  
  start: ->
    @setElement(@director.createHTMLElement(@rect)[0])
    @render()

  render: ->
    # make a start screen,
    # allow user to choose an available save
    # or start a new game
    # do the right thing
    @$el.html(@template({saves: @getSavedGames()}))

  stop: ->
    @remove()

  getSavedGames: ->
    [{name: 'Game1', date: Date.now(), id: '123'}]

  loadSavedGame: (event) ->
    id = $(event.currentTarget).attr('id').slice(5);
    console.log 'load', id

  startNewGame: ->
    @director.replaceScene(new loader.Loader(@director, 'level1.json'))
)

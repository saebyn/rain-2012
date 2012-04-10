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
    @el$ = @director.createHTMLElement(@rect.inflate(-4, -4))
    @el$.attr({id: 'mobile'})
    # TODO render mobile device via HTML

  start: ->
    @director.bind 'mousedown', @click

  stop: ->
    @director.unbind 'mousedown', @click

  click: (event) =>
    if event.button == 0 and @rect.collidePoint(event.pos)
      return false

  update: (ms) ->

  draw: (display) ->
    gamejs.draw.rect(display, '#ffff00', @rect);

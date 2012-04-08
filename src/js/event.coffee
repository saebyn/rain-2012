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

exports.Event = class Event
  # `bind`, `unbind`, and `trigger` inspired by Backbone.js
  #
  # Bind an event, specified by a string name, ev, to a callback function.
  # Passing "all" will bind the callback to all events fired.
  bind: (ev, callback) ->
    @callbacks ?= {}
    if ev not of @callbacks
      @callbacks[ev] = []

    @callbacks[ev].push(callback)

  # Remove one or many callbacks. If callback is null, removes all callbacks
  # for the event. If ev is null, removes all bound callbacks for all events.
  unbind: (ev=null, callback=null) ->
    @callbacks ?= {}
    if ev is null
      @callbacks = {}
    else if callback is null
      @callbacks[ev] = []
    else
      delete @callbacks[ev][@callbacks[ev].indexOf(callback)]

  # Trigger an event, firing all bound callbacks. Callbacks are passed the
  # same arguments as trigger is, apart from the event name. Listening for
  # "all" passes the true event name as the first argument. Callbacks will be
  # called in the following order:
  #   Callbacks bound to "all", from most-recently bound to least
  #   Callbacks bound to the triggered event, from most-recently bound to least
  #   
  # If any callback returns false, no other callbacks will be executed in
  # response to the triggered event and trigger will return false.
  trigger: (ev, args...) ->
    if ev != 'all'
      if @trigger('all', [ev, args...]) is false
        return false

    @callbacks ?= {}

    if ev of @callbacks
      for callback in @callbacks[ev].reverse()
        if callback(args...) is false
          return false

    return true

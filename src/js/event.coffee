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

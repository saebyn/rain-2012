exports.Event = class Event
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


exports.FSM = class FSM
  constructor: (description, @callback) ->
    @state = description[0]
    @table = description[1]
    @transitions = description[2]
    @tokens = []

  getTransitionIn: (state) ->
    if @transitions[state]?.inTransition?
      @transitions[state].inTransition
    else
      false

  getTransitionOut: (state) ->
    if @transitions[state]?.outTransition?
      @transitions[state].outTransition
    else
      false

  nextState: (token) ->
    if @table[@state]? and token of @table[@state]
      next = @table[@state][token]
      [next, @getTransitionOut(@state), @getTransitionIn(next)]
    else
      [false, null, null]

  switchState: (token) ->
    [nextState, outT, inT] = @nextState(token)
    if nextState
      if outT
        @callback(outT)

      @state = nextState
      if inT
        @callback(inT)

  input: (token) ->
    @tokens.push(token)

  update: ->
    if @tokens.length > 0
      token = @tokens[0]
      @tokens = @tokens[1..]
      @switchState(token)

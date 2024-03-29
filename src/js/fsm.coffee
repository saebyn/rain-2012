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


exports.FSM = class FSM
  constructor: (description, @callback) ->
    @state = description[0]
    @table = description[1]
    @transitions = description[2]
    @tokens = []

  copy: (callback) ->
    fsmCopy = new FSM([@state, @table, @transitions], callback)
    fsmCopy.tokens = @tokens
    fsmCopy

  load: (serialization) ->
    @state = serialization.state
    @table = serialization.table
    @transitions = serialization.transitions
    @tokens = serialization.tokens

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

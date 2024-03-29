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

$v = require 'gamejs/utils/vectors'

inventory = require 'inventory'
fsm = require 'fsm'
menu = require 'menu'
attacks = require 'attacks'

Entity = require('entity').Entity

npcDialog = require 'dialog/test'


threshold = (value, level, min = 0.0) ->
  if Math.abs(value) < level then min else value


class Character extends Entity
  constructor: (scene, rect, id, @life=100) ->
    super(scene, rect, id)
    @direction = [0.0, 0.0]  # our current movement vector

    @landed = false
    @collided = false
    @looking = ''
    @lastFacing = 'right'

    @baseSpeed = 0.1
    @speedIncrement = 0.2
    @maxSpeed = 1.2

    @jumpSpeed = -1.2
    @gravitySpeed = 0.4
    @maxGravitySpeed = 1.0

  copyData: (newObject) ->
    super(newObject)
    newObject.landed = @landed
    newObject.direction = @direction
    newObject.collided = @collided
    newObject.looking = @looking
    newObject.lastFacing = @lastFacing
    newObject.life = @life

  copyData: (serializedObject) ->
    super(serializedObject)
    @landed = serializedObject.landed
    @direction = serializedObject.direction
    @collided = serializedObject.collided
    @looking = serializedObject.looking
    @lastFacing = serializedObject.lastFacing
    @life = serializedObject.life

  # attack the direction we're facing
  attack: ->
    if @looking == ''
      @looking = @lastFacing

    @isAttackingTimer = 300
    attack = attacks.buildAttack(@scene, @, 'melee', @rect, @looking)

  hit: (hp) ->
    @life -= hp
    if @life <= 0
      @kill()

  handleCollisions: (movement) ->
    # if applying movement to the rect results in no collisions, return movement
    rect = @worldRect.move(movement)
    @collided = false
    collisions = (sprite for sprite in @scene.solids.sprites() when sprite.worldRect.collideRect(rect))
    # if there are any collisions, handle them
    for sprite in collisions
      if rect.collideRect(sprite.worldRect)  # because we may no longer collide
        # If we are trying to move and we're overlapping on that side, and it's
        # not further than we were trying to go...

        if movement[0] < 0 and rect.left <= sprite.worldRect.right and (rect.left - sprite.worldRect.right) > movement[0]
          rect.left = sprite.worldRect.right + 1
          @collided = true
          @clearXMomentum()
        else if movement[0] > 0 and rect.right >= sprite.worldRect.left and (rect.right - sprite.worldRect.left) < movement[0]
          rect.right = sprite.worldRect.left - 1
          @collided = true
          @clearXMomentum()

      if rect.collideRect(sprite.worldRect)  # because we may no longer collide
        if movement[1] < 0 and rect.top <= sprite.worldRect.bottom
          # if we are trying to move up and we're overlapping on our top side
          rect.top = sprite.worldRect.bottom + 1
          @clearYMomentum()
        else if movement[1] > 0 and rect.bottom >= sprite.worldRect.top
          # if we are trying to fall and we're overlapping on our bottom side,
          rect.bottom = sprite.worldRect.top - 1
          @landed = true
          @clearYMomentum()

    # convert our changes to our temporary rect into a new movement vector
    $v.subtract(rect.topleft, @worldRect.topleft)

  clearXMomentum: ->
    @direction[0] = 0.0

  clearYMomentum: ->
    @direction[1] = 0.0

  update: (msDuration) ->
    @frameKeys = []

    if @isAttackingTimer > 0
      @frameKeys.push('hitting')
      @isAttackingTimer -= msDuration
    else if @direction[1] < 0
      @frameKeys.push('jumping')
    else if Math.abs(@direction[0]) > @baseSpeed + @maxSpeed / 2.0
      @frameKeys.push('running')
    else if Math.abs(@direction[0]) > 0
      @frameKeys.push('walking')

    if @looking == 'right'
      @frameKeys.push('right')
    else if @looking == 'left'
      @frameKeys.push('left')

    super(msDuration)
    movement = $v.multiply(@direction, msDuration)
    movement = @handleCollisions(movement)
    @worldRect.moveIp(movement)

    # decrease direction vector based on movement
    @direction[0] = threshold(@direction[0] / 2.0, @baseSpeed)
    @direction[1] = threshold(@direction[1] / 2.0, @baseSpeed)

    # clean up the coordinates
    @worldRect.top = (0.5 + @worldRect.top) | 0
    @worldRect.left = (0.5 + @worldRect.left) | 0

    # apply gravity
    @addMotion(0.0, @gravitySpeed)

  addMotion: (x, y) ->
    x += @direction[0]

    if x > -@baseSpeed and x < 0
      x = -@baseSpeed
    else if x < @baseSpeed and x > 0
      x = @baseSpeed
    else if x < -@maxSpeed
      x = -@maxSpeed
    else if x > @maxSpeed
      x = @maxSpeed

    if x < 0
      @looking = 'left'
    else if x > 0
      @looking = 'right'
    else
      if @looking != ''
        @lastFacing = @looking

      @looking = ''

    y += @direction[1]

    @direction = [x, Math.min(@maxGravitySpeed, y)]


exports.NPCharacter = class NPCharacter extends Character
  constructor: (scene, rect, id, dialogName, behavior) ->
    super(scene, rect, id)
    @behavior = new fsm.FSM(behavior, @behaviorDispatch)
    @behavior.input('start')
    if dialogName
      # `dialog` is the dialog object selected for this NPC
      # this should not be changed after being set
      @dialog = new npcDialog.dialogs[dialogName](
        player: @scene.getPlayer(),
        self: @
      )
      # `dialogResponse` is the current response given to the player
      # it should be null when the NPC isn't talking to the player
      @dialogResponse = null

  copyData: (newObject) ->
    super(newObject)
    newObject.behavior = @behavior.copy(newObject.behaviorDispatch)

  # Copy the data of the serialized object into this entity
  loadData: (serializedObject) ->
    super(serializedObject)
    @behavior.load(serializedObject.behavior)

  updateDialog: ->
    # extract dialog options
    options = ([option] for option in @dialogResponse.getOptions())
    # add dialog exit option
    options.push(['Bye', 'exitdialog'])
    if not @dialogMenu?
      @dialogMenu = new menu.DialogMenu(@, @scene.getDirector().getViewport())

    @dialogMenu.build(@dialogResponse.text, options)
    @dialogMenu

  startDialog: ->
    if not @dialog?
      return

    @dialogResponse = @dialog.getResponse()
    if @dialogResponse
      @behavior.input('dialog')
      @updateDialog()

  stopDialog: ->
    @behavior.input('exitdialog')
    @dialogMenu.kill()
    @dialogMenu = null
    @dialogResponse = null
    @scene.paused = false

  chooseDialogOption: (option) ->
    optionObj = @dialogResponse.choose(option)
    @dialogResponse = optionObj.getResponse()
    if @dialogResponse
      @updateDialog()
    else
      @stopDialog()

  trigger: (event, args...) ->
    if event == 'exitdialog'
      @stopDialog()
    else if event == 'dialog'
      @chooseDialogOption(args[0])
    else
      super(event, args...)

  update: (msDuration) ->
    super(msDuration)
    @behavior.update()

  behaviorDispatch: (params) =>
    this[params[0]](params[1..]...)

  pace: (distance) ->
    # setup for when starting
    if not @paceDirection?
      @paceDirection = -1
      @paceCenter = @position[0]
      # @lastPace != @position[0] when no collision occured
      @lastPace = @paceCenter - @paceDirection

    walkedFarEnough = Math.abs(@position[0] - @paceCenter) > distance

    # if we stopped (because of collision) or if we have walked far enough
    if @collided or walkedFarEnough
      if walkedFarEnough
        # make sure that we don't go outside of area and get trapped out
        @worldRect.left = @paceCenter + (distance * @paceDirection)

      # clear existing pacing motions
      @clearXMomentum()
      @paceDirection *= -1  # switch direction

    @addMotion(@paceDirection * @baseSpeed, 0.0)
    @lastPace = @position[0]
    @behavior.input('continue')
 
  follow: (target, closeEnough=80) ->
    @behavior.input('continue')

    if not @followTarget?
      if target == 'player'
        @followTarget = @scene.player

    if @direction[0] == 0.0
      if @followTarget.position[0] < @position[0] - closeEnough
        direction = [-1, 0]
      else if @followTarget.position[0] > @position[0] + closeEnough
        direction = [1, 0]
      else
        return
      
      # TODO follow up stairs and such

      @addMotion(direction[0] * @baseSpeed, direction[1] * @jumpSpeed)


exports.Player = class Player extends Character
  constructor: (scene, rect) ->
    super(scene, rect, '#player')
    @inventory = new inventory.Inventory()
    @player = true
    @sprinting = false

  update: (msDuration) ->
    super(msDuration)

    @scene.center(@position)

  # Copy any data that should be carried over between levels into the
  # new level's player object.
  copyLevelInvariantData: (newPlayerObject) ->
    newPlayerObject.life = @life
    newPlayerObject.inventory = @inventory

  getInventory: ->
    if not @inventory.models?
      @inventory = new inventory.Inventory(@inventory)

    return @inventory

  addItemToInventory: (id, parameters) ->
    parameters.id = id
    @inventory.add(parameters)

  getSpeedIncrement: ->
    if @sprinting
      @speedIncrement * 1.8
    else
      @speedIncrement

  left: ->
    @addMotion(-@getSpeedIncrement(), 0.0)
    @

  right: ->
    @addMotion(@getSpeedIncrement(), 0.0)
    @

  jump: ->
    if @landed
      @landed = false
      @addMotion(0.0, @jumpSpeed)
    @

  startSprint: ->
    @sprinting = true

  stopSprint: ->
    @sprinting = false

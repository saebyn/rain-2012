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
$v = require 'gamejs/utils/vectors'
$o = require 'gamejs/utils/objects'
fsm = require 'fsm'
menu = require 'menu'


threshold = (value, level, min = 0.0) ->
  if Math.abs(value) < level then min else value


exports.EntityBuilder = class EntityBuilder
  constructor: (@scene, @group, @type, @spritesheets) ->

  newEntity: (parameters={}) ->
    rect = @scene.toScreenRect(new gamejs.Rect(parameters.x, parameters.y, parameters.width, parameters.height))
    behavior = parameters.behavior or []
    distance = parameters.distance or 0
    destination = parameters.destination or ''

    entity = switch @type
      when 'npcs' then new NPCharacter(@scene, rect, behavior)
      when 'solids' then new Entity(@scene, rect)
      when 'backgrounds' then new BackgroundSprite(@scene, rect, distance)
      when 'portals' then new Portal(@scene, rect, destination)

    if @type != 'portals'
      @loadSpriteSpec(entity, parameters)

    @group.add(entity)

    # a bit of a hack to ensure proper sprite order for backgrounds
    if @type == 'backgrounds'
      @group._sprites.sort (a,b) ->
        if a.distance > b.distance
          -1
        else if a.distance < b.distance
          1
        else
          0

    entity

  drawRepeat: (source, dest, repeatX, repeatY) ->
    sourceSize = source.getSize()
    for x in [0...repeatX]
      for y in [0...repeatY]
        dest.blit(source, [x * sourceSize[0], y * sourceSize[1]])

  applyImageSpec: (sprite, rawImage, spec) ->
      if spec.repeat? and spec.repeat != 'none'
        sprite.image = new gamejs.Surface(sprite.rect)
        imageSize = rawImage.getSize()
        switch spec.repeat
          when 'x' then @drawRepeat(rawImage, sprite.image, sprite.rect.width / imageSize[0], 1)
          when 'y' then @drawRepeat(rawImage, sprite.image, 1, sprite.rect.height / imageSize[1])
          when 'xy' then @drawRepeat(rawImage, sprite.image, sprite.rect.width / imageSize[0], sprite.rect.height / imageSize[1])
      else
        sprite.image = rawImage

  loadSpriteFromSheet: (name, rect) ->
    [spritesheetName, spriteName] = name.split('.')
    image = new gamejs.Surface(rect)

    # load the spritesheet image
    sheetImage = gamejs.image.load(@spritesheets[spritesheetName].image)

    spriteDef = @spritesheets[spritesheetName].sprites[spriteName]
    # PROBLEM: FIXME the source area of the spritesheet isn't dealt with correctly by gamejs
    srcArea = new gamejs.Rect([spriteDef.x, spriteDef.y],
                              [spriteDef.width, spriteDef.height])

    # extract the specific sprite from the sheet
    image.blit(sheetImage, [0, 0], srcArea)
    image

  loadSpriteSpec: (sprite, spec) ->
    if spec.image?
      rawImage = gamejs.image.load(spec.image)
      @applyImageSpec(sprite, rawImage, spec)
    else if spec.sprite?
      rawImage = @loadSpriteFromSheet(spec.sprite, sprite.rect)
      @applyImageSpec(sprite, rawImage, spec)
    else if spec.color?
      sprite.image = new gamejs.Surface(sprite.rect)
      sprite.image.fill(spec.color)


class Entity extends gamejs.sprite.Sprite
  constructor: (@scene, rect) ->
    super()
    @worldRect = @scene.toWorldRect(rect)
    @player = false

    rectGet = ->
      @scene.toScreenRect(@worldRect)

    rectSet = (rect) ->
      @worldRect = @scene.toWorldRect(rect)
      return

    positionGet = ->
      @worldRect.topleft

    positionSet = (point) ->
      @worldRect.topleft = point

    $o.accessor(this, 'rect', rectGet, rectSet)
    $o.accessor(this, 'position', positionGet, positionSet)

  getScene: ->
    @scene


class BackgroundSprite extends Entity
  constructor: (scene, rect, @distance) ->
    super(scene, rect)

    rectGet = ->
      if @distance == 0
        return @scene.toScreenRect(@worldRect)

      playerRect = @scene.player.rect
      # get x distance from player to this rect
      dx = @worldRect.center[0] - playerRect.center[0]
      # calculate offset based on @distance
      # apply offset to rect
      offset = dx * (@distance / (12000.0))
      @scene.toScreenRect(@worldRect.move(-offset, 0))

    rectSet = (rect) ->
      @worldRect = @scene.toWorldRect(rect)
      return

    $o.accessor(this, 'rect', rectGet, rectSet)


class Portal extends Entity
  constructor: (scene, rect, @destination) ->
    super(scene, rect)
    @image = new gamejs.Surface(rect)
    @image.fill("#ffaaaa")
    @image.setAlpha(0.1)


class Character extends Entity
  constructor: (scene, rect) ->
    super(scene, rect)
    @direction = [0.0, 0.0]  # our current movement vector

    @landed = false
    @collided = false

    @baseSpeed = 0.1
    @speedIncrement = 0.2
    @maxSpeed = 1.2

    @jumpSpeed = -1.2
    @gravitySpeed = 0.4
    @maxGravitySpeed = 1.0

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

    y += @direction[1]

    @direction = [x, Math.min(@maxGravitySpeed, y)]


class NPCharacter extends Character
  constructor: (scene, rect, behavior) ->
    super(scene, rect)
    @behavior = new fsm.FSM(behavior, @behaviorDispatch)
    @behavior.input('start')

  startDialog: ->
    @behavior.input('dialog')
    # construct and return dialog menu
    # TODO extract dialog options
    new menu.DialogMenu(@, @scene.getDirector().getViewport(), 'What do you want?', ['...'])

  trigger: (event, args...) ->

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
    super(scene, rect)
    @player = true

  update: (msDuration) ->
    super(msDuration)
    @scene.center(@position)

  left: ->
    @addMotion(-@speedIncrement, 0.0)
    @

  right: ->
    @addMotion(@speedIncrement, 0.0)
    @

  jump: ->
    if @landed
      @landed = false
      @addMotion(0.0, @jumpSpeed)
    @

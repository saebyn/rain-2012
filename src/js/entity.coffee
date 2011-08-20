gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'
$o = require 'gamejs/utils/objects'

exports.Entity = class Entity extends gamejs.sprite.Sprite
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


exports.Character = class Character extends Entity
  constructor: (scene, rect) ->
    super(scene, rect)
    @motions = []
    @landed = false
    @speed = 0.1
    @jumpSpeed = -0.8
    @maxSpeed = 0.5
    @gravitySpeed = 0.4

  handleCollision: (movement) ->
    oldPosition = @position.slice()
    @position = $v.add(@position, movement)
    # clean up the coordinates
    @position = [(0.5 + @position[0]) | 0, (0.5 + @position[1]) | 0]

    collides = gamejs.sprite.spriteCollide(this, @scene.solids)
    if collides.length > 0
      # fix X coord
      for x in [movement[0]..0]
        # make trial changes
        @position = oldPosition.slice()
        @worldRect.left += x

        if true not in (gamejs.sprite.collideRect(this, sprite) for sprite in collides)
          # that was enough
                
          # whatever we hit stopped us, whichever direction we were going.
          if Math.abs(oldPosition[0] - @position[0]) < Math.abs(movement[0])
            @clearXMomentum()

          break

        # if we fail to find a spot where we don't collide, just quit
        @position = oldPosition

      # save new X changes, but keep old Y value
      oldPosition = [@position[0], oldPosition[1]]

      # fix Y coord
      for y in [movement[1]..0]
        # make trial changes
        @position = oldPosition.slice()
        @worldRect.top += y - 0.1  # a little extra,
                                   # a hack to keep from catching the floor

        if true not in (gamejs.sprite.collideRect(this, sprite) for sprite in collides)
          # that was enough
                
          # whatever we hit stopped us, whichever direction we were going.
          if Math.abs(oldPosition[1] - @position[1]) < Math.abs(movement[1])
            @clearYMomentum()

          break

        # if we fail to find a spot where we don't collide, just quit
        @position = oldPosition

  applyMotions: (msDuration) ->
    # Remove old motions (do this first so that every motion will get applied
    # at least once).
    @motions = (motion for motion in @motions when motion.time > 0)

    # Update elapsed time of motions.
    motion.time -= msDuration for motion in @motions

    # Sum motions into a direction vector for this frame.
    @direction()

  moving: (type=null) ->
    if type?
      (motion for motion in @motions when motion.type == type).length > 0
    else
      @motions.length > 0

  direction: ->
    direction = [0.0, 0.0]
    for motion in @motions
      direction = $v.add(direction, [motion.x, motion.y])

    direction

  clearXMomentum: ->
    # filter all @motions where item[0] != 0.0
    @motions = (motion for motion in @motions when motion.x != 0.0)

  clearYMomentum: ->
    # filter all @motions where item[1] != 0.0
    @motions = (motion for motion in @motions when motion.y != 0.0)
    @landed = true

  update: (msDuration) ->
    direction = @applyMotions(msDuration)

    movement = $v.multiply(direction, msDuration)
    @handleCollision(movement)

    # apply gravity by adding gravity vector to @motions
    if (motion for motion in @motions when motion.type == 'gravity').length == 0
      @addMotion(0.0, @gravitySpeed, time = 1000000000, type = 'gravity')

  addMotion: (x, y, time = 200, type = 'default') ->
    @motions[@motions.length] = x: x, y: y, time: time, type: type


exports.NPCharacter = class NPCharacter extends Character
  constructor: (scene, rect, @behavior) ->
    super(scene, rect)

  startDialog: ->
    @behavior.type = 'dialog'

  pace: ->
    # setup for when starting
    if not @paceDirection?
      @paceDirection = -1.0
      @paceCenter = @position[0]
      # @lastPace != @position[0] when no collision occured
      @lastPace = @paceCenter - @paceDirection

    # if we stopped (because of collision) or if we have walked far enough
    if Math.abs(@lastPace - @position[0]) == 0 or Math.abs(@position[0] - @paceCenter) > @behavior.distance
      # clear existing pacing motions
      @motions = (motion for motion in @motions when motion.type != 'pacing')
      @paceDirection *= -1.0  # switch direction

    @addMotion(@paceDirection * @speed, 0.0, 1, type='pacing')
    @lastPace = @position[0]
 
  follow: ->
    closeEnough = 80.0

    if not @followTarget?
      if @behavior.target == 'player'
        @followTarget = @scene.player

    if not @moving('following')
      if @followTarget.position[0] < @position[0] - closeEnough
        direction = [-1, 0]
      else if @followTarget.position[0] > @position[0] + closeEnough
        direction = [1, 0]
      else
        return
      
      # TODO follow up stairs and such

      @addMotion(direction[0] * @speed, direction[1] * @jumpSpeed, 100, type='following')

  update: (msDuration) ->
    super(msDuration)
    switch @behavior.type
      when 'pacing' then @pace()
      when 'following' then @follow()


exports.Player = class Player extends Character
  constructor: (scene, rect) ->
    super(scene, rect)
    @player = true

  update: (msDuration) ->
    super(msDuration)
    @scene.center(@position)

  left: ->
    @addMotion(-@speed, 0.0)
    @

  right: ->
    @addMotion(@speed, 0.0)
    @

  jump: ->
    if @landed
      @landed = false
      @addMotion(0.0, @jumpSpeed, 100)
    @

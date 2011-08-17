gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

threshold = (value, level, min = 0.0) ->
  if Math.abs(value) < level then min else value

exports.Character = class Character extends gamejs.sprite.Sprite
  constructor: (@scene, rect) ->
    super()
    @rect = rect
    @motions = []
    @position = @scene.toWorldCoord @rect
    @speed = 0.1
    @maxSpeed = 0.5

  handleCollision: (movement) ->
    @position = $v.add(@position, movement)
    # update sprite position on screen (only place rect should be written to)
    @rect.center = @scene.toScreenRect(@position, [@rect.width, @rect.height])

    collides = gamejs.sprite.spriteCollide(this, @scene.solids)
    if collides.length > 0
      # try undoing X movement
      @rect.left -= movement[0]
      if true not in (gamejs.sprite.collideRect(this, sprite) for sprite in collides)
        # that was enough
        # fix position
        @position[0] -= movement[0]
        @clearXMomentum()
      else
        # undo X change, try Y next
        @rect.left += movement[0]
        @rect.top += movement[1]  # backwards because of difference between screen and world coords
        if true not in (gamejs.sprite.collideRect(this, sprite) for sprite in collides)
          # that was enough
          # fix position
          @position[1] -= movement[1]
          @clearYMomentum()
        else
          # do both coordinates (already done with Y)
          @rect.left -= movement[0]
          # fix position
          @position[0] -= movement[0]
          @position[1] -= movement[1]
          @clearXMomentum()
          @clearYMomentum()

  applyMotions: (msDuration) ->
    # remove old motions, effect slowdowns
    motion[2] -= msDuration for motion in @motions
    @motions = (motion for motion in @motions when motion[2] > 0)
    # sum motions
    @direction()

  direction: ->
    direction = [0.0, 0.0]
    for motion in @motions
      direction = $v.add(direction, motion)

    direction

  clearXMomentum: ->
    # filter all items from @motions where item[0] != 0.0
    @motions = (motion for motion in @motions when motion[0] != 0.0)

  clearYMomentum: ->
    # filter all items from @motions where item[1] != 0.0
    @motions = (motion for motion in @motions when motion[1] != 0.0)

  # TODO
  # move some of this to an entity class
  update: (msDuration) ->
    direction = @applyMotions(msDuration)

    movement = $v.multiply(direction, msDuration)
    @handleCollision(movement)

    # apply gravity by adding gravity vector to @motions
    #@addMotion(0.0, -0.01)

  addMotion: (x, y, time = 50) ->
    # TODO limit x and y motion
    @motions[@motions.length] = [x, y, time]

  left: ->
    currentSpeed = @direction()[0]
    @addMotion(Math.max(-@maxSpeed, currentSpeed - @speed), 0.0)
    @

  right: ->
    currentSpeed = @direction()[0]
    @addMotion(Math.min(@maxSpeed, currentSpeed + @speed), 0.0)
    @

  isJumping: ->
    true in (motion[1] != 0.0 for motion in @motions)

  jump: ->
    if not @isJumping
      @addMotion(0.0, @maxSpeed)
    @

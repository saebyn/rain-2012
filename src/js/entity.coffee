gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

exports.Character = class Character extends gamejs.sprite.Sprite
  constructor: (@scene, rect) ->
    super()
    @rect = rect
    @motions = []
    @position = @scene.toWorldCoord @rect
    @landed = false
    @speed = 0.1
    @jumpSpeed = 0.5
    @maxSpeed = 0.5
    @gravitySpeed = -0.2

  handleCollision: (movement) ->
    @position = $v.add(@position, movement)
    # update sprite position on screen (only place rect should be written to)
    @rect.center = @scene.toScreenRect(@position, [@rect.width, @rect.height])

    collides = gamejs.sprite.spriteCollide(this, @scene.solids)
    if collides.length > 0
      # TODO make trial attempts to fit the sprite towards the collision
      #  - hopefully that will remove gaps undernear characters after they jump.
      
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

    @rect.center = [(0.5 + @rect.center[0]) | 0, (0.5 + @rect.center[1]) | 0]

  applyMotions: (msDuration) ->
    # Remove old motions (do this first so that every motion will get applied
    # at least once).
    @motions = (motion for motion in @motions when motion.time > 0)

    # Update elapsed time of motions.
    motion.time -= msDuration for motion in @motions

    # Sum motions into a direction vector for this frame.
    @direction()

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
    if (motion for motion in @motions when motion.gravity).length == 0
      @addMotion(0.0, @gravitySpeed, time = 1000000000, gravity = true)

  addMotion: (x, y, time = 200, gravity = false) ->
    @motions[@motions.length] = x: x, y: y, time: time, gravity: gravity

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

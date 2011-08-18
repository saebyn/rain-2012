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
    # remove old motions, effect slowdowns
    @motions = (motion for motion in @motions when motion.time > 0)

    # TODO decrease length of motion vector near end
    motion.time -= msDuration for motion in @motions

    # sum motions
    @direction()

  direction: ->
    direction = [0.0, 0.0]
    for motion in @motions
      direction = $v.add(direction, [motion.x, motion.y])

    direction

  clearXMomentum: ->
    # filter all items from @motions where item[0] != 0.0
    @motions = (motion for motion in @motions when motion.x != 0.0)

  clearYMomentum: ->
    # filter all items from @motions where item[1] != 0.0
    @motions = (motion for motion in @motions when motion.y != 0.0)

  # TODO
  # move some of this to an entity class
  update: (msDuration) ->
    direction = @applyMotions(msDuration)

    movement = $v.multiply(direction, msDuration)
    @handleCollision(movement)

    # apply gravity by adding gravity vector to @motions
    @addMotion(0.0, -0.1, time = 100, gravity = true)

  addMotion: (x, y, time = 200, gravity = false) ->
    # TODO limit x and y motion?
    @motions[@motions.length] = x: x, y: y, time: time, gravity: gravity

  left: ->
    @addMotion(-@speed, 0.0)
    @

  right: ->
    @addMotion(@speed, 0.0)
    @

  isJumping: ->
    jumps = (motion for motion in @motions when motion.y != 0 and not motion.gravity)
    jumps.length > 0

  jump: ->
    if not @isJumping()
      @addMotion(0.0, @maxSpeed, 100)
    @

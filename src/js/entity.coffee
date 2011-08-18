gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'
$o = require 'gamejs/utils/objects'

exports.Entity = class Entity extends gamejs.sprite.Sprite
  constructor: (@scene, rect) ->
    super()
    @width = rect.width
    @height = rect.height
    @position = @scene.toWorldCoord rect

    rectGet = ->
      @scene.toScreenRect(@position, [@width, @height])

    rectSet = (rect) ->
      @position = @scene.toWorldCoord(rect)
      return

    $o.accessor(this, 'rect', rectGet, rectSet)

exports.Character = class Character extends Entity
  constructor: (scene, rect) ->
    super(scene, rect)
    @motions = []
    @landed = false
    @speed = 0.1
    @jumpSpeed = 0.8
    @maxSpeed = 0.5
    @gravitySpeed = -0.4

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
        @position[0] += x

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
        @position[1] += y + 0.1  # a little extra,
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

    @scene.center(@position)

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

gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

class Character extends gamejs.sprite.Sprite
  constructor: (@solid_entities) ->
    @direction = [0.0, 0.0]
    super()

  handleCollision: (oldCenter) ->
    # TODO changes:
    #  are we colliding with anything?
          #  do a search along the direction vector for the last non-colliding position
          #  examine each component of the vector to determine if any movement can be taken in one of those directions
          #  kill the momentum of the direction that can't be moved any further in
          #  done

    # the following sucks:
    while Math.abs(movement[1]) > 0.001
      if gamejs.sprite.spriteCollide(this, @solid_entities).length == 0
        break
      
      @direction[1] = 0.0  # stop momentum
      movement[1] -= movement[1] / Math.abs(movement[1])  # make movement closer to 0 by 1
      @rect.center = $v.add(oldCenter, movement)

    while Math.abs(movement[0]) > 0.001
      if gamejs.sprite.spriteCollide(this, @solid_entities).length == 0
        break
     
      @direction[0] = 0.0  # stop momentum
      movement[0] -= movement[0] / Math.abs(movement[0])  # make movement closer to 0 by 1
      @rect.center = $v.add(oldCenter, movement)

  # TODO
  # move some of this to an entity class
  update: (msDuration) ->
    movement = $v.multiply(@direction, msDuration)
    oldCenter = @rect.center
    @rect.center = $v.add(@rect.center, movement)
    @handleCollision(oldCenter)

    # slow down
    @direction[0] += -@direction[0] / msDuration

    # @direction[1] += -@direction[1] / msDuration
    # TODO apply gravity
    @direction[1] += 0.1

  left: ->
    @direction[0] = Math.max -0.5, @direction[0] - 0.1

  right: ->
    @direction[0] = Math.min 0.5, @direction[0] + 0.1

  jump: ->
    @direction[1] -= 0.5 if @direction[1] <= 0.1

exports.Character = Character

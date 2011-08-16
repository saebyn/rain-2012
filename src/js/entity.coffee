gamejs = require 'gamejs'
$v = require 'gamejs/utils/vectors'

class Character extends gamejs.sprite.Sprite
  constructor: (@solid_entities) ->
    @direction = [0.0, 0.0]
    super()

  # TODO
  # move some of this to an entity class
  update: (msDuration) ->
    movement = $v.multiply(@direction, msDuration)
    @rect.center = $v.add(@rect.center, movement)

    # TODO this sucks
    if gamejs.sprite.spriteCollide(this, @solid_entities).length
      @rect.top -= movement[1]
      direction[1] = 0.0
      if gamejs.sprite.spriteCollide(this, @solid_entities).length
        @rect.left -= movement[0]
        direction[0] = 0.0
    
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
    @direction[1] -= 0.2 if @direction[1] == 0.0

exports.Character = Character

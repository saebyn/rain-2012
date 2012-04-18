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
entities = require 'entity'

exports.EntityBuilder = class EntityBuilder
  constructor: (@scene, @group, @type, @spritesheets) ->

  newPlayer: (rect, spriteName) ->
    player = new entities.Player(@scene, rect)
    @setupSprite(player, spriteName)
    @group.add(player)
    @scene.player = player
    player

  newEntity: (parameters={}) ->
    rect = @scene.toScreenRect(new gamejs.Rect(parameters.x, parameters.y, parameters.width, parameters.height))
    behavior = parameters.behavior or []
    distance = parameters.distance or 0
    destination = parameters.destination or ''

    entity = switch @type
      when 'solids' then new entities.Entity(@scene, rect)
      when 'npcs' then new entities.NPCharacter(@scene, rect, parameters.dialog, behavior)
      when 'backgrounds' then new entities.BackgroundSprite(@scene, rect, distance)
      when 'portals' then new entities.Portal(@scene, rect, destination)

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

  applyImageSpec: (entity, rawImage, spec) ->
      if spec and spec.repeat? and spec.repeat != 'none'
        if not entity.image?
          entity.image = new gamejs.Surface(entity.rect)

        imageSize = rawImage.getSize()
        switch spec.repeat
          when 'x' then @drawRepeat(rawImage, entity.image, entity.rect.width / imageSize[0], 1)
          when 'y' then @drawRepeat(rawImage, entity.image, 1, entity.rect.height / imageSize[1])
          when 'xy' then @drawRepeat(rawImage, entity.image, entity.rect.width / imageSize[0], entity.rect.height / imageSize[1])
      else
        entity.image = rawImage

  loadSpriteFromSheet: (name, rect) ->
    [spritesheetName, spriteName] = name.split('.')

    # load the spritesheet image
    sheetImage = gamejs.image.load(@spritesheets[spritesheetName].image)

    spriteDef = @spritesheets[spritesheetName].sprites[spriteName]
    image = @getSpriteImage(rect, sheetImage, spriteDef)   
    [image, sheetImage, spriteDef]

  getSpriteImage: (rect, sheetImage, spriteDef, frame=0) ->
    image = new gamejs.Surface(rect)

    x = spriteDef.x
    y = spriteDef.y

    if frame != 0
      if spriteDef.direction == 'x'
        x += spriteDef.width * frame
      else if spriteDef.direction == 'y'
        y += spriteDef.height * frame

    srcArea = new gamejs.Rect([x, y],
                              [spriteDef.width, spriteDef.height])
    # destination area has to be specified with a Rect to ensure
    # that the correct width and height are used, otherwise it defaults
    # to the size of the source area (which doesn't work at all)
    destArea = new gamejs.Rect([0, 0], [spriteDef.width, spriteDef.height])

    # extract the specific sprite from the sheet
    image.blit(sheetImage, destArea, srcArea)
    image

  getFrames: (entity, spriteDef) ->
    if not isNaN(parseInt(spriteDef.frames))
      [0...spriteDef.frames]
    else
      frameKey = entity.frameKey or 'default'
      if frameKey of spriteDef.frames
        [spriteDef.frames[frameKey][0]..spriteDef.frames[frameKey][1]]
      else
        [0]

  # return the number of frames in the sprite animation
  getFrameCount: (entity, spriteDef) ->
    @getFrames(entity, spriteDef).length

  # return the start frame of the sprite animation
  getStartFrame: (entity, spriteDef) ->
    @getFrames(entity, spriteDef)[0]

  normalizeFrame: (entity, spriteDef) ->
    frameIndex = entity.frame - @getStartFrame(entity, spriteDef)
    normalizedFrameIndex = frameIndex % @getFrameCount(entity, spriteDef)
    entity.frame = normalizedFrameIndex + @getStartFrame(entity, spriteDef)

  loadAnimation: (spriteDef, entity, sheetImage, spec) ->
    # TODO consider moving some of this code (and the methods it uses) into the Entity
    if spriteDef.frames?
      entity.updateAnimation = (msDuration) =>
        if not entity.frame?
          entity.frame = @getStartFrame(entity, spriteDef)

        if not entity.frameTime?
          entity.frameTime = 0

        entity.frameTime += msDuration

        if entity.frameTime >= spriteDef.frameDelay
          entity.frame += (entity.frameTime / spriteDef.frameDelay) | 0
          entity.frameTime = 0

        @normalizeFrame(entity, spriteDef)

        updatedImage = @getSpriteImage(entity.rect, sheetImage, spriteDef, entity.frame)
        @applyImageSpec(entity, updatedImage, spec)

  setupSprite: (entity, spriteName, spec=false) ->
      [rawImage, sheetImage, spriteDef] = @loadSpriteFromSheet(spriteName, entity.rect)
      @applyImageSpec(entity, rawImage, spec)
      @loadAnimation(spriteDef, entity, sheetImage, spec)

  loadSpriteSpec: (entity, spec) ->
    if spec.image?
      rawImage = gamejs.image.load(spec.image)
      @applyImageSpec(entity, rawImage, spec)
    else if spec.sprite?
      @setupSprite(entity, spec.sprite, spec)
    else if spec.color?
      entity.image = new gamejs.Surface(entity.rect)
      entity.image.fill(spec.color)

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
$o = require 'gamejs/utils/objects'


# Blit the source onto dest repeatedly the specified number of times in
# each direction.
drawRepeat = (source, dest, repeatX, repeatY) ->
  sourceSize = source.getSize()
  for x in [0...repeatX]
    for y in [0...repeatY]
      dest.blit(source, [x * sourceSize[0], y * sourceSize[1]])


getSpriteImage = (rect, sheetImage, spriteDef, frame=0) ->
  image = new gamejs.Surface(rect)

  if spriteDef.direction == '-x'
    x = spriteDef.width * (spriteDef.frames - 1)
    y = spriteDef.y
  else if spriteDef.direction == '-y'
    x = spriteDef.x
    y = spriteDef.height * (spriteDef.frames - 1)
  else
    x = spriteDef.x
    y = spriteDef.y

  if frame != 0
    if spriteDef.direction == 'x'
      x += spriteDef.width * frame
    else if spriteDef.direction == 'y'
      y += spriteDef.height * frame
    else if spriteDef.direction == '-x'
      x -= spriteDef.width * frame
    else if spriteDef.direction == '-y'
      y -= spriteDef.height * frame

  srcArea = new gamejs.Rect([x, y],
                            [spriteDef.width, spriteDef.height])
  # destination area has to be specified with a Rect to ensure
  # that the correct width and height are used, otherwise it defaults
  # to the size of the source area (which doesn't work at all)
  destArea = new gamejs.Rect([0, 0], [spriteDef.width, spriteDef.height])

  # extract the specific sprite from the sheet
  image.blit(sheetImage, destArea, srcArea)
  image


loadAnimation = (spriteDef, entity, sheetImage, spec) ->
  if spriteDef.frames?
    entity.updateAnimation = (msDuration) =>
      entity.progressFrame(msDuration, spriteDef)
      updatedImage = getSpriteImage(entity.rect, sheetImage, spriteDef, entity.frame)
      applyImageSpec(entity, updatedImage, spec)


applyImageSpec = (entity, rawImage, spec) ->
  if spec and spec.repeat? and spec.repeat != 'none'
    if not entity.image?
      entity.image = new gamejs.Surface(entity.rect)

    imageSize = rawImage.getSize()
    switch spec.repeat
      when 'x' then drawRepeat(rawImage, entity.image, entity.rect.width / imageSize[0], 1)
      when 'y' then drawRepeat(rawImage, entity.image, 1, entity.rect.height / imageSize[1])
      when 'xy' then drawRepeat(rawImage, entity.image, entity.rect.width / imageSize[0], entity.rect.height / imageSize[1])
  else
    entity.image = rawImage


loadSpriteFromSheet = (name, rect, spritesheets) ->
  [spritesheetName, spriteName] = name.split('.')

  # load the spritesheet image
  sheetImage = gamejs.image.load(spritesheets[spritesheetName].image)

  spriteDef = spritesheets[spritesheetName].sprites[spriteName]
  image = getSpriteImage(rect, sheetImage, spriteDef)   
  [image, sheetImage, spriteDef]


exports.setupSprite = setupSprite = (entity, spriteName, spritesheets, spec=false) ->
    [rawImage, sheetImage, spriteDef] = loadSpriteFromSheet(spriteName, entity.rect, spritesheets)
    applyImageSpec(entity, rawImage, spec)
    loadAnimation(spriteDef, entity, sheetImage, spec)


exports.loadSpriteSpec = (entity, spec, spritesheets) ->
  if spec.image?
    rawImage = gamejs.image.load(spec.image)
    applyImageSpec(entity, rawImage, spec)
  else if spec.sprite?
    setupSprite(entity, spec.sprite, spritesheets, spec)
  else if spec.color?
    entity.image = new gamejs.Surface(entity.rect)
    entity.image.fill(spec.color)


exports.Sprite = class Sprite extends gamejs.sprite.Sprite
  constructor: (@scene, rect=false) ->
    super()
    if rect
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

  getFrames: (spriteDef) ->
    if not isNaN(parseInt(spriteDef.frames))
      [0...spriteDef.frames]
    else
      frameKey = @frameKey or 'default'
      if frameKey of spriteDef.frames
        [spriteDef.frames[frameKey][0]..spriteDef.frames[frameKey][1]]
      else
        [0]

  # return the number of frames in the sprite animation
  getFrameCount: (spriteDef) ->
    @getFrames(spriteDef).length

  # return the start frame of the sprite animation
  getStartFrame: (spriteDef) ->
    @getFrames(spriteDef)[0]

  normalizeFrame: (spriteDef) ->
    frameIndex = @frame - @getStartFrame(spriteDef)
    normalizedFrameIndex = frameIndex % @getFrameCount(spriteDef)
    @frame = normalizedFrameIndex + @getStartFrame(spriteDef)

  progressFrame: (msDuration, spriteDef) ->
    if not @frame?
      @frame = @getStartFrame(spriteDef)

    if not @frameTime?
      @frameTime = 0

    @frameTime += msDuration

    if @frameTime >= spriteDef.frameDelay
      @frame += (@frameTime / spriteDef.frameDelay) | 0
      @frameTime = 0

    @normalizeFrame(spriteDef)

  update: (msDuration) ->
    if @updateAnimation?
      @updateAnimation(msDuration)

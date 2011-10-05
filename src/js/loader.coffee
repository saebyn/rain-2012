
gamejs = require 'gamejs'
scene = require 'scene'

# A loading screen...
# Preload the level sprites, etc, create a game scene, and switch the
# director to it.

exports.Loader = class Loader
  constructor: (@director, @levelFilename) ->
    @spritesheets = {}
    @level = gamejs.http.load(@levelFilename)
    @getLoadProgress = @load(@extractResources())
    @loaded = false

  start: ->
    @director.bind 'update', (msDuration) =>
      @update(msDuration)

    @director.bind 'draw', (display) =>
      @draw(display)

  # extract the relative urls to the resources in @level
  extractResources: ->
    resources = []

    # find spritesheets, load their images, build mapping of spritesheet names
    for name, sheetfn of @level.spritesheets
        sheet = gamejs.http.load(sheetfn)
        @spritesheets[name] = sheet
        resources.push(sheet.image)

    for name, sprite of @level.solids
      if sprite.image?
        resources.push(sprite.image)

    for name, sprite of @level.backgrounds
      if sprite.image?
        resources.push(sprite.image)

    for name, sprite of @level.npcs
      if sprite.image?
        resources.push(sprite.image)

    resources

  resourcesLoaded: =>
    @loaded = true

  load: (resources) ->
    gamejs.preload(resources)
    gamejs.ready(@resourcesLoaded)

  progress: ->
    (@getLoadProgress() * 100) + '%'

  update: (msDuration) ->
     if @loaded
       newScene = new scene.Scene(@director, @)
       @director.replaceScene(newScene)

  draw: (display) ->
    # draw progress
    # create a font
    font = new gamejs.font.Font('24px monospace')
    # render text - this returns a surface with the text written on it.
    textSurface = font.render("loading... " + @progress())

    display.clear()

    x = display.getSize()[0] / 2 - 100
    y = 100
    display.blit(textSurface, [x, y])
    width = 200
    lineWidth = 1
    gamejs.draw.rect(display, '#000', new gamejs.Rect(x, y + 40, width, 50), lineWidth)
    gamejs.draw.rect(display, '#000', new gamejs.Rect(x + lineWidth, y + 40 + lineWidth, width * @getLoadProgress() - lineWidth * 2, 50 - lineWidth * 2), 0)

  loadEntities: (scene, specName, group, fn) ->
    specs = @level[specName]
    for name, spec of specs
      rect = scene.toScreenRect(new gamejs.Rect(spec.x, spec.y, spec.width, spec.height))
      sprite = fn(name, spec, rect)
      @loadSpriteSpec(sprite, spec)
      group.add(sprite)

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

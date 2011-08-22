
gamejs = require 'gamejs'
pathfinding = require 'pathfinding'
entity = require 'entity'

exports.Scene = class Scene
  constructor: (@director, level) ->
    @viewportRect = @director.getViewport()
    @solids = new gamejs.sprite.Group()
    @characters = new gamejs.sprite.Group()

    @worldWidth = level.size[0]
    @worldHeight = level.size[1]

    playerSize = [64, 128]
    playerPosition = @toScreenRect(new gamejs.Rect(level.playerStart, playerSize))
    @player = new entity.Player(this, playerPosition)
    @player.image = new gamejs.Surface(@player.rect)
    @player.image.fill('#ff0000')
    @characters.add(@player)

    for name, spec of level.npcs
      rect = @toScreenRect(new gamejs.Rect(spec.x, spec.y, spec.width, spec.height))
      sprite = new entity.NPCharacter(this, rect, spec.behavior)
      @loadSpriteSpec(sprite, spec)
      @characters.add(sprite)

    for name, spec of level.solids
      rect = @toScreenRect(new gamejs.Rect(spec.x, spec.y, spec.width, spec.height))
      sprite = new entity.Entity(this, rect)
      @loadSpriteSpec(sprite, spec)
      @solids.add(sprite)

    # Hold a function to be called every frame to continue a player action.
    @playerMove = ->

  drawRepeat: (source, dest, repeatX, repeatY) ->
    sourceSize = source.getSize()
    for x in [0...repeatX]
      for y in [0...repeatY]
        dest.blit(source, [x * sourceSize[0], y * sourceSize[1]])

  loadSpriteSpec: (sprite, spec) ->
    if spec.image?
      rawImage = gamejs.image.load(spec.image)
      if spec.repeat? and spec.repeat != 'none'
        sprite.image = new gamejs.Surface(sprite.rect)
        imageSize = rawImage.getSize()
        switch spec.repeat
          when 'x' then @drawRepeat(rawImage, sprite.image, sprite.rect.width / imageSize[0], 1)
      else
        sprite.image = rawImage
    else
      sprite.image = new gamejs.Surface(sprite.rect)
      sprite.image.fill(spec.color)

  leftClick: (point) ->
    # find character clicked on
    charactersClicked = @characters.collidePoint(point)
    # launch dialog subsys for first clicked NPC
    for char in charactersClicked
      if not char.player
        char.startDialog()  # tell NPC that we want to talk
        # TODO start dialog overlay
        break
 
  handleEvent: (event) =>
    switch event.type
      when gamejs.event.MOUSE_DOWN then switch event.button
        when 0 then @leftClick(event.pos)
      when gamejs.event.KEY_DOWN then switch event.key
        when gamejs.event.K_a then @playerMove = -> @player.left()
        when gamejs.event.K_d then @playerMove = -> @player.right()
        when gamejs.event.K_SPACE then @player.jump()
      when gamejs.event.KEY_UP then switch event.key
        when gamejs.event.K_a then @playerMove = ->
        when gamejs.event.K_d then @playerMove = ->

  update: (msDuration) ->
    # just let it skip a bit if we got slowed down that much
    if msDuration > 100
      msDuration = 100

    @playerMove()
    @characters.update(msDuration)

  draw: (display) ->
    display.clear()
    @solids.draw(display)
    @characters.draw(display)

  getPathfindingMap: (character) ->
    # character capabilities and location of solids needs to be passed in
    new pathfinding.Map(character, this)

  center: (worldPosition) ->
    @viewportRect.center = worldPosition
    if @viewportRect.bottom > @worldHeight
      @viewportRect.bottom = @worldHeight

    if @viewportRect.left < 0
      @viewportRect.left = 0
      
    if @viewportRect.right > @worldWidth
      @viewportRect.right = @worldWidth

  toWorldRect: (rect) ->
    # convert screen coordinates to world coordinates
    rect.move(@viewportRect)

  toScreenRect: (rect) ->
    # convert world coordinates to screen coordinates
    rect.move(-@viewportRect.left, -@viewportRect.top)

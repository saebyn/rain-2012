
gamejs = require 'gamejs'
pathfinding = require 'pathfinding'
entity = require 'entity'
loader = require 'loader'

exports.Scene = class Scene
  constructor: (@director, level) ->
    @viewportRect = @director.getViewport()

    # backgrounds are non-interactive sprites
    @backgrounds = new gamejs.sprite.Group()

    # doors that when clicked load a different level file
    @portals = new gamejs.sprite.Group()

    # items are interactive sprites
    # (either things to be picked up or activated)
    @items = new gamejs.sprite.Group()

    # solids are things you can't walk or fall through
    @solids = new gamejs.sprite.Group()

    # characters are the player and NPCs
    @characters = new gamejs.sprite.Group()

    @worldWidth = level.size[0]
    @worldHeight = level.size[1]

    playerSize = [64, 128]
    playerPosition = @toScreenRect(new gamejs.Rect(level.playerStart, playerSize))
    @player = new entity.Player(this, playerPosition)
    @player.image = new gamejs.Surface(@player.rect)
    @player.image.fill('#ff0000')
    @characters.add(@player)

    @loadEntities(level.npcs, @characters, (name, spec, rect) =>
      new entity.NPCharacter(this, rect, spec.behavior))

    @loadEntities(level.solids, @solids, (name, spec, rect) =>
      new entity.Entity(this, rect))

    @loadEntities(level.backgrounds, @backgrounds, (name, spec, rect) =>
      new entity.Entity(this, rect))

    @loadEntities(level.portals, @portals, (name, spec, rect) =>
      new entity.Portal(this, rect, spec.destination))

    # Hold a function to be called every frame to continue a player action.
    @playerMove = ->

  loadEntities: (specs, group, fn) ->
    for name, spec of specs
      rect = @toScreenRect(new gamejs.Rect(spec.x, spec.y, spec.width, spec.height))
      sprite = fn(name, spec, rect)
      @loadSpriteSpec(sprite, spec)
      group.add(sprite)

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
          when 'y' then @drawRepeat(rawImage, sprite.image, 1, sprite.rect.height / imageSize[1])
          when 'xy' then @drawRepeat(rawImage, sprite.image, sprite.rect.width / imageSize[0], sprite.rect.height / imageSize[1])
      else
        sprite.image = rawImage
    else if spec.color
      sprite.image = new gamejs.Surface(sprite.rect)
      sprite.image.fill(spec.color)

  leftClick: (point) ->
    # find any portals clicked on
    portalsClicked = @portals.collidePoint(point)
    if portalsClicked.length > 0
      @loadPortal(portalsClicked[0])
      return

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
    @backgrounds.draw(display)
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

  loadPortal: (portal) ->
    scene = new loader.Loader(@director, portal.destination)
    @director.replaceScene(scene)

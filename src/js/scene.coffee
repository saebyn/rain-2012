
gamejs = require 'gamejs'
pathfinding = require 'pathfinding'
entity = require 'entity'
loader = require 'loader'

exports.Scene = class Scene
  constructor: (@director, @sceneLoader) ->
    @viewportRect = @director.getViewport()
    @paused = false

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

    @worldWidth = @sceneLoader.level.size[0]
    @worldHeight = @sceneLoader.level.size[1]

    playerSize = [64, 128]
    playerPosition = @toScreenRect(new gamejs.Rect(@sceneLoader.level.playerStart, playerSize))
    @player = new entity.Player(this, playerPosition)
    @player.image = new gamejs.Surface(@player.rect)
    @player.image.fill('#ff0000')
    @characters.add(@player)

    @sceneLoader.loadEntities(@, 'npcs', @characters, (name, spec, rect) =>
      new entity.NPCharacter(this, rect, spec.behavior))

    @sceneLoader.loadEntities(@, 'solids', @solids, (name, spec, rect) =>
      new entity.Entity(this, rect))

    @sceneLoader.loadEntities(@, 'backgrounds', @backgrounds, (name, spec, rect) =>
      new entity.BackgroundSprite(this, rect, spec.distance))

    @sceneLoader.loadEntities(@, 'portals', @portals, (name, spec, rect) =>
      new entity.Portal(this, rect, spec.destination))

    # Hold a function to be called every frame to continue a player action.
    @playerMove = ->

  leftClick: (point) ->
    # no interactions while paused
    if @paused
      return

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
        when gamejs.event.K_p then @paused = true
        when gamejs.event.K_ESC then @paused = false

  update: (msDuration) ->
    # just let it skip a bit if we got slowed down that much
    if msDuration > 100
      msDuration = 100

    if not @paused
      @playerMove()
      @characters.update(msDuration)

  draw: (display) ->
    display.clear()
    @backgrounds.draw(display)
    @solids.draw(display)
    @characters.draw(display)

    if @paused
      font = new gamejs.font.Font('36px monospace')
      textSurface = font.render("Paused...")
      font = new gamejs.font.Font('24px monospace')
      subtextSurface = font.render("(press ESC to resume)")

      textRect = new gamejs.Rect([0, 0], textSurface.getSize())
      screenCenterX = display.getSize()[0] / 2
      screenCenterY = display.getSize()[1] / 2
      textRect.center = [screenCenterX, screenCenterY]
      display.blit(textSurface, textRect)

      subtextRect = new gamejs.Rect([0, 0], subtextSurface.getSize())
      subtextRect.center = [screenCenterX, screenCenterY + textRect.height + 10]
      display.blit(subtextSurface, subtextRect)

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


gamejs = require 'gamejs'
pathfinding = require 'pathfinding'
entity = require 'entity'
loader = require 'loader'
menu = require 'menu'


exports.Scene = class Scene
  constructor: (@director, worldSize, playerStart) ->
    @viewportRect = @director.getViewport()
    @paused = false

    @modalDialogs = new gamejs.sprite.Group()

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

    @worldWidth = worldSize[0]
    @worldHeight = worldSize[1]

    playerSize = [64, 128]
    @player = new entity.Player(this, @toScreenRect(new gamejs.Rect(playerStart, playerSize)))
    @player.image = new gamejs.Surface(@player.rect)
    @player.image.fill('#ff0000')
    @characters.add(@player)

    # Hold a function to be called every frame to continue a player action.
    @playerMove = ->

  getDirector: ->
    @director

  getEntityBuilder: (entityType, spritesheets) ->
    group = switch entityType
      when 'npcs' then @characters
      when 'solids' then @solids
      when 'backgrounds' then @backgrounds
      when 'portals' then @portals

    return new entity.EntityBuilder(@, group, entityType, spritesheets)

  start: ->
    @director.bind 'update', (msDuration) =>
      @update(msDuration)

    @director.bind 'resume', =>
      @paused = false

    @director.bind 'draw', (display) =>
      @draw(display)

    @director.bind 'mousedown', (event) =>
      switch event.button
        when 0 then @leftClick(event.pos)

    @director.bind 'keydown', (event) =>
      switch event.key
        when gamejs.event.K_a then @playerMove = -> @player.left()
        when gamejs.event.K_d then @playerMove = -> @player.right()
        when gamejs.event.K_SPACE then @player.jump()

    @director.bind 'keyup', (event) =>
      switch event.key
        when gamejs.event.K_a then @playerMove = ->
        when gamejs.event.K_d then @playerMove = ->
        when gamejs.event.K_ESC then @pause()


  stop: ->

  leftClick: (point) ->
    # check for any modal dialogs in the modals group and click on the last one
    if @modalDialogs.sprites().length > 0
      sprites = @modalDialogs.sprites()
      sprites[sprites.length-1].click(point)
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
        dialogMenu = char.startDialog()  # tell NPC that we want to talk
        # add dialogMenu to overlay
        @modalDialogs.add(dialogMenu)
        break
 
  pause: ->
    if not @paused
      @modalDialogs.add(new menu.Menu(@, 'Paused', {resume: 'Back to Game', quit: 'Quit Game'}))
      @paused = true

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
    @items.draw(display)
    @characters.draw(display)

    if @modalDialogs.sprites().length > 0
      display.fill('rgba(0, 0, 0, 0.7)')
      @modalDialogs.draw(display)

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
    newScene = new loader.Loader(@director, portal.destination)
    @director.replaceScene(newScene)

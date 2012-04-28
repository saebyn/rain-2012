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
pathfinding = require 'pathfinding'
loader = require 'scenes/loader'
menu = require 'menu'
mobile = require 'mobile'
inventory = require 'inventory'

EntityBuilder = require('entitybuilder').EntityBuilder


exports.GameScene = class GameScene
  constructor: (@director, @world, @spritesheets) ->
    @viewportRect = @director.getViewport()
    @paused = false

    @mobileDisplay = new mobile.MobileDisplay(@director)

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

    # attacks are things that move and hit things
    @attacks = new gamejs.sprite.Group()

    @worldWidth = @world.size[0]
    @worldHeight = @world.size[1]

    # Hold a function to be called every frame to continue a player action.
    @playerMove = ->

  getPlayer: ->
    @player

  getDirector: ->
    @director

  getTime: ->
    new Date(@world.gameTime*1000 + 0x9fff9fff*1000)

  getEntityBuilder: (entityType) ->
    group = switch entityType
      when 'npcs' then @characters
      when 'solids' then @solids
      when 'backgrounds' then @backgrounds
      when 'portals' then @portals
      when 'player' then @characters
      when 'items' then @items

    return new EntityBuilder(@world, this, group, entityType, @spritesheets)

  start: ->
    @director.addHover 'items', @items
    @director.bind 'hover:items', @highlight

    @director.bind 'resume', @resumeGame
    @director.bind 'save', @saveGame
    @director.bind 'savequit', @quitGame
    @director.bind 'savequit', @saveGame
    @director.bind 'quit', @quitGame

    @director.bind 'draw', @draw
    @director.bind 'update', @update

    @director.bind 'time', =>
      if not @paused
        @world.gameTime++
        @mobileDisplay.setTime(@getTime())

    @director.bind 'mousedown', _.debounce((event) =>
      switch event.button
        when 0 then @leftClick(event.pos)
    , 100, true)

    @director.bind 'keydown', (event) =>
      if @paused
        return

      switch event.key
        when gamejs.event.K_a then @playerMove = -> @player.left()
        when gamejs.event.K_d then @playerMove = -> @player.right()
        when gamejs.event.K_w then @player.jump()
        when gamejs.event.K_SPACE then @attack()
        when gamejs.event.K_SHIFT then @player.startSprint()
        when gamejs.event.K_i then @openInventory()

    @director.bind 'keyup', (event) =>
      switch event.key
        when gamejs.event.K_ESC then @togglePause()
        when gamejs.event.K_a then @playerMove = ->
        when gamejs.event.K_d then @playerMove = ->
        when gamejs.event.K_SHIFT then @player.stopSprint()

    @mobileDisplay.start()

    (character.initialize() for character in @characters.sprites() when character.initialize?)

  stop: ->
    # XXX its currently unsafe to rely on this scene unbinding its own events
    # currently not cleaned up: key and mouse events, and time ticks
    @mobileDisplay.stop()
    @director.unbind 'draw', @draw
    @director.unbind 'update', @update

    @director.unbind 'hover:items', @highlight
    @director.removeHover 'items'
    @director.unbind 'resume', @resumeGame
    @director.unbind 'save', @saveGame
    @director.unbind 'savequit', @quitGame
    @director.unbind 'savequit', @saveGame
    @director.unbind 'quit', @quitGame
    @saveToWorld()

  # Handle event to exit from ESC/pause menu.
  resumeGame: =>
    @paused = false
    @pauseMenu.kill()

  # Handle quit event from director
  quitGame: =>
    if confirm('Are you sure you want to quit without saving your progress?')
      # TODO switch the scene to the intro scene
      console.log 'quit game'
  
  # Handle game save event from director
  saveGame: =>
    @saveToWorld()
    saveName = prompt('Savepoint name?')
    if saveName
      @world.save(saveName)
    else
      return false

  # serialize all entities into world cache
  saveToWorld: ->
    @world.clearEntities()
    @world.addEntity('npcs', npc) for npc in @characters.sprites() when not npc.player
    @world.addEntity('items', item) for item in @items.sprites()
    @world.updatePlayer(@player)

  attack: _.debounce(->
    @player.attack()
  , 300, true)

  highlight: (sprites) ->
    sprite.highlight() for sprite in sprites

  leftClick: (point) ->
    # TODO generalize these sets of procedures... try to do pixel perfect collsion detection for characters and items
    # check for any modal dialogs in the modals group and click on the last one
    if @modalDialogs.sprites().length > 0
      sprites = @modalDialogs.sprites()
      sprites[sprites.length-1].click(point)
      return

    # find character clicked on
    charactersClicked = @characters.collidePoint(point)
    # launch dialog subsys for first clicked NPC
    for char in charactersClicked
      if not char.player
        @paused = true
        dialogMenu = char.startDialog()  # tell NPC that we want to talk
        # add dialogMenu to overlay
        @modalDialogs.add(dialogMenu)
        return

    # find any item clicked on
    itemsClicked = @items.collidePoint(point)
    if itemsClicked.length > 0
      itemsClicked[0].activate()
      return

    # find any portals clicked on
    portalsClicked = @portals.collidePoint(point)
    if portalsClicked.length > 0
      @loadPortal(portalsClicked[0])
      return
 
  togglePause: _.debounce(->
    if @paused
      sprite.kill() for sprite in @modalDialogs.sprites()
      @paused = false
    else
      @pauseMenu = new menu.Menu(@director, @director.getViewport())
      @pauseMenu.build('Paused', [['Back to Game', 'resume'],
                                  ['Save Progress', 'save'],
                                  ['Save and Quit', 'savequit'],
                                  ['Quit Game', 'quit']])
      @modalDialogs.add(@pauseMenu)
      @paused = true
  , 200, true)

  openInventory: ->
    @modalDialogs.add(new inventory.InventorySprite(@director, @player.getInventory(), =>
      @paused = false
    ))
    @paused = true

  update: (msDuration) =>
    # just let it skip a bit if we got slowed down that much
    # TODO think about how this works a bit...
    # maybe pause the game if we detect that we're going to lose focus.. is that doable?
    if msDuration > 100
      msDuration = 100

    if not @paused
      @playerMove()
      @characters.update(msDuration)
      @attacks.update(msDuration)
      @mobileDisplay.update(msDuration)
      @solids.update(msDuration)

  draw: (display) =>
    @backgrounds.draw(display)
    @portals.draw(display)
    @solids.draw(display)
    @items.draw(display)
    @characters.draw(display)
    @attacks.draw(display)
    @mobileDisplay.draw(display)

    if @modalDialogs.sprites().length > 0
      display.fill('rgba(0, 0, 0, 0.7)')
      @modalDialogs.draw(display)

  getPathfindingMap: (character) ->
    # character capabilities and location of solids needs to be passed in
    new pathfinding.Map(character, this)

  # Center the viewport on the given world position
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
    @paused = true
    newScene = new loader.Loader(@director, portal.destination, @world)
    @director.replaceScene(newScene)

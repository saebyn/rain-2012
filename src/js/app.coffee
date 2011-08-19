gamejs = require 'gamejs'
entity = require 'entity'
scene = require 'scene'

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 400

gamejs.ready ->
  viewport = new gamejs.Rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
  display = gamejs.display.setMode([SCREEN_WIDTH, SCREEN_HEIGHT])

  level = gamejs.http.load('level1.json')
  scene = new scene.Scene(viewport, level.size[0], level.size[1])

  playerSize = [64, 128]
  playerPosition = scene.toScreenRect(new gamejs.Rect(level.playerStart, playerSize))
  player = new entity.Player(scene, playerPosition)
  player.image = new gamejs.Surface(player.rect)
  player.image.fill('#ff0000')
  scene.setPlayer(player)

  for name, spec of level.npcs
    rect = scene.toScreenRect([spec.x, spec.y], [spec.width, spec.height])
    sprite = new entity.NPCharacter(scene, rect, spec.behavior)
    sprite.image = new gamejs.Surface(rect)
    sprite.image.fill(spec.color)
    scene.characters.add(sprite)

  for name, spec of level.solids
    rect = scene.toScreenRect(new gamejs.Rect(spec.x, spec.y, spec.width, spec.height))
    sprite = new entity.Entity(scene, rect)
    sprite.image = new gamejs.Surface(rect)
    sprite.image.fill(spec.color)
    scene.solids.add(sprite)

  # Hold a function to be called every frame to continue a player action.
  playerMove = ->

  leftClick = (point) ->
    # find character clicked on
    charactersClicked = scene.characters.collidePoint(point)
    # launch dialog subsys for first clicked NPC
    for char in charactersClicked
      if not char.player
        char.startDialog()  # tell NPC that we want to talk
        # TODO start dialog overlay
        break

  main = (msDuration) ->
    handleEvent = (event) ->
      switch event.type
        when gamejs.event.MOUSE_DOWN then switch event.button
          when 0 then leftClick(event.pos)
        when gamejs.event.KEY_DOWN then switch event.key
          when gamejs.event.K_a then playerMove = -> player.left()
          when gamejs.event.K_d then playerMove = -> player.right()
          when gamejs.event.K_SPACE then player.jump()
        when gamejs.event.KEY_UP then switch event.key
          when gamejs.event.K_a then playerMove = ->
          when gamejs.event.K_d then playerMove = ->

    # just let it skip a bit if we got slowed down that much
    if msDuration > 100
      msDuration = 100

    handleEvent event for event in gamejs.event.get()
    playerMove()
    scene.characters.update(msDuration)
    display.clear()
    display.blit((new gamejs.font.Font('30px Sans-serif')).render('    {x: ' + Math.round(scene.player.position[0]) + ', y: ' + Math.round(scene.player.position[1]) + '} ' + msDuration))
    scene.solids.draw(display)
    scene.characters.draw(display)


  gamejs.time.fpsCallback(main, this, 30)


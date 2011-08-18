gamejs = require 'gamejs'
entity = require 'entity'
scene = require 'scene'

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 400

gamejs.ready ->
  characters = new gamejs.sprite.Group()
  viewport = new gamejs.Rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
  display = gamejs.display.setMode([SCREEN_WIDTH, SCREEN_HEIGHT])

  level = gamejs.http.load('level1.json')
  scene = new scene.Scene(SCREEN_WIDTH, SCREEN_HEIGHT,
                          viewport,
                          level.size[0], level.size[1])

  playerSize = [64, 128]
  playerPosition = scene.toScreenRect(level.playerStart, playerSize)
  player = new entity.Character(scene, playerPosition)
  player.image = new gamejs.Surface(player.rect)
  player.image.fill('#ff0000')
  characters.add(player)

  for name, spec of level.solids
    rect = scene.toScreenRect([spec.x, spec.y], [spec.width, spec.height])
    sprite = new entity.Entity(scene, rect)
    sprite.image = new gamejs.Surface(rect)
    sprite.image.fill(spec.color)
    scene.solids.add(sprite)

  # Hold a function to be called every frame to continue a player action.
  playerMove = ->

  main = (msDuration) ->
    handleEvent = (event) ->
      switch event.type
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
    characters.update(msDuration)
    display.clear()
    display.blit((new gamejs.font.Font('30px Sans-serif')).render('    {x: ' + Math.round(player.position[0]) + ', y: ' + Math.round(player.position[1]) + '}'))
    scene.solids.draw(display)
    characters.draw(display)


  gamejs.time.fpsCallback(main, this, 30)


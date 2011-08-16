gamejs = require 'lib/gamejs'
entity = require 'entity'

SCREEN_WIDTH = 400
SCREEN_HEIGHT = 400
display = false

player = false

characters = new gamejs.sprite.Group()
backgrounds = new gamejs.sprite.Group()
object_entities = new gamejs.sprite.Group()
solid_entities = new gamejs.sprite.Group()

handleEvent = (event) ->
  switch event.type
    when gamejs.event.KEY_DOWN then switch event.key
      when gamejs.event.K_a then player.left()
      when gamejs.event.K_d then player.right()
      when gamejs.event.K_SPACE then player.jump()

main = (msDuration) ->
  handleEvent event for event in gamejs.event.get()
  characters.update(msDuration)
  display.clear()
  display.blit((new gamejs.font.Font('30px Sans-serif')).render('' + msDuration))
  solid_entities.draw(display)
  characters.draw(display)

gamejs.ready ->
  display = gamejs.display.setMode([SCREEN_WIDTH, SCREEN_HEIGHT])

  player = new entity.Character(solid_entities)
  player.rect = new gamejs.Rect(15, SCREEN_HEIGHT - 56, 20, 45)
  player.image = new gamejs.Surface(player.rect)
  player.image.fill('#ff0000')
  characters.add(player)

  floor = new gamejs.sprite.Sprite()
  floor.rect = new gamejs.Rect(0, SCREEN_HEIGHT - 10, SCREEN_WIDTH, 10)
  floor.image = new gamejs.Surface(floor.rect)
  floor.image.fill('#0000ff')
  solid_entities.add(floor)

  wall = new gamejs.sprite.Sprite()
  wall.rect = new gamejs.Rect(0, 0, 10, SCREEN_HEIGHT - 10)
  wall.image = new gamejs.Surface(wall.rect)
  wall.image.fill('#0000ff')
  solid_entities.add(wall)

  gamejs.time.fpsCallback(main, this, 30)


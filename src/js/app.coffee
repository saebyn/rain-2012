director = require 'director'
loader = require 'loader'

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 400


gamejs.ready ->
  gameDirector = new director.Director(SCREEN_WIDTH, SCREEN_HEIGHT)
  gameDirector.start(new loader.Loader(gameDirector, 'level1.json'))

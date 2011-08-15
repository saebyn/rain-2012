gamejs = require 'gamejs'
SCREEN_WIDTH = 400
SCREEN_HEIGHT = 400
display = false

handleEvent = (event) ->
  switch event.type
    when gamejs.event.MOUSE_UP then alert('Click!')

main = (msDuration) ->
  handleEvent event for event in gamejs.event.get()
  display.clear()
  display.blit((new gamejs.font.Font('30px Sans-serif')).render('' + msDuration))

gamejs.ready ->
  display = gamejs.display.setMode([SCREEN_WIDTH, SCREEN_HEIGHT])
  gamejs.time.fpsCallback(main, this, 30)


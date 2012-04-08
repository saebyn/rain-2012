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
scene = require 'scene'

# A loading screen...
# Preload the level sprites, etc, create a game scene, and switch the
# director to it.

exports.Loader = class Loader
  constructor: (@director, levelFilename) ->
    @spritesheets = {}
    @level = gamejs.http.load(levelFilename)
    @loaded = false

  start: ->
    @getLoadProgress = @load(@extractResources())
    @director.bind 'update', (msDuration) =>
      @update(msDuration)

    @director.bind 'draw', (display) =>
      @draw(display)

  stop: ->

  # extract the relative urls to the resources in @level
  extractResources: ->
    resources = []

    # find spritesheets, load their images, build mapping of spritesheet names
    for name, sheetfn of @level.spritesheets
        sheet = gamejs.http.load(sheetfn)
        @spritesheets[name] = sheet
        resources.push(sheet.image)

    for name, sprite of @level.solids
      if sprite.image?
        resources.push(sprite.image)

    for name, sprite of @level.backgrounds
      if sprite.image?
        resources.push(sprite.image)

    for name, sprite of @level.npcs
      if sprite.image?
        resources.push(sprite.image)

    resources

  resourcesLoaded: =>
    @loaded = true

  load: (resources) ->
    gamejs.preload(resources)
    gamejs.ready(@resourcesLoaded)

  progress: ->
    (@getLoadProgress() * 100) + '%'

  update: (msDuration) ->
     if @loaded
       newScene = new scene.Scene(@director, @level.size, @level.playerStart)
       for entityType in ['npcs', 'solids', 'backgrounds', 'portals']
         if @level[entityType]?
           entityBuilder = newScene.getEntityBuilder(entityType, @spritesheets)
           for entityName, entityDef of @level[entityType]
             entityBuilder.newEntity(entityDef)

       @director.replaceScene(newScene)

  draw: (display) ->
    # draw progress
    # create a font
    font = new gamejs.font.Font('24px monospace')
    # render text - this returns a surface with the text written on it.
    textSurface = font.render("loading... " + @progress())

    display.clear()

    x = display.getSize()[0] / 2 - 100
    y = 100
    display.blit(textSurface, [x, y])
    width = 200
    lineWidth = 1
    gamejs.draw.rect(display, '#000', new gamejs.Rect(x, y + 40, width, 50), lineWidth)
    gamejs.draw.rect(display, '#000', new gamejs.Rect(x + lineWidth, y + 40 + lineWidth, width * @getLoadProgress() - lineWidth * 2, 50 - lineWidth * 2), 0)

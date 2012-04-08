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

exports.Menu = class Menu extends gamejs.sprite.Sprite
  constructor: (@eventSink, @viewport, title, options) ->
    super()
    @titleFont = new gamejs.font.Font('36px monospace')
    @buttonFont = new gamejs.font.Font('36px monospace')
    # create pause menu image, define button rects
    @buttons = @createButtons(options)
    # -> {optionName: {rect: Rect(), image: Surface()}, ...}
    @image = @renderMenu(title, @buttons)
    @rect = @positionMenu(@image)

  positionMenu: (image) ->
    positionRect = new gamejs.Rect([0, 0], image.getSize())
    positionRect.center = @viewport.center
    return positionRect

  createButton: (name, text, x, y, padding) ->
    image = @buttonFont.render(text, 'white')
    imageSize = image.getSize()
    buttonImage = new gamejs.Surface([imageSize[0] + padding * 2, imageSize[1] + padding * 2])
    buttonImage.fill('#333333')
    buttonImage.blit(image, [padding, padding])
    rect = new gamejs.Rect([x, y], buttonImage.getSize())
    {rect: rect, image: buttonImage}
  
  createButtons: (options) ->
    buttons = {}
    BUTTON_MARGIN = 15
    BUTTON_PADDING = 5
    x = y = BUTTON_MARGIN
    for name, text of options
      buttons[name] = @createButton(name, text, x, y, BUTTON_PADDING)
      y += buttons[name].rect.height + BUTTON_MARGIN

    return buttons

  renderMenu: (title, buttons) ->
    # render title text
    titleImage = @titleFont.render(title, 'white')
    # calc title spacing
    TITLE_SPACING = 10
    titleRect = new gamejs.Rect([TITLE_SPACING, TITLE_SPACING], titleImage.getSize())
    titleRect.height += TITLE_SPACING
    titleRect.width += TITLE_SPACING

    # get max x (with title) & y (of buttons)
    maxWidth = titleRect.width
    bottom = titleRect.bottom
    
    # alter button positions to fit title
    for name, button of buttons
      button.rect.top += titleRect.height

      # collect max x & y
      if button.rect.bottom > bottom
        bottom = button.rect.bottom

      if button.rect.width > maxWidth
        maxWidth = button.rect.width

    # center button rects vertically
    for name, button of buttons
      button.rect.center = [maxWidth/2, button.rect.center[1]]

    # center title vertically
    titleRect.center = [maxWidth/2, titleRect.center[1]]

    # create menu image
    menuImage = new gamejs.Surface(maxWidth, bottom)

    # menu background effects
    menuImage.fill('#aaaaaa')

    # blit title to menu
    menuImage.blit(titleImage, titleRect)
    # blit buttons to menu
    for name, button of buttons
      menuImage.blit(button.image, button.rect)

    # return menu image
    menuImage

  # find the button in @buttons that was clicked
  findButton: (point) ->
    # subtract @rect.topleft from point
    point = [point[0] - @rect.left, point[1] - @rect.top]
    # search each @buttons .rect for collision
    for name, button of @buttons
      if button.rect.collidePoint(point)
        return name

    false

  click: (point) ->
    button = @findButton(point)
    if button
      @eventSink.trigger(button)
      @kill()


# TODO find positioning for dialog (ideally above npc, else centered on screen)
exports.DialogMenu = class DialogMenu extends Menu

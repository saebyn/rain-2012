gamejs = require 'gamejs'

exports.Menu = class Menu extends gamejs.sprite.Sprite
  constructor: (@director, title, options) ->
    super()
    @font = new gamejs.font.Font('36px monospace')
    # create pause menu image, define button rects
    @buttons = @createButtons(options)
    # -> {optionName: {rect: Rect(), image: Surface()}, ...}
    @image = @renderMenu(title, @buttons)
    @rect = @positionMenu(@image)

  positionMenu: (image) ->
    positionRect = new gamejs.Rect([0, 0], image.getSize())
    positionRect.center = @director.getViewport().center
    return positionRect

  createButton: (name, text, x, y) ->
    image = @font.render(text)
    # TODO button effect
    rect = new gamejs.Rect([x, y], image.getSize())
    {rect: rect, image: image}
  
  createButtons: (options) ->
    buttons = {}
    BUTTON_SPACING = 5
    x = y = BUTTON_SPACING
    for name, text of options
      buttons[name] = @createButton(name, text, x, y)
      y += buttons[name].rect.height + BUTTON_SPACING

    return buttons

  renderMenu: (title, buttons) ->
    # render title text
    titleImage = @font.render(title)
    # calc title spacing
    TITLE_SPACING = 10
    titleRect = new gamejs.Rect([0, 0], titleImage.getSize())
    titleRect.height += TITLE_SPACING * 2
    titleRect.width += TITLE_SPACING * 2

    # get max x (with title) & y (of buttons)
    maxWidth = titleRect.width
    bottom = titleRect.height
    
    # alter button positions to fit title
    for name, button of buttons
      button.rect.top += titleRect.height
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

    # TODO menu background effects

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
      @director.trigger(button)

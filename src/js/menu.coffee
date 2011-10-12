gamejs = require 'gamejs'

exports.Menu = class Menu extends gamejs.sprite.Sprite
  constructor: (scene, title, options) ->
    super()
    @director = scene.getDirector()
    @titleFont = new gamejs.font.Font('36px monospace')
    @buttonFont = new gamejs.font.Font('36px monospace')
    # create pause menu image, define button rects
    @buttons = @createButtons(options)
    # -> {optionName: {rect: Rect(), image: Surface()}, ...}
    @image = @renderMenu(title, @buttons)
    @rect = @positionMenu(@image)

  positionMenu: (image) ->
    positionRect = new gamejs.Rect([0, 0], image.getSize())
    positionRect.center = @director.getViewport().center
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
      @director.trigger(button)
      @kill()


# TODO find positioning for dialog (ideally above npc, else centered on screen)
# TODO have events go to NPC rather than director
exports.DialogMenu = class DialogMenu extends Menu
  constructor: (@npc, text, options...) ->
    super(@npc.getScene(), text, options)

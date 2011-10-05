

# TODO find positioning for dialog (ideally above npc, else centered on screen)
# TODO bind mouse click event and connect it to dialog options (and close
#      button)
# TODO cancel mouse click so that it doesn't bubble if the click is within the
#      dialog area
# TODO tell npc which option was selected (or that we canceled)

exports.Dialog = class Dialog extends gamejs.Sprite
  constructor: (@scene, @npc, text, options...) ->
    @optionRects = []
    TEXT_SPACING = 3
    OPTION_SPACING = 3

    # TODO cancel button
    font = new gamejs.font.Font('16px Verdana')
    textSurface = font.render(text)
    optionTextSurfaces = []
    for option in options
      optionTextSurface = font.render(option)
      optionTextSurfaces.push(optionTextSurface)
      @optionRects.push(new gamejs.Rect([0, 0], optionTextSurface.getSize()))

    textHeight = textSurface.getSize()[1]
    textTotalSpacing = TEXT_SPACING * 2

    textWidths = [rect.width for rect in @optionRects] + textSurface.getSize()[0]
    maxTextWidth = textWidths.reduce (x1, x2) -> Math.max(x1, x2)

    optionHeights = [rect.height for rect in @optionRects]
    optionsHeight = optionHeights.reduce (y1, y2) -> y1 + y2
    optionTotalSpacing = (@optionRects.length - 1) * OPTION_SPACING

    @image = new gamejs.Surface(maxTextWidth + TEXT_SPACING * 2,
                                optionsHeight + optionTotalSpacing + textHeight + textTotalSpacing)
    # TODO blit text surfaces onto image

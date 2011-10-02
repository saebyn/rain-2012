

# TODO determine size of area needed for dialog
# TODO find positioning for dialog (ideally above npc, else centered on screen)
# TODO bind mouse click event and connect it to dialog options (and close
#      button)
# TODO cancel mouse click so that it doesn't bubble if the click is within the
#      dialog area
# TODO blit the text, options text, and close button to the sprite image
# TODO tell npc about what choice was made

exports.Dialog = class Dialog extends gamejs.Sprite
  constructor: (@scene, @npc, @text, @options...) ->


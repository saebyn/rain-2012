require.ensure ['entity', 'scene', 'gamejs'], (require) ->
  entity = require 'entity'
  scene = require 'scene'
  gamejs = require 'gamejs'

  describe 'entity', ->
    beforeEach ->
      # scene setup
      @scene = new scene.Scene(100, 100, new gamejs.Rect(0, 0, 100, 100))
      @char = new entity.Character(@scene, new gamejs.Rect(25, 30, 10, 10))
      @leftWall = new gamejs.sprite.Sprite()
      @leftWall.rect = new gamejs.Rect(0, 0, 10, 40)
      @floor = new gamejs.sprite.Sprite()
      @floor.rect = new gamejs.Rect(0, 40, 40, 10)

      @scene.solids.add [@leftWall, @floor]

      @addMatchers(
        isDirectlyAbove: (expected) ->
          actualRect = @actual.rect.clone()
          actualRect.center = [actualRect.center[0], expected.rect.center[1]]
          actualRect.collideRect(expected.rect) and \
          @actual.rect.center[1] < expected.rect.center[1]
        isDirectlyLeft: (expected) ->
          actualRect = @actual.rect.clone()
          actualRect.center = [expected.rect.center[0], actualRect.center[1]]
          actualRect.collideRect(expected.rect) and \
          @actual.rect.center[0] < expected.rect.center[0]
        isDirectlyRight: (expected) ->
          actualRect = @actual.rect.clone()
          actualRect.center = [expected.rect.center[0], actualRect.center[1]]
          actualRect.collideRect(expected.rect) and \
          @actual.rect.center[0] > expected.rect.center[0]
        isNextTo: (expected) ->
          Math.abs(@actual.rect.right - expected.rect.left) <= 1 or \
          Math.abs(@actual.rect.left  - expected.rect.right) <= 1 or \
          Math.abs(@actual.rect.top   - expected.rect.bottom) <= 1 or \
          Math.abs(@actual.rect.bottom - expected.rect.top) <= 1
      )

    it 'should work with directional asserts', ->
      expect(@char).isDirectlyRight @leftWall
      expect(@char).isDirectlyAbove @floor
      expect(@char).not.isNextTo @leftWall
      expect(@char).isNextTo @floor

    it 'should move 100 pixels in one second after a single move', ->
      oldPosition = @char.rect.left
      @char.right()
      for i in [1...20]
        @char.update 50  # Give it a full second
      expect(@char.rect.left).toEqual(oldPosition + 100)

    it 'should be able to move right after hitting left wall', ->
      @char.jump().left().left().left().left()
      for i in [1...20]
        @char.update 50  # Give it a full second

      expect(@char).isDirectlyRight @leftWall
      expect(@char).isDirectlyAbove @floor
      expect(@char).isNextTo @leftWall
      expect(@char).isNextTo @floor

      @char.right()
      for i in [1...20]
        @char.update 50  # Give it a full second

      expect(@char).not.isNextTo @leftWall
      expect(@char).isNextTo @floor
  
  describe 'scene', ->
    beforeEach ->
      @scene = new scene.Scene(100, 100, new gamejs.Rect(50, 50, 50, 50))

    it 'should convert world coordinates to screen coordinates', ->
      screenRect = @scene.toScreenRect [50, 10], [10, 10]
      expect(screenRect.left).toEqual(0)
      expect(screenRect.right).toEqual(10)
      expect(screenRect.top).toEqual(40)
      expect(screenRect.bottom).toEqual(50)

    it 'should convert screen coordinates to world coordinates', ->
      screenRect = new gamejs.Rect(0, 40, 10, 10)
      [x, y] = @scene.toWorldCoord screenRect
      expect(x).toEqual(50)
      expect(y).toEqual(10)

  jasmine.getEnv().addReporter(new jasmine.TrivialReporter())
  jasmine.getEnv().execute()

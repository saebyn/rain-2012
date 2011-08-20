require.ensure ['entity', 'scene', 'pathfinding', 'gamejs'], (require) ->
  entity = require 'entity'
  scene = require 'scene'
  pathfinding = require 'pathfinding'
  gamejs = require 'gamejs'

  describe 'entity', ->
    beforeEach ->
      # scene setup
      @scene = new scene.Scene(new gamejs.Rect(0, 0, 100, 100), 100, 100)
      @char = new entity.Player(@scene, new gamejs.Rect(25, 80, 10, 10))
      @leftWall = new entity.Entity(@scene, new gamejs.Rect(0, 0, 10, 100))
      @floor = new entity.Entity(@scene, new gamejs.Rect(0, 90, 40, 10))

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

    it 'should update worldRect when changing position', ->
      @char.position = [3, 3]
      expect(@char.worldRect.left).toEqual(3)
      expect(@char.worldRect.top).toEqual(3)
      @char.position[0] = 1
      expect(@char.worldRect.left).not.toEqual(1)
      expect(@char.worldRect.left).toEqual(3)

    it 'should work with directional asserts', ->
      expect(@char).isDirectlyRight @leftWall
      expect(@char).isDirectlyAbove @floor
      expect(@char).not.isNextTo @leftWall
      expect(@char).isNextTo @floor

    it 'should automatically update its rectangle when its worldRect changes', ->
      oldX = @char.rect.left
      oldY = @char.rect.top
      @char.worldRect.left += 1
      @char.worldRect.top += 1
      expect(@char.rect.left).toEqual(oldX + 1)
      expect(@char.rect.top).toEqual(oldY + 1)

  describe 'scene', ->
    beforeEach ->
      @scene = new scene.Scene(new gamejs.Rect(49, 50, 50, 50), 200, 100)
      @char = new entity.Player(@scene, new gamejs.Rect(25, 80, 10, 10))
      @leftWall = new entity.Entity(@scene, new gamejs.Rect(0, 50, 10, 40))
      @floor = new entity.Entity(@scene, new gamejs.Rect(0, 90, 40, 10))

      @scene.solids.add [@leftWall, @floor]

    it 'should convert world coordinates to screen coordinates', ->
      screenRect = @scene.toScreenRect(new gamejs.Rect(50, 10, 10, 10))
      expect(screenRect.left).toEqual(1)
      expect(screenRect.right).toEqual(11)
      expect(screenRect.top).toEqual(-40)
      expect(screenRect.bottom).toEqual(-30)

    it 'should convert screen coordinates to world coordinates', ->
      screenRect = new gamejs.Rect(0, 40, 10, 10)
      worldRect = @scene.toWorldCoord screenRect
      expect(worldRect.left).toEqual(49)
      expect(worldRect.top).toEqual(90)

    it 'should move the viewport when the player moves right off the screen', ->
      @scene.center(@char.worldRect.center)
      oldViewportRightEdge = @scene.viewportRect.right
      @char.worldRect.left += 100
      @scene.center(@char.worldRect.center)
      expect(oldViewportRightEdge).toBeLessThan(@scene.viewportRect.right)

    it 'should cause the screen position of the left wall to change when player moves right off the screen', ->
      @scene.center(@char.worldRect.center)
      oldLeftWallX = @leftWall.rect.left
      @char.worldRect.left += 100
      @scene.center(@char.worldRect.center)
      expect(@leftWall.rect.left).not.toEqual(oldLeftWallX)

  describe 'pathfinding', ->
    beforeEach ->
      @scene = new scene.Scene(new gamejs.Rect(49, 50, 50, 50), 200, 100)
      @char = new entity.Player(@scene, new gamejs.Rect(25, 80, 10, 10))
      @leftWall = new entity.Entity(@scene, new gamejs.Rect(0, 50, 10, 40))
      @floor = new entity.Entity(@scene, new gamejs.Rect(0, 90, 40, 10))
      @map = @scene.getPathfindingMap(@char)

    it 'should compute an estimated distance as a lower bound for the actual distance', ->
      destination = [90, 30]
      expect(@map.estimatedDistance(@char.worldRect.topleft, destination)).not.toBeGreaterThan(@map.actualDistance(@char.worldRect.topleft, destination))

  jasmine.getEnv().addReporter(new jasmine.TrivialReporter())
  jasmine.getEnv().execute()

require.ensure ['entity'], (require) ->
  describe 'entity', ->
    beforeEach = ->
      @addMatchers(
        toBeVisible: ->
          @actual.isVisible()
      )

    it 'nested expectation', ->
      expect(1).toEqual(1)

  jasmine.getEnv().addReporter(new jasmine.TrivialReporter())
  jasmine.getEnv().execute()

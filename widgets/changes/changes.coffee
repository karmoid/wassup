class Dashing.Changes extends Dashing.Widget

  @accessor 'quote', ->
    "“#{@get('current_change')?.body}”"

  @accessor 'when', ->
    "#{@get('current_change')?.when}"
    
  ready: ->
    @currentIndex = 0
    @changeElem = $(@node).find('.change-container')
    @nextChange()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextChange, 5000)

  nextChange: =>
    changes = @get('changes')
    if changes
      @changeElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % changes.length
        @set 'current_change', changes[@currentIndex]
        @changeElem.fadeIn()

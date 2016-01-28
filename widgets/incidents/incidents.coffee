class Dashing.Incidents extends Dashing.Widget

  @accessor 'quote', ->
    "“#{@get('current_incident')?.body}”"

  @accessor 'when', ->
    "#{@get('current_incident')?.when}"
    
  ready: ->
    @currentIndex = 0
    @incidentElem = $(@node).find('.incident-container')
    @nextIncident()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextIncident, 10000)

  nextIncident: =>
    incidents = @get('incidents')
    if incidents
      @incidentElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % incidents.length
        @set 'current_incident', incidents[@currentIndex]
        @incidentElem.fadeIn()

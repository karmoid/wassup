class Dashing.Velib extends Dashing.Widget

    @accessor 'stateClass', ->
        if @get('state') == "OPEN"
            "station-state-open"
        else if @get('state') == "CLOSED"
            "station-state-closed"
        else
            "station-state-unknown"

    constructor: ->
        super

    ready: ->
        $(@node).addClass(@get('stateClass'))

    onData: (data) ->
        $(@node).addClass(@get('stateClass'))
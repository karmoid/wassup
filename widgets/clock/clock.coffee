class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    today = new Date()

    h = today.getHours()
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)
    options = {weekday: "long",  month: "long", day: "numeric"}
    @set('time', h + ":" + m + ":" + s)
    @set('date', today.toLocaleDateString("fr-FR",options))

  formatTime: (i) ->
    if i < 10 then "0" + i else i
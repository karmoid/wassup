class Dashing.Backlog extends Dashing.Widget

  DIVISORS = [
      {number: 100000000000000000000000,  label: 'Y'}
      {number: 100000000000000000000,     label: 'Z'}
      {number: 100000000000000000,        label: 'E'}
      {number: 1000000000000000,          label: 'P'}
      {number: 1000000000000,             label: 'T'}
      {number: 1000000000,                label: 'G'}
      {number: 1000000,                   label: 'M'}
      {number: 1000,                      label: 'K'}
  ]

  # Take a long number like "2356352" and turn it into "2.4M"
  formatNumber = (number) ->
    for divisior in DIVISORS
      if number > divisior.number
          number = "#{Math.round(number / (divisior.number/10))/10}#{divisior.label}"
          break
    number

  formatText = (number) ->
     map = {
       0: 'AA'
       1: 'BB'
       2: 'CC'
       3: 'DD'
       4: 'EE'
     }
     console.log("number = ~#{number}")
     map[number]

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('points')
    cumulate = @get('cumulated')
    raw = @get('raw')
    if points
      if cumulate
        backlog = for point in points
          point.y
        if raw
          "#{backlog.reduce (x,y)->x+y}"
        else
          formatNumber( backlog.reduce (x,y)->x+y )
      else
        if raw
          "#{points[points.length - 1].y}"
        else
          formatNumber( points[points.length - 1].y )

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))
    palette = new Rickshaw.Color.Palette(
      scheme: 'munin'
      )
    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      renderer: @get("graphtype")
      interpolation: "linear"
      series: [
        {
        color: "#fff",
        data: [{x:1, y:0}]
        palette: palette.color()
        }
      ]
    )

    txtLegend = @get('legend') if @get('legend')
    txtLegend ||= false
    if txtLegend
      x_axis = new Rickshaw.Graph.Axis.X(
        graph: @graph
        orientation: 'top'
        tickFormat: formatText
      )
    else
      x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)

    y_axis = new Rickshaw.Graph.Axis.Y(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)

    @graph.series[0].data = @get('points') if @get('points')
    @graph.render()

  onData: (data) ->
    if @graph
      console.log data
      @graph.series[0].data = data.points
      @graph.render()

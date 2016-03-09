class Dashing.Jmeter extends Dashing.Widget

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

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('points')
    @status = @get('status')
    if points
      formatNumber( points[points.length - 1].y )

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))
    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      renderer: @get("graphtype")
      series: [
        {
        color: "#fff",
        data: [{x:0, y:0}]
        }
      ]
    )

    @graph.series[0].data = @get('points') if @get('points')

    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    y_axis = new Rickshaw.Graph.Axis.Y(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)
    @graph.render()

  onData: (data) ->
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
    @status = data.status
    if @status
      $(@node).css('background-color', '#42b2aa')
    else
      $(@node).css('background-color', '#e85c28')

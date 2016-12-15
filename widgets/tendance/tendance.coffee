class Dashing.Tendance extends Dashing.Widget

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
    cumulate = @get('cumulated')
    if points
      if cumulate
        backlog = for point in points
          point.y
        formatNumber( backlog.reduce (x,y)->x+y )
      else
        formatNumber( points[points.length - 1].y )


  # @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = parseFloat(@get('last'))
      current = parseFloat(@get('current'))
      if last != 0
        diff = Math.round(((current - last)) * 100) / 100
        "#{diff}"
    else
      ""

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

    # x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    y_axis = new Rickshaw.Graph.Axis.Y(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)
    @graph.render()


  @accessor 'arrow', ->
    if @get('last')
      if parseFloat(@get('current')) > parseFloat(@get('last')) then 'icon-arrow-up' else if parseFloat(@get('current')) < parseFloat(@get('last')) then 'icon-arrow-down' else 'icon-check'

  mixin: (data) ->
    if data?
      @updateColor(data)
    super data

  onData: (data) ->
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
      @updateColor(data)


  updateColor: (data) ->
    if data.current?
      node = $(@node)
      currentVal = parseFloat data.current
      cool = parseFloat node.data "cool"
      warm = parseFloat node.data "warm"
      if warm >= cool
        level = switch
          when currentVal <= cool then 0
          when currentVal >= warm then 4
          else 1
      else
        level = switch
          when currentVal >= cool then 0
          when currentVal <= warm then 2
          else  1
      backgroundClass = "hotfloat#{level}"
      lastClass = @get "lastClass"
      node.toggleClass "#{lastClass} #{backgroundClass}"
      @set "lastClass", backgroundClass

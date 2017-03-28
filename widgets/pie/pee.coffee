class Dashing.Pie extends Dashing.Widget
  @accessor 'value'

  onData: (data) ->
    @render(data)
    # console.log data

  render: (data) ->
    if(data)
      data = data.value
      values = data.values
    if !data or !data.value
      data = @get("value")
      values = @get("values")
    if(!data)
        return

    width = 320
    height = 320
    radius = 160
    label_radius = 158
    color = d3.scale.category20()

    $(@node).children("svg").remove();

    chart = d3.select(@node).append("svg:svg")
        .data([data])
        .attr("width", width)
        .attr("height", height)
        .append("svg:g")
        .attr("transform", "translate(#{radius} , #{radius})")

    #
    # Center label
    #
    label_group = chart.append("svg:g")
      .attr("dy", ".35em")

    center_label = label_group.append("svg:text")
      .attr("class", "chart_label")
      .attr("text-anchor", "middle")
      .attr("fill", "white")
      .text(@get("title"))

    arc = d3.svg.arc().innerRadius(radius * .6).outerRadius(radius)
    pie = d3.layout.pie().value((d) -> d.value)

    arcs = chart.selectAll("g.slice")
      .data(pie)
      .enter()
      .append("svg:g")
      .attr("class", "slice")

    arcs.append("svg:path")
      .attr("fill", (d, i) -> color(i))
      .attr("d", arc)

    #
    # Legend
    #
    legend = d3.select(@node).append("svg:svg")
      .attr("class", "legend")
      .attr("x", 0)
      .attr("y", 0)
      .attr("height", 160)
      .attr("width", 240)

    legend.selectAll("g").data(data)
      .enter()
      .append("g")
      .each((d, i) ->
        g = d3.select(this)

        row = i % 6
        col = parseInt(i / 6)

        decalage = 0
        if values
          decalage = 20
          g.append("text")
            .attr("x", (col * 50) + 15)
            .attr("y", (row + 1) * 15 - 6 + 15)
            .attr("font-size", "14px")
            .attr("fill", "white")
            .attr("height", 10)
            .attr("text-anchor", "end")
            .attr("width", 30)
            .text(data[i].value)

        g.append("rect")
          .attr("x", col * 50 + decalage )
          .attr("y", row * 15 + 15)
          .attr("width", 10)
          .attr("height", 10)
          .attr("fill", color(i))

        console.log "wat"
        g.append("text")
          .attr("x", (col * 50) + 15 + decalage)
          .attr("y", (row + 1) * 15 - 6 + 15)
          .attr("font-size", "14px")
          .attr("fill", "white")
          .attr("height", 30)
          .attr("width", 75)
          .text(data[i].label)
      )

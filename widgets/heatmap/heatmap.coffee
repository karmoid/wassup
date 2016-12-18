class Dashing.Heatmap extends Dashing.Widget
	ready: ->
		# Maximum number of jobs that can be scheduled for a later minute
		# Used to adjust the heatmap color range
		# A minute having @maxJobPerMinute or more scheduled jobs will be the brightest
		@maxJobPerMinute = 20

		# --

		@calheatmap = new CalHeatMap();

		heatmapcontainer = $(@node).append('<div id="my-heatmap"></div>')
		legendStep = Math.round(@maxJobPerMinute/5);

		now = new Date()
		@startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours()).getTime()

		@calheatmap.init({
			itemSelector: "#my-heatmap",
			start: new Date()-(60*60*1000*4),
			domain: @get("domain"),
			subDomain: @get("subdomain"),
			range: 5,
			cellSize: 10,
			domainGutter: 5,
			legend: d3.range(legendStep, @maxJobPerMinute + legendStep, legendStep),
			displayLegend: false,
			itemName: "incident",
			subDomainDateFormat: "%H:%M",
			subDomainTitleFormat: {
				empty: "no incident for {date}",
				filled: "{count} incidents for {date}"
			}
			label: {
				height: 50
			}
		})

	onData: (data) ->
		if @calheatmap
			# Shift the calendar by one hour when the Time has come
			diff = 60 * 60 * 1000
			if (+Date.now() - @startDate) >= diff
				@calheatmap.next()
				@startDate += diff

			@calheatmap.update(data.items)

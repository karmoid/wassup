current_valuation = 0
current_karma = 0
tendance_stack = []
current_tendance = 0
tendance_inc = 10
tendance_max = 40
sens = 1


def get_scheduled_jobs
	t = Time.now
  endTime = Time.new(t.year, t.month, t.day, t.hour)
	startTime = endTime - (60 * 60 * 4) # Get stats for the next 5 hours
	@buffer ||=
	{
			"#{startTime.to_i}": 10,
			"#{startTime.to_i+600}": 20,
			"#{startTime.to_i+1200}": 10,
			"#{startTime.to_i+1260}": 25,
			"#{startTime.to_i+1320}": 1
	}
	@buffer["#{Time.new.to_i}"] = rand(15)
	return @buffer
end

SCHEDULER.every '30s' do
  last_valuation = current_valuation
  last_karma     = current_karma
  current_valuation = rand(100)
  current_karma     = rand(200000)

  last_tendance = current_tendance
  current_tendance = last_tendance + rand(tendance_inc)*sens

  if current_tendance > tendance_max
    sens = -1
  end

  if current_tendance < 0
    current_tendance = 0
    sens = 1
  end
  tendance_stack << {x: Time.now.to_i, y: current_tendance}
  tendance_stack.shift if (tendance_stack.length > 18)

  send_event('valuation', { current: current_valuation, last: last_valuation })
  send_event('karma', { current: current_karma, last: last_karma })
  send_event('synergy',   { value: rand(100) })
  send_event("Tendance", { current: current_tendance, last: last_tendance, points: tendance_stack } )

	# items =  get_scheduled_jobs
	# puts items.inspect
  # send_event('inc-heatmap', { items: items })
end

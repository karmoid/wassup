require "time"

SCHEDULER.every '15m', :first_in => 0 do |job|

	snow_req = ServicenowHelper::Requester.new

	current_date = DateTime.now-334
	curr = DateTime.new(current_date.year,current_date.month,1)
	backlog_groups = []
	(1..12).to_a.reverse.each do |week|
	  next_month = curr+32
	  next_month = DateTime.new(next_month.year,next_month.month,1)
	  snow_req.add_date_filter("sys_created_on",curr,next_month-(1.0/(24*60*60)))
		result = snow_req.execute_qy(:agregate,"incident_by_months_last_year")
		res = eval(result.body)
	  # puts "#{curr} to #{next_month} -> #{res[:result][:stats][:count].to_i}"
		backlog_groups << {x: Time.parse(curr.to_s).to_i, y: res[:result][:stats][:count].to_i}
	  curr=next_month
	end
	# puts backlog_groups.inspect
	send_event("snow-13-backlog", points: backlog_groups )


	# Données Dashboard Service Delivery - Backlog full
  backlog_groups = []
  result = snow_req.execute_qy(:agregate,"backlog_full")
  res = eval(result.body)
  # puts "#{res.inspect}"
	i = 0
  res[:result].each do |res_item|
    stats = res_item[:stats][:count].to_i
    group_by = res_item[:groupby_fields].first[:value]
    # puts "(#{i} - stats=#{stats.inspect} & group_by=#{group_by.inspect}"
    backlog_groups << {x: i, y: stats}
		i += 1
  end
  # puts backlog_groups.inspect
	send_event("snow-14-backlog", points: backlog_groups )

	# result = snow_req.execute_qy(:table,"backlog_details")
	# res = eval(result.body)
	# puts res.inspect

	# Données Dashboard Service Delivery - Backlog Service Delivery
  backlog_groups = []
  result = snow_req.execute_qy(:agregate,"incident_serv_deliv_backlog")
  res = eval(result.body)
  # puts "#{res.inspect}"

  res[:result].each do |res_item|
    stats = res_item[:stats][:count].to_i
    group_by = res_item[:groupby_fields].first[:value]
    # puts "stats=#{stats.inspect} & group_by=#{group_by.inspect}"
		grpfields = /BKFR-(.*)$/.match(group_by)
		# puts cmdfields.inspect
		grpfields = [group_by,group_by] if grpfields.nil?
		puts grpfields.inspect
    backlog_groups << {label: grpfields[1], value: stats}
  end
  # puts "IT PIE: #{backlog_groups.inspect}"

	send_event("snow-15-backlog", value: backlog_groups )

  # Données Dashboard Service Delivery - Volume annuel par mois
  current_date = DateTime.now-6
  curr = DateTime.new(current_date.year,current_date.month,current_date.day)
  backlog_groups = []
  (1..7).to_a.reverse.each do |day|
    next_day = curr+1
    snow_req.add_date_filter("sys_created_on",curr,next_day-(1.0/(24*60*60)))
    # puts snow_req.debug_qy(:agregate,"incident_serv_deliv_backlog")
    result = snow_req.execute_qy(:agregate,"incident_by_months_last_year")
    res = eval(result.body)
    # puts "#{curr} to #{next_day} -> #{res[:result][:stats][:count].to_i}"
    backlog_groups << {x: Time.parse(curr.to_s).to_i, y: res[:result][:stats][:count].to_i}
    curr=next_day
  end
  puts backlog_groups.inspect
	send_event("snow-16-backlog", points: backlog_groups )

end

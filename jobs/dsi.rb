
SCHEDULER.every '5m', :first_in => 0 do |job|

	snow_req = ServicenowHelper::Requester.new

	current_date = DateTime.now-365
	curr = DateTime.new(current_date.year,current_date.month,1)
	(1..12).to_a.reverse.each do |week|
	  next_month = curr+32
	  next_month = DateTime.new(next_month.year,next_month.month,1)
	  snow_req.add_date_filter("sys_created_on",curr,next_month-(1.0/(24*60*60)))
		result = snow_req.execute_qy(:agregate,"incident_by_months_last_year")
	  puts result.to_str
		puts result.body.inspect
		puts Psych.parse(result.body).to_json.inspect
	  curr=next_month
		exit
	end
end

require "time"

unassigned_hist = []
unassigned_last = unassigned_curr = 0

vip_hist = []
vip_last = vip_curr = 0

SCHEDULER.every '5m', :first_in => 0 do |job|

	snow_req = ServicenowHelper::Requester.new

	# Données Dashboard EUS Service - Backlog EUS
  result = snow_req.execute_qy(:table,"backlog_eus")
  res = eval(result.body)
  # puts "#{res.inspect}"

  tweets = res[:result].map do |row|
    {status: row[:priority],
      created_on: row[:sys_created_on],
      updated_on: row[:sys_updated_on],
      month: Time.parse(row[:sys_created_on]).strftime('01-%m-%Y')
    }
  end
  # puts tweets.inspect
  grouped = tweets.group_by {|t| t[:month]}
  keys = grouped.keys # => ["food", "drink"]
  arrUsed = keys.map {|k| [Time.parse(k),
                           grouped[k].reduce(0) {|t,h| t+1 }
                           ]}.sort { |x,y| x[0] <=> y[0] }
  # puts arrUsed.inspect

  backlog_groups = []

  arrUsed.each { |backlog|
    backlog_groups << {x: backlog[0].to_i, y: backlog[1]}
  }

  # puts backlog_groups.inspect
  send_event("snow-inc-eus-backlog", points: backlog_groups )

  hrows = [
    { cols: [ {value: 'SEV'}, {value: 'Site'}, {value: 'catégorie'}, {value: 'sous-categ'}, {value: 'statut'}, {value: 'Composant'}, {value: 'Quand'} ] }
  ]
  rows = []
  [1,2].each do |i|
    # Données Dashboard EUS Service - Incident SEV 2
    result = snow_req.execute_qy(:table,"eus_sev#{i}")
    res = eval(result.body)
		# puts res.inspect

    rows += res[:result].map do |row|
      ts = Time.parse(row[:sys_created_on])
      # tstxt = "il y a"
      ts = Time.now - ts
      { cols: [ {value: i.to_s}, {value: snow_req.display_value(row[:location])}, {value: row[:category]}, {value: row[:subcategory]}, {value: row[:state]}, {value: snow_req.display_value(row[:cmdb_ci])}, {value: humanizeJH(ts)} ]}
    end
  end

  send_event("eus-sev12", { hrows: hrows, rows: rows.take(8) } )

# eus_sev1
# eus_sev2
end

require 'csv'
require 'open-uri'
require 'nokogiri'

SCHEDULER.every '5m', :first_in => 0 do |job|
  begin
    # puts "execute getincidents.sh avec bash"
    # puts system('bash ./getincidents.sh') ? "Run OK" : "KO!"
    # config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    # config = YAML::load(File.open(config_file))
    # command = config["cmd_i"]
    # system(command)

    username = ENV["uname"]
    password=ENV["pwd"]

    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-FCT_TELETRANS%5EpriorityIN1%2C2%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart(5)&CSV"

    (open(url, :http_basic_authentication => [username, password]))

    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

    # page.xpath("/html/body/p").each do |line|
    #   puts ">> [#{line}]"
    # end

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], where: row[:location], when: tstxt + " " + humanize(ts) }
    end
    # puts tweets.inspect
  send_event('snow-inc-dfo', incidents: tweets)



  url = "https://brinkslatam.service-now.com/change_request_list.do?sysparm_query=active%3Dtrue%5EstateIN14%2C15%2C13%2C10%5Elocation.country%3DFrance%5Erequested_by_dateBETWEENjavascript%3Ags.daysAgoStart(#{MAX_CHG_OVERDUE})%40javascript%3Ags.daysAgoEnd(#{-1*MAX_CHG_AWAY})%5Eassignment_group%3D05ba4d3e6faaf9403a4d508e5d3ee479&CSV"

  (open(url, :http_basic_authentication => [username, password]))
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

  changes = []
  today = Date.today
  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    ts = Time.parse(row[:requested_by_date])
    if Time.now > ts
      tstxt = "il y a"
      ts = Time.now - ts
    else
      tstxt = "dans"
      ts = ts - Time.now
    end
    days_away = (Date.parse(row[:requested_by_date]) - today).to_i
    changes << {"name" => row[:short_description][0..40], "date" => Time.parse(row[:requested_by_date]).strftime('%b %-d, %Y'), "state" => row[:state], "background" => state_to_color(row[:state])}
    { number: row[:number], name: row[:state], body: row[:short_description], when: tstxt + " " + humanize(ts) }
  end
  timechanges = {"events" => changes}
  # puts e.to_yaml

  # File.open("timeline_data.yml", "w") { |file| file.write timechanges.to_yaml }
  send_event('snow-chg-dfo', changes: tweets)

  unless timechanges["events"].nil?
    events =  Array.new
    today = Date.today
    no_event_today = true
    timechanges["events"].each do |event|
      # puts event.inspect
      days_away = (Date.parse(event["date"]) - today).to_i
      if (days_away >= 0) && (days_away <= MAX_CHG_AWAY)
        events << {
          name: event["name"],
          date: event["date"],
          background: event["background"]
        }
        # puts event["date"] + " positif donne " + days_away.to_s + "days_away"
      elsif (days_away < 0) && (days_away.abs <= MAX_CHG_OVERDUE)
        events << {
          name: event["name"],
          date: event["date"],
          background: event["background"],
          opacity: 0.5
        }
        # puts event["date"] + " negatif donne " + days_away.to_s + "days_away"
      end

      no_event_today = false if days_away == 0
    end

    if no_event_today
      events << {
        name: "TODAY",
        date: today.strftime('%a %d %b %Y'),
        background: "gold"
      }
    end

    send_event("dfo_timeline", {events: events})
  else
    puts "No events found :("
  end

  [1,2].each {|i|
    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-FCT_TELETRANS%5Epriority%3D#{i.to_s}%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart(2)%5EcategoryINfr_access%2Cfr_office_software%2Cfr_business_application%2Cfr_hardware%2Cfr_messaging%2Cfr_mobility%2Cfr_network%2Cfr_security%2Cfr_system&CSV"
    # puts url
    (open(url, :http_basic_authentication => [username, password]))
    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], categ: row[:category] + ", "+ row[:subcategory], body: row[:short_description], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:site]}
    keys = grouped.keys # => ["food", "drink"]

    arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t + 1}]}
      # => [["food", 110], ["drink", 12]]

    tasks = []
    arr.sort { |a, b| a[1] <=> b[1] }.reverse.each do |t|
      # puts t.inspect
      tasks << {
            name: t[0],
            date: Date.today,
            priority: 1,
            formatted_date: t[1].to_s
          }
    end

    max_items = 10
    send_event "snow-indfo-site-#{i.to_s}", { items: tasks.take(max_items) }




    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], categ: row[:category], subcateg: row[:subcategory], body: row[:short_description], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:subcateg]}
    keys = grouped.keys # => ["food", "drink"]

    arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t + 1}]}
      # => [["food", 110], ["drink", 12]]

    tasks = []
    arr.sort { |a, b| a[1] <=> b[1] }.reverse.each do |t|
      # puts t.inspect
      tasks << {
            name: t[0],
            date: Date.today,
            priority: 1,
            formatted_date: t[1].to_s
          }
    end

    max_items = 10
    send_event "snow-indfo-categ-#{i.to_s}", { items: tasks.take(max_items) }


    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], ci: row[:cmdb_ci], body: row[:short_description], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:ci]}
    keys = grouped.keys # => ["food", "drink"]

    arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t + 1}]}
      # => [["food", 110], ["drink", 12]]

    tasks = []
    arr.sort { |a, b| a[1] <=> b[1] }.reverse.each do |t|
      # puts t.inspect
      tasks << {
            name: t[0],
            date: Date.today,
            priority: 1,
            formatted_date: t[1].to_s
          }
    end

    max_items = 10
    send_event "snow-indfo-ci-#{i.to_s}", { items: tasks.take(max_items) }

  }





















  end
end

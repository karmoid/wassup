require 'csv'
require 'open-uri'
require 'nokogiri'

MAX_CHG_OVERDUE = 15
MAX_CHG_AWAY = 15

# config_file = File.dirname(File.expand_path(__FILE__)) + '/../timeline_data.yml'
SCHEDULER.every '15m', :first_in => 0 do |job|
  begin
    # puts "execute getchanges.sh avec bash"
    # puts system('bash ./getchanges.sh') ? "Run OK" : "KO!"
    # config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    # config = YAML::load(File.open(config_file))
    # command = config["cmd_c"]
    # system(command)

    # page.xpath("/html/body/p").each do |line|
    #   puts ">> [#{line}]"
    # end
    url = "https://brinkslatam.service-now.com/change_request_list.do?sysparm_query=active%3Dtrue%5EstateIN14%2C15%2C13%2C10%5Elocation.country%3DFrance%5Erequested_by_dateBETWEENjavascript%3Ags.daysAgoStart(#{MAX_CHG_OVERDUE})%40javascript%3Ags.daysAgoEnd(#{-1*MAX_CHG_AWAY})&CSV"

    username = ENV["uname"]
    password=ENV["pwd"]

    #(open(url, :http_basic_authentication => [username, password]))

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
    send_event('change_mentions', changes: tweets)

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

      send_event("ags_timeline", {events: events})
    else
      puts "No events found :("
    end
  end
end

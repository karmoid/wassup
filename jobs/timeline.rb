MAX_DAYS_OVERDUE = -15
MAX_DAYS_AWAY = 15

config_file = File.dirname(File.expand_path(__FILE__)) + '/../timeline_data.yml'

SCHEDULER.every '15m', :first_in => 0 do |job|
  config = YAML::load(File.open(config_file))
  unless config["events"].nil?
    events =  Array.new
    today = Date.today
    no_event_today = true
    config["events"].each do |event|
      # puts event.inspect
      days_away = (Date.parse(event["date"]) - today).to_i
      if (days_away >= 0) && (days_away <= MAX_DAYS_AWAY) 
        events << {
          name: event["name"],
          date: event["date"],
          background: event["background"]
        }
        # puts event["date"] + " positif donne " + days_away.to_s + "days_away"
      elsif (days_away < 0) && (days_away >= MAX_DAYS_OVERDUE)
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
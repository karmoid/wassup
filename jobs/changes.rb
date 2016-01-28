require 'csv'

def state_to_color(state)
  case state
    when "Open" then ""
    when "Closed Successful" then "lightgreen"
    when "Closed Backed Out" then "red"
    when "Closed Rejected" then "red"
    when "Closed Cancelled" then "red"
    when "Implementation" then "pink"
    when "Classification" then "pink"
    when "Assessment & Planning" then "pink"
    when "SM Review" then "white"
    when "Technical Review" then "white"     
    else "gray"     
  end  
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../timeline_data.yml'
SCHEDULER.every '15m', :first_in => 0 do |job|
  begin
    # puts "execute getchanges.sh avec bash"
    # puts system('bash ./getchanges.sh') ? "Run OK" : "KO!"    
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    config = YAML::load(File.open(config_file))
    command = config["cmd_c"]
    system(command)
    
    changes = []
    today = Date.today
    tweets = CSV.foreach("public/changes.csv", {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:requested_by_date])
      if Time.now > ts 
        tstxt = "il y a"
        ts = Time.now - ts
      else
        tstxt = "dans"
        ts = ts - Time.now
      end
      days_away = (Date.parse(row[:requested_by_date]) - today).to_i
      if (days_away < 20) && (days_away > -20)
        changes << {"name" => row[:short_description][0..40], "date" => Time.parse(row[:requested_by_date]).strftime('%b %-d, %Y'), "state" => row[:state], "background" => state_to_color(row[:state])}
      end  
        { number: row[:number], name: row[:state], body: row[:short_description], when: tstxt + " " + humanize(ts) }
    end
    timechanges = {"events" => changes}
    # puts e.to_yaml
    File.open("timeline_data.yml", "w") { |file| file.write timechanges.to_yaml }
    send_event('change_mentions', changes: tweets)
  end
end
# widget configuration

SCHEDULER.every '3h', :first_in => 0 do |job|
  begin
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/contacts.yml'
    config = YAML::load(File.open(config_file))

    contacts = []

    if config["contacts"].nil?
      puts "No Contact found"
    else
      config["contacts"].each_pair do |data_id, query_config|
        # puts data_id + " -> " + query_config.inspect
        contacts << {
              name: query_config["name"],
              date: Date.today,
              priority: query_config["priority"],
              formatted_date: query_config["tel"]
            }
      end
    end

    max_items = 5
    send_event "contacts", { items: contacts.take(max_items) }
  end
end

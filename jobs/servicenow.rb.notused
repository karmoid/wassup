require 'rs_service_now'

def update_count(sn, table, query)
  result = sn._request table, query
  result.count
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/servicenow.yml'
config_sec = YAML::load(File.open(config_file))
puts config_sec.inspect

SCHEDULER.every("10m", first_in: '1s') do

  instance = config_sec["instance"]
  proxy = config_sec["proxy"]
  username = config_sec["user"]
  password = config_sec["password"]

  config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/servicenow.yml'
  config = YAML::load(File.open(config_file))
  puts config.inspect

  sn = RsServiceNow::Record.new(username, password, instance, proxy)
  if config["queries"].nil?
    puts "No Service-Now queries found"
  else
    config["queries"].each_pair do |data_id, query_config|
      puts "send event #{data_id} on table #{query_config['table']}"
      send_event(data_id, { value: update_count(sn, query_config["table"], query_config["query"])})
    end
  end
end

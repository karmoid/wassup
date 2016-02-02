require 'rs_service_now'

def update_count(sn, table, query)
  result = sn._request table, query
  result.count
end

SCHEDULER.every("10m", first_in: '1s') do
  config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/servicenow.yml'
  config = YAML::load(File.open(config_file))

  instance = config["instance"]
  proxy = config["proxy"]
  username = config["user"]
  password = config["password"]

  config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/servicenow.yml'
  config = YAML::load(File.open(config_file))

  sn = RsServiceNow::Record.new(username, password, instance, proxy)
  if config["queries"].nil?
    puts "No Service-Now queries found"
  else
    config["queries"].each_pair do |data_id, query_config|
      send_event(data_id, { value: update_count(sn, query_config["table"], query_config["query"])})
    end
  end
end

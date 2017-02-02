  require 'bundler/setup'
  require 'nagiosharder'

# second pass
SCHEDULER.every "5m", :first_in => 1 do
  config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/nagios.yml'
  config = YAML::load(File.open(config_file))

  environments = {}

  if config["hosts"].nil?
    puts "No Nagios-Host found"
  else
    config["hosts"].each_pair do |host_id, query_config|
      environments[host_id] = {url: query_config["nagios_url"], username: query_config["user"], password: query_config["password"], timef: query_config["time"]}
    end
  end

  environments.each do |key, env|
    nag = NagiosHarder::Site.new(env[:url], env[:username], env[:password], 3, 'us', true)

    host_groups = ["GRP_Darwin","GRP_EMS"]


    host_groups.each {|hg|
      n = nag.hostgroups_summary(hg)
      tasks = []
      # puts n.inspect
      tasks << {name: "Hôtes", priority: 4, date: Date.today, formatted_date: "ETAT" }
      tasks << {name: "Opérationnel", priority: 3, date: Date.today, formatted_date: n[hg]["host_status_counts"]["up"] }
      tasks << {name: "Indisponible", priority: 1, date: Date.today, formatted_date: n[hg]["host_status_counts"]["down"] }
      tasks << {name: "", priority: 4, date: Date.today, formatted_date: "" }
      tasks << {name: "Services", priority: 4, date: Date.today, formatted_date: "ETAT" }
      tasks << {name: "Opérationnel", priority: 3, date: Date.today, formatted_date: n[hg]["service_status_counts"]["ok"] }
      tasks << {name: "Critiques", priority: 1, date: Date.today, formatted_date: n[hg]["service_status_counts"]["critical"] }
      tasks << {name: "Avertissement", priority: 2, date: Date.today, formatted_date: n[hg]["service_status_counts"]["warning"] }
      # puts tasks.inspect
      max_items = 10
      send_event "nagios-#{key.downcase}-#{hg.downcase}", { items: tasks.take(max_items) }

      # tasks << {name: hg, priority: 1, date: Date.today, formatted_date: "Services #{n['service_status_counts']['ok']}"}
      # (tasks << {name: hg, priority: 2, date: Date.today, formatted_date: "Critical #{n['host_status_counts']['critical']}"}) unless n["service_status_counts"]["critical"] = 0
    }

  end

end

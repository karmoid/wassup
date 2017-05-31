require 'csv'
require "http"
require 'open-uri'
require 'nokogiri'
require 'openssl'

# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

high_stats = {devices: [], max_binaries: []}
intermediate_stats = {devices: [], max_binaries: []}
devices_updated = {devices: [], updates: [], max_updates: []}

cfg = NexthinkHelper::Config.new

start_time = Time.now

SCHEDULER.every '1h', :first_in =>  0 do |job|
  begin
    iteration_time = Time.now

    c = cfg.get_values( "version5", "recent_updates" )

    # puts c.inspect
    hrows = [
      { cols: [ {value: 'Entité'}, {value: '# Devices'} ] }
    ]
    rows = c["update_by_site"].sort {|a,b| b[1]<=>a[1] }.take(6).map {|dl|
      { cols: [ {value: dl[0] }, {value: dl[1] } ]}
    }
    send_event('updates-entities', { hrows: hrows, rows: rows } )

    devices_updated[:devices]  << { x: iteration_time.to_i, y: c["device_updated"].to_i }
    devices_updated[:devices].shift if (devices_updated[:devices].length > 9)

    send_event("updated-devices", points: devices_updated[:devices])

    devices_updated[:updates]  << { x: iteration_time.to_i, y: c["updates"].to_i }
    devices_updated[:updates].shift if (devices_updated[:updates].length > 9)

    send_event("updates-total", points: devices_updated[:updates])

    devices_updated[:max_updates]  << { x: iteration_time.to_i, y: c["max_updates"].to_i }
    devices_updated[:max_updates].shift if (devices_updated[:max_updates].length > 9)

    send_event("max_updates-total", points: devices_updated[:max_updates])

    iteration_time = Time.now

    c = cfg.get_values( "version5", "allos" )

    # puts c.inspect
    max_items = 10
    tasks = c["os_count"].sort {|a,b| b[1]<=>a[1] }.map {|dl|
      { name: dl[0],
        date: Date.today,
        priority: 1,
        formatted_date: dl[1].to_s
        }
    }
    send_event "os-count", { items: tasks.take(max_items) }

    c = cfg.get_values( "version5", "high_threat" )
    # puts c.inspect

    high_stats[:devices]  << { x: iteration_time.to_i, y: c["devices"].to_i }
    high_stats[:devices].shift if (high_stats[:devices].length > 9)

    # puts high_stats[:devices]
    send_event("threats-h-devices", points: high_stats[:devices])

    high_stats[:max_binaries]  << { x: iteration_time.to_i, y: c["max_threats"].to_i }
    high_stats[:max_binaries].shift if (high_stats[:max_binaries].length > 9)

    # puts horus_stats[:quality].inspect
    send_event("threats-h-binaries", points: high_stats[:max_binaries])

    hrows = [
      { cols: [ {value: 'Device name'}, {value: 'Entité'}, {value: '# Threats'} ] }
    ]
    rows = c["device_list"].sort {|a,b| b["number_of_binaries"]<=>a["number_of_binaries"] }.take(5).map {|dl|
      { cols: [ {value: dl["name"]}, {value: dl["entity"] }, {value: dl["number_of_binaries"] } ]}
    }
    send_event('threats-devices', { hrows: hrows, rows: rows } )

    c = cfg.get_values( "version5", "intermediate_threat" )
    # puts c.inspect

    intermediate_stats[:devices]  << { x: iteration_time.to_i, y: c["devices"].to_i }
    intermediate_stats[:devices].shift if (intermediate_stats[:devices].length > 9)

    send_event("threats-i-devices", points: intermediate_stats[:devices])

    intermediate_stats[:max_binaries]  << { x: iteration_time.to_i, y: c["max_threats"].to_i }
    intermediate_stats[:max_binaries].shift if (intermediate_stats[:max_binaries].length > 9)

    send_event("threats-i-binaries", points: intermediate_stats[:max_binaries])

    c = cfg.get_values( "version5", "dangerous_binary_exec" )
    # puts c.inspect

    hrows = [
      { cols: [ {value: 'Device name'}, {value: 'Entité'}, {value: 'User'} ] }
    ]
    rows = c["device_list"].take(5).map {|dl|
      { cols: [ {value: dl["name"]}, {value: dl["entity"] }, {value: dl["last_logged_on_user"]}]  }
    }
    send_event('threats-score', { hrows: hrows, rows: rows } )

    c = cfg.get_values( "version5", "disks_smart_index" )
    # puts @vcenter.inspect
  	nb_vm = c["device_list"].size
		items = c["device_list"].take(10).map do |dl|
      index = dl["disks_smart_index"].to_f
			{
				name: dl["name"],
				date: Date.today,
				priority: index<=0.2 ? 1 : 2,
				formatted_date: (index*100).to_s+"%"
			}
		end
		send_event "SMART-disk", { items: items, current: "#{nb_vm} Poste#{nb_vm>1 ? 's' : ''}"}
   end
end

require 'csv'
require "http"
require 'open-uri'
require 'nokogiri'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

high_stats = {devices: [], max_binaries: []}
intermediate_stats = {devices: [], max_binaries: []}
cfg = NexthinkHelper::Config.new

start_time = Time.now

SCHEDULER.every '1h', :first_in =>  0 do |job|
  begin
    iteration_time = Time.now

    c = cfg.get_values( "version5", "high_threat" )
    # puts c.inspect
    high_stats[:devices]  << { x: iteration_time.to_i, y: c["devices"].to_i }
    high_stats[:devices].shift if (high_stats[:devices].length > 9)

    # puts horus_stats[:quality].inspect
    send_event("threats-h-devices", points: high_stats[:devices])

    high_stats[:max_binaries]  << { x: iteration_time.to_i, y: c["max_threats"].to_i }
    high_stats[:max_binaries].shift if (high_stats[:max_binaries].length > 9)

    # puts horus_stats[:quality].inspect
    send_event("threats-h-binaries", points: high_stats[:max_binaries])

    # puts c["device_list"].inspect

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

    # puts horus_stats[:quality].inspect
    send_event("threats-i-devices", points: intermediate_stats[:devices])

    intermediate_stats[:max_binaries]  << { x: iteration_time.to_i, y: c["max_threats"].to_i }
    intermediate_stats[:max_binaries].shift if (intermediate_stats[:max_binaries].length > 9)

    # puts horus_stats[:quality].inspect
    send_event("threats-i-binaries", points: intermediate_stats[:max_binaries])

   end
end

require 'csv'
require "http"
require 'open-uri'
require 'nokogiri'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

horus_stats = {quality: [], count: [], availability: []}
darwin_stats = {quality: [], count: [], availability: []}
darwin_avail = {low: [], medium: []}

cfg = NexthinkHelper::Config.new

start_time = Time.now

SCHEDULER.every '5m', :first_in =>  0 do |job|
  begin
    iteration_time = Time.now

    c = cfg.get_values( "version5", "horusquality" )
    # puts c.inspect
    horus_stats[:quality]  << { x: iteration_time.to_i, y: c["availability2"].to_i / 1000 }
    horus_stats[:quality].shift if (horus_stats[:quality].length > 9)

    # puts horus_stats[:quality].inspect
    send_event("drwevol-quality", points: horus_stats[:quality])

    horus_stats[:count]  << { x: iteration_time.to_i, y: c["count"].to_i }
    horus_stats[:count].shift if (horus_stats[:count].length > 9)

    # puts horus_stats[:count].inspect
    send_event("drwevol-count", points: horus_stats[:count])

    # puts c["netavailability"].inspect

    count = c["count"].to_i
    high_count = c["netavailability"]["high"].nil? ? 0 : c["netavailability"]["high"]

    send_event("drwevol-availability", value: high_count * 100 / count)

    c = cfg.get_values( "version5", "darwinquality" )
    # puts c.inspect
    darwin_stats[:quality]  << { x: iteration_time.to_i, y: c["availability2"].to_i / 1000 }
    darwin_stats[:quality].shift if (darwin_stats[:quality].length > 9)

    # puts darwin_stats[:quality].inspect
    send_event("darwin-quality", points: darwin_stats[:quality])

    darwin_stats[:count]  << { x: iteration_time.to_i, y: c["count"].to_i }
    darwin_stats[:count].shift if (darwin_stats[:count].length > 9)

    # puts darwin_stats[:count].inspect
    send_event("darwin-count", points: darwin_stats[:count])

    # puts c["netavailability"].inspect
    count = c["count"].to_i
    high_count = c["netavailability"]["high"].nil? ? 0 : c["netavailability"]["high"]

    send_event("darwin-availability", value: (high_count * 100 / count))

    c = cfg.get_values( "version5", "cash_availability" )

    # puts c["servers"].inspect

    darwin_avail[:low]  << { x: iteration_time.to_i, y: c["servers"]["low"] }
    darwin_avail[:low].shift if (darwin_avail[:low].length > 9)

    send_event("darwin-low", points: darwin_avail[:low])

    darwin_avail[:medium]  << { x: iteration_time.to_i, y: c["servers"]["medium"] }
    darwin_avail[:medium].shift if (darwin_avail[:medium].length > 9)

    # puts darwin_stats[:count].inspect²
    send_event("darwin-medium", points: darwin_avail[:medium])

    # puts c["sites"].inspect

    hrows = [
      { cols: [ {value: 'Site'}, {value: 'Disponibilité'} ] }
    ]
    rows = c["sites"].take(5).map {|dl|
      { cols: [ {value: dl["server_location"]}, {value: dl["network_availability_level"] } ]}
    }
    send_event('server-low', { hrows: hrows, rows: rows } )



   end
end

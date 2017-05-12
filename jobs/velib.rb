#!/usr/bin/env ruby

require 'net/https'
require 'json'

## Velib API key to get on JC Decaux dev website
## more infos : https://developer.jcdecaux.com/
## --
API_KEY = ENV["JCDECAUX_API_KEY"]

## Stations to retrieve
## --
stations = {
  'victoire' => '9111',
  'taitbout' => '9025',
}

## Job itself
## --
SCHEDULER.every '2m', :first_in => 0 do |job|
  # Define keys if not defined
  API_KEY = '' unless defined?(API_KEY)

  stations.each do |station,station_id|
    begin
      # url = "https://api.jcdecaux.com/vls/v1/stations/#{station_id}?contract=Paris&apiKey=#{API_KEY}"
      # puts url
      # response = HTTParty.get(url)
      # datas = JSON.parse(response.body)

      http = Net::HTTP.new("api.jcdecaux.com", 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      puts "/vls/v1/stations/#{station_id}?contract=Paris&apiKey=#{API_KEY}"
      response = http.request(Net::HTTP::Get.new("/vls/v1/stations/#{station_id}?contract=Paris&apiKey=#{API_KEY}"))
      datas = JSON.parse(response.body)

      station_name = datas['name'].partition('- ').last
      status = datas['status']
      total_stands = datas['bike_stands']
      available_stands = datas['available_bike_stands']
      available_bikes = datas['available_bikes']

      if not defined?(send_event)
        puts "#------------------------------------------------------------#"
        puts "Station name     : #{station_name}"
        puts "Status           : #{status}"
        puts "Total stands     : #{total_stands}"
        puts "Available stands : #{available_stands}"
        puts "Available bikes  : #{available_bikes}"
        puts "#------------------------------------------------------------#"
      else
        title = 'velib-'+station.to_s
        send_event(title, station: station_name, state: status, bikes_available: available_bikes, stands_available: available_stands)
      end

    rescue
      puts response.body
      puts "Something went wrong ... Could not fetch the informations."
    end
  end

end

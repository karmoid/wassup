require 'csv'
require "http"
require 'open-uri'
require 'nokogiri'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  nexthinkvalues = {
  "laptop" => {used_space: [], count: [], last_x: 0},
  "desktop" => {used_space: [], count: [], last_x: 0},
  "unknown" => {used_space: [], count: [], last_x: 0}
  }

  nexthink_groups = {}

nexthinkvalues.each { |k,nv|
  # puts k + "," + nv.inspect
  (1..10).each do |i|
    nv[:used_space] << { x: i, y: 0 }
    nv[:count] << { x: i, y: 0 }
  end
  nv[:last_x] = nv[:used_space].last[:x]
}

SCHEDULER.every '10m', :first_in =>  '5s' do |job|
  begin

  if false
      username = ENV["nname"]
      password=ENV["npwd"]

      query_prefix = "https://frmonnxthnk03.emea.brinksgbl.com:1671/2"
      query = "/query?query=(select (name distinguished_name total_drive_capacity total_drive_free_space total_drive_usage first_seen last_seen device_type total_ram number_of_days_since_last_boot last_logon_time group_name *entity) (from device (where device (eq #'Source is active' (enum yes))))&format=csv"

      url = URI.parse(URI::encode(query_prefix+query))

      open(url.to_s, :http_basic_authentication => [username, password])
      page = Nokogiri::HTML(open( url.to_s, :http_basic_authentication => [username, password] ))
  else
  #    tweets = CSV.parse(page.children.text, {:col_sep => "\t", :headers => true, :header_converters => :symbol}).map do |row|
    begin
      tweets = CSV.foreach(File.dirname(File.expand_path(__FILE__)) + '/../nexthink-src.csv', {:headers => true, :col_sep => ";", :header_converters => :symbol}).map do |row|
        # puts row.inspect
        {device_type: row[:device_type].nil? ? "unknown" : row[:device_type].downcase,
          group_name: row[:group_name].nil? ? "unknown" : row[:group_name].downcase,
          total_drive_capacity: row[:total_drive_capacity].nil? ? 0 : eval(row[:total_drive_capacity].gsub(",",".")),
          total_drive_free_space: row[:total_drive_free_space].nil? ? 0 : eval(row[:total_drive_free_space].gsub(",","."))}
      end
    rescue CSV::MalformedCSVError
      puts "failed to parse line"
    end
  end
      grouped = tweets.group_by {|t| t[:device_type]}
      keys = grouped.keys # => ["food", "drink"]
      arrUsed = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+h[:total_drive_capacity]-h[:total_drive_free_space] }]}


      # puts tweets.inspect
      #arrUsed.each {|line|
      # puts line.inspect

        arrUsed.each { |usedspace|
          unless nexthinkvalues[usedspace[0]].nil?
            nv = nexthinkvalues[usedspace[0]]
            nv[:used_space].shift
            nv[:last_x] += 5*60
            nv[:used_space] << { x: nv[:last_x], y: usedspace[1] }
            # puts "next-used-#{usedspace[0]}"

            send_event("next-used-#{usedspace[0].downcase}", points: nv[:used_space])
          end
        }
      #}

      # puts tweets.inspect
      #arrTotal.each {|line|
      # puts line.inspect
      arrTotal = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+1 }]}

        arrTotal.each { |count|
          unless nexthinkvalues[count[0]].nil?
            nv = nexthinkvalues[count[0]]
            nv[:count].shift
            nv[:last_x] += 5*60
            nv[:count] << { x: nv[:last_x], y: count[1] }
            # puts "next-sum-#{count[0]}"
            send_event("next-sum-#{count[0].downcase}", points: nv[:count])
          end
        }
      #}


# Cumul par Groupe
      grouped = tweets.group_by {|t| t[:group_name]}
      keys = grouped.keys # => ["food", "drink"]
      arrGrp = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+1}]}


      arrGrp.each { |count|
        nexthink_groups[count[0]] = {count: [], last_x: 0} if nexthink_groups[count[0]].nil?
        grp = nexthink_groups[count[0]]
        grp[:count].shift if (grp[:count].length > 9)
        grp[:last_x] += 5*60
        grp[:count] << { x: grp[:last_x], y: count[1] }
        # puts "next-grp-#{count[0]}"

        send_event("next-grp-#{count[0]}", points: grp[:count])
      }

   end
end

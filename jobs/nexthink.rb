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
    i = {}
    cfg = NexthinkHelper::Config.new
    qy = cfg.get_value("version5","alldrives",i)
    url = URI.parse(URI::encode(qy))

    page = Nokogiri::HTML(open( url.to_s, :http_basic_authentication => [i[:username], i[:pwd]] ))
    tweets = CSV.parse(page.children.text, {:col_sep => "\t", :headers => true, :header_converters => :symbol}).map do |row|
      {device_type: row[:device_type].nil? ? "unknown" : row[:device_type].downcase,
        group_name: row[:group_name].nil? ? "unknown" : row[:group_name].downcase,
        total_drive_capacity: row[:total_drive_capacity].nil? ? 0 : eval(row[:total_drive_capacity].gsub(",",".")),
        total_drive_free_space: row[:total_drive_free_space].nil? ? 0 : eval(row[:total_drive_free_space].gsub(",","."))}
    end
=begin
    puts "! On va faire notre cuisine FORMULA !"
    c = cfg.get_values( "version5", "horusquality" )
    puts "=> On est revenu de notre notre cuisine FORMULA"
    puts c.inspect

    puts "! On va faire notre cuisine FORMULA !"
    c = cfg.get_values( "version5", "darwinquality" )
    puts "=> On est revenu de notre notre cuisine FORMULA"
    puts c.inspect
=end
    grouped = tweets.group_by {|t| t[:device_type]}
    keys = grouped.keys # => ["food", "drink"]
    arrUsed = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+h[:total_drive_capacity]-h[:total_drive_free_space] }]}

    arrUsed.each { |usedspace|
      unless nexthinkvalues[usedspace[0]].nil?
        nv = nexthinkvalues[usedspace[0]]
        nv[:used_space].shift
        nv[:last_x] += 5*60
        nv[:used_space] << { x: nv[:last_x], y: usedspace[1] }

        send_event("next-used-#{usedspace[0].downcase}", points: nv[:used_space])
      end
    }

    arrTotal = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+1 }]}

    arrTotal.each { |count|
      unless nexthinkvalues[count[0]].nil?
        nv = nexthinkvalues[count[0]]
        nv[:count].shift
        nv[:last_x] += 5*60
        nv[:count] << { x: nv[:last_x], y: count[1] }

        send_event("next-sum-#{count[0].downcase}", points: nv[:count])
      end
    }

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

      send_event("next-grp-#{count[0]}", points: grp[:count])
    }

   end
end

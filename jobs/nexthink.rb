require 'csv'
require "http"
require 'open-uri'
require 'nokogiri'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
#SCHEDULER.every '10m', :first_in =>  '5s' do |job|
#  begin

    username = ENV["nname"]
    password=ENV["npwd"]

    query_prefix = "https://frmonnxthnk03.emea.brinksgbl.com:1671/2"
    query = "/query?query=(select (name distinguished_name total_drive_capacity total_drive_free_space total_drive_usage first_seen last_seen device_type total_ram number_of_days_since_last_boot last_logon_time group_name *entity) (from device (where device (eq #'Source is active' (enum yes))))&format=csv"

    url = URI.parse(URI::encode(query_prefix+query))

    open(url.to_s, :http_basic_authentication => [username, password])
    page = Nokogiri::HTML(open( url.to_s, :http_basic_authentication => [username, password] ))

    tweets = CSV.parse(page.children.text, {:col_sep => "\t", :headers => true, :header_converters => :symbol}).map do |row|
      # puts row.inspect
      {device_type: row[:device_type], total_drive_usage: row[:total_drive_usage]}
    end

    grouped = tweets.group_by {|t| t[:device_type]}
    keys = grouped.keys # => ["food", "drink"]
    arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t+(h[:total_drive_usage].nil? ? 0 : h[:total_drive_usage].to_f) }]}

    # puts tweets.inspect
#  end
# end

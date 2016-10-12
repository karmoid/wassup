require 'open-uri'
require 'nokogiri'


class Net::HTTPResponse
  def ensure_success
    unless kind_of? Net::HTTPSuccess
      warn "Request failed with HTTP #{@code}"
      each_header do |h,v|
        warn "#{h} => #{v}"
      end
      # abort
    end
  end
end

def do_request(uri_string)
  response = nil
  tries = 0
  loop do
    uri = URI.parse(uri_string)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri_string.match(/^https/)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
    end
    begin
      # puts uri_string
      request = Net::HTTP::Get.new(uri.request_uri)
      # puts request.inspect
      response = http.request(request)
      # puts response.inspect
      # puts response['location'] if response['location']
      uri_string = response['location'] if response['location']
      test = response.code + " " + response.message
      unless response.kind_of? Net::HTTPRedirection
        # response.ensure_success
        break
      end
      if tries == 10
        puts "Timing out after 10 tries"
        break
      end
      tries += 1
    rescue Timeout::Error => e
      response = nil
    rescue => e
      break
    end
  end
  response
end

SCHEDULER.every '2m', :first_in => 0 do |job|
  begin
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/websites.yml'
    config = YAML::load(File.open(config_file))

    if config["sites"].nil?
      puts "No web site found"
    else
      site_results = []
      config["sites"].each do |site_config|
        url = site_config["url"]
        waitfor = site_config["waitfor"]
        name = site_config["name"]
        maintenance = site_config["maintenance"]

        response = do_request(url)
        if response.nil?
          reply_ok = "to"
          site_results << {label: name, value: reply_ok}
        elsif response.code.to_i <200 || response.code.to_i >= 300
          # puts "Response.code = #{response.code} for #{site["url"]}"
          # puts response.body.inspect
          reply_ok = "ko"
          site_results << {label: name, value: reply_ok}
        else
          # puts "Elapsed time: /#{b - a}/"
          reply_ok = response.body.include?(waitfor) ? "ok" : "ko"
          # puts response.code + " " + response.message
          if reply_ok == "ko" && maintenance
            reply_ok = "mt" if response.body.include?(maintenance)
          end
          site_results << {label: name, value: reply_ok} if reply_ok != "ok"
        end
      end
      send_event('websites', { items: site_results })
    end
  end
end

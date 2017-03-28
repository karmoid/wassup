require 'psych'
require 'base64'
require 'json'
require 'rest_client'

config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/servicenow.sec'
security = Psych.load(File.open(config_file))
config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/servicenow.cfg'
config = Psych.load(File.open(config_file))

@instance = security["instance"]
@proxy = security["proxy"]
@username = security["user"]
@password = security["password"]
nb_hours = 4
@startValue = Time.new.utc-(nb_hours*60*60)
@startDate = @startValue.to_s
@items = {}

def next_load
  # Set the request parameters
  url = "https://#{@instance}.service-now.com/api/now/table/"

  # Eg. User name="admin", Password="admin" for this code sample.

  snowdate = @startDate.to_s.split
  qy = "/incident?sysparm_query=u_service_desk=FRANCE^sys_created_on>javascript:gs.dateGenerate('#{snowdate[0]}','#{snowdate[1]}')&sysparm_fields=sys_created_on"
  # puts "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  # puts qy
  # puts "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  response = RestClient.get("#{url}#{qy}",
                       {:authorization => "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                       :accept => 'application/json'
                       })
  begin
    # puts "Response status: #{response.code}"

    resp = JSON.parse(response)

    mybuffer = resp["result"].inject({}) do |buffer,v|
      v.each do |k,v|
        if !v.empty?
          t1 = Time.parse("#{v} +0000").localtime
          if t1 > @startValue
            @startValue = t1
            @startDate = v
          end
          buffer[t1.to_i.to_s] ||= 0
          buffer[t1.to_i.to_s] += 1
        end
      end
      buffer
    end
    # puts mybuffer.inspect
    # puts "on va merger #{mybuffer.inspect}"
    mybuffer
  rescue => e
    puts "ERROR: #{e}"
  end
end
  # puts "Demarrage à #{@startDate}"
  iter = 0
  SCHEDULER.every '15s', :first_in =>  0 do
    if iter % 8 == 0
      @items.merge!(next_load)
      # puts "#{@items.length} items, maxDate = #{@startDate}"
    else
      # puts "#CACHE #{@items.length} items, maxDate = #{@startDate}"
    end
    send_event('inc-heatmap', { items: @items })
    iter += 1
  end

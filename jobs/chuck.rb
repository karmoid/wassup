require 'net/http'
require 'json'
require 'cgi'
require 'htmlentities'

#The Internet Chuck Norris Database
server = "http://api.icndb.com"

#Id of the widget
id = "chuck"

#Proxy details if you need them - see below
proxy_host = 'XXXXXXX'
proxy_port = 8080
proxy_user = 'XXXXXXX'
proxy_pass = 'XXXXXXX'

#The Array to take the names from
teammembers = [['Mickey','Mouse']]

json_data = nil
page = MAX_PAGE = 35

SCHEDULER.every '30s', :first_in => 0 do |job|
    random_member = teammembers.sample
    firstName = random_member[0]
    lastName = random_member[1]

    if json_data.nil?
      page += 1
      page=1 if page > MAX_PAGE
      #The uri to call, swapping in the team members name
      # uri = URI("#{server}/jokes/random?firstName=#{firstName}&lastName=#{lastName}&limitTo=[nerdy]")
      uri = URI("http://chucknorrisfacts.fr/api/get?data=type:txt;tri:top;page:#{page}")
      #This is for when there is no proxy
      res = Net::HTTP.get(uri)

      #This is for when there is a proxy
      #res = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).get(uri)

      #marshal the json into an object
      json_data = JSON[res]
      puts "page #{page} - #{json_data.size} Facts lus!"
    end

    if json_data.nil? || json_data.size == 0
      joke = "Pas de Fact lu!"
    else
      idx = rand(json_data.size)
      joke = HTMLEntities.new.decode(CGI.unescapeHTML(json_data[idx]["fact"]))
      # puts "avant delete_at #{json_data.inspect}"
      json_data.delete_at(idx)
      # puts "après delete_at #{json_data.inspect}"
      json_data = nil if json_data.size == 0
    end
    #Get the joke
    puts "P:#{page} remains:#{json_data.nil? ? 0 : json_data.size} <<#{joke}>>"
    #Send the joke to the text widget
    send_event(id, { title: "Chuck Norris Fact", text: joke })
end

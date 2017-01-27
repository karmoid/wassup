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

id_line = -1
json_data = nil

SCHEDULER.every '30s', :first_in => 0 do |job|
    random_member = teammembers.sample
    firstName = random_member[0]
    lastName = random_member[1]

    if id_line == -1
      #The uri to call, swapping in the team members name
      # uri = URI("#{server}/jokes/random?firstName=#{firstName}&lastName=#{lastName}&limitTo=[nerdy]")
      uri = URI("http://chucknorrisfacts.fr/api/get?type=%22txt%22;tri=%22top%22;nb=100")
      #This is for when there is no proxy
      res = Net::HTTP.get(uri)

      #This is for when there is a proxy
      #res = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).get(uri)

      #marshal the json into an object
      json_data = JSON[res]
      id_line=0
      puts "#{json_data.size} Facts lus!"
    end

    if json_data.size>0
      joke = HTMLEntities.new.decode(CGI.unescapeHTML(json_data[id_line]["fact"]))
      id_line += 1
      id_line = -1 if id_line==json_data.size
    else
      joke = "Pas de Fact lu!"
    end
    #Get the joke

    #Send the joke to the text widget
    send_event(id, { title: "Chuck Norris Fact ##{id_line}", text: joke })

end

require 'uri'
require 'net/http'

# url = URI("http://localhost:3030/widgets/ticker")
url = URI("http://#{ENV['dashhost']}:3030/widgets/ticker")

http = Net::HTTP.new(url.host, url.port)

# msg = ["Premier message","Deuxième message"]

msg = []
ARGV.each do |arg|
   msg << arg
end

request = Net::HTTP::Post.new(url)
request["authorization"] = 'Basic YWRtaW46Vk13YXJlMjAxNiE='
request["content-type"] = 'application/json'
request["cache-control"] = 'no-cache'
request["postman-token"] = 'f4d510be-766d-8170-e651-d8f936834d1b'
request.body = "{\"items\":#{msg.inspect},\"auth_token\": \"#{ENV['auth_token']}\"}"
puts request.body

response = http.request(request)
puts response.read_body

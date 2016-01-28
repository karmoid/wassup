require 'csv'

SCHEDULER.every '1m', :first_in => 0 do |job|
  begin
    # puts "execute getincidents.sh avec bash"
    # puts system('bash ./getincidents.sh') ? "Run OK" : "KO!"
    tweets = CSV.foreach("public/incidents.csv", {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:impact][3..row[:impact].length-1], body: row[:short_description], when: tstxt + " " + humanize(ts) }
    end
    # puts tweets.inspect
  send_event('incident_mentions', incidents: tweets)
  end
end
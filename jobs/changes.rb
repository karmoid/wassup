require 'csv'

def humanize secs
  secs, n = secs.divmod(3600)
  [[24, :heures], [1000, :jours]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      "#{n.to_i} #{name}"
    end
  }.compact.reverse.join(' ')
end

SCHEDULER.every '1m', :first_in => 0 do |job|
  begin
    tweets = CSV.foreach("public/changes.csv", {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:requested_by_date])
      if Time.now > ts 
        tstxt = "il y a"
        ts = Time.now - ts
      else
        tstxt = "dans"
        ts = ts - Time.now
      end
        { number: row[:number], name: row[:state], body: row[:short_description], when: tstxt + " " + humanize(ts) }
    end
    send_event('change_mentions', changes: tweets)
  end
end
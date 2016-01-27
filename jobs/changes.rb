require 'csv'
SCHEDULER.every '1m', :first_in => 0 do |job|
  begin
    tweets = CSV.foreach("public/changes.csv", {:headers => true, :header_converters => :symbol}).map do |row|
      { name: row[:number], body: row[:short_description] }
    end
   send_event('change_mentions', comments: tweets)
  end
end
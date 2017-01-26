require 'csv'
require 'open-uri'
require 'nokogiri'

MAX_APPROV_OVERDUE = 15
MAX_APPROV_AWAY = 15


# config_file = File.dirname(File.expand_path(__FILE__)) + '/../timeline_data.yml'
SCHEDULER.every '15m', :first_in => 0 do |job|
  begin
    # puts "execute getchanges.sh avec bash"
    # puts system('bash ./getchanges.sh') ? "Run OK" : "KO!"
    # config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    # config = YAML::load(File.open(config_file))
    # command = config["cmd_c"]
    # system(command)

    domain = "https://brinkslatam.service-now.com"
    query = "sysapproval_approver_list.do?sysparm_query=state%3Drequested%5Edue_dateBETWEENjavascript%3Ags.daysAgoStart(#{MAX_APPROV_OVERDUE})%40javascript%3Ags.daysAgoEnd(#{-1*MAX_APPROV_AWAY})%5EORsys_created_onBETWEENjavascript%3Ags.daysAgoStart(#{MAX_APPROV_OVERDUE})%40javascript%3Ags.daysAgoEnd(#{-1*MAX_APPROV_AWAY})%5Esysapproval.location.country%3DFrance&CSV"

    url = "#{domain}/#{query}"

    username = ENV["uname"]
    password=ENV["pwd"]

    # puts url

    (open(url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      { approver: row[:approver], body: row[:short_description], when: row[:due_date].empty? ? Time.parse(row[:sys_created_on]) : Time.parse(row[:due_date]) }
    end
    # puts tweets.inspect

    grouped = tweets.group_by {|t| t[:approver]}
    keys = grouped.keys # => ["food", "drink"]

    arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t + 1}]}
    # => [["food", 110], ["drink", 12]]

    tasks = []
    arr.sort { |a, b| a[1] <=> b[1] }.reverse.each do |t|
      # puts t.inspect
      tasks << {
        name: t[0],
        date: Date.today,
        priority: 1,
        formatted_date: t[1].to_s
        }
    end

    max_items = 10
    send_event "snow-approvals", { items: tasks.take(max_items) }

  end
end

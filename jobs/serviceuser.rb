require 'csv'
require 'open-uri'
require 'nokogiri'

SCHEDULER.every '5m', :first_in => 0 do |job|
  begin
    # puts "execute getincidents.sh avec bash"
    # puts system('bash ./getincidents.sh') ? "Run OK" : "KO!"
    # config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    # config = YAML::load(File.open(config_file))
    # command = config["cmd_i"]
    # system(command)

    username = ENV["uname"]
    password=ENV["pwd"]

    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-TEC_N2%5EpriorityIN1%2C2%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart(5)&CSV"

    (open(url, :http_basic_authentication => [username, password]))

    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

    # page.xpath("/html/body/p").each do |line|
    #   puts ">> [#{line}]"
    # end

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], where: row[:location].nil? ? "" : row[:location], when: tstxt + " " + humanize(ts) }
    end
    # puts tweets.inspect
  send_event('snow-inc-eus', incidents: tweets)

  [1,2].each {|i|
    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-TEC_N2%5Epriority%3D#{i.to_s}%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart(2)%5EcategoryINfr_access%2Cfr_office_software%2Cfr_business_application%2Cfr_hardware%2Cfr_messaging%2Cfr_mobility%2Cfr_network%2Cfr_security%2Cfr_system&CSV"
    # puts url
    (open(url, :http_basic_authentication => [username, password]))
    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], categ: row[:category] + ", "+ row[:subcategory], body: row[:short_description], where: row[:location].nil? ? "" : row[:location], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:site]}
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
    send_event "snow-inc-eus-site-#{i.to_s}", { items: tasks.take(max_items) }




    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], categ: row[:category], subcateg: row[:subcategory], body: row[:short_description], where: row[:location].nil? ? "" : row[:location], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:subcateg]}
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
    send_event "snow-inc-eus-categ-#{i.to_s}", { items: tasks.take(max_items) }


    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { site: row[:location], ci: row[:cmdb_ci], body: row[:short_description], when: Time.parse(row[:sys_created_on]) }
    end

    grouped = tweets.group_by {|t| t[:ci]}
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
    send_event "snow-inc-eus-ci-#{i.to_s}", { items: tasks.take(max_items) }
  }

    if true
      url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-TEC_N2&CSV"

      # (open(url, :http_basic_authentication => [username, password]))
      page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

      tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
        {status: row[:priority],
          created_on: row[:sys_created_on],
          updated_on: row[:sys_updated_on],
          month: Time.parse(row[:sys_created_on]).strftime('01-%m-%Y')
        }
      end
      # puts tweets.inspect
      grouped = tweets.group_by {|t| t[:month]}
      keys = grouped.keys # => ["food", "drink"]
      arrUsed = keys.map {|k| [Time.parse(k),
                               grouped[k].reduce(0) {|t,h| t+1 }
                               ]}.sort { |x,y| x[0] <=> y[0] }
      # puts arrUsed.inspect

      backlog_groups = []

      arrUsed.each { |backlog|
        backlog_groups << {x: backlog[0].to_i, y: backlog[1]}
      }

      # puts backlog_groups.inspect
      send_event("snow-inc-eus-backlog", points: backlog_groups )
    end
  end
end

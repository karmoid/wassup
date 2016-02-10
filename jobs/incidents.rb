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

    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR%5EpriorityIN1%2C2%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart(5)%5EcategoryINfr_access%2Cfr_office_software%2Cfr_business_application%2Cfr_hardware%2Cfr_messaging%2Cfr_mobility%2Cfr_network%2Cfr_security%2Cfr_system&CSV"

    (open(url, :http_basic_authentication => [username, password]))

    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

    # page.xpath("/html/body/p").each do |line|
    #   puts ">> [#{line}]"
    # end

    tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], where: row[:location], when: tstxt + " " + humanize(ts) }
    end
    # puts tweets.inspect
  send_event('incident_mentions', incidents: tweets)

  url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Eu_task_for.vip%3Dtrue%5EstateNOT%20IN3%2C4%2C6%5EpriorityIN1%2C2&sysparm_view=&CSV"
  (open(url, :http_basic_authentication => [username, password]))
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

  hrows = [
    { cols: [ {value: '#incident'}, {value: 'vip'}, {value: 'categorie'}, {value: 'sous-categ'}, {value: 'composant'}, {value: 'quand'} ] }
  ]


    rows = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { cols: [ {value: row[:number]}, {value: row[:u_task_for]}, {value: row[:category]}, {value: row[:subcategory]}, {value: row[:cmdb_ci]}, {value: tstxt + " " + humanize(ts)} ]}
#      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], ci: row[:cmdb_ci], qui: row[:u_task_for], when: tstxt + " " + humanize(ts),
#        label:"#{row[:number]} - [#{row[:category]}/#{row[:subcategory]}] Impact #{row[:priority]}, #{row[:short_description]} " , value:"#{row[:u_task_for]} #{row[tstxt]} #{humanize(ts)}" }
    end
    # puts tweets.inspect
    # send_event('incident-vip', items: tweets)
    send_event('incident-vip', { hrows: hrows, rows: rows } )
  end
end

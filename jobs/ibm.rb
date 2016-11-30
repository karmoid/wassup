require 'csv'
require 'open-uri'
require 'nokogiri'
last_tweets = current_tweets = 0
SCHEDULER.every '1m', :first_in => 0 do |job|
  begin
    # puts "execute getincidents.sh avec bash"
    # puts system('bash ./getincidents.sh') ? "Run OK" : "KO!"
    # config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/environment.yml'
    # config = YAML::load(File.open(config_file))
    # command = config["cmd_i"]
    # system(command)

  username = ENV["uname"]
  password=ENV["pwd"]

# Couleur BaclogOSS
# ----- Retirer le nombre de ticket sur Charge OSS
# Les incidents tous les 1/4 d'heure
# Les incidents pas de fleche ou stganant si 0
# Aligner note des commandes à gauche
# Volume ticket par mois (prendre backlog global line) pas de cumul
# ------ Devices threat list à droite décaler les autres. Heure plus bas
# ------- Corriger le mois du backog oct pour septembre
# --- vip en couleur orange comme détail incident_list
# detail incident couleur plus console / retirer image service now
# ----- message - limite première ligne

  url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Estate%3D-5%5EORstate%3D2%5EORstate%3D1%5EORstate%3D8%5Eassignment_groupSTARTSWITHbkfr-eus%5EORassignment_groupSTARTSWITHIBM&CSV"

  #(open(url, :http_basic_authentication => [username, password]))

  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

  # page.xpath("/html/body/p").each do |line|
   # puts ">> [#{line}]"
  # end

  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    ts = Time.parse(row[:sys_created_on])
    tstxt = "il y a"
    ts = Time.now - ts
    { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], where: row[:location].nil? ? "" : row[:location], when: tstxt + " " + humanize(ts), group: row[:assignment_group], category: row[:category] }
  end
  # puts tweets.inspect

  send_event('incident_ibm_det', incidents: tweets)

  grouped = tweets.group_by {|t| t[:group]}
  keys = grouped.keys # => ["food", "drink"]

  arr = keys.map {|k| [k, grouped[k].reduce(0) {|t,h| t + 1}]}
  # => [["food", 110], ["drink", 12]]

  tasks = []
  data = []
  arr.sort { |a, b| a[1] <=> b[1] }.reverse.each do |t|
    # puts t.inspect
    tasks << {
      name: t[0],
      date: Date.today,
      priority: 1,
      formatted_date: t[1].to_s
      }
    data << {label: t[0], value: t[1]}
  end

  max_items = 10
  send_event "incident_ibm_grp", { items: tasks.take(max_items) }

  send_event 'incident_ibm_grppie', { value: data.take(max_items) }

  url= "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=u_service_desk%3DFRANCE%5EstateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-EUS-OSS_PROVENCE&CSV"
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    {status: row[:priority],
      created_on: row[:sys_created_on],
      updated_on: row[:sys_updated_on],
      assigned_to: row[:assigned_to],
      month: Time.parse(row[:sys_created_on]).strftime('%y%m%d')
    }
  end
  last_tweets = current_tweets
  current_tweets = tweets.size
  # puts tweets.inspect
  grouped = tweets.group_by {|t| t[:month]}
  keys = grouped.keys # => ["food", "drink"]
  arrUsed = keys.map {|k| [Time.parse(k),
                           grouped[k].reduce(0) {|t,h| t+1 }
                           ]}.sort { |x,y| x[0] <=> y[0] }
  puts arrUsed.inspect

  backlog_groups = []

  arrUsed.each { |backlog|
    backlog_groups << {x: backlog[0].to_i, y: backlog[1]}
  }

  # puts backlog_groups.inspect
  send_event("incident-ibm-backlog", points: backlog_groups )
  send_event("myId", { current: current_tweets, last: last_tweets } )


  grouped = tweets.group_by {|t| t[:assigned_to]}
  keys = grouped.keys # => ["food", "drink"]
  arrUsed = keys.map {|k| [k,
                           grouped[k].reduce(0) {|t,h| t+1 }
                           ]}.sort { |x,y| x[0] <=> y[0] }
  # puts arrUsed.inspect

  backlog_groups = [{values: [], max_value: tweets.size, hide_total: true}]

  arrUsed.each { |backlog|
    backlog_groups[0][:values] << {label: backlog[0].to_s, value: backlog[1]}
  }
  # puts backlog_groups.inspect

  send_event("incident-ibm-ossload", series: backlog_groups.to_json)

  url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Eu_task_for.vip%3Dtrue%5EstateNOT%20IN3%2C4%2C6%5EpriorityIN1%2C2&sysparm_view=&CSV"
  # (open(url, :http_basic_authentication => [username, password]))
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))

  hrows = [
    { cols: [ {value: 'Incident'}, {value: 'VIP'}, {value: 'Composant'}, {value: 'Quand'} ] }
  ]


    rows = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      tstxt = "il y a"
      ts = Time.now - ts
      { cols: [ {value: row[:number]}, {value: row[:u_task_for]}, {value: row[:cmdb_ci]}, {value: tstxt + " " + humanize(ts)} ]}
#      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], ci: row[:cmdb_ci], qui: row[:u_task_for], when: tstxt + " " + humanize(ts),
#        label:"#{row[:number]} - [#{row[:category]}/#{row[:subcategory]}] Impact #{row[:priority]}, #{row[:short_description]} " , value:"#{row[:u_task_for]} #{row[tstxt]} #{humanize(ts)}" }
    end
    # puts tweets.inspect
    # send_event('incident-vip', items: tweets)
    send_event('incident-vip-ibm', { hrows: hrows, rows: rows } )

    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=u_service_desk%3DFRANCE%5EstateIN-5%2C2%2C1%2C8%5Eshort_descriptionLIKE%5BCDA%20FR&CSV"
    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password] ))
    # page.xpath("/html/body/p").each do |line|
    #  puts ">> [#{line}]"
    # end
    hrows = [
      { cols: [ {value: '#cmd'}, {value: 'composant'}, {value: 'fournisseur'}, {value: 'N° incident'}, {value: 'statut'}, {value: 'note'} ] }
    ]
    # "number",
    # "category",
    # "short_description",
    # "u_task_for",
    # "assignment_group",
    # "assigned_to",
    # "cmdb_ci",
    # "subcategory",
    # "location",
    # "priority",
    # "state",
    # "sys_created_on",
    # "sys_updated_on"


      rows = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
        ts = Time.parse(row[:sys_created_on])
        tstxt = "il y a"
        ts = Time.now - ts
        cmd = row[:short_description]
        # puts cmd.inspect
        cmdfields = /\[CDA\s(FR\w*\s?-\s?\w*)\s?\/\s?(.*)\](?:\[.*\])?\s(.*)$/.match(cmd)
        # puts cmdfields.inspect
        cmdfields = [cmd,"n/a",cmd] if cmdfields.nil?

        fournisseur = cmdfields[2].split('][')[0] unless cmdfields.nil?

        { cols: [ {value: cmdfields[1]}, {value: row[:cmdb_ci]}, {value: fournisseur}, {value: row[:number]}, {value: row[:state]}, {value: cmdfields[3]} ]}
  #      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], ci: row[:cmdb_ci], qui: row[:u_task_for], when: tstxt + " " + humanize(ts),
  #        label:"#{row[:number]} - [#{row[:category]}/#{row[:subcategory]}] Impact #{row[:priority]}, #{row[:short_description]} " , value:"#{row[:u_task_for]} #{row[tstxt]} #{humanize(ts)}" }
      end
      puts rows.inspect
      # send_event('incident-vip', items: tweets)
      send_event('commande-achat', { hrows: hrows, rows: rows.take(15) } )
  end
end

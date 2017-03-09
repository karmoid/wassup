require 'csv'
require 'open-uri'
require 'nokogiri'
last_tweets_ibm = last_tweets_hd = current_tweets_ibm = current_tweets_hd = 0
backlog_ibm = []
backlog_hd = []

SCHEDULER.every '10m', :first_in => 0 do |job|
begin
  snow_req = ServicenowHelper::Requester.new

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

# ** Brinks logo - Heure - Backlog cercle -
# Incidents (Police plus grosse pour la légende) - Incidents tendance
# Toutes les 30 minutes pour la page
# ** Backlog oss une colonne
# ajouter incident tendance HelpDesk. Ce qui est important c'est la tendance.
# Evolution Commande
# Prevoir carré vde Futur use
# ** champ note aligné gauuche
# widget tendance avec courbe de tendance a la place de la courbe de Volume


  url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Estate%3D-5%5EORstate%3D2%5EORstate%3D1%5EORstate%3D8%5Eassignment_groupSTARTSWITHbkfr-eus%5EORassignment_groupSTARTSWITHIBM&CSV"

  #(open(url, :http_basic_authentication => [username, password]))

  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

  # page.xpath("/html/body/p").each do |line|
   # puts ">> [#{line}]"
  # end

  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    ts = Time.parse(row[:sys_created_on])
    # tstxt = "il y a"
    ts = Time.now - ts
    { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], where: row[:location].nil? ? "" : row[:location], when: humanize_with_lib(ts,"il y a","récent"), group: row[:assignment_group], category: row[:category] }
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
    stats = t[1]
    group_by = t[0]
		grpfields = /BKFR-(.*)$/.match(group_by)
		grpfields = [group_by,group_by] if grpfields.nil?
    data << {label: grpfields[1], value: stats}
  end

  max_items = 10
  send_event "incident_ibm_grp", { items: tasks.take(max_items) }

  # puts "IBM PIE: #{data.inspect}"
  send_event 'incident_ibm_grppie', { value: data.take(max_items)}

  url= "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=u_service_desk%3DFRANCE%5EstateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-EUS-OSS_PROVENCE&CSV"
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    {status: row[:priority],
      created_on: row[:sys_created_on],
      updated_on: row[:sys_updated_on],
      assigned_to: row[:assigned_to],
      month: Time.parse(row[:sys_created_on]).strftime('%y%m%d')
    }
  end
  last_tweets_ibm = current_tweets_ibm
  current_tweets_ibm = tweets.size
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

  backlog_ibm << {x: Time.now.to_i, y: tweets.length}
  backlog_ibm.shift if (backlog_ibm.length > 18)

  # puts backlog_groups.inspect
  send_event("incident-ibm-backlog", points: backlog_groups )
  # send_event("myId", { current: current_tweets, last: last_tweets } )
  send_event("myTendance", { current: current_tweets_ibm, last: last_tweets_ibm, points: backlog_ibm } )

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


  url= "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=u_service_desk%3DFRANCE%5EstateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR-EUS-HELP_DESK&CSV"
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

  tweets = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
    {status: row[:priority],
      created_on: row[:sys_created_on],
      updated_on: row[:sys_updated_on],
      assigned_to: row[:assigned_to],
      month: Time.parse(row[:sys_created_on]).strftime('%y%m%d')
    }
  end
  last_tweets_hd = current_tweets_hd
  current_tweets_hd = tweets.size
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

  # result_file = File.dirname(File.expand_path(__FILE__)) + "/hd.log"
  # puts "ecriture sur #{result_file}"
  # open(result_file, 'a') { |f|
  #   f.puts backlog_groups.inspect
  # }

  backlog_hd << {x: Time.now.to_i, y: tweets.length}
  backlog_hd.shift if (backlog_hd.length > 18)

  # puts backlog_groups.inspect
  send_event("incident-hd-backlog", points: backlog_groups )
  # send_event("myId", { current: current_tweets, last: last_tweets } )
  send_event("myTendancehd", { current: current_tweets_hd, last: last_tweets_hd, points: backlog_hd } )


  url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Eu_task_for.vip%3Dtrue%5EstateNOT%20IN3%2C4%2C6%5EpriorityIN1%2C2&sysparm_view=&CSV"
  # (open(url, :http_basic_authentication => [username, password]))
  page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))

  hrows = [
    { cols: [ {value: 'Incident'}, {value: 'VIP'}, {value: 'Composant'}, {value: 'Quand'} ] }
  ]


    rows = CSV.parse(page.children.text, {:headers => true, :header_converters => :symbol}).map do |row|
      ts = Time.parse(row[:sys_created_on])
      # tstxt = "il y a"
      ts = Time.now - ts
      { cols: [ {value: row[:number]}, {value: row[:u_task_for]}, {value: row[:cmdb_ci]}, {value: humanize_with_lib(ts,"il y a","récent")} ]}
#      { number: row[:number], name: row[:category] + ", "+ row[:subcategory], impact: row[:priority][3..row[:priority].length-1], body: row[:short_description], ci: row[:cmdb_ci], qui: row[:u_task_for], when: tstxt + " " + humanize(ts),
#        label:"#{row[:number]} - [#{row[:category]}/#{row[:subcategory]}] Impact #{row[:priority]}, #{row[:short_description]} " , value:"#{row[:u_task_for]} #{row[tstxt]} #{humanize(ts)}" }
    end
    # puts tweets.inspect
    # send_event('incident-vip', items: tweets)
    send_event('incident-vip-ibm', { hrows: hrows, rows: rows } )

    url = "https://brinkslatam.service-now.com/incident_list.do?sysparm_query=u_service_desk%3DFRANCE%5EstateIN-5%2C2%2C1%2C8%5Eshort_descriptionLIKE%5BCDA%20FR%5Eassignment_group!%3D3cba4d3e6faaf9403a4d508e5d3ee431&CSV"
    page = Nokogiri::HTML(open( url, :http_basic_authentication => [username, password], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE  ))
    # page.xpath("/html/body/p").each do |line|
    #  puts ">> [#{line}]"
    # end
    hrows = [
      { cols: [ {value: '#cmd'}, {value: 'composant'}, {value: 'fournisseur'}, {value: 'N° incident'}, {value: 'statut'}, {value: 'note'} ] }
    ]

    # Données Dashboard Service Delivery - Backlog Service Delivery
    backlog_groups = []
    result = snow_req.execute_qy(:table,"commande_en_cours")
    res = eval(result.body)
    # puts ">>>commande en cours<<<<"
    # puts "#{res.inspect}"
    # puts ">>>commande en cours<<<<"
    rows = res[:result].map do |row|
      ts = Time.parse(row[:sys_created_on])
      # tstxt = "il y a"
      ts = Time.now - ts
      cmd = row[:short_description]
      # puts cmd.inspect
      cmdfields = /\[CDA\s(FR\w*\s?-\s?\w*)\s?\/\s?(.*)\](?:\[.*\])?\s(.*)$/.match(cmd)
      # puts cmdfields.inspect
      cmdfields = [cmd,"n/a",cmd] if cmdfields.nil?
      fournisseur = cmdfields[2].split('][')[0] unless cmdfields.nil?
      { cols: [ {value: cmdfields[1]}, {value: snow_req.display_value(row[:cmdb_ci])}, {value: fournisseur}, {value: row[:number]}, {value: row[:state]}, {value: cmdfields[3]} ]}
    end

    send_event('commande-achat', { hrows: hrows, rows: rows.take(15) } )
  end
end

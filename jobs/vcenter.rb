# encode("utf-8")
require 'json'
require 'time'
require 'rbvmomi'

def get_percent (values, padv)
  pct = (100.0 * values.freeSpace / values.capacity).round(2)
end


def getFreeSpaceAlert(url,uname,upwd)
  puts "Analyse de #{url} avec user #{uname} et pwd #{upwd}"
  vim = RbVmomi::VIM.connect host: url, ssl: true, insecure: true, user: uname, password: upwd
  dc = vim.serviceInstance.find_datacenter

  # puts "datastore".rjust(31)+" "+
  #      "capacity".ljust(12)+
  #      "free".ljust(12)+
  #      "% free".rjust(12)+" "+
  #      "ftype".ljust(10)
  # dc.datastore.each do |ds|
  #   pct = get_colored_percent(ds.summary,12)
  #   puts "#{ds.name.rjust(31)} "+
  #       "#{ds.summary.capacity.to_s.ljust(12)}"+
  #       "#{ds.summary.freeSpace.to_s.ljust(12)}"+
  #       "#{pct}"+
  #       "#{ds.summary.type.ljust(10)}" unless pct==""
  # end
  datastores = dc.datastore.map do |ds|
    pct = get_percent(ds.summary,12)
    {host: url,
      name: ds.name,
     capacity: ds.summary.capacity,
      freespace: ds.summary.freeSpace,
      pct: pct,
      type: ds.summary.type
    }
  end
end

pwd = ENV["vcenterp"]

SCHEDULER.every '4h', :first_in => 0 do |job|
  config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/vcenter.yml'
  config = YAML::load(File.open(config_file))
  if config["vcenters"].nil?
    puts "No vcenter found"
  else
    datastorus = []
    config["vcenters"].each do |vc|
      # puts vc.inspect
      vcenter = user = ""
      active = false
      vc[1].each_pair do |key, value|
        case key
        when "fqdn"
          vcenter = value
        when "credential"
          user = value
        when "active"
          active = value
        end
      end
      if active
        puts "Traitement de #{vcenter} (#{vc[0]})"
        datastorus += getFreeSpaceAlert(vcenter, user, pwd)
      else
        puts "#{vcenter} (#{vc[0]}) est inactif"
      end
    end
    data_stores=datastorus.group_by { |g| g[:type] }.map do |key, value|
       [key, value.group_by { |g| g[:name] }]
    end.to_h
    # puts data_stores.inspect

    keys = data_stores.keys # => ["VMFS", "NFS"]
    arrUsed = keys.map {|k| [k,
                             data_stores[k].reduce(0) {|t,h| t+h[1][0][:capacity] },
                             data_stores[k].reduce(0) {|t,h| t+h[1][0][:freespace] },
                             data_stores[k].reduce(100.0) {|t,h| t>h[1][0][:pct] ? h[1][0][:pct] : t}
                             ]}
    # puts arrUsed.inspect
    arrUsed.each do |values|
  		items = [
  			{
  				name: "TOTAL",
  				date: Date.today,
  				priority: (values[3]<12 ? 1 : (values[3] < 20 ? 2 : 3)),
  				formatted_date: values[1].to_humanB
  			},
        {
  				name: "LIBRE",
  				date: Date.today,
  				priority: (values[3]<12 ? 1 : (values[3] < 20 ? 2 : 3)),
  				formatted_date: values[2].to_humanB
  			},
        {
  				name: "UTILISE",
  				date: Date.today,
  				priority: (values[3]<12 ? 1 : (values[3] < 20 ? 2 : 3)),
  				formatted_date: (values[1]-values[2]).to_humanB
  			},
      ]
  		# puts "on vc-#{values[0].downcase} send #{items.inspect}"
  		send_event "vc-#{values[0].downcase}", { items: items, current: "#{values[3]}%" }
  	end

    hrows = [
      { cols: [ {value: 'Name'}, {value: 'Total'}, {value: 'Used'}, {value: 'Free'}, {value: '% free'}, {value: "Nb Conx"} ] }
    ]

    data_stores=datastorus.group_by { |g| g[:name] }
    keys = data_stores.keys # => ["BA_NFS_B4", "BA_NFS_G1"]
    arrUsed = keys.map {|k| [k,
      data_stores[k].reduce(0) {|t,h| h[:capacity] },
      data_stores[k].reduce(0) {|t,h| h[:freespace]},
      data_stores[k].reduce(0) {|t,h| h[:pct]},
      data_stores[k].reduce(0) {|t,h| t+1},
      ]}
      rows = arrUsed.sort_by { |e| e[3]  }.take(19).map do |row|
        { cols: [ {value: row[0]}, {value: row[1].to_humanB}, {value: (row[1]-row[2]).to_humanB}, {value: row[2].to_humanB}, {value: row[3]}, {value: row[4]} ]}
      end
      send_event('vc-datastore', { hrows: hrows, rows: rows } )
  end
end

# encode("utf-8")
require 'json'
require 'time'
require 'rbvmomi'

def get_percent (values, padv)
  pct = (100.0 * values.freeSpace / values.capacity).round(2)
end


def getFreeSpaceAlert(url,uname,upwd)
  vim = RbVmomi::VIM.connect host: url, ssl: true, insecure: true, user: uname, password: upwd
  dc = vim.serviceInstance.find_datacenter
  puts "Analyse de #{url}"

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
    pct = get_colored_percent(ds.summary,12)
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
      vc[1].each_pair do |key, value|
        case key
        when "fqdn"
          vcenter = value
        when "credential"
          user = value
        when "active"
          active = value.downcase=="true"
        end
      end
      if active
        puts "Traitement de #{vcenter}"
        datastorus += getFreeSpaceAlert(vcenter, user, pwd)
      else
        puts "#{vcenter} est inactif"
      end
    end
    data_stores=datastorus.group_by { |g| g[:type] }.map do |key, value|
       [key, value.group_by { |g| g[:name] }]
    end.to_h
    puts data_stores.inspect
  end
end

require 'pg'

# Avec cette requete, on récupère les heures de début et de fin des traitements par vCenter
#
QY_LAST_DISCOVERY_SESSIONS = <<EOF
select min(b1.dsfrom) dsfrom, max(b1.dsto) dsto from (
select ds.name, max(ds.from) dsfrom, max(ds.to) dsto
from discovery_sessions ds
inner join discoveries d on (d.id=ds.discovery_id)
inner join discovery_tools dt on (dt.name='vcenter' and dt.id=d.discovery_tool_id)
group by ds.name
) as b1
EOF

# Avec cette requete, on récupére la date de la session précédentes
# Utile pour faire des analyses de progression
QY_PREVIOUS_DISCOVERY_SESSIONS = <<EOF
select min(b1.dsfrom) dsfrom, max(b1.dsto) dsto from (
select ds.name, max(ds.from) dsfrom, max(ds.to) dsto
from discovery_sessions ds
inner join discoveries d on (d.id=ds.discovery_id)
inner join discovery_tools dt on (dt.name='vcenter' and dt.id=d.discovery_tool_id)
where ds.to < $1
group by ds.name
) as b1
EOF

# Avec cette requete, on récupère host par host le cumul d'un type d'attribut en ne prenant en compte que les valeurs calculée la veille
# voir le script de l'application apps
QY_CUMUL_ATTRIBUTE_VALUE = <<EOF
select distinct h.name host, d.name discovery, dt.name discovery_type, da.value valeur, da.name attribute_name , da.version attribute_version
from discovery_attributes da
inner join hosts h on (h.id = da.host_id)
inner join discoveries d on (d.id=da.discovery_id)
inner join discovery_tools dt on (dt.id=d.discovery_tool_id)
where (da.discovery_id, da.host_id, da.attribute_type_id, da.version) in (
select d.id, h.id, at.id, max(davalue.version)-$3
from hosts h
inner join discovery_tools dt on (dt.name='vcenter')
inner join discoveries d on (dt.id=d.discovery_tool_id)
inner join discovery_attributes da on (da.host_id = h.id and da.discovery_id=d.id)
inner join attribute_types at on (at.name=$1)
inner join discovery_attributes davalue on (davalue.host_id = h.id and davalue.attribute_type_id=at.id)
where not exists (
	select danot.id
	from discovery_attributes danot
	inner join attribute_types atnot on (atnot.name='hosttype' and atnot.id =danot.attribute_type_id)
	where danot.host_id=h.id and danot.value=$2
	)
group by d.id, h.id, at.id
having max(da.updated_at) between $4 and $5
)
EOF

MAX_ITEMS = 5

DESCRIPTION = {
	"mem-guest" => "Mémoire Matérielle",
	"mem-host" => "Mémoire définie",
	"cpu-guest" => "CPUs",
	"cpu-host" => "vCPUs ",
	"guest" => "ESX 🖥",
	"host" => "VM 💻"
}

@conn = nil

def getLastSessions()
	@conn.exec_params(QY_LAST_DISCOVERY_SESSIONS)
end

def getPreviousSessions(to)
	@conn.exec_params(QY_PREVIOUS_DISCOVERY_SESSIONS, [to])
end

def getMeasures(mesure_type, excluded_host_type, version_delta, from, to)
  @conn.exec_params(QY_CUMUL_ATTRIBUTE_VALUE, [mesure_type, excluded_host_type, version_delta, from, to])
end

def getDescription(code)

end

SCHEDULER.every '5m', :first_in =>  0 do |job|
  puts "Hello from query_karto"
  @conn = PG::Connection.new(host: "sfrdtcsupport02.emea.brinksgbl.com", port: 5432, dbname: "apps_production", user: "appsuser", password: "M@rc496527")

	@dates = getLastSessions
	from = Time.parse(@dates[0]["dsfrom"])
	to = Time.parse(@dates[0]["dsto"])
	@date_previous = getPreviousSessions(to)
	pfrom = Time.parse(@date_previous[0]["dsfrom"])
	pto = Time.parse(@date_previous[0]["dsto"])
	puts "Il semble que la precedente session ait été du #{pfrom} au #{pto}"
	puts "La toute derniere du #{from} au #{to}"

	@vcenter = {}
	# {"dsfrom"=>"2017-05-11 16:39:56.451448", "dsto"=>"2017-05-11 16:49:02.582955"}
  ["cpu","mem"].each do |mesure|
    ["guest","host"].each do |hosttype|
      # Récupère le cumul des Host Esx
			res = getMeasures(mesure, hosttype, 0, from, to)
      grouped = res.group_by {|t| t["discovery"]}
      keys = grouped.keys # => ["food", "drink"]
      arrUsed = keys.map {|k| [k,
                               grouped[k].reduce(0) {|t,h| t+h["valeur"].to_i },
															 grouped[k].reduce(0) {|t,h| t+1 }
                               ]}
      arrUsed.each do |row|
				@vcenter[row[0]] ||= {}
				@vcenter[row[0]]["#{mesure}-#{hosttype}"] = row[1]
				@vcenter[row[0]]["#{hosttype}"] = row[2]
				puts "on stocke dans @vcenter[#{row[0]}] item [#{mesure}-#{hosttype}] la valeur '#{row[1]}' et [#{hosttype}] la valeur #{row[2]}"
      end
    end
  end
  @conn.close
	# puts @vcenter.inspect
	nb_vm = 0
	@vcenter.each do |discovery,values|
		puts "dans Each, #{discovery} a comme valeur #{values.inspect}"
		items = values.map do |k,v|
			nb_vm = v if k=="host"
			{
				name: DESCRIPTION[k],
				date: Date.today,
				priority: k.include?("guest") ? 1 : 2,
				formatted_date: case k
				when "mem-guest"
					(v*1024*1024).to_humanB
				when "mem-host"
					(v*1024*1024).to_humanB
				else
					v.to_s
				end
			}
		end
		puts "on vc-#{discovery} send #{@vcenter.inspect}"
		send_event "vc-#{discovery}", { items: items, current: "#{nb_vm} Vms" }
	end

end

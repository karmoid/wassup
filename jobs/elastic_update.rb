# Mise à jour d'Elasticsearch avec cles données de Service now
#

@client = ElasticClient::MySimpleClient.new
p @client.cluster.health

# A LIRE !
# http://www.rubydoc.info/gems/elasticsearch-api

LOOP_COUNT = 10
MAX_DAYS = 30
MAX_DATE_QY = {
  "_source": [
    "sys_updated_on"
  ],
  "query": {
    "match_all": {}
  },
  "sort":
    {
      "sys_updated_on": "desc"
    },
  "size": 1
}

def get_result_count body
  0
  body["hits"]["total"] unless body.nil? || body["hits"].nil? || body["hits"]["total"].nil?
end

def get_current_start_value

  max_date_res = @client.perform_request "GET", "servicenow-*/_search", "", MAX_DATE_QY
  body = max_date_res.body

  json_body = JSON.parse(body)
  count = get_result_count json_body

  sdate = Time.parse(JSON.parse(body)["hits"]["hits"].first["_source"]["sys_updated_on"]).utc unless count==0
  sdate ||= Time.parse("2015-07-01T00:00:00 +0000").utc

  if count == 0
    puts "Default date used : [#{sdate}] - Computed"
  else
    puts "Last date used : [#{sdate}] -- Elasticsearch"
  end
  sdate
end

snow_req = ServicenowHelper::Requester.new

# all_fr_incidents:
#   active: true
#   table:  "incident"
#   query: "u_service_desk=FRANCE"
#   display_value: true
#   fields: "sys_id,incident_state,state,impact,number,assignment_group,assigned_to,short_description,sys_created_on,sys_updated_on,category,subcategory,cmdb_ci,location,priority,u_task_for,u_service_desk,company,contact_type,urgency"

INDEX_NAME = "servicenow-"
TYPE_NAME = "incidents"

# ENV['TZ'] = 'Europe/Paris'
i = 0

loopRemaining = 0
SCHEDULER.every '30s', first_in: '10s' do |job|
  if loopRemaining<=1
    loopRemaining = LOOP_COUNT
    i += 1
    step = "#{Time.now}: Step ##{i}"

    startValue = get_current_start_value
    startDate = startValue.to_s

    if Time.now-startValue.localtime>MAX_DAYS*3600*24
      snow_req.add_date_filter("sys_updated_on",startValue.localtime, (startValue+(MAX_DAYS*3600*24)).localtime, true)
      puts "Resultats partiels (+ de #{MAX_DAYS} jours): on continue dans 30 secs"
      loopRemaining = 1
      puts "[#{step}] de #{startValue.localtime} a #{(startValue+(MAX_DAYS*3600*24)).localtime}"
    else
      snow_req.add_date_filter("sys_updated_on",startValue.localtime,nil, true)
      puts "[#{step}] a partir de #{startValue.localtime}"
    end
    result = snow_req.execute_qy(:table,"all_fr_incidents")
    if result.nil?
      puts "on reessaie dans 30 secs"
      loopRemaining = 1
    else
      res = JSON.parse(result.body)
      bulk_buf = []
      if !res["result"].empty?
        res["result"].each do |item|
          row_head = {"index": {"_index": INDEX_NAME, "_type": TYPE_NAME, "_id": nil}}
          row_data = {}
          value_u = item["sys_updated_on"]
          value_c = item["sys_created_on"]
          value_c = value_u if value_c == ""
          item.each do |k,v|
            case k
            when "sys_updated_on"
              t1 = Time.parse(value_u)
              row_data[k] = t1.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
            when "sys_created_on"
              t1 = Time.parse(value_c)
              row_data[k] = t1.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
              row_head[:index][:_index] = row_head[:index][:_index] + t1.utc.strftime("%Y")
            when "sys_id"
              row_head[:index][:_id] = v
            else
              if v.is_a?(Hash)
                row_data[k] = v["display_value"]
              else
                row_data[k] = v
              end
            end
          end
          bulk_buf << row_head
          bulk_buf << row_data
        end
        obj = bulk_buf
        puts "Envoi de #{obj.count / 2} elements"
        @client.jsonbody_request "PUT", "_bulk", "", obj
      else
        puts "no new incident"
      end
    end
  else
    loopRemaining -= 1
    # puts "#{Time.now}: #{loopRemaining}/LOOP_COUNT"
  end

end

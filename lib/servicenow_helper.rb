require 'base64'
require 'json'
require 'rest_client'
require 'psych'

module ServicenowHelper
  class Config
    attr_accessor :queries
    attr_accessor :security

    def initialize
      load_config_files(File.dirname(File.expand_path(__FILE__)) + '/../')
    end

    def load_config_files( src_path)
      config_file = src_path + 'security/servicenow.qy'
      security_file = src_path + 'security/servicenow.sec'
      @queries = Psych.load(File.open(config_file))
      @security = Psych.load(File.open(security_file))
    end
  end

  ApiMode = {table: "table", agregate: "stats"}

  class Requester
    attr_accessor :config
    attr_accessor :date_filters

    def initialize
      @config = Config.new
      @date_filters = {}
    end

    def get_datestring date_value
      "javascript:gs.dateGenerate('#{date_value.strftime("%Y-%m-%d")}','#{date_value.strftime("%H-%M-%S")}')"
    end

    def get_time_limits(field, from, to)
      if from.nil?
        if to.nil?
          ""
        else
          "#{field}<=#{get_datestring(to)}"
        end
      elsif to.nil?
        "#{field}>=#{get_datestring(from)}"
      else
        "#{field}BETWEEN#{get_datestring(from)}@#{get_datestring(to)}"
      end
    end

    def get_time_fields
      tf = date_filters.map do |field_name,dates|
        get_time_limits field_name, dates[:from], dates[:to]
      end.join("^")
      puts tf
      tf
    end

    def add_date_filter(field, from, to)
      date_filters[field] = {from: from, to: to}
    end

    def get_query_fields query, dates
      if query.empty?
        dates
      elsif dates.empty?
        ""
      else
        "#{query}^#{dates}"
      end
    end

    def build_url(api, query_data)
      case api
      when :table
        url = <<ENDQY
https://#{config.security["instance"]}.service-now.com/api/now/table/#{query_data["table"]}
?sysparm_query=#{get_query_fields(query_data["query"],get_time_fields)}&
&sysparm_display_value=#{query_data["display_value"]}&sysparm_fields=#{query_data["fields"]}&
sysparm_limits=#{query_data["limit"]}
ENDQY
      when :agregate
        url = <<ENDQY
https://#{config.security["instance"]}.service-now.com/api/now/stats/#{query_data["table"]}
?sysparm_query=#{get_query_fields(query_data["query"],get_time_fields)}&
sysparm_avg_fields=#{query_data["avg_fields"]}&sysparm_count=#{query_data["count"]}&
sysparm_min_fields=#{query_data["min_fields"]}&sysparm_max_fields=#{query_data["max_fields"]}
&sysparm_sum_fields=#{query_data["sum_fields"]}&sysparm_group_by=#{query_data["group_by"]}&
sysparm_order_by=#{query_data["order_by"]}&sysparm_having=#{query_data["having"]}
&sysparm_display_value=#{query_data["display_value"]}
ENDQY
      end
      puts url
      url.gsub("\n","")
    end

    def execute_query(api, query_data)
      begin
        response = RestClient.get(build_url(api, query_data),
                                   {:authorization => "Basic #{Base64.strict_encode64("#{config.security["user"]}:#{config.security["password"]}")}",
                                   :accept => 'application/json'
                                   })
        # puts "#{response.to_str}"
        # puts "Response status: #{response.code}"
        # response.headers.each { |k,v|
        #   puts "Header: #{k}=#{v}"
        # }
        @date_filters = {}
      response
      rescue => e
        puts "ERROR: #{e}"
        raise e
      end
    end

    def execute_qy api, query_name
      # puts "Execute [#{query_name}] with config [#{config.inspect}]"
      # puts "execute_query #{api}, #{ApiMode[api]} - config.queries['queries'][#{ApiMode[api]}]"
      execute_query api, config.queries["queries"][ApiMode[api]][query_name]
    end

  end
end

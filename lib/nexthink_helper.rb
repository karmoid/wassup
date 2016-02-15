require 'yaml'
require 'csv'
require 'nokogiri'

module NexthinkHelper
  class Config
    attr_accessor :config
    attr_accessor :security

    def initialize
      load_config_files(File.dirname(File.expand_path(__FILE__)) + '/../')
    end

    def load_config_files( src_path)
      config_file = src_path + 'config/nexthink.yml'
      security_file = src_path + 'security/nexthink.yml'
      @config = YAML::load(File.open(config_file))
      @security = YAML::load(File.open(security_file))
    end

=begin
 engine_name : Nom de la référence Host dans le fichier de config
 key_value : Nom de la valeur a récupérer qui va nous indiquer la requête et le
 traitement à appliquer
=end

    def get_value( engine_name, key_value, user_id )
      qy = get_query(engine_name, key_value, user_id)
    end

    def get_query( engine_name, key_value, user_id )
      engine_cfg = config[engine_name]
      engine_sec = security["engines"][engine_name]
      unless engine_cfg.nil? || engine_sec.nil?
        user_id[:username] = engine_sec["user"]
        user_id[:pwd] = engine_sec["password"]
        engine_sec["url"] + engine_cfg["queries"][key_value]["query"].chomp + "&format=" + engine_sec["format"]
      end
    end

    def get_values( engine_name, key_value )
      engine_cfg = config[engine_name]
      user_id = {}
      my_values = {}
      qy = get_value(engine_name, key_value, user_id)
      url = URI.parse(URI::encode(qy))
      page = Nokogiri::HTML(open( url.to_s, :http_basic_authentication => [user_id[:username], user_id[:pwd]] ))
      lines = CSV.parse(page.children.text, {:col_sep => "\t", :headers => true, :header_converters => :symbol})
      lines.each {|l| puts l[:average_network_response_time].inspect}
      values = engine_cfg["queries"][key_value]["values"]
      myvalues = values.map {|row|
          puts row.inspect
          {row["name"] =>
             case row["agregate"]
              when "min"
                lines.min {|l| l[row["formula"].to_sym].to_i}[row["formula"].to_sym].to_i
              when "max"
                lines.max {|l| l[row["formula"].to_sym].to_i}[row["formula"].to_sym].to_i
              when "average"
                lines.sum {|l| l[row["formula"].to_sym].to_i} / lines.length
              else
                -1
            end
          }
      }

    end

  end
end

=begin
$LOAD_PATH << 'lib'
require 'nexthink_helper'
c = NexthinkHelper::Config.new
i = {}
c.get_value("version5","alldrives",i)
=end

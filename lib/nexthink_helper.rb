require 'yaml'
require 'csv'
require 'nokogiri'

FIXNUM_MAX = (2**(0.size * 8 -2) -1)
FIXNUM_MIN = -(2**(0.size * 8 -2))

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

# a = [{name: "marc", value: 12},{name: "eric", value: -2},{name: "roro", value: 234},{name: "dudu", value: 23}]

    def get_values( engine_name, key_value )
      engine_cfg = config[engine_name]
      user_id = {}
      my_values = {}
      qy = get_value(engine_name, key_value, user_id)
      # gsub('+','%2b') remplace le caractere + des formules mathematiques par le caractere encode
      # sinon, le WEB considere que c'est un espace...
      url = URI.parse(URI::encode(qy).gsub('+','%2b'))
      # puts url.inspect
      page = Nokogiri::HTML(open( url.to_s, :http_basic_authentication => [user_id[:username], user_id[:pwd]], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE ))
      lines = CSV.parse(page.children.text, {:col_sep => "\t", :headers => true, :header_converters => :symbol})
      # lines.each {|l| puts l[:average_network_response_time].inspect}
      values = engine_cfg["queries"][key_value]["values"]
      values.each {|row|
          # puts "#{key_value} - " + row.inspect
          # puts "longueur: #{lines.length}"
          my_values[row["name"]] = (case row["agregate"]
              when "min"
                lines.length == 0 ? 0 : lines.reduce(FIXNUM_MAX) {|v,l| l[row["formula"].to_sym].to_i < v ? l[row["formula"].to_sym].to_i : v }
              when "max"
                lines.length == 0 ? 0 : lines.reduce(FIXNUM_MIN) {|v,l| l[row["formula"].to_sym].to_i > v ? l[row["formula"].to_sym].to_i : v }
              when "average"
                lines.length == 0 ? 0 : lines.inject(0) {|sum,l| sum + l[row["formula"].to_sym].to_i} / lines.length
              when "sum"
                lines.length == 0 ? 0 : lines.inject(0) {|sum,l| sum + l[row["formula"].to_sym].to_i}
              when "count"
                lines.length
              when "group_by"
                grouped = lines.group_by {|l| l[row["formula"].to_sym]}
                keys = grouped.keys # => ["food", "drink"]
                work = {}
                keys.each {|k| work[k] = grouped[k].reduce(0) {|t,h| t+1 }}
                work
              when "list"
                lines.map {|l|
                  # puts l.inspect
                  item = {}
                  row["formula"].split(",").each { |f|
                    item[f] = l[f.to_sym]
                   }
                   item
                }
              else
                -1
            end)
      }
      my_values
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

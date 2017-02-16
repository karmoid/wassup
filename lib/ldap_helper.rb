require 'net/ldap'
require 'yaml'

FIXNUM_MAX = (2**(0.size * 8 -2) -1)
FIXNUM_MIN = -(2**(0.size * 8 -2))

module LdapHelper
  class Security
    attr_accessor :security

    def initialize
      load_config_files(File.dirname(File.expand_path(__FILE__)) + '/../')
    end

    def load_config_files( src_path)
      security_file = src_path + 'security/ldap_authent.yml'
      @security = YAML::load(File.open(security_file))
    end
  end

  class LockedAccount
    attr_accessor :security

    def initialize
      @security = Security.new
    end

    def get_value(debug)
      ldap = Net::LDAP.new host: security.security["instance"],
           :port => 389,
           :auth => {
                 :method => :simple,
                 :username => security.security["user"],
                 :password => security.security["password"]
           }

      filter = Net::LDAP::Filter.construct("(&(objectCategory=Person)(objectClass=User)(lockouttime>=1))")
      attrs = ["mail", "cn", "sn", "objectclass", "lockoutTime", "msDS-User-Account-Control-Computed"]
      treebase = "OU=FR,OU=z_EMEA,DC=emea,DC=brinksgbl,DC=com"
      locked_accounts = 0
      ldap.search( :base => treebase, :filter => filter, :attributes => attrs ) do |entry|
        entry.each do |attribute, values|
          values.each do |value|
            if /msds-user-account-control-computed/i.match(attribute)
              locked_accounts += 1 if (value.to_i & 16) != 0
              puts "Verrou sur #{entry["cn"]}" if (debug && (value.to_i & 16) != 0)
            end
          end
        end
      end
      p ldap.get_operation_result if debug
      ldap = nil
      return locked_accounts
    end
  end
end

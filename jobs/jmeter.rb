require 'tlsmail'
require 'net/smtp'
require 'time'

my_stats = {}

SCHEDULER.every '5m', :first_in => 0 do |job|
  begin
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/jmeter.yml'
    config = YAML::load(File.open(config_file))
    command_root = config["jmeter-root"]
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/jmeter.yml'
    config = YAML::load(File.open(config_file))
    command = command_root + "\\" + config["cmd_jmeter"]
    mailfrom = config["mailfrom"]
    fromname = config["fromname"]

    iteration_time = Time.now

    if config["websites"].nil?
      puts "No website found"
    else
      config["websites"].each do |ws|
        web_id = ws[0]
        url = ""
        mailto = ""
        toname = ""
        ws[1].each_pair do |key, value|
          case key
          when "url"
            url = value
          when "mailto"
            mailto = value
          when "toname"
            toname = value
          end
        end
        unless url.empty?
          result_file = File.dirname(File.expand_path(__FILE__)) + '/../security/' + web_id + ".log"
          # puts command + " -n -t " + config_name + " > " + result_file
          output = system(command + " -n -t " + url + " > " + result_file)
          lines = File.read(result_file)
          values = lines.match(/summary.*[=].*in\s*(\d*,?\d+).*Err:\s+(\d+)\s/)
          # puts values.inspect
          if values.size == 3
            # puts "#{web_id} : Timing #{values[1]} avec #{values[2]} erreur"

            my_stats[web_id] = {state: false, timing: []} if my_stats[web_id].nil?
            my_stats[web_id][:state] = (values[2].to_i==0)
            my_stats[web_id][:timing] << {x: iteration_time.to_i, y: my_stats[web_id][:state] ? values[1].gsub(",",".").to_f : 0.0}
            my_stats[web_id][:timing].shift if my_stats[web_id][:timing].length > 9

            if !(my_stats[web_id][:state] || mailto.empty?)
              puts "Alerte sur #{web_id} via Email..."
              # To: #{mailto} <#{mailto}>

              msgstr = <<END_OF_MESSAGE
From: #{fromname} <#{mailfrom}>
To: #{toname} <#{mailto}>
Subject: [ALERTE] check sit web [#{web_id}]
Date: #{Time.now.rfc2822}

La verification du site #{web_id} a #{iteration_time.to_s} a retourne une erreur
Output:[
#{lines}
]
END_OF_MESSAGE

              Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
              Net::SMTP.start("smtp.office365.com",587,ENV["maildomain"],ENV["mailuser"],ENV["mailpwd"], :login) do |server|
                server.send_message msgstr, mailfrom, mailto
              end
            end

            # puts my_stats.inspect
            send_event web_id+"-websites", { points: my_stats[web_id][:timing], status: my_stats[web_id][:state] }
          end
        end
      end
    end
  end
end

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
    mailactive = config["mailactive"]

    iteration_time = Time.now

    if config["websites"].nil?
      puts "No website found"
    else
      config["databases"].each do |db|
        mymail = mailactive
        db_id = db[0]
        url = ""
        options = ""
        output_file = ""
        db[1].each_pair do |key, value|
          case key
          when "url"
            url = value
          when "options"
            options = value
          when "output"
            output_file = value
          when "mailactive"
            mymail = value
          end
        end
        db[1].each_pair do |key,value|
          options.gsub!("$#{key}$",value)
        end
        unless url.empty?
          result_file = File.dirname(File.expand_path(__FILE__)) + '/../security/' + db_id + ".log"
          puts command + " -n -t " + url + " " + options + " > " + result_file
          File.delete(output_file) if File.exist?(output_file)
          output = system(command + " -n -t " + url + " " + options + " > " + result_file)
          lines = File.read(output_file)
          line_count = lines.split("\n").size
          error = 0

          hrows = [
            { cols: [ {value: 'Base de données'}, {value: 'Message'}] }
          ]

          rows = []
          lines.split("\n").each do |l|
            results = l.split(",")
            unless results[4].downcase=="ok"
              error += 1
              rows << { cols: [ {value: results[2]},
                                {value: results[4]}
                              ]}
            end
          end
          puts "#{line_count} mesures - #{(100.0 * error / line_count).round(2)}% d'erreur"
        end
        send_event("#{db_id}-databases", { hrows: hrows, rows: rows.take(8) } )
      end
    end

    if config["websites"].nil?
      puts "No website found"
    else
      config["websites"].each do |ws|
        mymail = mailactive
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
          when "mailactive"
            mymail = value.downcase=="true"
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

            if !(my_stats[web_id][:state] || mailto.empty? || !mymail)
              puts "Alerte sur #{web_id} via Email..."
              # To: #{mailto} <#{mailto}>

              msgstr = <<MESSAGE_END
From: #{fromname} <#{mailfrom}>
To: #{toname} <#{mailto}>
Subject: =?UTF-8?B?#{Base64.strict_encode64("[ALERTE] Vérification des sites WEB - "+web_id)}?=
Date: #{Time.now.rfc2822}
MIME-Version: 1.0
Content-type: text/html; charset=UTF-8

<h1>#{web_id}</h1>
<p>La vérification du site à #{iteration_time.to_s} a retourné une erreur<p>
<h5>Résumé de la mesure</h5>
<p>#{values[0]}</p>
MESSAGE_END

              Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
              Net::SMTP.start("smtp.office365.com",587,ENV["maildomain"],ENV["mailuser"],ENV["mailpwd"], :login) do |server|
                server.send_message msgstr, mailfrom, mailto
              end
              puts "Email sent to #{mailto}"
            end

            # puts my_stats.inspect
            send_event web_id+"-websites", { points: my_stats[web_id][:timing], status: my_stats[web_id][:state] }
          end
        end
      end
    end
  end
end

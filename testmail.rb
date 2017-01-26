require 'tlsmail'
require 'net/smtp'
require 'time'
require 'yaml'
require 'base64'

config_file = 'security/jmeter.yml'
config = YAML::load(File.open(config_file))
command_root = config["jmeter-root"]
config_file = 'config/jmeter.yml'
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
      result_file = 'security/' + web_id + ".log"
      # puts command + " -n -t " + config_name + " > " + result_file
      lines = File.read(result_file)
      values = lines.match(/summary.*[=].*in\s*(\d*,?\d+).*Err:\s+(\d+)\s/)
      # puts values.inspect

      puts "Alerte sur #{web_id} via Email..."

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
<br/>
<h2>Bonjour,</h2>
<h2>Merci de ne pas prendre en compte ce Mail.</h2>
<h1>Il s’agit d’un test.</h1>
<h2>Cordialement</h2>

MESSAGE_END

      puts "to #{toname} <#{mailto}>"
      puts "from #{fromname} <#{mailfrom}>"

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start("smtp.office365.com",587,ENV["maildomain"],ENV["mailuser"],ENV["mailpwd"], :login) do |server|
        server.send_message msgstr, mailfrom, mailto
      end
      puts "mail sent"
      exit
    end
  end
end

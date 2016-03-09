
my_stats = {}

SCHEDULER.every '5m', :first_in => 0 do |job|
  begin
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../security/jmeter.yml'
    config = YAML::load(File.open(config_file))
    command_root = config["jmeter-root"]
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/jmeter.yml'
    config = YAML::load(File.open(config_file))
    command = command_root + "\\" + config["cmd_jmeter"]

    iteration_time = Time.now

    if config["websites"].nil?
      puts "No website found"
    else
      config["websites"].each_pair do |web_id, config_name|
        result_file = File.dirname(File.expand_path(__FILE__)) + '/../security/' + web_id + ".log"
        # puts command + " -n -t " + config_name + " > " + result_file
        output = system(command + " -n -t " + config_name + " > " + result_file)
        values = File.read(result_file).match(/summary.*[=].*in\s*(\d*,?\d+).*Err:\s+(\d+)\s/)
        # puts values.inspect
        if values.size == 3
          # puts "#{web_id} : Timing #{values[1]} avec #{values[2]} erreur"

          my_stats[web_id] = {state: false, timing: []} if my_stats[web_id].nil?
          my_stats[web_id][:state] = (values[2].to_i==0)
          my_stats[web_id][:timing] << {x: iteration_time.to_i, y: my_stats[web_id][:state] ? values[1].gsub(",",".").to_f : 0.0}
          my_stats[web_id][:timing].shift if my_stats[web_id][:timing].length > 9

          # puts my_stats.inspect
          send_event web_id+"-websites", { points: my_stats[web_id][:timing], status: my_stats[web_id][:state] }
        end
      end
    end
  end
end

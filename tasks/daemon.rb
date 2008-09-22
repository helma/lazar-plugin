namespace :daemon do

  desc "Stop lazar daemons"
  task :stop => :environment do
    LazarModule.find(:all).each do |m|
      puts "killing lazar instance with pid #{m.pid}"
      begin
        sh "kill #{m.pid}" if m.pid
      rescue
        puts "no lazar process with pid #{m.pid} running"
      end
    end
    puts "deleting database information"
    LazarModule.delete_all
    LazarCategory.delete_all
  end

  desc "Start lazar daemons"
  task :start => [:stop, :environment] do

    port = `ps aux|grep lazar  | sed 's/.* -p //'|sort -rn|sed -n '1p'`.chomp.to_i
    port = 10000 if port < 10000
    port += 1

    id = 1

    categories = YAML::load(File.open("config/lazar/prediction.yml"))["data"]
    categories.each do |cat_name,modules|

      category = LazarCategory.create(:name => cat_name) unless LazarCategory.find_by_name(cat_name)

      modules.each do |m|

       puts m["endpoint"]

        smi = Dir["#{m["directory"]}/**/data/*.smi"]
        cl = Dir["#{m["directory"]}/**/data/*.class"]
        act = Dir["#{m["directory"]}/**/data/*.act"]
        linfrag = Dir["#{m["directory"]}/**/data/*.linfrag"]
        
        if (!smi.blank? && !linfrag.blank?)

          if !cl.blank?
            m["prediction_type"] = "classification"
            m["applicability_domain"] = 0.025 #unless m["applicability_domain"]
            syscall = "./lazar -s #{RAILS_ROOT}/#{smi} -t #{RAILS_ROOT}/#{cl} -f #{RAILS_ROOT}/#{linfrag} -a #{@lazar_dir}/data/elements.txt -p #{port} 2>/dev/null &"
            m["unit"] = '' unless m["unit"]

          elsif !act.blank?
            m["prediction_type"] = "regression"
            m["applicability_domain"] = '0.2' #unless m["applicability_domain"]
            m["unit"] = '' unless m["unit"]
            syscall = "./lazar -k -s #{RAILS_ROOT}/#{smi} -t #{RAILS_ROOT}/#{act} -f #{RAILS_ROOT}/#{linfrag} -a #{@lazar_dir}/data/elements.txt -p #{port} -r 2>/dev/null &"

          end

          sh "cd #{@lazar_dir} && nohup #{syscall}" do |ok, res|

            if ok
              startup = true
              puts "Waiting for lazar to start ..."

              while startup do
                sleep(1)
                ps = `lsof -i :#{port}`
                startup = false unless ps.empty?
              end
              
              id += 1
              m["id"] = id
              m["pid"] = ps.split(/\n/)[1].split(/\s+/)[1]
              m["port"] = port
              m["lazar_category_id"] = category.id
              LazarModule.create(m)
              puts "lazar started with PID #{m["pid"]} on port #{m["port"]} (#{m["prediction_type"]}, ad: #{m["applicability_domain"]})"

            else
              puts "Could not start lazar: #{res.exitstatus}"

            end

           end

        end

        port += 1
      end

    end
  end

end

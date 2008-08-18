namespace :data do

  desc "Checkout training data"
  task :checkout do
    tree = YAML::parse(File.open("config/lazar/prediction.yml")).transform
    tree.each do |key,data|
      if key == "data" 
        data.each do |db|
          db.each do |d|
            d[1].each do |endpoint|
              svn =  endpoint["svn_url"]
              dir =  endpoint["directory"]
              if FileTest.directory?(dir)
                puts `svn up #{dir}`
              else
                puts `svn co #{svn} #{dir}`
              end
            end
          end
        end
      end
    end
  end

  desc "Extract data source file(s). Depends on a working Rakefile in the src directory of the training data."
  task :extract do
    data_src_dirs("validation").each do |d|
      if File.exist?("#{d}/Rakefile")
        sh "cd #{d} && rake -t" unless Dir["public/data/#{d}/*/data/*smi"] 
      else
        puts "A Rakefile for the extraction of structures and features is missing in #{d}"
      end
    end
    # fix newlines
    data_dirs("validation").each do |d|
      Dir["public/data/#{d}/*/data/*"].each do |file|
        sh "dos2unix #{file}"
      end
    end
  end

end

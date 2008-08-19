require 'classification_loo2summary.rb'
require 'regression_loo2summary.rb'
require 'summary2png.rb'
#require 'stats.rb'
require 'tools.rb'

namespace :validation do

  desc "Validate (pseudo-)external test sets"
  task :external => :lazar do
   
    validation_svn = svn_url("validation")
    data_dirs("validation").each do |dir|

      smi=""
      linfrag=""
      cl=""
      act=""
      ext=""

      Dir["#{dir}/data/*.smi"].each do |smi|

        dataset = (smi.split('/'))[-4]
        linfrag = smi.sub(/\.smi$/,".linfrag")
        cl = smi.sub(/\.smi$/,".class")
        act = smi.sub(/\.smi$/,".act")

        # determine ext input files
        @ext = Dir["#{dir}/data/*ext"]
        @ext.sort!
        
        # for all lazar versions 
        validation_svn.each do |version|
          validation_path = dir + "/validation" + branch_revision(version) +"/"
          FileUtils.mkpath(validation_path) unless FileTest.directory?(validation_path)
          lazar_dir = @lazar_validation_dir + branch_revision(version)

          if FileTest.exists?(cl)
            train = cl
          elsif FileTest.exists?(act)
            train = "#{act} -r -k"
          end

        # for each external test file
          @ext.each do |e|
          ext_out = validation_path+File.basename(e)
          ext_sum = ext_out.sub(/\.ext$/,".sum")

            if (!uptodate?(ext_out, e))
              sh "cd #{lazar_dir}/ && ./lazar -s #{smi} -t #{train} -f #{linfrag} -a #{lazar_dir}/data/elements.txt -i #{e} > #{ext_out} 2>/dev/null"
            end


            if (!uptodate?(ext_sum, [ext_out, "config/lazar/tools.yml"]))

              if FileTest.exists?(cl)
                  classification_loo2summary(ext_out, ext_sum)
              elsif FileTest.exists?(act)
                  regression_loo2summary(ext_out, ext_sum, ad_thresholds(dataset))
              end
            end
          end # end for each external test file

          if FileTest.exists?(act)

              write_extsum = false;
              esp = ""
              es = Array.new

              if (@ext.size > 0)
                  esp = validation_path + (File.basename(@ext[0]).sub(/\.01/,'')) << "sum"
              end
              
              if (esp.size > 0)
              
                  # gather summary files
                  @ext.each do |e|
                      ext_sum = validation_path + (File.basename(e).sub(/\.ext$/,'.sum'))
                      if File.exists?(ext_sum)
                        es << ext_sum
                        write_extsum = true unless FileUtils.uptodate?(esp, ext_sum)
                      else # if File.exists
                        puts "Error: Missing .sum file. Aborting!"
                        exit 1
                      end
                    end
                  end
                  

                  if (write_extsum == true)
                    ads = Array.new;
                    nrs = Hash.new
                    r_sqs = Hash.new
                    was = Hash.new
                    mes = Hash.new
                    rmses = Hash.new

                    es.each do |e|
                        ext_sum_yaml = YAML::load(File.open(e))
                        ext_sum_yaml.each { |d|
                            d.each_key { |k|
                                if (k.index("ad"))
                                    ad = d[k]
                                    if (!ads.include?(ad)) 
                                        ads << ad
                                    end
                                    nrs[ad] = (nrs[ad].to_s << " " << d['nr'].to_s).lstrip
                                    r_sqs[ad] = (r_sqs[ad].to_s << " " << d['rsq'].to_s).lstrip
                                    was[ad] = (was[ad].to_s << " " << d['wa'].to_s).lstrip
                                    mes[ad] = (mes[ad].to_s << " " << d['me'].to_s).lstrip
                                    rmses[ad] = (rmses[ad].to_s << " " << d['rmse'].to_s).lstrip
                                end    
                            }
                        } 
                    end
           
                    if (ads.size > 0)
                      ads.sort!
                      extsum = File.new(esp, "w")
                      ads.each do |ad|
                        extsum.print(ad.sub(/ad/,''), "\t");
                        n = nrs[ad].split.collect! {|n| n.to_i}
                        extsum.print(n.median, "\t")
                        n = r_sqs[ad].split.collect! {|n| n.to_f}
                        extsum.print(n.median, "\t")
                        n = was[ad].split.collect! {|n| n.to_f}
                        extsum.print(n.median, "\t")
                        n = mes[ad].split.collect! {|n| n.to_f}
                        extsum.print(n.median, "\t")
                        n = rmses[ad].split.collect! {|n| n.to_f}
                        extsum.print(n.median, "\t")

                        extsum.print("\n");
                      end 
                    end # end if (ads.size ...)

                  end # end if(write_extsum) == true

                end # end for all lazar versions
                 
              end
          end

      end
  end
   
  desc "Perform leave-one-out crossvalidations"
  task :loo => ["compile:lazar", "lazar:features:fragments"] do 

    # visit all validation databases
    validation_svn = svn_url("validation")
    data_dirs("validation").each do |dir|

      smi=""
      cl=""
      linfrag=""

      Dir["#{dir}/data/*.smi"].each do |smi|

        dataset = (smi.split('/'))[-4]
        linfrag = smi.sub(/\.smi$/,".linfrag")
        cl = smi.sub(/\.smi$/,".class")
        act = smi.sub(/\.smi$/,".act")

        # use all validation versions
        validation_svn.each do |version|

          validation_path = dir + "/validation" + branch_revision(version) +"/"
          FileUtils.mkpath(validation_path) unless FileTest.directory?(validation_path)
          lazar_dir = @lazar_validation_dir + branch_revision(version)
          loo = validation_path + File.basename(smi.sub(/\.smi$/,".loo"))

          if FileTest.exists?(cl)

            if uptodate?( loo , ["#{lazar_dir}/lazar",smi,cl,linfrag])
              puts "#{loo} is up to date."
            else
              begin
                  sh "cd #{lazar_dir}/ && ./lazar -s #{smi} -t #{cl} -f #{linfrag} -x > #{loo}"
              rescue
                  puts "Validation of #{cl} with #{lazar_dir}/lazar failed."
              end
            end

          elsif FileTest.exists?(act)

            if uptodate?( loo , ["#{lazar_dir}/lazar",smi,act,linfrag]) 
              puts "#{loo} is up to date."
            else
              begin
                  sh "cd #{lazar_dir}/ && ./lazar -k -r -s #{smi} -t #{act} -f #{linfrag} -x > #{loo}"
              rescue
                  puts "Validation of #{cl} with #{lazar_dir}/lazar failed."
              end
            end
       
          end # if FileTest.exists?(cl)

        end 
      end
    end
  end

  desc "Create summaries for validation runs"
  #task :summary => :loo do
  task :summary do
    
    classification_ad = 0.025
    regression_ad = 0.2
    # visit all validation databases
    validation_svn = svn_url("validation")

    data_dirs("validation").each do |dir|

      Dir["#{dir}/**/*.loo"].each do |loo|

        dataset = (loo.split('/'))[-7]
        cl = File.basename(loo).sub(/\.loo$/,".class")
        act = File.basename(loo).sub(/\.loo$/,".act")
        path = File.dirname(loo)
        summary_file = path + "/summary.yaml"
        misclassifications_file = path + "/misclassifications.yaml"
        cumulative_accuracies_file = path + "/cumulative_accuracies.yaml"
        cumulative_accuracies_plot = path + "/cumulative_accuracies.png"
        correlation_plot = path + "/correlation.png"
        roc_plot = path + "/roc.png"

        if !Dir["#{dir}/**/#{cl}"].empty?  # classification
          # create summary files
          if uptodate?( summary_file , loo) and uptodate?(misclassifications_file, loo)  and uptodate?(cumulative_accuracies_file, loo) 
            puts "Summary for #{loo} is up to date."
          else
            begin
              classification_loo2summary(loo, summary_file, misclassifications_file, cumulative_accuracies_file,classification_ad)
            rescue
              puts "Summary creation failed for #{loo} with '#{$!}'"
            end
          end
          # create summary plots
          if uptodate?( cumulative_accuracies_plot , cumulative_accuracies_file)
            puts "#{cumulative_accuracies_plot} is up to date."
          else
            begin
              accuracy_plot(cumulative_accuracies_file, cumulative_accuracies_plot,classification_ad)
            rescue
              puts "Plot creation failed for #{cumulative_accuracies_plot} with '#{$!}'"
            end
          end
          # create roc plots
          if uptodate?( roc_plot , summary_file)
            puts "#{roc_plot} is up to date."
          else
            begin
              roc_plot(summary_file, roc_plot)
            rescue
              puts "Plot creation failed for #{roc_plot} with '#{$!}'"
            end
          end

        elsif !Dir["#{dir}/**/#{act}"].empty? # regression
          # create summary files
          if uptodate?( summary_file , loo) and uptodate?(misclassifications_file, loo)  and uptodate?(cumulative_accuracies_file, loo) 
            puts "Summary for #{loo} is up to date."
          else
            begin
              regression_loo2summary(loo, summary_file, misclassifications_file, cumulative_accuracies_file,regression_ad)
            rescue
              puts "Summary creation failed for #{loo} with '#{$!}'"
            end
          end
          # create summary plots
          # cumulative accuracies
          if uptodate?( cumulative_accuracies_plot , cumulative_accuracies_file)
            puts "#{cumulative_accuracies_plot} is up to date."
          else
            begin
              accuracy_plot(cumulative_accuracies_file, cumulative_accuracies_plot,regression_ad)
            rescue
              puts "Image creation failed for #{cumulative_accuracies_plot} with '#{$!}'"
            end
          end
          # correlation
          if uptodate?( correlation_plot , loo)
            puts "#{correlation_plot} is up to date."
          else
            begin
              correlation_plot(loo, correlation_plot,regression_ad)
            rescue
              puts "Image creation failed for #{correlation_plot} with '#{$!}'"
            end
          end
        end

      end
    end

  end

  namespace :compile do 

    desc "Compile lazar versions in config/lazar/validate.yml"
    task :lazar do

      if ENV.include?("r")
        rev=ENV['r']
      else 
        rev="HEAD"
      end

      svn_url("validation").each do |version|
        dir = @lazar_validation_dir + branch_revision(version)
        FileUtils.mkpath(dir) unless FileTest.directory?(dir)
        sh "svn co -r #{rev} #{version} #{dir}"
        sh "cd #{dir}; make lazar"
      end
    end

    desc "Compile testset versions in config/lazar/validate.yml"
    task :external_testset do

      if ENV.include?("r")
        rev=ENV['r']
      else 
        rev="HEAD"
      end

      validation_svn = svn_url("validation")
      c = 0
      validation_svn.each do |t|
        c = c+1
        if (c > 1)
          puts "Error: Multiple validation versions found. Aborting!"
          exit 1
        end
      end

      validation_svn.each do |version|
        dir = @lazar_validation_dir + branch_revision(version)
        FileUtils.mkpath(dir) unless FileTest.directory?(dir)
        sh "svn co -r #{rev} #{version} #{dir}"
        sh "cd #{dir}; make testset"
      end
    end
  end


  desc "Create pseudo-external test sets"
  task :testsets => :external_testset do

    nr = 0
    size_p = 0
    tsp = test_set_params
    nr = tsp["test_sets_nr"].to_i unless !tsp["test_sets_nr"]
    size_p = tsp["test_sets_size_p"].to_i unless !tsp["test_sets_size_p"]
    validation_svn = svn_url("validation")

    if (nr == 0 && size_p>0 && size_p<100) 
      # creating folds
      nr = (100.0 / size_p).to_i
      puts "Creating #{nr.to_i} consecutive sets (folds) with size #{size_p}% using the whole database."
      data_dirs("validation").each do |dir|
        `rm #{dir}/data/*.ext `
        Dir["#{dir}/data/*.smi"].each do |smi|
          begin
            db_size = `wc -l #{smi} | sed 's/ .*/''/g'`.to_i
          rescue
            puts "Problems reading database size. Aborting!"
            exit(1);
          end
          fold_size = (db_size / nr).to_i
          for i in (1..nr)
            puts "Creating fold nr. #{i} with #{fold_size} compounds."
            il = sprintf("%02i", i)
            ext = smi.sub(/\.smi$/,".#{il}.ext")
            validation_svn.each do |version|
              lazar_dir = @lazar_validation_dir + branch_revision(version)
              start_index = ((i-1)*fold_size)
              sh "#{lazar_dir}/testset -s #{smi} -p #{size_p} -i #{start_index} > #{ext} 2>/dev/null"
            end
          end
        end
      end

    elsif (nr>0 && size_p>0 && size_p<100)
      # creating random sets
      puts "Creating #{nr} random sets with size #{size_p} %."
      data_dirs("validation").each do |dir|

        `rm #{dir}/data/*.ext `
        for i in (1..nr) do
          Dir["#{dir}/data/*.smi"].each do |smi|
            il = sprintf("%02i", i)
            ext = smi.sub(/\.smi$/,".#{il}.ext")
            validation_svn.each do |version|
              lazar_dir = @lazar_validation_dir + branch_revision(version)
              sh "#{lazar_dir}/testset -s #{smi} -p #{size_p} > #{ext} 2>/dev/null"
            end
          end
        end

      end

    else 
      puts "Error: at least 1 test set needed, sizes only between 1% and 100%"
    end 
  end

  desc "Remove all old validation results"
  task :cleanup do
    max = 0
    Dir["public/data/**/validation/**/trunk/*"].each do |d|
      version = File.basename(d).to_i
      FileUtils.rm_rf(d) if version < max
      max = version if version > max
    end
    Dir["public/data/**/validation/**/branches"].each do |d|
      FileUtils.rm_rf(d) 
    end
  end

  desc "Submit validation results to subversion repository"
  task :checkin do
    YAML::load(File.open("config/svn.yml"))["data"].each do |db|
      dir = db.gsub(%r{svn://www\.in-silico\.de/opentox},'public')
      `svn st #{dir}`.each do |line|
        puts line
        items = line.split(/\s+/)
        case items[0]
        when '?'
          puts `svn add #{items[1]}`
        when '!'
          puts `svn rm #{items[1]}`
        end
      end
      begin
        sh "cd #{dir} && svn ci -m 'Validation results for #{File.basename(dir)} updated.' "
      rescue
        puts "svn submission of #{dir} failed"
      end
    end
  end

end

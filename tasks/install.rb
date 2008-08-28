namespace :program do

  desc "Install the complete lazar system"
  task :install => "lazar:program:compile"

  desc "Checkout lazar source"
  task :checkout do
    url = YAML.load(File.open("config/lazar/prediction.yml"))['url']
    if File.exist?(@lazar_dir)
      sh "cd #{@lazar_dir} && git pull"
    else
      sh "git clone #{url} #{@lazar_dir}"
    end
  end

  desc "Compile lazar"
  task :compile => ["lazar:program:checkout"] do
    sh "cd #{@lazar_dir}; make; cp -f linfrag lazar #{@bin_dir}/"
  end

end

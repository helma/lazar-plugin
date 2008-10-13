desc "Install the complete lazar system"
task :install => :compile

namespace :R do

  require 'environment.rb'
  path = ENV["R_HOME"]
  r = path+"/bin/R"

  namespace :install do

    desc "install the kernlab package"
    task :kernlab do
      sh "cd #{path} && wget http://www.in-silico.de/~ch/kernlab_0.9-7.tar.gz" unless File.exist?(path+"/kernlab_0.9-7.tar.gz")
      sh "cd #{path} && #{r} CMD INSTALL kernlab_0.9-7.tar.gz" unless uptodate?("#{path}/library/kernlab","#{path}/kernlab_0.9-7.tar.gz")
    end
  end
end

desc "Checkout lazar source"
task :checkout do
  url = YAML.load(File.open("config/lazar/prediction.yml"))['url']
  sh "git clone #{url} #{@lazar_dir}" unless File.exist?(@lazar_dir)
  sh "cd #{@lazar_dir} && git pull"
end

desc "Compile lazar"
task :compile => ["R:install:kernlab", :checkout] do
  sh "cd #{@lazar_dir}; make"
end

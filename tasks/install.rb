namespace :program do

  desc "Install the complete lazar system"
  task :install => "lazar:program:compile"

  desc "Checkout lazar source"
  task :checkout do
    sh "svn co #{svn_url("prediction")} #{@lazar_dir}"
  end

  desc "Compile lazar"
  task :compile => "lazar:program:checkout" do
    sh "cd #{@lazar_dir}; make lazar"
  end

end

namespace :features do

  desc "Create linear fragments"
  task :fragments => "lazar:data:extract" do
    data_dirs("validation").each do |dir|
      Dir["#{dir}/data/*.smi"].each do |smi|
        linfrag = smi.sub(/\.smi$/,".linfrag")
        if File.exist?(linfrag)
          sh "#{@lazar_dir}/linfrag -s #{smi} -a #{@lazar_dir}/data/elements.txt > #{linfrag} 2>/dev/null"  if File.mtime(smi) > File.mtime(linfrag) 
        else
          sh "#{@lazar_dir}/linfrag -s #{smi} -a #{@lazar_dir}/data/elements.txt > #{linfrag} 2>/dev/null" 
        end
      end
    end
  end

end

# tools to read configuration files

def ad_thresholds(dataset)
  ads = YAML::load(File.open("config/lazar/validation.yml"))["ad"][dataset]
  if ads
    return ads
  else
    puts "Error: No ad thresholds in config file found for dataset '#{dataset}'!"
    exit(1)
  end
end

def svn_url(item)
  tree = YAML::parse(File.open("config/lazar/#{item}.yml")).transform
  case item
  when "prediction"
    r =  tree["version"]
  when "tools"
    r =  tree["version"]
  when "validation"
    r =  tree["versions"]
  end
  r
end

def test_set_params
  tree = YAML::parse(File.open("config/lazar/validation.yml")).transform
  test_set_params = { "nr_test_sets" => 0, "size_test_sets" => 0 }
  test_set_params["test_sets_nr"] = tree["test_sets_nr"] unless !tree["test_sets_nr"] 
  test_set_params["test_sets_size_p"] = tree["test_sets_size_p"] unless !tree["test_sets_size_p"]
  test_set_params
end

def data_dirs(item)
  tree = YAML::parse(File.open("config/lazar/#{item}.yml")).transform
  dirs = []
  if tree["data"]
    tree["data"].each do |database|
      Dir["#{RAILS_ROOT}/public/data/#{database}/*"].each do |dir|
        dirs << dir unless dir =~ /src/
      end
    end
  end
  dirs
end

def data_src_dirs(item)
  tree = YAML::parse(File.open("config/lazar/#{item}.yml")).transform
  dirs = []
  if tree["data"]
    tree["data"].each do |database|
      Dir["#{RAILS_ROOT}/public/data/#{database}/*"].each do |dir|
        dirs << dir if dir =~ /src/
      end
    end
  end
  dirs
end

def branch_revision(url)
  svninfo = `svn info #{url}`
  unless svninfo.empty?
    if ENV.include?("r")
      revision=ENV['r']
    else 
      revision = svninfo.grep(/Last Changed Rev/)[0].gsub(/.*Last Changed Rev: /,"").chomp 
    end
    svnurl = svninfo.grep(/URL/)[0].gsub(/.*URL: /,"").chomp
    svn_root = svninfo.grep(/Repository Root/)[0].gsub(/.*Repository Root: /,"").chomp

    data = svnurl.sub(svn_root,'') + "/" + revision
  end
  data
end


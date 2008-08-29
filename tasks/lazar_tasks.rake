$: << File.expand_path(File.dirname(__FILE__))
require 'yaml'
require 'R.rb'


namespace :lazar do

  @lazar_dir = RAILS_ROOT + "/vendor/src/lazar/"
  @lazar_validation_dir = RAILS_ROOT + "/vendor/plugins/lazar/lib/validation/"

  require 'data.rb'
  require 'install.rb'
  require 'features.rb'
  require 'validation.rb'
  require 'server.rb'
  require 'tools.rb'

end

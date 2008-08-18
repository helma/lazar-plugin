$: << File.expand_path(File.dirname(__FILE__))
require 'yaml'
require 'R.rb'


namespace :lazar do

  @lazar_dir = RAILS_ROOT + "/vendor/plugins/lazar/lib/lazar/"
  @lazar_validation_dir = RAILS_ROOT + "/vendor/plugins/lazar/lib/validation/"
  @lazar_tools  = RAILS_ROOT + "/vendor/plugins/lazar/lib/tools"

  require 'data.rb'
  require 'install.rb'
  require 'features.rb'
  require 'validation.rb'
  require 'server.rb'
  require 'tools.rb'

end

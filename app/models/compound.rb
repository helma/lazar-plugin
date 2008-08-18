require_dependency "#{RAILS_ROOT}/vendor/plugins/opentox/app/models/compound.rb" 

class Compound < ActiveRecord::Base
  has_and_belongs_to_many :lazar_modules
end

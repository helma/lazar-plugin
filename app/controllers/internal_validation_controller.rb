require 'stats.rb'
require 'csv'

class InternalValidationController < ApplicationController
  layout "lazar"

  def index
    @databases = YAML::parse(File.open("config/lazar/validation.yml")).transform["data"]
    @categories = Array.new(@databases.length)
    j = 0;
    while j<@databases.length do
	@categories[j] = Dir["public/data/#{@databases[j]}/**/*{loo,extsum}"]
	j += 1
    end
    @categories.each do |cat|
      cat.sort!
    end

  end

  def show
    @databases = YAML::parse(File.open("config/lazar/validation.yml")).transform["data"]
    @categories = Array.new(@databases.length)
    j = 0;
    while j<@databases.length do
	@categories[j] = Dir["public/data/#{@databases[j]}/**/*{loo,extsum}"]
	j += 1
    end
    @categories.each do |cat|
      cat.sort!
    end

    @identifier = params[:id].to_s.split('_')
    @d_id = @identifier[0];
    @valrun = @identifier[1];

    j = 0
    while j<@categories.length do
      j += 1
      if (j == @d_id.to_i)
        i = 0

        (@categories[j-1]).each do |cat|
          i += 1

          if (i == @valrun.to_i) 
            # determine data info
            (cat.index('trunk')!=NIL) ? offset = 1 : offset = 0
            @dataset = cat.split(/\//)[-8+offset]
    	    @endpoint = cat.split(/\//)[-7+offset]
	        @revision = cat.split(/\//)[-2]
    	    @branch = cat.split(/\//)[-3]
            if (File.extname(cat) == (".loo"))
               # read loo summary file
	           @summary_file = cat.sub(/loo/,'summary')
               @summary = YAML::load(File.open(@summary_file))
               #@summary=true
            elsif (File.extname(cat) == (".extsum"))
               ext_reader = CSV.open(cat, 'r')
               @ext_data = Array.new
               row = ext_reader.shift
               until row.empty? 
                 @ext_data << row
                 row = ext_reader.shift
               end
               ext_reader.close
               # find external test set summary files
               extsum_path = cat.sub(/extsum/,'*.sum')
               @extsum = Dir["#{extsum_path}"]
            end
            break

          end # end (i == @valrun.to_i)
        end # end (@categories[j-1]).each do |cat|

      end # end if (j == @d_id.to_i)
    end # end while j<@categories.length do
  end
end

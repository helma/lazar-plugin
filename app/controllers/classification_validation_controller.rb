class ClassificationValidationController < ApplicationController

  layout "lazar"

  def index

    @endpoints = {}
    @versions = []
    @weighted_accuracies = {}
    @max = {}

    @databases = YAML::load(File.open("config/lazar/validation.yml"))["data"]
    @databases.each do |d|
      @endpoints[d] = Dir["public/data/#{d}/*"]
      @endpoints[d].each do |e|
        summaries = Dir["#{e}/**/*summary"]
        unless summaries.blank? || Dir["#{e}/**/*class"].blank?
          @weighted_accuracies[e] = {}
          @max[e] = {}
          max = 0
          Dir["#{e}/**/*summary"].each do |s|
            begin
              if s.match(/lazar/)
                version = s.sub(/#{e}\/validation\/lazar\/(.*)\/.*summary/,'\1')
              else
                version = '-'
              end
              acc = YAML::load(File.open(s))[:weighted][:accuracy]
              @weighted_accuracies[e][version] = acc 
              max = acc if acc >= max
              @versions << version
            rescue
            end
          end
          @weighted_accuracies[e].each do |v,a|
            if a == max
              @max[e][v] = true
            else
              @max[e][v] = false
            end
          end
        end
      end
    end
    @versions.uniq!
  end

  def show
    
    @versions = []
    @images = {}
    @summaries = {}

    Dir["#{params[:endpoint]}/validation/lazar/**/*summary"].each do |s|
      version = s.sub(/#{params[:endpoint]}\/validation\/lazar\/(.*)\/.*summary/,'\1')
      @versions << version
      @images[version] = s.sub(/public/,'').sub(/summary/,'png')
      @summaries[version] = YAML::load(File.open(s))
    end

    @nr = {}

    @tp = {}
    @tn = {}
    @fp = {}
    @fn = {}

    @sens = {}
    @spec = {}
    @pp = {}
    @np = {}
    @fpr = {}
    @fnr = {}
    @acc = {}

    ["weighted","within_ad","all"].each do |t| 

      @tp[t] = []
      @tn[t] = []
      @fp[t] = []
      @fn[t] = []

      @nr[t] = []

      @sens[t] = []
      @spec[t] = []
      @pp[t] = []
      @np[t] = []
      @fpr[t] = []
      @fnr[t] = []
      @acc[t] = []

      @versions.each do |v|

        begin

          if t == "weighted"
            tp = @summaries[v][t.intern][:tp].to_f
            tn = @summaries[v][t.intern][:tn].to_f
            fp = @summaries[v][t.intern][:fp].to_f
            fn = @summaries[v][t.intern][:fn].to_f
          else
            tp = @summaries[v][t.intern][:tp].to_i
            tn = @summaries[v][t.intern][:tn].to_i
            fp = @summaries[v][t.intern][:fp].to_i
            fn = @summaries[v][t.intern][:fn].to_i
          end

          @tp[t] << tp
          @fp[t] << fp
          @tn[t] << tn
          @fn[t] << fn

          @nr[t] << tp+tn+fp+fn
          @sens[t] << tp.to_f/(tp+fn)
          @spec[t] << tn.to_f/(tn+fp)
          @pp[t] << tp.to_f/(tp+fp)
          @np[t] << tn.to_f/(tn+fn)
          @fpr[t] << fp.to_f/(tp+fn)
          @fnr[t] << fn.to_f/(tn+fp)
          @acc[t] << (tp+tn).to_f/(tp+tn+fp+fn)

        rescue
        end

      end

    end
  end

  def misclassifications

    sum = Dir["**/#{params["endpoint"]}/validation/**/#{params["version"]}/*.summary"][0]
    summary = XmlSimple.xml_in(sum, { 'ForceArray' => false })
    @endpoint_id = LazarModule.find_by_directory(params["endpoint"]).id
    @misclassifications = summary["misclassifications"]["misclassification"]
      
  end

end


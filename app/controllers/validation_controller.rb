class ValidationController < ApplicationController

  layout 'lazar'

  def index
    @categories = LazarCategory.find(:all)
  end

  def show
    load
    case @module.prediction_type
    when "regression"
      render :action => :regression
    when "classification"
      render :action => :classification
    end
  end

  def misclassifications
    load
    @misclassifications = YAML.load(File.open(@misclassification_file))
  end

  private 

  def load
    @module = LazarModule.find(params[:id])
    @conf_limit = @module.applicability_domain.to_f
    @version = `cd vendor/plugins/lazar/lib/lazar; svn info |grep "Last Changed Rev:"|sed 's/Last Changed Rev: //'`.chomp.to_i
    @svn_url = YAML::load(File.open("config/lazar/prediction.yml"))["version"]
    path = "#{@module.directory}/validation/lazar/trunk/#{@version}/"
    @summary_file = path + "summary.yaml"
    @misclassification_file = path + "misclassifications.yaml"
    path.sub!(/public/,'')
    @cumulative_accuracy_file = path + "cumulative_accuracies.png"
    @roc_file = path + "roc.png"
    @correlation_file = path + "correlation.png"
    @summary = YAML::load(File.open(@summary_file))
  end

end

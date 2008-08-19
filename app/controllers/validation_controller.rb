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
    @tag = `cd #{RAILS_ROOT}/vendor/lib/lazar; git tag`.chomp.to_i
    @git_url = YAML::load(File.open("config/lazar/prediction.yml"))["url"]
    path = "#{@module.directory}/validation/lazar/trunk/#{@tag}/"
    @summary_file = path + "summary.yaml"
    @misclassification_file = path + "misclassifications.yaml"
    path.sub!(/public/,'')
    @cumulative_accuracy_file = path + "cumulative_accuracies.png"
    @roc_file = path + "roc.png"
    @correlation_file = path + "correlation.png"
    @summary = YAML::load(File.open(@summary_file))
  end

end

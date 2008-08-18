class DocumentationController < ApplicationController

  layout "lazar"

  def index
    @svn_url = YAML::load(File.open("config/lazar/prediction.yml"))["version"]
  end

  def faq
  end

end

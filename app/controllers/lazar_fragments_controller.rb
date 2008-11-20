class LazarFragmentsController < ApplicationController

  layout 'lazar'

  def index
    @lazar = session[:lazar]
  end

end

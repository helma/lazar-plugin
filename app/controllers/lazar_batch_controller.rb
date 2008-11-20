class LazarBatchController < ApplicationController

  layout 'lazar'

  def upload
    @endpoints = LazarModule.find(:all)
  end

  def batch_prediction

    session[:page] = 1
    prefix = "tmp/"

    smiles_file = prefix + params[:file].original_filename
    File.delete(smiles_file) if File.exists?(smiles_file)
    File.open(smiles_file, "w") { |f| f.write(params[:file].read) }

    session[:batch_smiles] = []
    File.open(smiles_file).each do |line|
      session[:batch_smiles] << line.chomp.split(/\t/)
    end

    redirect_to :action => :batch_results, :endpoint_id => params[:endpoint_id]

  end

  def batch_results

    @items_per_page = 5
    @lazar_module = LazarModule.find(params[:endpoint_id])

    session[:page] = params[:page] if params[:page]

    @next_page = session[:page].to_i + 1
    @previous_page = session[:page].to_i - 1
    @start_item = @items_per_page * (session[:page].to_i - 1)
    @size = session[:batch_smiles].size
    @nr_pages = @size/@items_per_page

    @results = {}
    session[:batch_smiles].slice(@start_item, @items_per_page).each do |s|
      lazar = LazarClassifier.new(params[:endpoint_id])
      @results[s[0]] = lazar.predict(s[1])
    end

  end

  def fragments
    @lazar = session[:lazar]
  end

  def jme_help
    redirect_to "public/applets/jme_help.html"
  end
  
  private

  def translate_activity(act, unit)
    act_s = act.to_s
    case act_s
      when 'inactive'
        a = 'inactive'
      when '0'
        a = 'inactive'
      when 'active'
        a = 'active'
      when '1'
        a = 'active'
      else
        begin
          act_f = Float act_s 
          digits = act_f.to_i.abs + 3
          formatstr = "%."+digits.to_s+"f"
          a = round(10**act_f, 10)
          a = sprintf(formatstr+" ", a), unit;
        rescue 
          a = 'not available'
      end
    end
    a
  end

  def display_smiles_with_fragments(smiles, activating_fragments,deactivating_fragments,activating_p,deactivating_p,unknown_fragments)
    session[:smiles] = smiles
    session[:activating_fragments] = activating_fragments
    session[:deactivating_fragments] = deactivating_fragments
    session[:unknown_fragments] = unknown_fragments
    session[:activating_p] = activating_p
    session[:deactivating_p] = deactivating_p

    '<img src="' + url_for(:controller => "compounds", :action => "display_smiles_with_fragments", :smiles => smiles) + '" alt="' + smiles +'"></img>'
  end

end

class LazarController < ApplicationController

  layout 'lazar'

  def input
    session[:lazar] = nil
    # load current compound
    unless params[:smiles].blank?
      begin
        mol = CdkMol.new(params[:smiles])
        @molfile = mol.jme_molfile
      rescue
        flash[:notice] = "Cannot process '" + params[:smiles] + "'!"
      end
    end
    @endpoints = LazarModule.find(:all)
  end

  def prediction
    @module = LazarModule.find(params[:endpoint_id])
    if !params[:smiles].blank? 
      begin
        Obmol.new(params[:smiles]) # invalid smiles should fail here
        if @module[:prediction_type] == "classification"
          @lazar = LazarClassifier.new(params[:endpoint_id])
        elsif @module[:prediction_type] == "regression"
          @lazar = LazarRegression.new(params[:endpoint_id])
        end
        @lazar.predict(params[:smiles])
        session[:lazar] = @lazar
      rescue
        flash[:notice] = "lazar prediction for smiles '" + params[:smiles] + "' failed. Did you provide a valid structure?"
        session[:lazar] = nil
      end
    else
      flash[:notice] = "Please draw a structure or enter a smiles string."
    end
  end

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
  

end

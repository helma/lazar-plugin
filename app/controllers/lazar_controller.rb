class LazarController < ApplicationController

  layout 'lazar'

  def index
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

  def show
    @module = LazarModule.find(params[:endpoint_id])
    session[:lazar] = nil
    unless params[:smiles].blank? 
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
      end
    else
      flash[:notice] = "Please draw a structure or enter a smiles string."
    end
  end

end

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # a recent bug in rails forces us to include in the class definition
  load(RAILS_ROOT+"/vendor/plugins/opentox/app/models/inputs_output.rb")
  require 'rjb'
  require 'net/http'
  require 'uri'
  require 'rubygems'
  require 'hpricot'
  require 'open-uri'

  layout 'lazar'

	ActiveScaffold.set_defaults do |conf|
		conf.actions.exclude :delete, :edit
	end


  def pubchem_url_from_smiles(smiles)
    h('http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=PureSearch&db=pccompound&term=' + smiles2inchi(smiles))
  end

  def smiles2inchi(smiles)

    sp = Rjb::import('org.openscience.cdk.smiles.SmilesParser').new
    sw = Rjb::import('java.io.StringWriter').new
    mdl_writer = Rjb::import('org.openscience.cdk.io.MDLWriter').new
    mol2inchi = Rino::MolfileReader.new

    mol = sp.parseSmiles(smiles)
    mdl_writer.setWriter(sw)
    mdl_writer.write(mol)

    mol2inchi.read(sw.toString)

  end

  #
  def inchi2iupac(inchi)
    cid = inchi2cid(inchi)
    cid2smiles_iupac_inchi(cid)["iupac"]
  end

  # get PubChem CID from InChI
  def inchi2cid(inchi)
    begin
      agent = WWW::Mechanize.new
      url = ERB::Util.h("http://www.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pccompound&retmax=100&term=%22InChI=#{inchi}%22[InChI])")
      page = agent.get(url)
      (page.parser/"id").collect {|id| id.innerHTML}
    rescue
      url
    end
  end

  # get PubChem CID from CAS number
  def cas2cid(cas)
    agent = WWW::Mechanize.new
    page = agent.get("http://www.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pccompound&retmax=100&term=#{cas}")
    (page.parser/"id").collect {|id| id.innerHTML}
  end

  # get smiles, iupac name and InChI from PubChemID
  def cid2smiles_iupac_inchi(cid)
    result = {}
    summary = Hpricot(open("http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=#{cid}"))
    summary.to_s.split(/\n/).each do |line|
		  result["smiles"] = line.sub(/<b>.*<\/b>/,'').gsub(/<br \/>/,'') if line.match(/SMILES/)
		  result["iupac"] =  line.sub(/<b>.*<\/b>/,'').gsub(/<br \/>/,'') if line.match(/IUPAC/)
		  result["inchi"] =  line.sub(/<b>.*name="passinchi">/,'').sub(/<\/a>.*/,'').gsub(/<br \/>/,'') if line.match(/InChI:/)
    end
    result
  end

end

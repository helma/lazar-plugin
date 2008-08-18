class LazarRegression

require 'rubygems'
require 'statarray'

  # a recent bug in rails forces us to include in the class definition
  include Socket::Constants

  attr_reader :details, :activating_fragments, :deactivating_fragments, :activating_p, :deactivating_p, :unknown_fragments

  def initialize(endpoint_id)
    port = LazarModule.find(endpoint_id).port
    @socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
    sockaddr = Socket.pack_sockaddr_in( port, 'localhost' )
    @socket.connect( sockaddr )
  end

  def predict(smiles)
    @socket.write( smiles )
    @details = YAML::load(@socket.read)


    @activating_fragments = []
    @deactivating_fragments = []
    @activating_p = []
    @deactivating_p = []
    @unknown_fragments = []

    if @details['features']
        @details['features'].each do |f|
           @activating_fragments << f['smarts'] if f['property'] == 'activating'
           @deactivating_fragments << f['smarts'] if f['property'] == 'deactivating'
           @activating_p << f['p_ks'] if f['property'] == 'activating'
           @deactivating_p << f['p_ks'] if f['property'] == 'deactivating'
        end
    end   
 
    if @details['unknown_features']
        @details['unknown_features'].each do |f|
          @unknown_fragments << f
        end
    end
  end

  def prediction
    @details['prediction']
  end

  def confidence
    @details['confidence']
  end

  def db_activity
    db_act = ''
    if @details['db_activity']
	    @details['db_activity'].each do |act|
    		db_act += act.to_s
            db_act += ' / '
	    end
    else
       	db_act = '' 
    end
    db_act.sub(/ \/ $/,'')
  end
    

  def smiles
    @details['smiles']
  end

  def inchi
    @details['inchi']
  end

  def neighbors
    @details['neighbors']
  end

  def features
    @details['features']
  end

  def med_ndist
    @details['med_ndist']
  end

  def std_ndist
    @details['std_ndist']
  end

  def db_activity_class
  end

  def conf_colorcode(applicability_domain)
    #if (!unreliable_explanation(applicability_domain).empty?)
    #  return 'class="unknown"'
    #else
    #  return 'class="inactive"'
    #end
  end 
 
  def unreliable_explanation(applicability_domain)

    explanation = ''

    unknown_features = low_conf = false
    begin
      if @details['unknown_features']
        unknown_features = true
      end
      if @details['confidence'] < applicability_domain.to_f
        low_conf = true
      end
    rescue
    end

    explanation = "<p/><b>unreliable:</b>" if unknown_features
    explanation = explanation + '<br/>unknown/infrequent features' if unknown_features
    explanation = explanation + '<br/>low confidence (<' + applicability_domain + ')' if low_conf

    explanation

  end

  def prediction_quality
    explanation = ""

    if @details['db_activity']
        db_statarr = @details['db_activity'].to_statarray
        if ((db_statarr.median - prediction.to_f).abs <= 1.0)
            explanation = "<p/>prediction within 1 log unit"
        else
            explanation = "<p/>prediction <b>not</b> within 1 log unit"
        end
    end
  
  end

  def query_structure
    [ self.smiles, @activating_fragments, @deactivating_fragments, @activating_p, @deactivating_p]
  end

  def neighbor_activity(n)
    sum = 0
    activity = ''
    n['activity'].each do |a|
      sum += a.to_f
      digits = a.to_i.abs + 3
      formatstr = "%."+digits.to_s+"f"
      a = 10**a.to_f;
      a = sprintf(formatstr, a);
      activity += "#{a} / "
    end
    act = sum/n['activity'].size
    {'activity' => activity.sub(/ \/ $/,''), 'class' => ''}
  end

end

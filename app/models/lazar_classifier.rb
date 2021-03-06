class LazarClassifier

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
        @activating_p << f['p_chisq'] if f['property'] == 'activating'
        @deactivating_p << f['p_chisq'] if f['property'] == 'deactivating'
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
	      case act
	      when 0
    		db_act += 'inactive / '
	      when 1
	    	db_act += 'active / '
	      end
	    end
    else
   	    db_act = "not available" 
    end
    db_act.sub(/ \/ $/,'')
  end

  def db_activity_class
    db_act = 0
    if @details['db_activity']
	    @details['db_activity'].each do |act|
	      db_act += act.to_i
	    end
	    db_act = db_act.to_f/@details['db_activity'].size
	    if db_act > 0.5
	      cl = "class = 'active'"
	    elsif db_act < 0.5
	      cl = "class = 'inactive'"
	    else
	      cl = "class = 'unknown'"
	    end
    else
    	cl = ''
    end
    cl
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

  def applicability_domain 
    @module.applicability_domain
  end

  def conf_colorcode (applicability_domain)
    if (!unreliable_explanation(applicability_domain).empty?) 
      return 'class="unknown"'
    elsif prediction == 1
      return 'class="active"'
    elsif prediction == 0
      return 'class="inactive"'
    end
  end 

  def unreliable_explanation(applicability_domain)

    explanation = ''

    unknown_features = low_conf = false
    begin
      if !@details['unknown_features'].blank?
        unknown_features = true
      end
      if (@details['confidence'].to_f.abs < applicability_domain.to_f)
        low_conf = true
      end
    rescue
    end

    explanation = "<p/><b>unreliable:</b>" if unknown_features || low_conf
    explanation = explanation + '<br/>unknown/infrequent features' if unknown_features
    explanation = explanation + '<br/>low confidence (<' + applicability_domain + ')' if low_conf

    explanation

  end

  def prediction_quality
    explanation = ""
#    if !db_activity.empty?
#      if (db_activity.to_s == prediction.to_s)
#        explanation = "<p/>correctly classified"
#      else
#        explanation = "<p/><b>not</b> correctly classified"
#      end
#    end
  end

  def query_structure
    [ self.smiles, @activating_fragments, @deactivating_fragments, @activating_p, @deactivating_p]
  end

  def neighbor_activity(n)
    sum = 0
    activity = ''
    n['activity'].each do |a|
      sum += a.to_f
      case a
      when 0
        activity += 'inactive / '
      when 1
        activity += 'active / '
      end
    end
    act = sum/n['activity'].size
    if act > 0.5
      cl = 'active'
    elsif act < 0.5
      cl = 'inactive'
    else
      cl = 'unknown'
    end
    {'activity' => activity.sub(/ \/ $/,''), 'class' => cl}
  end

end

class LazarRegression

require 'rubygems'
require 'statarray'

  # a recent bug in rails forces us to include in the class definition
  include Socket::Constants

  attr_reader :details, :activating_fragments, :deactivating_fragments, :activating_p, :deactivating_p, :unknown_fragments

  def initialize(endpoint_id)
    @port = LazarModule.find(endpoint_id).port
  end

  def predict(smiles)

    socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
    sockaddr = Socket.pack_sockaddr_in( @port, 'localhost' )
    socket.connect( sockaddr )
    socket.write( smiles )

    @result = YAML::load(socket.read)


    @activating_fragments = []
    @deactivating_fragments = []
    @activating_p = []
    @deactivating_p = []
    @unknown_fragments = []

    if @result['features']
        @result['features'].each do |f|
           @activating_fragments << f['smarts'] if f['property'] == 'activating'
           @deactivating_fragments << f['smarts'] if f['property'] == 'deactivating'
           @activating_p << f['p_ks'] if f['property'] == 'activating'
           @deactivating_p << f['p_ks'] if f['property'] == 'deactivating'
        end
    end   
 
    if @result['unknown_features']
        @result['unknown_features'].each do |f|
          @unknown_fragments << f
        end
    end
  end

  def prediction
    @result['prediction']
  end

  def confidence
    @result['confidence']
  end

  def db_activity
    db_act = ''
    if @result['db_activity']
	    @result['db_activity'].each do |act|
    		db_act += act.to_s
            db_act += ' / '
	    end
    else
       	db_act = '' 
    end
    db_act.sub(/ \/ $/,'')
  end

  def smiles
    @result['smiles']
  end

  def inchi
    @result['inchi']
  end

  def neighbors
    @result['neighbors']
  end

  def features
    @result['features']
  end

  def med_ndist
    @result['med_ndist']
  end

  def std_ndist
    @result['std_ndist']
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
      if @result['unknown_features']
        unknown_features = true
      end
      if @result['confidence'] < applicability_domain.to_f
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

    if @result['db_activity']
        db_statarr = @result['db_activity'].to_statarray
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

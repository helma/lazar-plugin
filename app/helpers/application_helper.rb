module ApplicationHelper

  def round(float, num_of_decimal_places)
      exponent = num_of_decimal_places + 2
      @float = float*(10**exponent)
      @float = @float.round
      @float = @float / (10.0**exponent)
  end 

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

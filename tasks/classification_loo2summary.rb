def classification_loo2summary(loo,summary_file, misclassifications_file, cumulative_accuracies_file, ad_threshold=0.025)

  puts "Creating summary for #{loo}" 

  tp = 0
  wtp = 0
  ad_tp = 0

  tn = 0
  wtn = 0
  ad_tn = 0

  fp = 0
  wfp = 0
  ad_fp = 0

  fn = 0
  wfn = 0
  ad_fn = 0

  weighted_accuracy = 0.0
  ad_accuracy = 0.0
  accuracy = 0.0
  db_act=0.0

  misclassifications = []
  prediction_confidences = []
  
  # parse output file
  YAML::load_documents(File.open(loo)) { |p|

      unless ( p['prediction'].nil? || p['confidence'].nil? || p['db_activity'].nil?)

          # get primary data
          id = p['id']
          db_activities = p['db_activity']
          pred = p['prediction']
          conf = p['confidence'].abs
          smile = p['smiles']
          if p['known_fraction'] == 1
            unknown_features = false
          else
            unknown_features = true
          end

          sum = 0.0
          cnt = 0
          db_activities.each { |a|
              sum += a.to_i
              cnt += 1
          }
          if cnt 
              db_act = sum.to_f/cnt
          end
      
          if (pred == 1 && db_act >= 0.5)
              tp += 1
              wtp += conf
              ad_tp += 1 if conf > ad_threshold
              prediction_confidences << {:id => id.to_s, :confidence => conf, :correct_prediction => true}
          elsif (pred == 0 && db_act < 0.5)
              tn += 1
              wtn += conf
              ad_tn += 1 if conf > ad_threshold
              prediction_confidences << {:id => id.to_s, :confidence => conf, :correct_prediction => true}
          elsif (pred == 1 && db_act < 0.5)
              fp += 1
              wfp += conf
              ad_fp += 1 if conf > ad_threshold
              misclassifications << {:id => id.to_s, :smiles => smile, :prediction => pred, :confidence => conf, :db_activities => db_activities, :unknown_features => unknown_features}
              prediction_confidences << {:id => id, :confidence => conf, :correct_prediction => false}
          elsif (pred == 0 && db_act >= 0.5)
              fn += 1
              wfn += conf
              ad_fn += 1 if conf > ad_threshold
              misclassifications << {:id => id.to_s, :smiles => smile, :prediction => pred, :confidence => conf, :db_activities => db_activities, :unknown_features => unknown_features } if conf > ad_threshold
              prediction_confidences << {:id => id.to_s, :confidence => conf, :correct_prediction => false}
          end

      end
  } # end parsing

  if (wtp+wtn+wfp+wfn) > 0
      weighted_accuracy = (wtp+wtn) / (wtp+wtn+wfp+wfn)
  end
  if (ad_tp+ad_tn+ad_fp+ad_fn) > 0
      ad_accuracy = (ad_tp+ad_tn).to_f / (ad_tp+ad_tn+ad_fp+ad_fn)
  end
  if (tp+tn+fp+fn) > 0
      accuracy = (tp+tn).to_f / (tp+tn+fp+fn)
  end

  misclassifications.sort! { |x,y| y[:confidence] <=> x[:confidence] }
  prediction_confidences.sort! { |x,y| y[:confidence] <=> x[:confidence] }

  n = 0
  correct_predictions = 0

  prediction_confidences.each do |c|
    n += 1
    correct_predictions += 1 if c[:correct_prediction]
    c[:cumulative_accuracy] = correct_predictions.to_f/n
  end

  sum = { :weighted => {
      :tp => wtp,
      :tn => wtn,
      :fp => wfp,
      :fn => wfn,
      :accuracy => weighted_accuracy },

   :within_ad => {
      :tp => ad_tp,
      :tn => ad_tn,
      :fp => ad_fp,
      :fn => ad_fn,
      :accuracy => ad_accuracy },

   :all => {
      :tp => tp,
      :tn => tn,
      :fp => fp,
      :fn => fn,
      :accuracy => accuracy }
  }

    
  f = File.new(summary_file, "w+")
  f.puts sum.to_yaml
  f.close
  f = File.new(misclassifications_file, "w+")
  f.puts misclassifications.to_yaml
  f.close
  f = File.new(cumulative_accuracies_file, "w+")
  f.puts prediction_confidences.to_yaml
  f.close
  
end


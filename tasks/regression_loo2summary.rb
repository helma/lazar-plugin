require 'rubygems'
require 'statarray'
def regression_loo2summary(loo, summary_file, misclassifications_file, cumulative_accuracies_file, ad_threshold=0.15)

  puts "Creating summary for #{loo}" 

  
  summary = {}

  # variables
  dbs = {}
  preds = {}
  confs = {}
  smiles = {}
  errors = {}

  misclassifications = []
  prediction_confidences = []

  # parse output file
  YAML::load_documents(File.open(loo)) { |p|

    unless ( p['prediction'].nil? || p['confidence'].nil? || p['db_activity'].nil? )

      # get primary data
      id = p['id']
      db_activities = p['db_activity']
      db_statarr = db_activities.to_statarray
      db = db_statarr.median
      pred = p['prediction'].to_f 
      conf = p['confidence'].to_f 
      smile = p['smiles']
      error = (db.to_f-pred).abs
      if p['unknown_features'] 
        unknown_features = false
      else
        unknown_features = true
      end

      # prediction confidences and misclassifications
      if (error <=1)
        prediction_confidences << {:id => id.to_s, :confidence => conf, :within_1log_unit => true}
      else
        prediction_confidences << {:id => id.to_s, :confidence => conf, :within_1log_unit => false}
        misclassifications << {:id => id.to_s, :smiles => smile, :prediction => pred, :confidence => conf, :db_activities => db_activities, :unknown_features => unknown_features} if conf < ad_threshold
      end

      # store data in hashes
      dbs[id] = db
      preds[id] = pred
      confs[id] = conf
      errors[id] = error

    end
  } # end parsing

  
    # summary for different confidence thresholds
#    summary[:applicability_domain_data] = []
#    ads.each { |ad|
#        summary[:applicability_domain_data] << applicability_domain_data(ad.to_f, dbs, preds, confs, errors)
#    }
   
  #    summary
  summary = {}
  summary[:within_ad] = applicability_domain_data(ad_threshold, dbs, preds, confs, errors)
  summary[:all] = applicability_domain_data(0, dbs, preds, confs, errors)
  f = File.new(summary_file, "w+")
  f.puts summary.to_yaml
  f.close
    
  #    misclassifications
  misclassifications.sort! { |x,y| y[:confidence] <=> x[:confidence] }
  f = File.new(misclassifications_file, "w+")
  f.puts misclassifications.to_yaml
  f.close

  # cumulative accuracies
  prediction_confidences.sort! { |x,y| y[:confidence] <=> x[:confidence] }

  n = 0
  correct_predictions = 0

  prediction_confidences.each do |c|
    n += 1
    correct_predictions += 1 if c[:within_1log_unit]
    c[:cumulative_accuracy] = correct_predictions.to_f/n.to_f
  end

  f = File.new(cumulative_accuracies_file, "w+")
  f.puts prediction_confidences.to_yaml
  f.close
    
end

def applicability_domain_data(ad, dbs, preds, confs, errors)

    dbs_w = {}
    preds_w = {}
    confs_w = {}
    errors_w = {}
    dbs_o = {}
    preds_o = {}

    confs.each { |id,conf|
      if (conf >= ad)
          dbs_w[id] = dbs[id]
          preds_w[id] = preds[id]
          confs_w[id] = conf
          errors_w[id] = errors[id]
      else
          dbs_o[id] = dbs[id]
          preds_o[id] = preds[id]
      end
    }

    applicability_domain_statistics(ad, dbs_w, preds_w, confs_w, errors_w, dbs_o, preds_o)

end

def applicability_domain_statistics(ad, dbs, preds, confs, errors, dbs_out, preds_out)

    d=minus(dbs.values)
    d_out=minus(dbs_out.values)
    p=minus(preds.values)
    p_out=minus(preds_out.values)

    e = StatArray::StatArray.new(errors.values)
    se = StatArray::StatArray.new(square(errors.values))

    # return hash with statistics
    { :ad => ad,
      :nr => confs.size,
      :within_1log_unit => within_1log_unit(errors),
      :weighted_accuracy => weighted_accuracy(errors, confs),
      :me => e.mean,
      :ci => (e.ci[0] - e.ci[1]).abs,
      :se => e.stddev,
      :rmse => se.mean ** 0.5,
      :rsq => 1.0-se.mean/dbs.values.variance }

end

def minus (a)
    a.collect { |i| -1.0*i }
end

def square (a);
    a.collect { |i| i*i }
end

def within_1log_unit (errors);
    w1lc=0
    errors.each { |id, e| 
        if (e <= 1.0 ) 
            w1lc = w1lc+1 
        end 
    }
    w1lc
end

def weighted_accuracy (errors, confs)
    tp=0.0
    p=0.0
    wa = nil
    errors.each { |id,e|
        if ( e<=1.0 ) 
            tp = tp + confs[id]
        end
        p = p + confs[id]
    }
    wa = tp/p if (p>0) 
    wa
end


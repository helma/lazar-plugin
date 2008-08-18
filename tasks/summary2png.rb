require 'rubygems'
require 'rsruby'
require 'statarray'

def accuracy_plot(acc_file,png,ad_threshold)

  confidences = []
  cumulative_accuracies = []

  cmax = 0.0
  YAML::load(File.open(acc_file)).each do |p|
    conf = p[:confidence]
    confidences << conf
    cmax=conf if conf>cmax 
    cumulative_accuracies << p[:cumulative_accuracy]
  end

  puts "Creating image for #{acc_file}"
  r = RSRuby.instance
  r.png({'filename'=>png, 'width'=>420, 'height'=>480})
  r.plot({'x'=>confidences, 'y'=>cumulative_accuracies, 'type'=>'n', 'ylab'=>'True prediction rate', 'ylim'=>[0.5,1], 'xlab'=>'Confidence', 'xlim'=>[cmax,3e-03], 'log'=>'x'})
  r.rect(cmax, 0.5, ad_threshold, 1, {'col'=>'grey', 'border'=>'NA'})
  r.lines(confidences,cumulative_accuracies)
  r.points(confidences,cumulative_accuracies)
  r.text(cmax,0.55,"Applicability domain\n(Confidence > #{ad_threshold})", {'pos'=>4})
  r.dev_off.call

end

def correlation_plot(loo, correlation_plot, ad_threshold)

  predictions = []
  measurements= []
  predictions_within_ad = []
  measurements_within_ad= []
  predictions_outside_ad = []
  measurements_outside_ad= []

  puts "Creating correlation plot for #{loo}"
  YAML::load_documents(File.open(loo)) do |p|

    unless ( p['prediction'].nil? || p['confidence'].nil? || p['db_activity'].nil? )

      db_activities = p['db_activity'].to_statarray
      measurements << db_activities.median
      predictions << p['prediction'].to_f 
      if p['confidence'] > ad_threshold
        measurements_within_ad << db_activities.median
        predictions_within_ad << p['prediction'].to_f 
      else
        measurements_outside_ad << db_activities.median
        predictions_outside_ad << p['prediction'].to_f 
      end

    end

  end
    
  # plot predicted vs database activity
  r = RSRuby.instance
  rng = r.range(predictions)
  rnx = [rng[0]-2.0, rng[1]+2.0]
  rny = [rng[0]-2.0, rng[1]+2.0]
  r.png({'filename'=>correlation_plot, 'width'=>420, 'height'=>480})
  #r.plot({'x' => predictions, 'y' => measurements, 'xlab' => 'Prediction (-log)', 'ylab' => 'Database activity (-log)', 'cex.axis' => '1.5', 'cex.lab' => '1.5', 'type' => 'n', 'ylim' => rny, 'xlim' => rnx })
  r.plot({'x' => predictions, 'y' => measurements, 'xlab' => 'Prediction (-log)', 'ylab' => 'Database activity (-log)', 'type' => 'n', 'ylim' => rny, 'xlim' => rnx })
  r.par('cex.main'=>1.5)
  r.lines([-100,100], [-100,100])
  r.lines([-99,100], [-100,99])
  r.lines([-100,99], [-99,100])
  r.points( predictions, measurements, {'pch'=>17, 'cex'=>1.0, 'col'=>'#CCCCCC'})
  r.points( predictions_within_ad, measurements_within_ad, {'pch'=>17, 'cex'=>1.0, 'col'=>'#000000'})
  r.dev_off.call

end

def roc_plot(summary_file, roc_plot)
  
  summary = YAML::load(File.open(summary_file))

  all_n = summary[:all][:tn] + summary[:all][:tp] + summary[:all][:fn] + summary[:all][:fp]
  within_ad_n = summary[:within_ad][:tn] + summary[:within_ad][:tp] + summary[:within_ad][:fn] + summary[:within_ad][:fp]
  weighted_n = summary[:weighted][:tn] + summary[:weighted][:tp] + summary[:weighted][:fn] + summary[:weighted][:fp]

  labels = [ "all predictions" , "predictions within applicability domain" , "predictions weighted by confidence index" ]

  true_positive_rate = [
    (summary[:all][:tn] + summary[:all][:tp])/all_n.to_f,
    (summary[:within_ad][:tn] + summary[:within_ad][:tp])/within_ad_n.to_f,
    (summary[:weighted][:tn] + summary[:weighted][:tp])/weighted_n.to_f,
  ]

  false_positive_rate = [
    (summary[:all][:fn] + summary[:all][:fp])/all_n.to_f,
    (summary[:within_ad][:fn] + summary[:within_ad][:fp])/within_ad_n.to_f,
    (summary[:weighted][:fn] + summary[:weighted][:fp])/weighted_n.to_f,
  ]

  puts "Creating ROC plot for #{summary_file}"
  r = RSRuby.instance
  r.png({'filename'=>roc_plot, 'width'=>420, 'height'=>480})
  r.plot({'x'=>false_positive_rate, 'y'=>true_positive_rate, 'type'=>'n', 'xlab'=>'False positive rate', 'ylab'=>'True positive rate', 'ylim'=>[0,1], 'xlim'=>[0,1]})
  r.points(false_positive_rate,true_positive_rate, {'pch'=>[25,22,19],'bg'=>'black'})
  r.abline(0, 1)
  r.text(false_positive_rate,true_positive_rate,labels, {'pos'=>4, 'cex'=>0.5})
  r.dev_off.call



end


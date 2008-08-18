require 'yaml'
require 'statarray'
require 'rsruby'

def regression_accuracy_plot(acc_file,png)

  n = 0
  true_predictions = 0
  pl_confs = []
  pl_cas = []

  YAML::load(File.open(acc_file)).each do |p|
    n += 1
    true_predictions += 1 if p[:within_1log_unit]
    ca = true_predictions.to_f/n
    pl_confs << p[:confidence]
    pl_cas << ca
  end

  # plot confidence vs wa
  cmax = 0.0
  pl_confs.each { |c| cmax=c if c>cmax }

  puts "Creating image for #{acc_file}"
  r = RSRuby.instance
  r.png({'filename'=>png, 'width'=>420, 'height'=>480})
  r.plot({'x'=>pl_confs, 'y'=>pl_cas, 'type'=>'n', 'ylab'=>'Predictions within 1 log unit', 'ylim'=>[0.5,1], 'xlab'=>'Confidence', 'xlim'=>[cmax,3e-03], 'log'=>'x'})
  r.rect(cmax, 0.5, 0.025, 1, {'col'=>'grey', 'border'=>'NA'})
  r.lines(pl_confs,pl_cas)
  r.points(pl_confs,pl_cas)
  r.text(cmax,0.55,"Applicability domain\n(Confidence > 0.025)", {'pos'=>4})
  r.dev_off.call

end

def regression_summary2png(summary_fn, ads, pred_db_png=nil, acc_png=nil)

  puts "Creating #{pred_db_png} and #{acc_png} from #{summary_fn}"
  summary = YAML.load(File.open(summary_fn))

    if pred_db_png
=begin
      summary[:applicability_domain_data].each do |p|
        if p[:rsq].is_a?(Float) and p[:confidence].is_a?(Float) and p[:rsq].abs < 1.0/0.0
        rsqs << p[:rsq]
        cfs << p[:confidence]
        end
      end
        # plot predicted vs database activity
        r = RSRuby.instance
        rng = r.range(p)
        rnx = [rng[0]-2.0, rng[1]+2.0]
        rny = [rng[0]-2.0, rng[1]+2.0]
        r.png({'filename'=>pred_db_png, 'width'=>630, 'height'=>720})
        r.plot({'x' => p, 'y' => d, 'xlab' => 'Prediction (-log)', 'ylab' => 'Database activity (-log)', 'cex.axis' => '1.5', 'cex.lab' => '1.5', 'type' => 'n', 'ylim' => rny, 'xlim' => rnx })
        r.par('cex.main'=>1.5)
        r.title({'main'=>'Prediction vs Database activity'})
        r.lines([-100,100], [-100,100])
        r.lines([-99,100], [-100,99])
        r.lines([-100,99], [-99,100])
        r.points( p_out, d_out, {'pch'=>17, 'cex'=>1.0, 'col'=>'#CCCCCC'})
        r.points( p, d, {'pch'=>17, 'cex'=>1.0, 'col'=>'#000000'})
        r.dev_off.call
=end
    end

    if acc_png

    end


end


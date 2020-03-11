function rho = analyze_metric_group_correlations(metrics)
rho = partialcorr(table2array(metrcs));
end

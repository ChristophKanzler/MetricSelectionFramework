function [reference_population, impaired_population, lme] = postprocess_metrics(metrics, effects, reference_population, impaired_population)

for i = 1:length(metrics)
    metric_name = metrics{i};
    metric_transf = [metric_name '_t'];
    metric_transf_comp = [metric_name '_t_c'];
    metric_comp = [metric_name '_c'];
    
    metric_retest = [metric_name '_retest'];
    metric_retest_transf = [metric_retest '_t'];
    metric_retest_transf_comp = [metric_retest '_t_c'];
    metric_retest_comp = [metric_retest '_c'];
    
    % Apply Box-Cox transformation to make the metric more normal-like.
    [reference_population.(metric_transf), impaired_population.(metric_transf), lambda, min_val] = metric_boxcox(reference_population.(metric_name), impaired_population.(metric_name));
    [reference_population.(metric_retest_transf), impaired_population.(metric_retest_transf), ~, min_val_retest] = metric_boxcox(reference_population.(metric_retest), impaired_population.(metric_retest), lambda);
    
    %Fit mixed effect model based on reference subjects.
    [reference_population, impaired_population, lme] = compensate_standardize(reference_population, impaired_population, effects, metric_name);
    
    % Inverse Box-Cox transformation.
    [reference_population.(metric_comp), impaired_population.(metric_comp)] = metric_inverseboxcox(reference_population.(metric_transf_comp), impaired_population.(metric_transf_comp), lambda, min_val);
    [reference_population.(metric_retest_comp), impaired_population.(metric_retest_comp)] = metric_inverseboxcox(reference_population.(metric_retest_transf_comp), impaired_population.(metric_retest_transf_comp), lambda, min_val_retest);
end
end
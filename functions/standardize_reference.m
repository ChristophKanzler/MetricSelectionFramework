function [ reference_population, impaired_population ] = standardize_reference(reference_population, impaired_population, metric_name)
mu = median(reference_population.(metric_name));
sigma = mad(reference_population.(metric_name), 1);

reference_population.(metric_name) = (reference_population.(metric_name) - mu)./sigma;
impaired_population.(metric_name) = (impaired_population.(metric_name) - mu)./sigma; 
end


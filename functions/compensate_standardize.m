function [reference_population, impaired_population, lme] = compensate_standardize(reference_population, impaired_population, effects, metric)
effects_string = strcat(metric, '_t', " ~  1 + ", [sprintf('%s + ', effects{1:end-1}), effects{end}], ' + (1|id)');

% Fit the model using the reference population only.
lme = fitlme(reference_population, effects_string);

impaired_population.([metric '_t_c']) = compensate_confounds(impaired_population.([metric '_t']), impaired_population, effects, lme);
impaired_population.([metric '_retest_t_c']) = compensate_confounds(impaired_population.([metric '_retest_t']), impaired_population, effects, lme);

reference_population.([metric '_t_c']) = compensate_confounds(reference_population.([metric '_t']), reference_population, effects, lme);
reference_population.([metric '_retest_t_c']) = compensate_confounds(reference_population.([metric '_retest_t']), reference_population, effects, lme);
end
function [reference_population, impaired_population] = simulate_data(seed, n_subjects, n_metrics, mean_age_ref, var_age_ref, mean_age_imp, var_age_imp)
% Initialize the dummy participants' data.
reference_population = initialize_population(n_subjects, mean_age_ref, var_age_ref, false);
impaired_population = initialize_population(n_subjects, mean_age_imp, var_age_imp, true);

% Randomly initialize the metrics.
reference_population = initialize_metrics(reference_population, n_metrics, false);
rng(randi(seed));
impaired_population = initialize_metrics(impaired_population, n_metrics, true);
end
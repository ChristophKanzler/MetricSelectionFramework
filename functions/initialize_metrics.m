% Initialize n_metrics randomly, including retest metrics.
function population = initialize_metrics(population, n_metrics, is_impaired)
if (~is_impaired)
    mu_means = 30;
    var_means = 5;
else
    mu_means = 40;
    var_means = 10;
end

variability = 2;

seeds = randi([0, n_metrics * 100], 1, n_metrics);

for i = 1:n_metrics
    rng(seeds(i));
    mu = normrnd(mu_means, var_means, [1,1]);
    metric = generate_simulated_metric(mu, variability, population.age);
    population.(['metric' mat2str(i)]) = metric;

    mu_noise = 0.2 * mu;
    var_noise = 0.1 * variability;
    noise = generate_simulated_parameter(mu_noise, var_noise, height(population), 0);
    
    % Simulate slight learning effect (or perturbation) between test and
    % re-test.
    while ~all(metric > noise) 
        neg_vals = noise >= metric;
        noise(neg_vals) = metric(neg_vals) * 0.2;
    end
    
    population.(['metric' mat2str(i) '_retest']) = metric - noise;
end
end
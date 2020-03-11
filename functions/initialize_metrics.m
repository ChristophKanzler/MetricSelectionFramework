% Initialize n_metrics randomly, including retest metrics.
% TODO: introduce a seed for repeatability!
function population = initialize_metrics(population, seed, n_metrics, is_impaired)


if (~is_impaired)
    mu_means = 10;
    var_means = 3;
else
    mu_means = 15;
    var_means = 8;
end

mu_variabilities = 2;
var_variabilites = 0.8;

mu_retest_means = -200;
var_retest_means = 400;

seeds = randi([0, n_metrics * 100], 1, n_metrics);

for i = 1:n_metrics
    rng(seeds(i));
    mu = normrnd(mu_means, var_means, [1,1]);
    variability = normrnd(mu_variabilities, var_variabilites, [1,1]);
    metric = generate_simulated_metric(mu, variability, population.age);
    population.(['metric' mat2str(i)]) = metric;
    % Add simulated retest metric by adding random noise.
    %mu = -200;
    %variability = 2;
    mu = normrnd(mu_retest_means, var_retest_means, [1,1]);
    variability = normrnd(mu_variabilities, var_variabilites, [1,1]);
    noise = generate_simulated_parameter(mu,variability,height(population),0);
    population.(['metric' mat2str(i) '_retest']) = metric + noise;
    
    if(~isempty(find(isnan(population.(['metric' mat2str(i) '_retest'])))))
        error('NaN data after adding noise!');
    end
end
end
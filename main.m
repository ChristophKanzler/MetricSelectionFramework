%%% Exemplary code for
%
% "A data-driven framework for the
% selection and validation of digital health
% metrics:  use-case inneurological sensorimotor impairments"
%
% Christoph M. Kanzler*, Mike D. Rinderknecht, Anne Schwarz, Ilse Lamers,
% Cynthia Gagnon, Jeremia Held, Peter Feys,  Andreas R. Luft,
% Roger Gassert and Olivier Lambercy
%
%
% Rehabilitation Engineering Laboratory,
% Institute of Robotics and Intelligent Systems,
% Department of Health Sciences and Technology,
% ETH Zurich, Zurich, Switzerland
%
%
% Copyright (C) 2020, Christoph M. Kanzler, ETH Zurich
% Contact: christoph.kanzler@hest.ethz.ch
%
% Thanks to Pietro Oldrati for code cleanup.

disp('-------------------------------------------------------------------------------------------------');
disp('Examplary code for the paper:')
disp('"A data-driven framework for the selection and validation of digital health  metrics:');
disp('use-case in neurological sensorimotor impairments"');
disp('Christoph M. Kanzler, Mike D. Rinderknecht, Anne Schwarz, Ilse Lamers, Cynthia Gagnon, Jeremia Held, Peter Feys,  Andreas R. Luft, Roger Gassert, and Olivier Lambercy');
disp('https://www.biorxiv.org/content/10.1101/544601v2')
disp('-------------------------------------------------------------------------------------------------');


disp('');
disp('');
disp('This code starts with simulating a number of metrics and runs all steps of the proposed metric selection procedure!');
addpath(genpath(pwd));

seed = 9000;        % Seed for repeatability.
rng(seed);

%% simulate data
n_subjects = 100;   % Number of subjects for healthy and impaired groups.
n_metrics = 5;     % The total number of metrics.

%specificy demographic parameters for reference and impaired population
mu_age_ref = 50;
variability_age_ref = 40;
mu_age_imp = 40;
variability_age_imp = 50;

% Initialize the dummy participants' data.
reference_population = initialize_population(n_subjects, mu_age_ref, variability_age_ref, false);
impaired_population = initialize_population(n_subjects, mu_age_imp, variability_age_imp, true);

% Randomly initialize the metrics.
reference_population = initialize_metrics(reference_population, randi([0, 1000], 1, 1), n_metrics, false);
rng(randi(seed));
impaired_population = initialize_metrics(impaired_population, randi([0, 1000], 1, 1), n_metrics, true);


%% perform metric selection
metrics_mat = table();
for i = 1:n_metrics
    %% Postprocessing
    % Apply Box-Cox transformation to make the metric more normal-like.
    [reference_population.(['metric' mat2str(i) '_t']), impaired_population.(['metric' mat2str(i) '_t']), lambda, min_val] = metric_boxcox(reference_population.(['metric' mat2str(i)]), impaired_population.(['metric' mat2str(i)]));
    [reference_population.(['metric' mat2str(i) '_retest_t']), impaired_population.(['metric' mat2str(i) '_retest_t']), ~, min_val_retest] = metric_boxcox(reference_population.(['metric' mat2str(i) '_retest']), impaired_population.(['metric' mat2str(i) '_retest']), lambda);
    
    %Fit mixed effect model based on reference subjects.
    effects_string = ['metric' mat2str(i) '_t ~ 1 + age + gender + tested_hand + is_dominant_hand + (1|id)'];
    
    [reference_population, impaired_population, lme] = compensate_standardize(reference_population, impaired_population, effects_string, ['metric' mat2str(i)]);
    
    [reference_population.(['metric' mat2str(i) '_c']), impaired_population.(['metric' mat2str(i) '_c'])] = metric_inverseboxcox(reference_population.(['metric' mat2str(i) '_t_c']), impaired_population.(['metric' mat2str(i) '_t_c']), lambda, min_val);
    [reference_population.(['metric' mat2str(i) '_retest_c']), impaired_population.(['metric' mat2str(i) '_retest_c'])] = metric_inverseboxcox(reference_population.(['metric' mat2str(i) '_retest_t_c']), impaired_population.(['metric' mat2str(i) '_retest_t_c']), lambda, min_val_retest);
    
    % Standardize metric w.r.t reference population.
    mu = median(reference_population.(['metric' mat2str(i) '_c']));
    sigma = mad(reference_population.(['metric' mat2str(i) '_c']), 1);
    
    reference_population.(['metric' mat2str(i) '_c']) = (reference_population.(['metric' mat2str(i) '_c']) - mu)./sigma;
    impaired_population.(['metric' mat2str(i) '_c']) = (impaired_population.(['metric' mat2str(i) '_c']) - mu)./sigma;
    
    mu = median(reference_population.(['metric' mat2str(i) '_retest_c']));
    sigma = mad(reference_population.(['metric' mat2str(i) '_retest_c']), 1);
    
    reference_population.(['metric' mat2str(i) '_retest_c']) = (reference_population.(['metric' mat2str(i) '_retest_c']) - mu)./sigma;
    impaired_population.(['metric' mat2str(i) '_retest_c']) = (impaired_population.(['metric' mat2str(i) '_retest_c']) - mu)./sigma;
    
    metrics_mat.(['metric' mat2str(i) '_c']) = reference_population.(['metric' mat2str(i) '_c']);
    
    %% Metric selection & validation: steps 1 and 2.
    fprintf('\n\n');
    disp(['<strong>Results for metric ' num2str(i) ':</strong>']);
    [C1, C2, AUC, SRD, ICC, slope] = analyze_metric(reference_population, impaired_population, lme, i);
    disp('Press a button to continue...');
    waitforbuttonpress;
end

close all;
%% Metric selection & validation: step 3.
metrics_mat = table2array(metrics_mat);
rho = partialcorr(metrics_mat);
metric_names = strcat('Metric', arrayfun(@(n) num2str(n), (1:n_metrics)', 'UniformOutput', false));
hm_fig = figure('Position', [-1 -1 900 600]);
heatmap(rho, metric_names, metric_names, '%0.2f', 'Colormap', 'money', ...
    'FontSize', 9, 'Colorbar', {'SouthOutside'}, 'MinColorValue', -1, 'MaxColorValue', 1);
title('Inter-metric correlation')
movegui(hm_fig, 'center');
disp('Press a button to continue...');
waitforbuttonpress;
close all;

%% Further metric validation: step 1.
fprintf('\n\n<strong>Further metric validation: STEP 1</strong>\n')
% Scree plot to select the number of factors.
if(0)
    scree_fig = figure();
    plot(sort(eig(cov(metrics_mat)), 'descend'));
    title('Scree plot');
    xlabel('Factor number');
    ylabel('Eigenvalue');
    disp('According to the elbow criteria, k=3 was chosen for the factor analysis.')
end

disp('According to the elbow criteria, k=2 was chosen for the factor analysis.')
k = 2;

% rssuiwait(scree_fig);

% KMO test to see whether the metrics are adequate for factor analysis (should be >= 0.5).
kmo_idx = kmo(metrics_mat, false);
if (kmo_idx > 0.5)
    disp('The KMO test yields a degree of common variance above the minimum required to perform the factorization.')
else
    disp('The KMO test yields a degree of common variance below the minimum required to perform the factorization. It is not advised to factorize.')
end

tol =  0.00005;
rotation = 'promax';
optionsFactoran = statset('TolX',tol,'TolFun',tol);
loadings = factoran(metrics_mat, k, 'rotate',rotation, 'optimopts', optionsFactoran);
loadings_t = array2table(loadings);
loadings_t.Properties.VariableNames = strcat('Factor ', arrayfun(@(n) num2str(n), (1:k)', 'UniformOutput', false));
loadings_t.Properties.RowNames = strcat('Metric', arrayfun(@(n) num2str(n), (1:n_metrics)', 'UniformOutput', false));
disp('The following table shows the factor loadings for each metric.')
disp('Strong loadings have an absolute value above 0.5.')
disp(loadings_t)

population = [reference_population; impaired_population];
population.id = (1:height(population))';
metrics_mat = table();
for i = 1:n_metrics
    metrics_mat.(['metric' mat2str(i) '_c']) = population.(['metric' mat2str(i) '_c']);
end
metrics_mat = table2array(metrics_mat);

disp('Press a button to continue...');
waitforbuttonpress;
close all;

%% Further metric validation: step 2.
% Calculating the cutoff for the metrics with the 95% percentile.
abnormal_behaviour_cut_offs = prctile(metrics_mat, 95, 1)';
visualize_impairment_profile_non_parametric_mad(population, abnormal_behaviour_cut_offs);

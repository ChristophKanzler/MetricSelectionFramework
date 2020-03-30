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

% Seed for repeatability.
seed = 9000;                    
rng(seed);

%% Parameters.
% Decide whether to use simulated data or import it from .mat files. 
% Specify the correct path below if the latter option is chosen.
use_simulated_data = true;     
reference_data_file = fullfile('reference_population.mat');
impaired_data_file = fullfile('impaired_population.mat');

% If you are loading your own data-set, specify the metrics to be used for the analysis in this string array.
metrics = ["m1", "m2"];    

% Effects for the confound compensation.
effects = {'age', 'gender', 'tested_hand', 'is_dominant_hand'};

% Parameters for the simulated data.
n_simulated_subjects = 100;     % Number of subjects for healthy and impaired groups.
n_simulated_metrics = 5;        % Number of simulated metrics for each subject.

mean_age_ref = 50;
var_age_ref = 40;
mean_age_imp = 40;
var_age_imp = 50;

% Show the scree plot to choose k for the factor analysis (see below).
show_scree_plot = false;

% Number of factors to be used for the factor analysis. Obtained from the
% scree plot using the Elbow criterium.
k = 2;

%% Generate or load data. 
if (use_simulated_data)
    [reference_population, impaired_population] = simulate_data(seed, n_simulated_subjects, n_simulated_metrics, mean_age_ref, var_age_ref, mean_age_imp, var_age_imp);
    metrics = strcat("metric", string(1:n_simulated_metrics));
else
    reference_population = load(reference_data_file);
    impaired_population = load(impaired_data_file);
end
n_metrics = length(metrics);

%%  Postprocessing (modeling of confounds).
[reference_population, impaired_population, lme] = postprocess_metrics(metrics, effects, reference_population, impaired_population);

%% Metric selection & validation: steps 1 and 2.
metrics_mat = table();
for i = 1:n_metrics
    metric_name = metrics{i};
    metric_comp = [metric_name '_c'];
    metric_retest_comp = [metric_name '_retest_c'];
    
    fprintf('\n\n');
    disp(['<strong>Results for metric ' metric_name ':</strong>']);
    
    % Plot confound correction results.
    plot_confound_correction(reference_population, effects, metric_name)
    
    % Standardize metric w.r.t reference population.
    [reference_population, impaired_population] = standardize_reference(reference_population, impaired_population, metric_name);
    [reference_population, impaired_population] = standardize_reference(reference_population, impaired_population, metric_comp);
    [reference_population, impaired_population] = standardize_reference(reference_population, impaired_population, metric_retest_comp);
    
    [C1, C2, AUC, SRD, ICC, slope] = analyze_metric(reference_population, impaired_population, lme, metric_name);
    disp('Press a button to continue...');
    waitforbuttonpress;

    metrics_mat.(metric_comp) = reference_population.(metric_comp);
end

close all;

%% Metric selection & validation: step 3.
metrics_mat = table2array(metrics_mat);
rho = partialcorr(metrics_mat);
hm_fig = figure('Position', [-1 -1 900 600]);
heatmap(rho, metrics, metrics, '%0.2f', 'Colormap', 'money', ...
    'FontSize', 9, 'Colorbar', {'SouthOutside'}, 'MinColorValue', -1, 'MaxColorValue', 1);
title('Inter-metric correlation')
movegui(hm_fig, 'center');
disp('Press a button to continue...');
waitforbuttonpress;
close all;

%% Further metric validation: step 1.
factor_analysis(metrics, metrics_mat, k, show_scree_plot);

%% Further metric validation: step 2.
population = [reference_population; impaired_population];
population.id = (1:height(population))';
metrics_mat = table();
for i = 1:n_metrics
    metrics_mat.([metrics{i} '_c']) = population.([metrics{i} '_c']);
end
metrics_mat = table2array(metrics_mat);

disp('Press a button to continue...');
waitforbuttonpress;
close all;

% Calculating the cutoff for the metrics with the 95% percentile.
abnormal_behaviour_cut_offs = prctile(metrics_mat, 95, 1)';
visualize_impairment_profile_non_parametric_mad(population, metrics, abnormal_behaviour_cut_offs);

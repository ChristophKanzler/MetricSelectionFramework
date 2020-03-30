function [C1, C2, AUC, SRD, ICC, slope] = analyze_metric(reference_population, impaired_population, lme, metric_name)
addpath(genpath(pwd));

metric_transf = [metric_name '_t'];
metric_comp = [metric_name '_c'];
metric_retest_comp = [metric_name '_retest_c'];

%% Check confound model quality by calculating RMSE of predictions.
% The estimates are based on mixed effect model trained before.
y_adj_pred = predict(lme, reference_population, 'Conditional', true);

%% Get model quality based on mean absolute error (STEP 1).
[~, C1, C2] = mae_based_model_evaluation(reference_population.(metric_transf), y_adj_pred);

%% ROC curve of using this metric for classifying healthy vs patients with varying cutoff (STEP 2b).
AUC = get_abnormal_behaviour_cut_off_ROC_population_based(reference_population.(metric_comp), impaired_population.(metric_comp), metric_name);

%% ICC to check for intra-subject variability in test and retest (STEP 2).
ICC = ICC_mReliability(reference_population.(metric_comp), reference_population.(metric_retest_comp));

%% SRD to check the range of values where it is not possible to distinguish measurement errors from actual metric changes (STEP 2).
SRD = get_SRDs(reference_population.(metric_comp), reference_population.(metric_retest_comp), ICC,  true);

%% Assessment of learning effect. Metrics with hich learning effect are discarded (STEP 2).
mu_d1 = median(reference_population.(metric_comp), 2);
mu_d2 = median(reference_population.(metric_retest_comp), 2);
d = mu_d2 - mu_d1;
slope = mean(d)/(range([mu_d2; mu_d1]))*100;

fprintf('<strong>Metric selection & validation: STEP 1</strong>\n')
fprintf('C1: %f%%, C2: %f%%\n', C1, C2);

c_count = 0;
if (C1 > 15)
    c_count = c_count + 1;
end
if (C2 > 25)
    c_count = c_count + 1;
end
if (c_count == 0)
    disp('The model quality is good according to criteria C1 and C2.');
elseif (c_count == 1)
    disp('The model quality is of moderate quality according to criteria C1 and C2.');
else
    disp('The model quality is low according to criteria C1 and C2. It should be discarded.');
end
fprintf('\n\n');

fprintf('\n<strong>Metric selection & validation: STEP 2</strong>\n')
fprintf('Discriminant validity\n');
fprintf('AUC: %f\n', AUC);
if (AUC > 0.7)
    disp('The AUC of the ROC curve is above 0.7, hence the metric discriminates well between intact and impaired users.');
else
    disp('The AUC of the ROC curve is below 0.7, hence the metric does not discriminate well between intact and impaired users, and has to be discarded.');
end
fprintf('\n\n');

disp('');
disp('Measurement error');
fprintf('SRD: %f%%\n', SRD);
if (SRD < 30.3)
    disp('The measurement error of the metric, as measured by SRD, is below 30.3, hence it is acceptable.');
else
    disp('The measurement error of the metric, as measured by SRD, is aboce 30.3, hence the metric has to be discarded.');
end
fprintf('\n\n');

disp('');
disp('Test-retest reliability');
fprintf('ICC: %f\n', ICC);

if (ICC > 0.7)
    disp('The ICC between test and restest sessions is above 0.7, hence the metric is highly correlated across different sessions.');
else
    disp('The ICC between test and restest sessions is below 0.7, hence the metric is now well correlated across different sessions, and has to be discarded.');
end
fprintf('\n\n');


disp('Learning effects:');
fprintf('slope: %f\n', slope);

if (slope > -6.35)
    disp('The slope between test and restest sessions is above -6.35, hence the metric does not suffer from a strong learning effect.');
else
    disp('The slope between test and restest sessions is below -6.35, hence the metric suffers from a strong learning effect, and has to be discarded.');
end

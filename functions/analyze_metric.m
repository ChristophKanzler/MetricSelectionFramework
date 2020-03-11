function [C1, C2, AUC, SRD, ICC, slope] = analyze_metric(reference_population, impaired_population, lme, i)
addpath(genpath(pwd));

metric_name = ['metric' mat2str(i)];
metric_retest_name = ['metric' mat2str(i) '_retest'];

metric_c_name = ['metric' mat2str(i) '_c'];
metric_retest_c_name = ['metric' mat2str(i) '_retest_c'];

metric_t_name = ['metric' mat2str(i) '_t'];

effects_string = ['metric' mat2str(i) '_t ~ 1 + age + gender + tested_hand + is_dominant_hand + (1|id)'];

%% Plotting the confonund correction.
% if (i == 1)
cof = figure;
hold on;
marker_size_2 = 5; marker_size = 10;
plot(reference_population.age,reference_population.(metric_name),'ok','MarkerSize',marker_size_2);
plot(reference_population.age,reference_population.(metric_c_name),'.k','MarkerSize',marker_size);

tbl_reg = table();
y_plot =  reference_population.(metric_name);
if(min(y_plot) <= 0)
    min_val = 500;
    y_plot  = y_plot +min_val;
else
    min_val =0;
end

[tbl_reg.new,lambda_vis] = boxcox(y_plot);
tbl_reg.Properties.VariableNames{end} = metric_t_name;
tbl_reg.age = reference_population.age;
tbl_reg.gender = double(reference_population.gender)-1;
tbl_reg.tested_hand = double(reference_population.tested_hand)-1;
tbl_reg.is_dominant_hand = double(reference_population.is_dominant_hand)-1;
tbl_reg.id = double(reference_population.id);
lme_vis = fitlme(tbl_reg,effects_string);

vis = table();
vis.age = [min(tbl_reg.age):0.1:max(tbl_reg.age)]';
vis.gender = repmat(mean(tbl_reg.gender),size(vis,1),1);
vis.tested_hand = repmat(mean(tbl_reg.tested_hand),size(vis,1),1);
vis.is_dominant_hand = repmat(mean(tbl_reg.is_dominant_hand),size(vis,1),1);
vis.id = repmat(mean(tbl_reg.id),size(vis,1),1);

%make predictions: mean & cis
[preds_vis,ci] = (predict(lme_vis, vis, 'Conditional', false, 'Alpha', 0.05));

%transform back into regular space again
preds_ci_pos =  inverseboxcox(ci(:,2),lambda_vis,min_val);
preds_ci_neg = inverseboxcox(ci(:,1),lambda_vis,min_val);
preds_vis = inverseboxcox(preds_vis,lambda_vis,min_val);
color = 'k';

plot(vis.age,preds_vis,'-','LineWidth',1.25,'Color',color);
plot(vis.age,preds_ci_pos,'--k','LineWidth',1.25);
plot(vis.age,preds_ci_neg,'--k','LineWidth',1.25);

xlabel({'Age (yrs)'});
ylabel({['Metric ' num2str(i)]});
title('Modeling of confounds');
legend('Neurogically intact: raw data', 'Neurogically intact: compensated for confounds', 'Model estimate', 'Model 95% confidence interval');
%     uiwait(cof);
% end

%% Check confound model quality by calculating RMSE of predictions.
% The estimates are based on mixed effect model trained before.
y_adj_pred = predict(lme, reference_population, 'Conditional', true);

%if(~isnan(lambda))
%    y_adj_pred = inverseboxcox(y_adj_pred,lambda,min_val);
%end

%% Get model quality based on mean absolute error (STEP 1).
[~, C1, C2] = mae_based_model_evaluation(reference_population.(metric_t_name), y_adj_pred);

%% ROC curve of using this metric for classifying healthy vs patients with varying cutoff (STEP 2b).
AUC = get_abnormal_behaviour_cut_off_ROC_population_based(reference_population.(metric_c_name), impaired_population.(metric_c_name), i);

%% ICC to check for intra-subject variability in test and retest (STEP 2).
ICC = ICC_mReliability(reference_population.(metric_c_name), reference_population.(metric_retest_c_name));

%% SRD to check the range of values where it is not possible to distinguish measurement errors from actual metric changes (STEP 2).
SRD = get_SRDs(reference_population.(metric_c_name), reference_population.(metric_retest_c_name), ICC,  true);

%% Assessment of learning effect. Metrics with hich learning effect are discarded (STEP 2).
mu_d1 = median(reference_population.(metric_c_name), 2);
mu_d2 = median(reference_population.(metric_retest_c_name), 2);
d = mu_d2 - mu_d1;
slope = mean(d)/(range([mu_d2; mu_d1]))*100;

% if (i == 1)
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
% end

function [] = plot_confound_correction(reference_population, effects, metric_name)
metric_transf = [metric_name '_t'];
metric_comp = [metric_name '_c'];

effects_rhs = strcat(" ~  1 + ", [sprintf('%s + ', effects{1:end-1}), effects{end}], ' + (1|id)');
effects_string = strcat(metric_transf, effects_rhs);

%% Plotting the confonund correction.
figure;
hold on;
marker_size_2 = 5; marker_size = 10;
plot(reference_population.age,reference_population.(metric_name),'ok','MarkerSize',marker_size_2);
plot(reference_population.age,reference_population.(metric_comp),'.k','MarkerSize',marker_size);

tbl_reg = table();
y_plot =  reference_population.(metric_name);
if(min(y_plot) <= 0)
    min_val = 500;
    y_plot  = y_plot +min_val;
else
    min_val =0;
end

[tbl_reg.new,lambda_vis] = boxcox(y_plot);
tbl_reg.Properties.VariableNames{end} = metric_transf;
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
ylabel({metric_name});
title(['Modeling of confounds - ' metric_name]);
legend('Neurogically intact: raw data', 'Neurogically intact: compensated for confounds', 'Model estimate', 'Model 95% confidence interval');
end


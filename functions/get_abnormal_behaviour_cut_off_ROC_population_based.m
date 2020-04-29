function AUC = get_abnormal_behaviour_cut_off_ROC_population_based(dt_healthy, dt_impaired, metric_name, save_plots)
%% ROC analysis to generate abnormal behaviour cut-offs

all_metric = vertcat(dt_healthy, dt_impaired);

% Get indices for binary classification.
inds_healthy = zeros(length(all_metric), 1);
inds_healthy(1:length(dt_healthy)) = 1;
[AUC,true_positive_rates,false_positive_rates,iter_range] = analyze_ROC(all_metric,inds_healthy);

LB = '0';
if(length(LB)==3)
    LB = [LB '0'];
end

UB = '0';
if(length(UB)==3)
    UB = [UB '0'];
end

%% plot ROC
h = figure;
hold on;
plot(false_positive_rates,true_positive_rates,'-','Color','k');
plot(false_positive_rates,true_positive_rates,'.','Color','k');
fontSize = 15;

% Get operating point: top-left data point: %N. J. Perkins and E. F. Schisterman, “The inconsistency of “optimal” cut-points using two ROC based criteria,” American Journal of Epidemiology, vol. 163, no. 7, pp. 670–675, 2006. View at Google Scholar
x_target = 0;
y_target = 1;
dist = ((false_positive_rates - x_target).^2 + (true_positive_rates-y_target).^2).^(1/2);
[~,ind] = min(dist);

offset_x = -0.1;
offset_y = -0.05;

text(false_positive_rates(ind)-0.04+offset_x+0.3,true_positive_rates(ind)-0.03+offset_y,['AUC: ' num2str(round(AUC, 3))],'HorizontalAlignment','center','FontSize',fontSize-1);

ylabel({'True positive rate'});
xlabel({'False positive rate'});
box off;

xlim([0 1]);
ylim([0 1]);

ax = gca;
ax.Clipping = 'off';

x = 0:0.01:1;
plot(x,x,'--k');

legend('Reference population vs impaired subjects', 'Performance of random guessing');
title(['Metric discriminant validity (ROC curve) - ' metric_name]);

if save_plots
    save_plot(h, [metric_name '_roc.pdf']);
end
% uiwait(rocf);

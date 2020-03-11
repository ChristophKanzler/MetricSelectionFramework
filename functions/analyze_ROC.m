function [AUC,true_positive_rates,false_positive_rates,iter_range] = analyze_ROC(y,inds_healthy)

if(nargin == 1)
    inds_healthy = y(:,end);
    y = y(:,1:end-1);
end

true_positive_rates = [];
false_positive_rates = [];
best_avg_performance = -inf;
best_tpr = [];
best_fpr = [];

%iterate over cut_offs
iter_range = [min(y):range(y)/10000:max(y)];
for i = 1:length(iter_range)
    cut_off = iter_range(i);
    
    %apply cut_off
    healthy_pred = y<cut_off;
    
    %true positive rate (sensitivity)
    tp = length(find(~inds_healthy & ~healthy_pred));
    fn = length(find(~inds_healthy & healthy_pred));
    tpr = tp/(tp+fn);
    true_positive_rates = [true_positive_rates; tpr];
    
    %false positive rate (speficity)
    fp = length(find(inds_healthy & ~healthy_pred));
    tn = length(find(inds_healthy & healthy_pred));
    fpr = fp/(tn+fp);
    false_positive_rates = [false_positive_rates; fpr];
end

%calculate AUC
AUC = abs(trapz(false_positive_rates,true_positive_rates));
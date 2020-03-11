function [quality,criteria_1,criteria_2] = mae_based_model_evaluation(training, predictions)
% Be aware of error measures. Further studies on validation of predictive QSAR models
% Kunal Roy , Rudra Narayan Das 1, Pravin Ambure 1, Rahul B. Aher 1
% Drug Theoretics and Cheminformatics Laboratory, Department of Pharmaceutical Technology, Jadavpur University, Kolkata 700 032, India
%https://sites.google.com/site/dtclabxvplus/

%  exclude 5% residual outliers
e_init = abs(training-predictions);
e_init = sort(e_init,'descend');
e = e_init(round(length(e_init)*0.05):end);

%calc statistics
mae =  mean(e);

%% criteria 1: this is supposed to be <= to 10% for good predictions
criteria_1 = mae/range(training)*100;

%% criteria 2: this is supposed to be <= than 20% for good predictions
criteria_2 = (mae+3*std(e))/range(training)*100;

if(criteria_1 <= 10 && criteria_2 <= 20)
    quality = categorical(cellstr('good'));
elseif(criteria_1 > 15 || criteria_2 > 25)
    quality = categorical(cellstr('bad'));
else
    quality = categorical(cellstr('moderate'));
end



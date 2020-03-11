function [icc_val,LB,UB,MSE] = ICC_mReliability(values_day_1,values_day_2)
%% adapted from https://github.com/jmgirard/mReliability/blob/master/ICC_A_k.m


if(nargin==1)
    values_day_2 = values_day_1(:,2);
    values_day_1 = values_day_1(:,1);
end

%values_day_1: number of subjects x number of raters
%values_day_2: number of subjects x number of raters
repetitions = 5;

%stack data from day 1 and day 2 for each subject
data = [];
for ijk=1:length(values_day_1)
    data = [data; values_day_1(ijk,:)' values_day_2(ijk,:)'];
end

%size data: 2*number of subjects x number of raters
[n, k] = size(data);
[p,tbl,stats]= anova2(data,repetitions,'off');
MSC = tbl{2, 4};
MSR = tbl{3, 4};
MSE = tbl{4, 4};
MSW = sum(var(data,[], 2)) / n;         %summed variance across measurement
        
%% Calculate agreement ICC
sig_level = 0.05;
icc_val = (MSR - MSE) / (MSR + (MSC - MSE) / n);

%% Calculate the confidence interval 
c  = icc_val / (n * (1 - icc_val));
d  = 1 + (icc_val * (n - 1)) / (n * (1 - icc_val));
v  = ((c * MSC + d * MSE) ^ 2) / (((c * MSC) ^ 2) / (k - 1) + ((d * MSE) ^ 2) / ((n - 1) * (k - 1)));
FL = finv((1 - sig_level / 2), (n - 1), v);
FU = finv((1 - sig_level / 2), v, (n - 1));
LB = (n * (MSR - FL * MSE)) / (FL * (MSC - MSE) + n * MSR);
UB = (n * (FU * MSR - MSE)) / (MSC - MSE + n * FU * MSR);

function [cut_off,worst_value] = choose_cutoff(patient_table,feature_ind,abnormal_behaviour_cut_offs)

labels_init = patient_table.Properties.VariableNames;

%get correct metric (exclude names of metric that have other ending)
ind_metric_for_cut_off = arrayfun(@(x) contains(x,labels_init{feature_ind}) & ~contains(x,[labels_init{feature_ind} '_return'])  & ~contains(x,['log_' labels_init{feature_ind}]) ...
    & ~contains(x,[labels_init{feature_ind} '_mean'])   & ~contains(x,[labels_init{feature_ind} '_max'])  & ~contains(x,[labels_init{feature_ind} '_2'])  ...
    & ~contains(x,[labels_init{feature_ind} '_abs'])  & ~contains(x,[labels_init{feature_ind} '_std'])  & ~contains(x,[labels_init{feature_ind} '_max_vel']) ... 
    & ~contains(x,[labels_init{feature_ind} '_approach_peg']) & ~contains(x,[labels_init{feature_ind} '_approach_hole']), ...
    abnormal_behaviour_cut_offs.Properties.VariableNames);
abnormal_behaviour_cut_offs_sub= abnormal_behaviour_cut_offs(:,ind_metric_for_cut_off);

%choose cut-off for correct body side - NOT NEEDED ANY MORE - CUT OFFS ARE
%SIDE INDEPENDENT
% ind_side =arrayfun(@(x) contains(x,char(patient_table.tested_hand(1))),abnormal_behaviour_cut_offs_sub.Properties.VariableNames);
ind_side =arrayfun(@(x) contains(x,('left')),abnormal_behaviour_cut_offs_sub.Properties.VariableNames);
abnormal_behaviour_cut_offs_sub = abnormal_behaviour_cut_offs_sub(:,ind_side);
ind_cut_off = arrayfun(@(x) contains(x,'cut_off'),abnormal_behaviour_cut_offs_sub.Properties.VariableNames);
ind_worst = arrayfun(@(x) contains(x,'worst'),abnormal_behaviour_cut_offs_sub.Properties.VariableNames);

%get closest age
[~,ind_age] = min(abs(abnormal_behaviour_cut_offs.age-patient_table.age(1)));

%get cut-off based on metric, age, and side
cut_off = abnormal_behaviour_cut_offs_sub{ind_age,ind_cut_off};
worst_value = abnormal_behaviour_cut_offs_sub{ind_age,ind_worst};

if(length(cut_off)>1)
    warning('Selected multiple cut-offs!')
elseif(isempty(cut_off))
    warning('Could not find cut-off for this metric!')
end
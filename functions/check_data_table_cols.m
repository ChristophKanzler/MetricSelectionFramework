function [error_msg] = check_data_table_cols(table, effects, metrics)
% Makes sure that the data table meets the required structure.
% Output: 
%   * error_msg: nonempty if something is wrong with the table.
table_metrics = cellfun(@(metric) any(strcmp(table.Properties.VariableNames, metric)), metrics);
error_msg = '';

if ~all(table_metrics)
    error_msg = strcat("lacks columns for the metrics ", join(strcat(string(metrics(~table_metrics)), " ")));
    return
end

table_metrics_retest = cellfun(@(metric) any(strcmp(table.Properties.VariableNames, [metric '_retest'])), metrics);

if ~all(table_metrics_retest)
    error_msg = strcat("lacks columns for the retest values of metrics ", join(strcat(string(metrics(~table_metrics_retest)), " ")));
    return
end

table_effects = cellfun(@(effect) any(strcmp(table.Properties.VariableNames, effect)), effects);

if ~all(table_effects)
    error_msg = strcat("lacks columns for the effects ", join(strcat(string(metrics(~table_effects)), " ")));
    return
end
end


function [y_reference, y_target, lambda, min_val] = metric_boxcox(y_reference, y_target, lambda)
y_all = [y_reference; y_target];

%translate data if necessary
if(min(y_all) <= 1)
    flag = 1;
    min_val = 500;
else
    min_val = 0;
    flag = 0;
end
y_all  = y_all + min_val;

% Apply Box-Cox transform (get lambda from healthy population only).
% Lambda minimizes the log-likelihood function.
if (nargin == 2) 
    [~, lambda] = boxcox(y_all(1:length(y_reference)));
end
[y_all] = boxcox(lambda, y_all);
y_reference = y_all(1:length(y_reference));
y_target = y_all(length(y_reference)+1:end);
end
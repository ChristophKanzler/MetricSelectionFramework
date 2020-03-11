function [y_reference_hat_transf, y_target_hat_transf] = metric_inverseboxcox(y_reference_hat, y_target_hat, lambda, min_val)
% Reverse Box-Cox transform.
if(~isnan(lambda))
    y_all = [y_reference_hat; y_target_hat];
    y_all = inverseboxcox(y_all,lambda,min_val);
    y_reference_hat_transf = y_all(1:length(y_reference_hat));
    y_target_hat_transf = y_all(length(y_reference_hat)+1:end);
end
if(~isempty(find(~isreal(y_reference_hat_transf))) || ~isempty(find(~isreal(y_target_hat_transf))))
    error('Imaginary data after box-cox transform!');
end
end
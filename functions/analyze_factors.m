function [loadings_t] = analyze_factors(metrics, metrics_mat, k, show_scree_plot, save_plots)
fprintf('\n\n<strong>Further metric validation: STEP 1</strong>\n')
% Scree plot to select the number of factors.
if(show_scree_plot)
    h = figure();
    plot(sort(eig(cov(metrics_mat)), 'descend'));
    title('Scree plot');
    xlabel('Factor number');
    ylabel('Eigenvalue');
    if save_plots
        save_plot(h, 'scree.pdf');
    end
end
fprintf('According to the elbow criteria, k=%d was chosen for the factor analysis.\n', k)

% KMO test to see whether the metrics are adequate for factor analysis (should be >= 0.5).
kmo_idx = kmo(metrics_mat, false);
if (kmo_idx > 0.5)
    disp('The KMO test yields a degree of common variance above the minimum required to perform the factorization.')
else
    disp('The KMO test yields a degree of common variance below the minimum required to perform the factorization. It is not advised to factorize.')
end

tol =  0.00005;
rotation = 'promax';
optionsFactoran = statset('TolX', tol, 'TolFun', tol);
loadings = factoran(metrics_mat, k, 'rotate', rotation, 'optimopts', optionsFactoran);
loadings_t = array2table(loadings);
loadings_t.Properties.VariableNames = strcat('Factor ', arrayfun(@(n) num2str(n), (1:k)', 'UniformOutput', false));
loadings_t.Properties.RowNames = metrics;
disp('The following table shows the factor loadings for each metric.')
disp('Strong loadings have an absolute value above 0.5.')
disp(loadings_t)
end


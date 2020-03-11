function [reference_population, impaired_population, lme] = compensate_standardize(reference_population, impaired_population, effects_string, column)
lme = fitlme(reference_population, effects_string);

% Compensate for the influence of confounds.
gender = zeros(size(impaired_population, 1), 1);
gender(impaired_population.gender == 'female') = 1;
side = zeros(size(impaired_population, 1), 1);
side(impaired_population.tested_hand == 'right') = 1;
hand_dom = zeros(size(impaired_population, 1), 1);
hand_dom(impaired_population.is_dominant_hand == 'no') = 1;

impaired_population.([column '_t_c']) = impaired_population.([column '_t']) - lme.Coefficients.Estimate(5)*impaired_population.age - lme.Coefficients.Estimate(4)*gender ...
    - lme.Coefficients.Estimate(2)*side - lme.Coefficients.Estimate(3)*hand_dom;
impaired_population.([column '_retest_t_c']) = impaired_population.([column '_retest_t']) - lme.Coefficients.Estimate(5)*impaired_population.age - lme.Coefficients.Estimate(4)*gender ...
    - lme.Coefficients.Estimate(2)*side - lme.Coefficients.Estimate(3)*hand_dom;

% Compensate also the reference population.
gender = zeros(size(reference_population, 1), 1);
gender(reference_population.gender == 'female') = 1;
side = zeros(size(reference_population, 1), 1);
side(reference_population.tested_hand == 'right') = 1;
hand_dom = zeros(size(reference_population, 1), 1);
hand_dom(reference_population.is_dominant_hand == 'no') = 1;

reference_population.([column '_t_c']) = reference_population.([column '_t']) - lme.Coefficients.Estimate(5)*reference_population.age - lme.Coefficients.Estimate(4)*gender ...
    - lme.Coefficients.Estimate(2)*side - lme.Coefficients.Estimate(3)*hand_dom;
reference_population.([column '_retest_t_c']) = reference_population.([column '_retest_t']) - lme.Coefficients.Estimate(5)*reference_population.age - lme.Coefficients.Estimate(4)*gender ...
    - lme.Coefficients.Estimate(2)*side - lme.Coefficients.Estimate(3)*hand_dom;

%mu = median(reference_population.([column '_comp_transf']))
%sigma = mad(reference_population.([column '_comp_transf']), 1)

%reference_population.([column '_comp_transf']) = (reference_population.([column '_comp_transf']) - mu)./sigma
%impaired_population.([column '_comp_transf']) = (impaired_population.([column '_comp_transf']) - mu)./sigma

end
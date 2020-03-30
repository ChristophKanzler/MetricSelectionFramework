function data = compensate_confounds(data, population, effects, lme) 
coeff_names = lme.CoefficientNames;

for i = 1:length(coeff_names)
    coeff = coeff_names{i};
    
    if strcmp(coeff, '(Intercept)')
        continue;
    end
    
    eff = effects{find(cellfun(@(x) contains(coeff, x), effects))};
    coeff_val = strrep(coeff, eff, '');
    
    if ~isempty(coeff_val) && strcmp(coeff_val(1), '_')
        coeff_val = coeff_val(2:end);
    end
    
    if isempty(coeff_val)
        data = data - lme.Coefficients.Estimate(i) * population.(eff);
    else
        if isnumeric(population.(eff))
            eff_filter = population.(eff) == str2double(coeff_val);
        else
            eff_filter = population.(eff) == coeff_val;
        end
        
        data = data - lme.Coefficients.Estimate(i) * eff_filter;
    end
end
end
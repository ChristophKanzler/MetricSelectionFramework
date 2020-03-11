function population = initialize_population(num_subjects, mu_age, variability_age, is_impaired)
population = table();
population.id = [1:num_subjects]';
population.tested_hand = [repmat(categorical(cellstr('left')),num_subjects/2,1); repmat(categorical(cellstr('right')),num_subjects/2,1)];
population.is_dominant_hand = [repmat(categorical(cellstr('yes')),num_subjects/4,1); repmat(categorical(cellstr('no')),num_subjects/4,1); ...
                                       repmat(categorical(cellstr('yes')),num_subjects/4,1);   repmat(categorical(cellstr('no')),num_subjects/4,1)];
population.gender = [repmat(categorical(cellstr('male')),num_subjects/5,1); repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                       repmat(categorical(cellstr('male')),num_subjects/5,1);   repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                    repmat(categorical(cellstr('male')),num_subjects/5,1)];


if (is_impaired)
    last_chunk = mod(num_subjects, 3) + round(num_subjects/3);
    population.disease_severity = [repmat(categorical(cellstr('low')), round(num_subjects/3), 1) ; repmat(categorical(cellstr('medium')), round(num_subjects/3), 1); ...
        repmat(categorical(cellstr('high')), last_chunk, 1)];
else
    population.disease_severity = repmat(categorical(cellstr('no')), num_subjects, 1);
end
% Add age
do_log = 1;
population.age = generate_simulated_parameter(mu_age, variability_age, num_subjects, do_log);
end
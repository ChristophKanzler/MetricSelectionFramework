function [reference_population,impaired_population] = initiate_random_tables
%% Generate random data with all relevant columns to perform evaluation
%reference_population: neurologically intact subjects
%impaired_population: neurologically affected subjects


%% initiate table for reference distribution (healthy subjects)
%add meta data
num_subjects = 100;
reference_population = table();
reference_population.id = [1:num_subjects]';
reference_population.tested_hand = [repmat(categorical(cellstr('left')),num_subjects/2,1); repmat(categorical(cellstr('right')),num_subjects/2,1)];
reference_population.is_dominant_hand = [repmat(categorical(cellstr('yes')),num_subjects/4,1); repmat(categorical(cellstr('no')),num_subjects/4,1); ...
                                       repmat(categorical(cellstr('yes')),num_subjects/4,1);   repmat(categorical(cellstr('no')),num_subjects/4,1)];
reference_population.gender = [repmat(categorical(cellstr('male')),num_subjects/5,1); repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                       repmat(categorical(cellstr('male')),num_subjects/5,1);   repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                    repmat(categorical(cellstr('male')),num_subjects/5,1)];
                                   
%add age
do_log = 1;
mu_age = 50;
variability_age = 30;
reference_population.age = generate_simulated_parameter(mu_age,variability_age,num_subjects,do_log);

%add simulated  metric                                   
%mu = 46;
%variability = 32.2;
mu = 1;
variability = 0.3;
metric = generate_simulated_metric(mu,variability, reference_population.age,do_log);
reference_population.metric = metric;

% Add simulated retest metric by adding random noise.
mu = -200;
variability = 2;
noise = generate_simulated_parameter(mu,variability,num_subjects,0);
reference_population.metric_retest = metric + noise;

if(~isempty(find(isnan(reference_population.metric_retest))))
    error('NaN data after adding noise!');
end


%% Initiate table for neurologically impaired subjects.
% Add subject meta data.
num_subjects = 100;
impaired_population = table();
impaired_population.id = [1:num_subjects]';
impaired_population.tested_hand = [repmat(categorical(cellstr('left')),num_subjects/2,1); repmat(categorical(cellstr('right')),num_subjects/2,1)];
impaired_population.impaired_hand = impaired_population.tested_hand;
impaired_population.is_dominant_hand = [repmat(categorical(cellstr('yes')),num_subjects/4,1); repmat(categorical(cellstr('no')),num_subjects/4,1); ...
                                       repmat(categorical(cellstr('yes')),num_subjects/4,1);   repmat(categorical(cellstr('no')),num_subjects/4,1)];
impaired_population.gender = [repmat(categorical(cellstr('male')),num_subjects/5,1); repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                       repmat(categorical(cellstr('male')),num_subjects/5,1);   repmat(categorical(cellstr('female')),num_subjects/5,1); ...
                                    repmat(categorical(cellstr('male')),num_subjects/5,1)];
                                  
% Add age.
mu_age = 50;
variability_age = 30;
impaired_population.age = generate_simulated_parameter(mu_age,variability_age,num_subjects,do_log);
                                   
% Add simulated metric.                                   
mu = 1.07;
variability = 0.3;
metric = generate_simulated_metric(mu,variability,impaired_population.age,do_log);
impaired_population.metric = metric;

% Add simulated retest metric by adding random noise.
mu = -100;
variability = 2;
noise = generate_simulated_parameter(mu,variability,num_subjects,0);
impaired_population.metric_retest = metric + noise;

if(~isempty(find(isnan(impaired_population.metric_retest))))
    error('NaN data after adding noise!');
end

                                


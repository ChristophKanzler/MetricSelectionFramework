function  effects_p = mixed_effect_model_significances(tbl,lme,effects_string, simulated_lrt )
%% build alternative models with one effect less to test signifiance

%get fixed effect names
[~,names] = fixedEffects(lme);
names = table2cell(names)';
ind_intercept = cell2mat(strfind(names,'(Intercept)'));
names{ind_intercept} = '1';
fe_names = {};

%get variable info
vi = lme.VariableInfo;
vi(vi.InModel == 0,:) = [];
vi_names = vi.Properties.RowNames;

%check if we have a fixed effect with multiple categorical levels
check_levels = 0;
for i=2:length(vi_names)
    %build string
    s = '';
    ind = (cell2mat(strfind(names,vi_names{i})));
    if(~isempty(ind))
        %yes, it is a fixed effect --> substitute in effect string
        fe_names = [fe_names; {vi_names{i}}];
        
        if(~iscategorical(vi.Range{i}))
            continue;
        end
        levels = cellstr(vi.Range{i});

        if(1)
            continue;
        end
        
        if(length(levels)<=2)
            continue;
        else
            check_levels = 1;
        end
      
        %append string with levels
        for j=1:length(levels)
            if(j==length(levels))
                s = [s  vi_names{i} '_' levels{j}];
            else
                s = [s  vi_names{i} '_' levels{j} ' + '];
            end
        end
        
        effects_string = strrep(effects_string,vi_names{i},s);
    end
end

if(~isempty(ind_intercept))
    fe_names = [fe_names; {'1'}];
end
check_levels = 0;
if(check_levels)
    %split labels
    effects_mod = names;
else
    effects_mod = fe_names;
end
is_fixed_effect = true(length(effects_mod),1);

%build actual models
effects_p = table();
p_values = [];
for i=1:length(effects_mod)
    if(strcmp(effects_mod{i},'1'))
        %remove intercept from string
        alt_eff_string =strrep(effects_string,[' ' effects_mod{i} ' +'],'-1 +');
    elseif(strcmp(effects_mod{i},'1_RE'))
        %remove random intercept from string
        alt_eff_string =strrep(effects_string,['(1+'],'(-1+');
        continue;
    elseif(~is_fixed_effect(i))
        %remove random effect from string
        alt_eff_string =strrep(effects_string,['+' effects_mod{i}],'');
    else
        %remove effect from string
        alt_eff_string =strrep(effects_string,['+ ' effects_mod{i} ' '],' ');
    end
    
    %check if it worked
    if(strcmp(alt_eff_string,effects_string))
        error('Effect not removed for LME analysis!');
    end
    
    %build alternative model
    alt_lme = fitlme(tbl,alt_eff_string);
    
    if(simulated_lrt == 0 && is_fixed_effect(i))
        p_values = [p_values; -1];
    else
        if(is_fixed_effect(i))
            if(lme.LogLikelihood>  alt_lme.LogLikelihood)
                nesting = true;
            else
                nesting = false;
            end
            
            [results,sims] = compare(alt_lme,lme,'nsim',simulated_lrt,'CheckNesting',nesting);
        else
            continue;
            [results,sims] = compare(alt_lme,lme,'nsim',simulated_lrt,'CheckNesting',true);
        end
        p_values = [p_values; sims.pvalueSim];
    end
end
effects_p.labels = effects_mod;
effects_p(~is_fixed_effect,:) = [];
effects_p.p_values = p_values;
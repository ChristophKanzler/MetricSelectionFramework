function outcomes = analyze_reliability
%% Analyze test-retest reliability
if(nargin == 0)
    const = setup;
    
    do_healthy =1;
    if(do_healthy)
        load(fullfile(const.root_dir,'data_normative_trials.mat'));%%'));
        %         load(fullfile(const.root_dir,'data_normative_pegs.mat'));
        tmp = data_table;
        data_table(data_table.patient <= 6,:) = [];
        data_table = remove_non_repeated_measures(data_table);
        %         data_table.trial = data_table.trial-1;
        %         data_table.trial(data_table.session==2) = data_table.trial(data_table.session==2)-6;
        
        load('output/const_after_corr.mat');
        %         [~, ind] = unique(data_table(:,[1 2 3 4 5 6 7 8 10 11 12 13 14 15 22]), 'rows');
        %         data_table = data_table(ind,:);
        %         all_inds = 1:size(data_table,1);
        %         diffs = setdiff(all_inds,ind);
        %         removed = data_table(diffs,:);
    else
        %load(fullfile(const.root_dir,'/data_softpro_trials.mat'));%_pegs.mat'));
        load(fullfile(const.root_dir,'data_softpro_trials.mat'))%_pegs
        data_table = remove_non_repeated_measures(data_table);
    end
    
    dt = data_table;
    const =  adapt_feature_indices(dt,const);
    
    %% remove some pegs if neccessary here
    %     dt_sub = remove_outliers_per_subject(dt);
    % 	dt = average_per_trial(dt,const);
    
    if(do_healthy)
        outputPath = fullfile('output','reliability');
    else
        outputPath = 'output/softpro';
    end
    const.outputPath = outputPath;
    with_averaging = 0;
    dt_init = dt;
    [dt,const] = apply_framework_v4_models(dt,const,with_averaging);
    
    dt_all = normalize_worst_subject(dt,const);
    dt_all_sess = average_per_session(dt_all,const);
    %     dt = average_per_session(all,const);
end
% for i=1:length(const.feature_indices)
%     tmp = dt.(const.feature_indices(i));
%      tmp(tmp==0) = eps;
%      tmp(tmp==100)=100-eps;
%     tmp = logit(tmp./100);
%     dt.(const.feature_indices(i)) = tmp;
% end

if(nargin<=2)
    icc_type = 'A-k';
end
%% reliability: calc stats & bland-altmans
if(exist(outputPath) ==0)
    mkdir(outputPath);
end

%get diseases
diseases = unique(dt_all.disease);

outcomes = cell(length(diseases),2);
%get one outcome table per disease
mdc_all = [];
ICCs = [];
icc_all = [];
mdc_rel_all = [];
slopes = [];
all_metrics = dt_all_sess.Properties.VariableNames(const.feature_indices);

srd_cutoffs = table();
mdc_cutoff   =  30.246460623874171;%13.5266; %
slope_cutoff =   -6.354185746293189;
all_ps =[];
%iterate over diseases
for l=1:length(diseases)
    %init output
    stats = table();
    
    %restrict to current disease
    dt_cur = dt_all(dt_all.disease == diseases(l),:);
    outcomes{l,2} = diseases(l);
    
    %iterate over metrics
    for j=1:length(const.feature_indices)
        %iterate over sides
        for i=3
            if(dt_cur.disease(1) == 'healthy')
                sides = {'left','right','both'};
                %get only current side
                if(i==3)
                    dt_sides=dt_cur;
                else
                    dt_sides = dt_cur(dt_cur.tested_hand == sides{i},:);
                end
            else
                %get only current side
                sides = {'impaired','less_impaired','both'};
                if(i==1)
                    dt_sides = dt_cur(dt_cur.tested_hand == dt_cur.impaired_hand,:);
                elseif(i==2)
                    dt_sides = dt_cur(dt_cur.tested_hand ~= dt_cur.impaired_hand,:);
                else
                    dt_sides = dt_cur;
                end
            end
            
            %get current metric id
            ind = const.feature_indices(j);
            label = dt_sides.Properties.VariableNames{ind};
            label_init = label;
            
            %format label
            label = strrep(label,'_',' ');
            label = strrep(label,'go','transport');
            label = [upper(label(1)) label(2:end)];
            
            %safety checks
            dt_sides_cur = dt_sides;
            if(isempty(dt_sides_cur))
                continue;
            end
            %
            %             if(~isempty(find(isnan(dt_sides.(ind)))))
            %                 display(['Skipped '  ' due to NaNs!']);
            %             end
            
            %get data gruoped per subject
            [vals_d1,vals_d2] = get_test_retest_per_subject(dt_sides_cur,ind);
            %             tmp = vals_d1;
            %             tmp2= vals_d2;
            %             %replace nan by median
            %             if(1)
            %                 [rows, columns] = find(isnan(vals_d1));
            %                 for ijk=1:length(rows)
            %                     v = vals_d1(rows(ijk),:);
            %                     vals_d1(rows(ijk),columns(ijk)) = median(v(~isnan(v)));
            %                 end
            %                 [rows, columns] = find(isnan(vals_d2));
            %                 for ijk=1:length(rows)
            %                     v = vals_d2(rows(ijk),:);
            %                     vals_d2(rows(ijk),columns(ijk)) = median(v(~isnan(v)));
            %                 end
            %             end
            %look for nans
            [rows, columns] = find(isnan(vals_d1) | isnan(vals_d2));
            if(~isempty(rows))
                vals_d2(rows,:) = [];
                display(['Removed NaNs - to be fixed!: ' label]);
            end
            
            [icc_val,LB,UB,MSE] = ICC_mReliability(vals_d1,vals_d2);
            %             lme = 1(rows,:) = [];
            %             vals_dfitlme(dt_sides_cur, [label_init ' ~ 1+ (1|trial) + (1|patient) + (1|patient:trial) + (1|patient:session)']);
            %             mod <- lmer(y~1 + (1|Rater) + (1|ID) + (1|ID:Rater) + (1|ID:Day), data = dat)
            
            %take mean over trials
            mu_d1 = median(vals_d1,2);
            mu_d2 = median(vals_d2,2);
            
            label_init_with_side= [sides{i} '_' label_init];
            
            %             mdl = fitlm([zeros(length(mu_d1),1); ones(length(mu_d1),1)],[mu_d1; mu_d2]);
            fid = fopen(fullfile(const.outputPath,['learning_' char(diseases(l)) '_'  label_init_with_side '.txt']),'w');
            %             slope = mdl.Coefficients.Estimate(end);
            
            %             slopes = [slopes; slope];
            %p = mdl.Coefficients.pValue(end);
            
            [h,p,ci,stats_t] = ttest(mu_d2,mu_d1);
            all_ps = [all_ps; p];
            d = mu_d2-mu_d1;
            %             slope = stats_t.tstat;
            
            %           slop_est = mean(d)/(std(d)/sqrt(length(d)));
            %          slop_est = mean(d)/(range(d)/sqrt(length(d)));
            
            slope = mean(d)/(range([mu_d2; mu_d1]))*100;
            slopes = [slopes;slope];
            slope_rnd = round(slope*100)/100;
            s = num2str(slope_rnd);
            spl = strsplit(s,'.');
            if(length(spl)==1)
                s = [s '.00'];
            else
                if(length(spl{end})==1)
                    s = [s '0'];
                end
            end
            if(length(strrep(spl{1},'-',''))==1)
                s = ['\phantom{1}' s];
            end
            if(~contains(s,'-'))
                s = ['\phantom{-}' s];
            end
            
            if(p<0.05 && slope <= slope_cutoff)
                fprintf(fid,'%s',s);
            else
                fprintf(fid,'%s',['\textbf{' s '}']);
            end
            fclose(fid);
            
            %get coefficient of variation for intra-subject variability
            cvs_d1 = (std(vals_d1,[],2));%./mean(vals_d1,2));
            cvs_d2 = (std(vals_d2,[],2));%./mean(vals_d2,2));
            cvs_mu = mean([cvs_d1 cvs_d2],2);
            cvs_mu_across_subjects = mean(cvs_mu);
            fid = fopen(fullfile(const.outputPath,['ISV_' char(diseases(l)) '_'  label_init_with_side '.txt']),'w');
            s = num2str(round(cvs_mu_across_subjects*100)/100);
            beg =strsplit(s,'.');
            if(length(beg{1})==2)
                s = ['\phantom{1}' s];
            end
            fprintf(fid,'%s',s);
            fclose(fid);
            
            metrics_good = {'log_jerk_go','log_jerk_return','spectral_arc_return','path_length_ratio','path_length_ratio_return','throughput_return','vel_mean_go','vel_max_go',...
                'vel_mean_return','vel_max_return','jerk_approach_peg','spectral_arc_approach_hole','force_peaks_go','force_rate_spectral_arc_length','force_peaks_approach_peg','force_peaks_approach_hole',...
                'force_rate_spectral_arc_length_approach_hole','force_rate_spectral_arc_length_approach_peg','force_buildup_time','force_release_spectral_arc_length','actual_total_time'};
            
            %             %FOR  SEM calculation, use ALL TRIALS
            %             alpha = .05;
            %             r0 = 0;
            %             [icc_val_A_k, ~, ~, ~, ~, ~, ~,~, ~,MSE] = ICC(([vals_d1 vals_d2]),'A-k',alpha,r0);
            %
            %             %FOR OUTPUT ICC, USE SINGLE TRIAL
            %             alpha = .05;
            %             r0 = 0;
            % %             [icc_val, ~, UB, F, df1, df2, p,sem1, sem2,MSE] = ICC(([mu_d1 mu_d2]),'A-1',alpha,r0);
            %             [icc_val, ~, ~, ~, ~, ~, ~,~, ~,MSE] = ICC(([vals_d1 vals_d2]),'A-k',alpha,r0);
            %             [bootstat,bootsam] = bootci(10,@ICC,[vals_d1 vals_d2]);
            %             LB = bootstat(1);
            %             UB = bootstat(2);
            
            
            
            %get srd values
            percentage_output = 1;
            [srd_de_vet,srd_pfenning,srd_de_groot,srd_mike] = get_SRDs(vals_d1,vals_d2,icc_val,MSE,percentage_output);
            percentage_output = 0;
            [~,srd_pfenning_raw,~,~] = get_SRDs(vals_d1,vals_d2,icc_val,MSE,percentage_output);
            
            %put stats together
            [~,p_val] = ttest(mu_d1,mu_d2);
            stats.new = [icc_val mean(mu_d1) std(mu_d1) mean(mu_d2) std(mu_d2) mean(mu_d2 - mu_d1) std(mu_d2 - mu_d1) mean(abs(mu_d2-mu_d1)) std(abs(mu_d2-mu_d1)) p_val]';
            stats.Properties.VariableNames{end} = [label_init '_' sides{i}];
            label_init_tmp = label_init;
            
            mdc_all = [mdc_all; srd_pfenning];
            icc_all = [icc_all; icc_val];
            if(~isempty(find(ismember(metrics_good,label_init))))
                ICCs = [ICCs;icc_val];
                mdc_rel_all = [mdc_rel_all;srd_pfenning];
            end
            
            %export SRDs
            %             export_SRDs(icc_val,LB,UB,srd_de_vet,srd_pfenning,srd_de_groot,srd_mike,[char(diseases(l)) '_'  label_init_with_side],mdc_cutoff,const);
            if(do_healthy && i==3)
                srd_cutoffs.label(j) = {label_init_with_side};
                srd_cutoffs.healthy_srd_pfenning_raw(j) = srd_pfenning_raw;
                srd_cutoffs.healthy_srd_pfenning(j) = srd_pfenning;
            end
            
            
            %% make plot of day 1 vs day 2
            if(0 && i==3 && strcmp(label_init,'actual_total_time'))
                %make test-retest plot
                %                 visualize_test_retest;
                ms_size = 15;
                visualize_test_retest_with_jitter(mu_d1,mu_d2,label_init_tmp,icc_val,slope,diseases(l),ms_size,const);
                %make variability plot
                x_1 = 1.1;
                
                all_trials = [vals_d1, vals_d2];
                all_trials_std = std(all_trials,[],2);
                
                a = prctile(all_trials_std,[25 50 75]);
                d1_lq = a(1); d1_med = a(2); d1_uq = a(3);
                
                figure;
                hold on;
                box_width = 0.015;
                
                %                 raincloud_plot(all_trials_std,'box_on', 1);
                %                 xlabel('Intra-subject variability: task completion time');
                jitter = [-0.005:0.0005:0.005]';
                rng('default');
                inds = randi(length(jitter),[length(vals_d1) ,1]);
                
                x_1s = x_1.*ones(length(vals_d1),1) + arrayfun(@(x) jitter(x),inds);
                %plot day one
                plot(x_1s,all_trials_std,'.k','MarkerSize',ms_size);%data points
                plot([x_1-box_width x_1+box_width], [d1_med d1_med],'-r','LineWidth',2);%median
                plot([x_1-box_width/1.5 x_1+box_width/1.5], [d1_uq d1_uq],'-r','LineWidth',1.5);%upper quartile
                plot([x_1-box_width/1.5 x_1+box_width/1.5], [d1_lq d1_lq],'-r','LineWidth',1.5);%lower quartile
                
                %                 plot(x_2.*ones(length(vals_d2),1),vals_d2,'.k','MarkerSize',ms_size);
                %                 plot([x_2-box_width x_2+box_width], [d2_med d2_med],'-r','LineWidth',2);%median
                %                 plot([x_2-box_width/1.5 x_2+box_width/1.5], [d2_uq d2_uq],'-r','LineWidth',1.5);%upper quartile
                %                 plot([x_2-box_width/1.5 x_2+box_width/1.5], [d2_lq d2_lq],'-r','LineWidth',1.5);%lower quartile
                xlim([1.0 1.2])
                set(0,'DefaultFigureColor','remove')
                set(gcf,'color','w');
                box off;
                set(gca,'tickdir','out')
                xticks(1.1);
                %                 xticklabels('Y');
                %                 for ij=1:length(vals_d2)
                %                     h = plot([x_1; x_2],[mu_d1(ij); mu_d2(ij)],'-k');%,'Color',[220,220,220]./255);
                %                     %alpha(h,0.3
                %                     h.Color(4) = 0.2;
                %                 end
                label =adjust_labels({label_init_tmp});
                ylabel({'Task completion time','std. across repetitions','(norm. VPIT scores)'},'FontSize',ms_size-1);% ,'\rm (distance to neurol. intact norm)'});
                %                 xlabel(label{1});
                set(gca, 'FontSize', ms_size-1)
                xticklabels({'Test & retest'});
                %             title(['ICC: ' num2strset(round(icc_val*100)/100) ', MDC: ' num2str(round(mdc*100)/100)])
                yt = get(gca, 'ytick');
                ytl = strcat(strtrim(cellstr(num2str(yt'))), '%');
                set(gca, 'yticklabel', ytl);
                text(1.1,24,['SRD% ' num2str(round(srd_pfenning*100)/100)],'HorizontalAlignment','center','FontSize',ms_size);
                
                export_fig(fullfile(outputPath,['srd_' char(diseases(l)) '_' label_init ]),'-pdf');
            end
        end
    end
    
    cols = table();
    cols.description = {'ICC', 'Mean day 1', 'Std day 1','Mean day 2','Std day 2','Mean difference','Std difference','Mean abs. difference','Std abs. difference','paired t-test d1 & d2'}';
    stats = [cols stats];
    
    disp(['Mean ICC over metrics/sides: ' num2str(mean(table2array(stats(1,2:end)))) ' +- ' num2str(std(table2array(stats(1,2:end))))]);
    disp(['Mean change over days: ' num2str(mean(table2array(stats(end,2:end)))) ' +- ' num2str(std(table2array(stats(end,2:end)))) ' %']);
    
    outcomes{l} = stats;
end

save('output/srd_cutoffs.mat','srd_cutoffs');
prctile(ICCs,[25 50 75])
prctile(mdc_rel_all,[25 50 75])
prctile(mdc_all,80)
aucs_tmp = aucs;
icc_tmp = icc_all;
mdc_tmp = mdc_all;
slopes_tmp = slopes;

ind = find(cellfun(@(x) strcmp(x,'number_vel_peaks_return'),all_metrics));
aucs(ind) = [];
icc_all(ind) = [];
mdc_all(ind) = [];
slopes(ind) = [];
all_metrics(ind) = [];

% prct_cutoff = 30;
eval1 = aucs> 0.7 & icc_all >= 0.7 & mdc_all <= prctile(mdc_tmp,80) &  slopes > prctile(slopes_tmp,20);
sel_metrics = all_metrics(eval1);

icc_end = icc_all(eval1);
prctile(icc_end,[25 50 75])
mdc_end = mdc_all(eval1);
prctile(mdc_end,[25 50 75])

slopes_end = slopes(eval1);
prctile(slopes_end,[25 50 75])


aucs_end = aucs(eval1);
prctile(aucs_end,[25 50 75])


%
%
%
% aucs = [0.369500000000000
% 0.832333333333333
% 0.830041666666667
% 0.759291666666667
% 0.754291666666667
% 0.607395833333333
% 0.634812500000000
% 0.607229166666667
% 0.462333333333333
% 0.799750000000000
% 0.841854166666667
% 0.778312500000000
% 0.818520833333333
% 0.435541666666667
% 0.449625000000000
% 0.427937500000000
% 0.484687500000000
% 0.885354166666667
% 0.923375000000000
% 0.218562500000000
% 0.0862500000000000
% 0.828791666666667
% 0.898770833333333
% 0.839708333333333
% 0.710333333333333
% 0.733229166666667
% 0.761604166666667
% 0.554354166666667
% 0.574750000000000
% 0.668729166666667
% 0.667395833333333
% 0.605937500000000
% 0.556750000000000
% 0.554104166666667
% 0.509520833333333
% 0.508958333333333
% 0.595916666666667
% 0.939395833333333
% 0.857541666666667
% 0.657312500000000
% 0.686270833333333
% 0.566729166666667
% 0.738875000000000
% 0.860854166666667
% 0.778520833333333
% 0.372312500000000
% 0.363791666666667
% 0.282208333333333
% 0.146333333333333
% 0.387583333333333
% 0.454395833333333
% 0.316291666666667
% 0.175541666666667
% 0.841104166666667
% 0.911625000000000
% 0.895729166666667
% 0.903604166666667
% 0.249458333333333
% 0.249229166666667
% 0.395375000000000
% 0.395791666666667
% 0.289083333333333
% 0.0660000000000000
% 0.446000000000000
% 0.492375000000000
% 0.696000000000000
% 0.147041666666667
% 0.555937500000000
% 0.669750000000000
% 0.444958333333333
% 0.909645833333334
% 0.736583333333333
% 0.744937500000000
% 0.637541666666667
% 0.595333333333333
% 0.652458333333333
% 0.911208333333333];
% 'dbg'


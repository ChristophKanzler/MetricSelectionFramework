function analyze_factors
%% Concurrent validity analysis
if(nargin==0)
    %load healthy
    const = setup;
    load(fullfile(const.root_dir,'data_normative.mat'))
    data_table(data_table.patient <= 6 | data_table.session == 2,:) = [];
    data_table(data_table.has_stereo_vision == -1,:) = [];
    data_table.disease_type = cell(size(data_table,1),1);
    
    %load data if no input given
    [all,const] = load_studies('all data');
    all = average_per_session(all,const);
    all = concat_tables(all,data_table);
    const_init = adapt_feature_indices(all,const);
    
    %% remove repeated mesures
    all = remove_repeated_mesaures(all);
    %all(all.disease == 'stroke' & all.tested_hand ~= all.impaired_hand,:) = [];

    %apply VPIT framework
    outputPath=['T:/projects/VPIT/doc/publications/2017_VPIT_methods/submission_JNER/data'];
    const_init.outputPath = outputPath;
    [dt,const] = apply_framework_v4_models(all,const_init);
    
    dt = normalize_worst_subject(dt,const);
    %dt = all;
    %dt = average_per_session(dt,const_init);
    
    if(0)
        %export  info on subjects
        dt_exp = standardize_table(dt);
    %     tmp = dt(dt.study_id == 'RELab_study',:);
    %     get_study_information(tmp,const,0);

        dt_exp.time_since_injury(lower(dt_exp.study_id) == 'softpro') = dt_exp.time_since_injury(lower(dt_exp.study_id) == 'softpro')/54;
        dt_exp.time_since_injury(lower(dt_exp.study_id) == 'ms_old') = dt_exp.time_since_injury(lower(dt_exp.study_id) == 'ms_old')/54;
         dt_exp.time_since_injury((dt_exp.study_id) == 'ITRAVLE') = dt_exp.time_since_injury(lower(dt_exp.study_id) == 'ITRAVLE')/54;
        const.outputPath = 'output/methods-paper-2017';
        import_strings_latex = get_study_information_single_subjects(dt_exp(dt_exp.study_id~='RELab_study',:),const);
    end
end

%set output directory
outputPath = fullfile('output','factors');
if(exist(outputPath) ==0)
    mkdir(outputPath);
end

%% take pre-selected metrics only
load('output/const_after_corr.mat')
const = adapt_feature_indices(dt,const);
metrics_table = dt(:,const.feature_indices);

%removed based on factor analysis
% metrics_table.log_jerk_return = [];
% metrics_table.force_release_peaks_return = [];
metrics_array = table2array(metrics_table);

% %% whiten data (again)
%  metrics_array = zscore(metrics_array);

%% export KMO value
kmo_val=  kmo((metrics_array));
fid = fopen(fullfile('output','factors',['kmo.txt']),'w');
s = num2str(round(kmo_val*100)/100);
if(length(s)==3)
    s = [s '0'];
end
fwrite(fid, s);
fclose(fid);

%% export data to R to run parallel analysis for detemrinating number of factors
path = 'T:\projects\VPIT\doc\publications\2017_VPIT_methods\submission_JNER\factor_analysis_R';
csvwrite(fullfile(path,'data.csv'),metrics_array);

%% perform factor analysis with different rotations
%take oblique (i.e., non-orthogonal) rotation as we do not expect all
%factors to be uncorelated
labels = metrics_table.Properties.VariableNames;
labels = adjust_labels(labels);

% metrics_table.log_jerk_return = [];
% metrics_table.trajectory_error_max_go = [];
metrics_array = table2array(metrics_table);

% for i=1:size(metrics_array,2)
%     metrics_array(i,:) = (metrics_array(i,:)-mean(metrics_array(i,:)))/std(metrics_array(i,:));
% end
k=5;
rotations = {'promax','varimax','equamax','orthomax'};
% rotations = {'equamax'};
for ij= 1:length(rotations)
    tol =  0.00005;
    optionsFactoran = statset('TolX',tol,'TolFun',tol);
    [loadings,specificVar,T,stats,factors] = factoran((metrics_array), k,'rotate',rotations{ij},'optimopts',optionsFactoran);
 
    out = table();
    out.descriptions = labels';
    for l=1:size(loadings,2)
        out.new = loadings(:,l);
        out.Properties.VariableNames{end} = ['factor_' num2str(l)];
    end

    %export
    for l=1:size(out,1)
        fid = fopen(fullfile('output','factors',['metric_' num2str(l) '_description.txt']),'w');
        descr= strrep(out.descriptions{l},'_',' ');
        metric_str = [upper(descr(1)) descr(2:end)];
        metric_str = strrep(metric_str,'Dist','Distance');
        metric_str = strrep(metric_str,'2','');
        metric_str = strrep(metric_str,'go','transport');
        metric_str = strrep(metric_str,'Force','GF');
        metric_str = strrep(metric_str,'Spectral arc length','SPARC');
        metric_str = strrep(metric_str,'spectral arc length','SPARC');
        metric_str = strrep(metric_str,'GF peaks','GF num. peaks');
        fwrite(fid, metric_str);
        fclose(fid);

        for m=2:size(out,2)
            fid = fopen(fullfile('output','factors',['rot_' num2str(ij) '_metric_' num2str(l) '_factor_' num2str(m-1) '.txt']),'w');
            val = round(out.(m)(l)*100)/100;
            val_str = num2str(val);

            if(val == 1)
                val_str = '1.00';
            elseif(val==-1)
                val_str = '-1.00';
            elseif(length(val_str) == 1)
                val_str = '0.00';
            end
            if(length(val_str) == 3)
                val_str = [val_str '0'];
            end
            if(length(val_str) == 4 && strcmp(val_str(1),'-'))
                val_str = [val_str '0'];
            end
            if(length(val_str)==4)
                val_str = ['\,' val_str];
            end

            %if(abs(out.(m)(l)) == max(abs(table2array(out((l),2:end)))))
            if(abs(val)>=0.5)
                fwrite(fid,['\textbf{' val_str '}']);
%             elseif(abs(val)>=0.32)
%                 fwrite(fid,['\textit{' val_str '}']);
            else
                fwrite(fid,val_str);
            end
            fclose(fid);
        end
    end
end
'dbg'
%% remove metrics that do not load strongly anywhere
% remove = {'trajectory_error_max_go'};
% all_metrics = const.all_metrics;
% all_metrics(ismember(all_metrics,remove)) = [];
% const.aggregation_metrics = all_metrics;
% const.all_metrics = all_metrics;
% save('output/const_3.mat','const');

%% select number of clusters/components
% horn's paralel analysis
%metrics_array= zscore(metrics_array);

% nShuffle = 1000;
% alpha = 0.05;
% [latent, latentLow, latentHigh] = pa_test(metrics_array, nShuffle, alpha);
%
% percent = latent./sum(latent)*100;
% percent_ci_p = latentHigh./sum(latent)*100;
% percent_ci_n = latentLow./sum(latent)*100;
%
% figure;
% hold on;
% plot(1:length(percent),percent,'-ok')
% plot(1:length(percent),percent_ci_p,'-.k')
% %plot(1:length(percent),percent_ci_n,'-ob')
%
% plot(1:length(percent),repmat(1./sum(latent)*100,length(latent),1),'-k');
% xlabel('Component number');
% ylabel('Variance explained (%)');
% legend('PCA','Parallel analysis: 95% confidence interval','Kaiser criterion');

% % pca-based scree plot
% metrics_array= zscore(metrics_array);
% [~,~,latent, ~] = pca(metrics_array);
%
% figure;
% percent=latent./sum(latent)*100;
% plot(1:length(latent),percent,'-o');
% xlabel('Component number');
% ylabel('Variance explained (%)');
% %% Pca
% metrics_array=  zscore(metrics_array);
% pca_loadings= pca(metrics_array);
% %
% % concatted= [];
% % grp = [];
% % for i=1:length(pca_loadings)
% %     vals = abs(pca_loadings(i,1:k));
% %     concatted = [concatted; vals];
% %     grp = [grp; repmat(i,length(vals),1)];
% % end
% %
% % figure;
% % boxplot(abs(concatted),grp);
%
% % k=size(pca_loadings,2);
% % figure;
% % hold on;
% % summed_loadings = sum(abs(pca_loadings(:,[1:k])),2);
% % plot(1:length(pca_loadings),(summed_loadings),'-o');
%
% xticks([1:length(pca_loadings)]);
% xticklabels(adjust_labels(metrics_table.Properties.VariableNames));
% boxplot()
% ylabel('Absolute contribution to total variance');
% xtickangle(45);
%  [loadings,varimax_rotation] = rotatefactors(pca_loadings(:,1:k),'method','promax');%'promax');
%
%

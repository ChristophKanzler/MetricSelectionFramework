function [p_vals,all_metric_avg_effect_sizes] = visualize_impairment_profile_non_parametric_mad(population, metrics, abnormal_behaviour_cut_offs)
%% Make boxplots of metric groups to 'disease_severity' column
% Normalize everything w.r.t. worst neurological subject (highest value).
deactivate_stats = false;
n_metrics = length(abnormal_behaviour_cut_offs);
for i = 1:n_metrics
    metric_name = metrics{i};
    max_val = max(population.([metric_name '_c']));
    population.([metric_name '_norm']) = (population.([metric_name '_c']) ./ max_val) .* 100;
    abnormal_behaviour_cut_offs(i) = (abnormal_behaviour_cut_offs(i) / max_val * 100);
end
labels = metrics;

%init figure
figure('units','normalized','outerposition',[0 0 1 1]);
hold on;

%init arrays
p_vals = [];

% get disease severities
[groups,~,group_inds] = unique(population.disease_severity);

%generate legend entries with Ns
group_num_patients = [];
group_num_data_points = [];

for i=1:length(groups)
    group_num_data_points =[group_num_data_points; length(find(group_inds==i))];
end
legend_str = arrayfun(@(x,y,z) [char(x) ' impairment (n=' num2str(y) ')'],groups(1:end),group_num_data_points(1:end),'UniformOutput',false);

%define constants
width_group = 15; %width of the box plot group
%width_bar = .9; %width of the box plot bar
width_bar = 3.5;
width_whiskers = 1;
spacing_between_metrics = 10+width_group;
x_start = width_group;

%% set colors
%  Set colormap
hgg =[];

file_cnt = 1;

bonferoni_level = 0.05;
bonferoni_level_ph = 0.05;
all_metric_avg_effect_sizes = [];
x_middles= [];

%% iterate over metric groups and plot
for j=1:n_metrics
    %get metric
    y = population.(['metric' mat2str(j) '_norm']);
    
    if(~isempty(find(isnan(y))))
        warning(['Skipped due to NaN: ' labels{j}]);
        continue;
    end
    cmap = colorgrad(length(groups), 'red_down');
    cmap(1, :) = [192,192,192]./255;
    
    %apply statistical test
    g = double(population.disease_severity)';
    g_tmp = g;
    vals_g = unique(g);
    for i=2:length(vals_g)
        g(g==vals_g(i)) = i;
    end
    
    [p,~,stats] = kruskalwallis(y,g,'off');
    p_vals = [p_vals; p.*n_metrics];
    
    %group data according to severity level
    y_grouped = [];
    pats = {};
    for i=1:length(groups)
        y_cur = y(find(group_inds == i));
        
        if(length(y_cur) < length(y))
            y_cur = [y_cur; NaN(length(y)-length(y_cur),1)];
            y_grouped = [y_grouped y_cur];
            pats = [pats {population(find(group_inds==i),:)}];
        end
    end
    
    %save effect sizes via median distance per population
    effect_sizes = [];
    
    %iterate over severity groups
    x_middle_per_group = [];
    for i=1:size(y_grouped,2)
        %make legend at the end
        if(j==n_metrics)
            % Create a hggroup for each data set
            hgg(i) = hggroup();
            set(get(get(hgg(i),'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
            legendinfo(hgg(i),'patch',...
                'LineWidth',0.5,...
                'EdgeColor','k',...
                'FaceColor',cmap(i,:),...
                'LineStyle','-',...
                'XData',[0 0 1 1 0],...
                'YData',[0 1 1 0 0]);
            lgd = legend(hgg,legend_str,'AutoUpdate',false,'Location','southwest');
        end
        vals = y_grouped(:,i);
        vals = vals(~isnan(vals));
        % Calculate the mean and confidence intervals
        [q1, q2, q3, fu, fl, ~, ~] = quartile(vals);
        
        %define positions for whisker and vert. mid line
        x_middle = x_start - width_group/2+(i-size(y_grouped,2)/2)*width_group/size(y_grouped,2);%/(size(y_grouped,2)*horiz_space_scaling);
        x_left = x_middle -  width_whiskers/2;
        x_right =  x_middle +  width_whiskers/2;
        
        if(i==round(size(y_grouped,2)/2))
            %save middle anchor for xticks later
            x_middles = [x_middles; x_middle];
        end
        
        %save all middle anchors for placing p-values
        x_middle_per_group = [x_middle_per_group;x_middle];
        
        %plot whiskers
        line([x_middle x_middle],[fu fl],...
            'Color','k','LineStyle','-','HitTest','off');
        line([x_left x_right],[fu fu],...
            'Color','k','HitTest','off');
        
        line([x_left x_right],[fl fl],...
            'Color','k','HitTest','off');
        
        %define position for box
        x1 = x_start - width_group/2 +   (i-size(y_grouped,2)/2)*width_group/size(y_grouped,2)-width_bar/2;
        x_middle = x_start - width_group/2 +   (i-size(y_grouped,2)/2)*width_group/size(y_grouped,2);
        p3 = width_bar;
        right = x_middle+width_bar/2;
        
        p2 = q1;
        p4 = q3-q1;
        
        % Plot quantile
        if q3 > q1
            rectangle('Position',[x1 p2 p3 p4],...
                'EdgeColor','w','FaceColor',cmap(i,:),'HitTest','off');
        end
        
        % Plot median
        line([x1 right],[q2 q2],...
            'Color','k','LineWidth',1,'HitTest','off');
        effect_sizes = [effect_sizes; q2];
        
        % plot data points above cut-off
        pats_cur = pats{i};
        vals = [];
        for ijk=1:size(y_grouped,1)
           val = y_grouped(ijk,i);
           
           if(isnan(val))
               continue;
           end
           
           %get patient belonging to current data point
           pat = pats_cur(ijk,:);
           
           %choose cut-off based on subject characteristics
           cut_off = abnormal_behaviour_cut_offs(j);
           %visualize cut-off
            if(i==1)
                plot([x1-spacing_between_metrics/8],[cut_off ],'>','Color',cmap(min(size(cmap,1),3),:),'MarkerSize',8,'LineWidth',2);%'Color',[192,192,192]./255
            end
           
           if(val>cut_off)
               vals = [vals; val];
           end
        end
        if(~isempty(vals) && i~=1)
            [n1 n2]=size(vals);
            noise = x1 + (right-x1).*rand(n1,n2) - x_middle;
            ppp = plot(ones(n1,1)*x_middle+(noise/3),vals,'k.','MarkerSize',12);
        end
        
        if(i== size(y_grouped,2))
            %% plot omnibus results: plot significance line
            y_offset = 102;
            y_significance_line = y_offset;
            offset = 1;
            x_left_p = x_middle_per_group(1);
            x_right_p = x_middle_per_group(end);
                       
            p_r = round(p*1000)/1000;
            p_rounded = num2str(p_r);
            if(length(p_rounded) == 1)
                p_rounded = '<0.001';
                p_text = '**';
            elseif(p_r<0.05)
                p_text  ='*';
            end
            if(~deactivate_stats)
                % add text
                if(p<bonferoni_level)
                    line([x_left_p x_right_p],[y_significance_line y_significance_line],'Color','k');
                    text(mean([x_left_p  x_right_p]),y_significance_line+offset,[p_text],'HorizontalAlignment','center','FontWeight','bold');
                end
                
                
                %% Plot results from post-hoc test
                if(p<bonferoni_level)%0.05)
                    %make test
                    [comparison,means,h,gnames] = multcompare(stats,'Display','off','CType','bonferroni');
                    
                    %get results for comparison
                    cnt = 1;
                    jumps = 5;
                    for ijk =1:size(comparison,1)
                        %t = comparison.Compaarison
                        start_col = min(comparison(ijk,1),comparison(ijk,2));
                        end_col = max(comparison(ijk,1),comparison(ijk,2));
                        strings = {'A','B','C','D'};
                        %post-hoc p values
                        p_posthoc = comparison(ijk,end);
                        p_rounded = num2str(round(p_posthoc*1000)/1000);
                        if(length(p_rounded) == 1)
                            p_rounded = '<0.001';
                            p_text_posthoc = '**';
                        elseif(p_posthoc<0.05)
                            p_text_posthoc = '*';
                        end
                        
                        if(p_posthoc<0.05)
                            %plot
                            y_significance_line = y_offset+jumps*cnt;                       % y_significance_line = 102+cnt*8;
                            
                            x_left_ph = x_middle_per_group(start_col);%;x_middle-(start_col-size(y_grouped,2)/2)*width_group/size(y_grouped,2); %(i-size(y_grouped,2)/2)*width_group/;
                            x_right_ph =  x_middle_per_group(end_col);%x_middle-(end_col-size(y_grouped,2)/2)*width_group/size(y_grouped,2);
                            
                            % add text
                            if(p_posthoc<bonferoni_level_ph)
                                line([x_left_ph x_right_ph],[y_significance_line y_significance_line],'Color','k','LineStyle','--');
                                line([x_left_ph x_left_ph],[y_significance_line y_significance_line-offset],'Color','k','LineStyle','--');
                                line([x_right_ph x_right_ph],[y_significance_line y_significance_line-offset],'Color','k','LineStyle','--');
                                
                                text(mean([x_left_ph  x_right_ph]),y_significance_line+offset,p_text_posthoc,'HorizontalAlignment','center','FontWeight','bold');
                                cnt = cnt+1;
                            end
                        else
                            
                        end
                    end
                end
            end
        end
    end
    
    %get average effect size
    effect_size_avg = mean(effect_sizes);
    all_metric_avg_effect_sizes = [all_metric_avg_effect_sizes; effect_size_avg];
    
    %add spacing between groups
    if(j==n_metrics-1)
        x_start = x_start+ spacing_between_metrics;
    else
        x_start = x_start+ spacing_between_metrics;
    end
end
fontSize = 17;

box off;
xlim([min(xlim)-spacing_between_metrics max(xlim)])
set(gca,'XTick',x_middles);
set(gca,'XTickLabel',labels);

xtickangle(45);
yl = ylabel({'\bf Decreasing task performance'},'FontSize',fontSize);

annotation('arrow', [0.07 0.07],[0.45 0.7]);
t = text(-45,100,{'Worst' ,'neurological', 'subject'},'FontSize',15,'HorizontalAlignment','center');
t = text(-45,0,{'Median' ,'reference' ,'population'},'FontSize',15,'HorizontalAlignment','center');

yt = get(gca, 'YTick');
set(gca, 'FontSize', fontSize)
ax = gca;
ax.Clipping = 'off';

p = ax.Position;
xlim([min(xticks)-range(xticks)/length(abnormal_behaviour_cut_offs) max(xticks) + range(xticks)/length(abnormal_behaviour_cut_offs)])
ax.Position = [p(1:2) p(3) p(4)-0.1];
ylim([-90 100]);
 
yt = get(gca, 'ytick');
ytl = strcat(strtrim(cellstr(num2str(yt'))), '%');
set(gca, 'yticklabel', ytl);

clear
close all

addpath('../utilities.functions');
load('../output.MVPA/N32_ROI_sm3_9conds_BVmask00_svm_Caspers2010_fromMaps.mat')
path_save = '../reports/N32_Group_MVPA_ROI_noAccLb/'; % fromMaps
mkdir(path_save);

path_roi = '../input.ROIs';
flist_mask = dir([path_roi '/*nii']);
flist_mask = flist_mask(contains({flist_mask.name}, 'Caspers2010'));
testvec = 1:7;

if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:29 31:38];
end

%% t-test 
chance = 0.5;
accuracy_table = table;
mean_accuracy_table = table;
pval_accuracy_table = table;
P_all = [];
for im = 1:length(flist_mask)

    for it = 1:length(testvec)
        itest = testvec(it);
        subs_accuracy = squeeze(all_accuracies(im,itest,:));
        accuracy_table(all_masks{im}, all_tests{itest}) = {subs_accuracy};
        mean_accuracy_table(all_masks{im}, all_tests{itest}) = {mean(subs_accuracy, 'omitnan')};
        
        [h,p,~,stats] = ttest(subs_accuracy, chance, 0.05, 'right');
        P_all(im, itest) = p;

        pval_accuracy_table(all_masks{im}, all_tests{itest}) = {p};
    end
end


%% plot bar graphs
bcolor = [152, 193, 217; 28 106 166; 248, 173, 157];
sig_thres_uncorrected = [0.05 0.01 0.001];
sig_thres_corrected = [fdr(P_all, 0.05) fdr(P_all, 0.01) fdr(P_all, 0.001)];

%% within success
% plot_col = 2:3;
% plot_row = [3 6 1 4 2 5];
% [ave, err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = accuracy_table.Properties.VariableNames(plot_col);
% % tLegend = regexp(tLegend, '(?<=(\d)(\d)_)(.*)','match')
% tLegend = {'Within-Success, Within-Object', 'Within-Success, Across-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Sucessful Actions';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected)
% saveas(gca,[path_save '/MVPA_ROI_WithinSuccess.jpg']);
% close all
% 
%% within fail
% plot_col = 4:5;
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% tLegend = {'Within-Failure, Within-Object', 'Within-Failure, Across-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Failed Actions';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinFailed.jpg']);
% close all

%% within outcome (collapsed across success and failure)
% plot_col = 1;
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome, Within-Object', 'Within-Outcome, Across-Object'};
% tLegend = {};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinOutcome_WithinObject.jpg']);
% close all

%% hemis
% plot_col = 2;
% plot_row = [3 1 2];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome, Within-Object', 'Within-Outcome, Across-Object'};
% tLegend = {};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinOutcome_WithinObject_left.jpg']);
% close all
% 
% plot_col = 2;
% plot_row = [6 4 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome, Within-Object', 'Within-Outcome, Across-Object'};
% tLegend = {};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinOutcome_WithinObject_right.jpg']);
% close all

%% across-outcome, within-object
% plot_col = 6;
% % plot_col = 6;
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome', 'Across-Outcome'};
% tLegend = {'Across-Outcome, Within-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome_WithinObject.jpg']);
% close all


%% across-outcome, across-object
% plot_col = 7;
% % plot_col = 6;
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome', 'Across-Outcome'};
% tLegend = {'Across-Outcome, Across-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome_AcrossObject.jpg']);
% close all


%% hemis
% plot_col = 6;
% plot_row = [3 1 2];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome', 'Across-Outcome'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome_WithinObject_left.jpg']);
% close all
% 
% plot_col = 6;
% plot_row = [6 4 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome', 'Across-Outcome'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome_WithinObject_right.jpg']);
% close all
%%

% %% across-outcome
% % plot_col = 6:7;
% plot_col = [3 1];
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% tLegend = {'Within-Outcome', 'Across-Outcome'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome_WithinObject.jpg']);


%% Across object: within success + within failed 
% plot_col = [3 5];
% plot_row = [3 6 1 4 2 5];
% [ave, err, p] = getStats(accuracy_table(plot_row,plot_col));
% tLegend = {'Within-Success, Across-Object', 'Within-Failure, Across-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Within Failed Actions';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinOutcome_AcrossObjects.jpg']);
% close all

%% within-fail within object
% plot_col = 4;
% % plot_col = 6;
% plot_row = [3 6 1 4 2 5];
% [ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% % tLegend = {'Within-Outcome', 'Across-Outcome'};
% tLegend = {'Within-Fail, Within-Object'};
% tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
% tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
% tXTickLabels = replace(tXTickLabels, '_', ' ');
% tXTickLabels = replace(tXTickLabels, 'MNI ', '');
% tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
% plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected);
% saveas(gca,[path_save '/MVPA_ROI_WithinFail_WithinObjects.jpg']);
% close all

%% across-outcome
plot_col = 6:7;
% plot_col = 6;
plot_row = [3 6 1 4 2 5];
[ave,err, p] = getStats(accuracy_table(plot_row,plot_col));
% tLegend = {'Within-Outcome', 'Across-Outcome'};
tLegend = {'Across-Outcome, Within-Object', 'Across-Outcome, Across-Object'};
tTitle = 'MVPA ROI: Decoding Open Vs Close Across Outcomes';
tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
tXTickLabels = replace(tXTickLabels, '_', ' ');
tXTickLabels = replace(tXTickLabels, 'MNI ', '');
tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected, [0.45 0.6]);
% saveas(gca,[path_save '/MVPA_ROI_AcrossOutcome.jpg']);
close all

%% Within object: within success + within failed 
% bcolor = [158, 228, 73; 253 104 110];
bcolor = [158, 215, 73; 235, 104, 110];
plot_col = [2 4];
plot_row = [3 6 1 4 2 5];
[ave, err, p] = getStats(accuracy_table(plot_row,plot_col));
% tLegend = {'Within-Success, Within-Object', 'Within-Failure, Within-Object'};
tLegend = {'Within Successful Actions', 'Within Failed Actions'};
tTitle = 'MVPA ROI: Decoding Open Vs Close Within Failed Actions';
tXTickLabels = accuracy_table.Properties.RowNames(plot_row);
tXTickLabels = replace(tXTickLabels, '_', ' ');
tXTickLabels = replace(tXTickLabels, 'MNI ', '');
tXTickLabels = replace(tXTickLabels, '(Caspers2010)', '');
plotBarGraph(ave,err,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected, [0.45 0.7]);
saveas(gca,[path_save '/MVPA_ROI_WithinOutcome_WithinObjects_newcolor.jpg']);
close all


function plotBarGraph(y,e,p,bcolor,tLegend, tTitle, tXTickLabels, sig_thres_uncorrected, sig_thres_corrected, yLim)
b = bar(y, 'EdgeColor', 'none');
hold on
% errorbar(y,e, 'LineStyle','none');

% add errorbar for each bar
numgroups = size(y, 1);
numbars = size(y, 2) ;
groupwidth = 0.6;
x_errorbar = zeros(numgroups,numbars);
for i = 1:numbars
    x_errorbar(:,i) = [(1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars)];
%     errorbar(x_errorbar(:,i), y(:,i), e(:,i), 'k', 'LineStyle', 'none');
    l = line([x_errorbar(:,i) x_errorbar(:,i)]', [y(:,i) y(:,i)+e(:,i)]', 'LineWidth',2, 'Color', bcolor(i,:)/255); %'Color', bcolor(i,:)/255
    for ig = 1:numgroups
%         text(x_errorbar(ig,i),y(ig,i)+e(ig,i)/2+0.015,[sprintf('%0.2f', y(ig,i)*100) '%'],'vert','bottom','horiz','center');
    end
end

plot([0.5 length(y) + 0.5], [0.5 0.5], 'LineStyle', ':', 'Color', 'black');
xlim([0.5 length(y) + 0.5])

% ylim([0.46 0.58]);
ylim(yLim);
yticks(yLim(1):0.05:yLim(2))

% title(tTitle);
ylabel('Accuracy');
xticklabels(tXTickLabels);
for k = 1:size(y,2)
        b(k).FaceColor = bcolor(k,:)/255; 
end
% if ~isempty(tLegend)
%     legend(tLegend, 'Location', 'northwest');
% end
% set(gcf, 'Position', [100 600 800 400]);
set(gcf, 'Position', [100 400 500 460]);
set(gca, 'FontSize', 16);

% axis off
box OFF

% add star for significant effect
for ip = 1:length(p(:))

    i_sig_uncorr = max(find(p(ip) < sig_thres_uncorrected));
    i_sig_corr = max(find(p(ip) < sig_thres_corrected));

    if i_sig_corr > 0
        sig = repmat('*',1,i_sig_corr);
        color_sig = 'red';
    elseif i_sig_uncorr > 0
        sig = repmat('*',1,i_sig_uncorr);
        color_sig = 'black';
    else
        continue
    end

%     t = text(x_errorbar(ip), y(ip) + 0.05, sig, 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', color_sig);
%     t = text(x_errorbar(ip)+0.05, y(ip) + 0.025, sig, 'FontSize', 20, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Color', color_sig);

    t = text(x_errorbar(ip)+0.24, y(ip) + (yLim(2)-yLim(1)) / 6.5, sig, 'FontSize', 20, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Color', color_sig);
    t.Rotation = 90;


%     if p(ip) < 0.001
%         sig = '***';
%     elseif p(ip) < 0.01
%         sig = '**';
%     elseif p(ip) < 0.05
%         sig = '*';
%     else 
%         continue
%     end
    
%     t = text(x_errorbar(ip), y(ip) + 0.05, sig, 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'red');
end
end

function [ave,err,pval] = getStats(data)
    ave = nan(size(data));
    err = nan(size(data));
    pval = nan(size(data));
    for i = 1:size(data,1)
        for j = 1:size(data, 2)
            x = data{i,j}{1};
            x = x(~isnan(x));
            ave(i,j) = mean(x);
            err(i,j) = std(x)/(sqrt(length(x)));
            [h,p] = ttest(x, 0.5,'tail','right');
            pval(i,j) = p;
        end
    end

end
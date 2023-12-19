clear;
close all

addpath('../utilities.functions');
load('../output.MVPA/N32_ROI_sm3_9conds_BVmask00_svm_Caspers2010_fromMaps.mat')
subvec = [2 4:12 14 16:22 24:29 31:38];
testvec = [5 6]; % 1:6; % catch cond decoding will be removed. so 1:6 instead of 2:7

path_roi = '../input.ROIs';
flist_mask = dir([path_roi '/*nii']);
flist_mask = flist_mask(contains({flist_mask.name}, 'Caspers2010'));
chance = 0.5;
accuracy_table = table;
mean_accuracy_table = table;
pval_accuracy_table = table;
for im = 1:length(flist_mask)
    for itest = 1:size(all_accuracies,2)
        subs_accuracy = squeeze(all_accuracies(im,itest,:));
        accuracy_table(all_masks{im}, all_tests{itest}) = {subs_accuracy};
        mean_accuracy_table(all_masks{im}, all_tests{itest}) = {mean(subs_accuracy, 'omitnan')};
        
    end
end

accuracy_table(:, 1) = []; % removing catch cond decoding

%% ANOVA prep
Y = [];
TEST = [];
ROI = [];
HEMI = [];
SUB = [];
for isub = subvec
    for irow = 1:size(accuracy_table,1)
        for itest = testvec
            Y = [Y accuracy_table{irow, itest}{1}(isub)];
            TEST = [TEST itest];
            
            tmp_ROI = split(accuracy_table.Properties.RowNames{irow}, '_');
            ROI = [ROI tmp_ROI(3)];
            HEMI = [HEMI tmp_ROI(2)];

            SUB = [SUB isub];
        end
    end
end

%% ANOVA - 6 tests
% FACTORS = {TEST; ROI; HEMI; SUB};
% [ANOVA_P,ANOVA_TABLE,ANOVA_STATS,TERMS] = anovan(Y, FACTORS, 'random', 4, 'model', 'full', 'display','on',...
%     'varnames', {'TEST' 'ROI' 'HEMISPHERE' 'SUBJECT'});
% FACTORS = {TEST; ROI; HEMI};
% fn = sprintf('../output.MVPA/N32_ROI_ANOVA_N%d_H1_2.csv',length(subvec));
% % [P,table,STATS,TERMS] = anovan(Y, FACTORS, 'model', 'full', 'display','on',...
% %     'varnames', {'TEST' 'ROI' 'HEMISPHERE'});
% fn = sprintf('../output.MVPA/N32_ROI_ANOVA_N%d_H1.csv',length(subvec));
% writetable(cell2table(ANOVA_TABLE),fn);

%% ANOVA - test 01 VS 03
FACTORS = {TEST; ROI; HEMI; SUB};
[ANOVA_P,ANOVA_TABLE,ANOVA_STATS,TERMS] = anovan(Y, FACTORS, 'random', 4, 'model', 'full', 'display','on',...
    'varnames', {'TEST' 'ROI' 'HEMISPHERE' 'SUBJECT'});
fn = sprintf('../output.MVPA/N32_ROI_ANOVA_N%d_H1_test5vs6.csv',length(subvec));
writetable(cell2table(ANOVA_TABLE),fn);

%% post-hoc paired t test 
% wSwO vs wFwO for each ROI
P_all = [];
pair_idx = repmat([1 3], 6, 1);
pair_dim = 2; % 1 for pairing up two rows, 2 for cols
test_dim = 1;
test_idx = 1:6;
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

% wSaO vs wFaO for each ROI
pair_idx = repmat([2 4], 6, 1);
pair_dim = 2; % 1 for pairing up two rows, 2 for cols
test_dim = 1;
test_idx = 1:6;
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

% aOwO vs aOaO for each ROI
pair_idx = repmat([5 6], 6, 1);
pair_dim = 2; % 1 for pairing up two rows, 2 for cols
test_dim = 1;
test_idx = 1:6;
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

%% lROI vs rROI for wS
pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [1 1 1];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [3 3 3];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

%% lROI vs rROI for wF
pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [2 2 2];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [4 4 4];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

%% lROI vs rROI for aO
pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [5 5 5];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

pair_idx = [1 4; 2 5; 3 6];
pair_dim = 1;
test_idx = [6 6 6];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

[alpha thres] = fdr(P_all,0.05);

%% between lIPL, rIPL, rPMv for aOwO
pair_idx = [1 4; 1 6; 4 6];
pair_dim = 1;
test_idx = [5 5 5];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

pair_idx = [1 4; 1 6; 4 6];
pair_dim = 1;
test_idx = [6 6 6];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

[alpha thres] = fdr(P_all,0.05);

%% between lIPL, rIPL, rPMv and rLOTC, lLOTC for aOwO
pair_idx = [1 2; 4 2; 6 2; 1 5; 4 5; 6 5];
pair_dim = 1;
test_idx = [5 5 5 5 5 5];
P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx);
P_all = [P_all P];

[alpha thres] = fdr(P_all,0.05);


function P = multi_posthoc(accuracy_table, pair_idx, pair_dim, test_idx)
mat1 = []; 
mat2 = [];
names = {};
if pair_dim == 1
    for i = 1:length(test_idx)
        mat1 = [mat1 accuracy_table{pair_idx(i, 1), test_idx(i)}{1}];
        mat2 = [mat2 accuracy_table{pair_idx(i, 2), test_idx(i)}{1}];
        names(i, :) = [accuracy_table.Properties.VariableNames(test_idx(i)),...
            accuracy_table.Properties.RowNames(pair_idx(i, 1)),...
            accuracy_table.Properties.RowNames(pair_idx(i, 2))];
    end
elseif pair_dim == 2
    for i = 1:length(test_idx)
        mat1 = [mat1 accuracy_table{test_idx(i), pair_idx(i, 1)}{1}];
        mat2 = [mat2 accuracy_table{test_idx(i), pair_idx(i, 2)}{1}];
        names(i, :) = [accuracy_table.Properties.RowNames(test_idx(i)),...
            accuracy_table.Properties.VariableNames(pair_idx(i, 1)),...
            accuracy_table.Properties.VariableNames(pair_idx(i, 2))];
    end
end

[H,P,CI,STATS] = ttest(mat1, mat2);
for i = 1:size(names, 1)
    if P(i) < 0.001
        sig = '***';
    elseif P(i) < 0.01
        sig = '**';
    elseif P(i) < 0.05
        sig = '*';
    else 
        sig = '';
    end
    fprintf('%s - %s (%0.4f) vs %s (%0.4f)\n\tt(%d) = %0.3f, p = %0.4f (two-tailed) %s\n\n', ...
    names{i,1}, names{i,2}, mean(mat1(:,i), 'omitnan'),...
    names{i,3}, mean(mat2(:,i), 'omitnan'),...
        STATS.df(i), STATS.tstat(i), P(i), sig);
%     texttable = table;
%     texttable(1, i) = [STATS.tstat(i), P(i)];
end
fprintf('\n\n');
% texttable
end


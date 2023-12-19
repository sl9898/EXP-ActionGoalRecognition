% 2022-08-23 Shuchen Liu
% subject-specific ROI-based MVPA decoding
%   - leave-one-run-out cross-validation
%   - SVM classifer
%   - ROI analysis with masks
%   - decoding targets
%       - decoding 0 (sanity check): open vs close within successful actions
%       - decoding A: open vs close within failed actions
%       - decoding B: open vs close across outcome within object
%       - decoding C: open vs close across outcome and object

clearvars -except subvec
warning off

path_mvpa = '../output.MVPA/N32_Searchlight_sm3_9conds_BVmask00_svm';
path_output = '../output.MVPA'; % where to save results
path_roi = '../input.ROIs';

folders_setting = dir(path_mvpa);
folders_setting = folders_setting(~contains({folders_setting.name},'.'));

flist_mask = dir([path_roi '/*nii']);
flist_mask = flist_mask(contains({flist_mask.name}, 'Caspers2010'));

if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:29 31:38];
end

savename = sprintf('N%0.2d_ROI_sm3_9conds_BVmask00_svm_Caspers2010_fromMaps', length(subvec));

%% specify which decoding to run
test_code = 0:12; % [1:4];

%% initialize variables for saving
all_accuracies = nan(length(flist_mask), length(test_code), max(subvec));
all_masks = cell(length(flist_mask),1);
all_tests = cell(length(test_code),1);

for itest = 1:length(folders_setting)
    flist_sub = dir([fpath(folders_setting(itest)) '/*.nii']);
    subs = regexp([flist_sub.name], '(?<=SUB)(.\d)', 'match');
    subs = str2num(cell2mat(subs'));
    flist_sub = flist_sub(ismember(subs, subvec),:);

    all_tests{itest} = folders_setting(itest).name;

    nsub = length(flist_sub);

    for isub = 1:nsub
        ds = cosmo_fmri_dataset(fpath(flist_sub(isub)));

        % assign chunks
        n_samples = size(ds.samples,1);
        ds.sa.chunks = ones(n_samples,1)*isub;
        ds.sa.targets = 1;

        % store results
        ds_cell{isub} = ds;

    end

    %% stack datasets
    ds_all = cosmo_stack(ds_cell);

    %% take only voxels that over half the subjects have data
    % also convert 0s (missing data) to nan, so that they can be excluded
    % from averaging
    feature_msk = mean(ds_all.samples(1:length(subvec),:)~=0)>0.5;
    ds_all.samples(ds_all.samples == 0) = NaN;

    for im = 1:length(flist_mask)
    %% load ROI mask
        ROI_mask = fullfile(flist_mask(im).folder, flist_mask(im).name);
        ROI_name = regexp(ROI_mask, '(?<=ROI_)(.*)(?=.nii)', 'match');
        ROI_name = ROI_name{1};
        all_masks{im} = ROI_name;

        msk_ds = cosmo_fmri_dataset(ROI_mask);

        data_roi = mean(ds_all.samples(1:length(subvec), msk_ds.samples == 1 & feature_msk), 2, 'omitnan');
        if sum(msk_ds.samples == 1 & feature_msk) < sum(msk_ds.samples == 1)
            disp(sum(msk_ds.samples == 1 & feature_msk))
        end
        
        all_accuracies(im, itest, subvec) = data_roi;

    end
end

%% organize and save results
chance = 0.5;
accuracy_table = table;
mean_accuracy_table = table;
pval_accuracy_table = table;
for im = 1:length(flist_mask)
    for itest = 1:length(test_code)
        subs_accuracy = squeeze(all_accuracies(im,itest,:));
        accuracy_table(all_masks{im}, all_tests{itest}) = {subs_accuracy};
        mean_accuracy_table(all_masks{im}, all_tests{itest}) = {mean(subs_accuracy, 'omitnan')};
        
        [h,p,~,stats] = ttest(subs_accuracy, chance, 'tail','right');
%         P_all(im, itest) = p;
        
        pval_accuracy_table(all_masks{im}, all_tests{itest}) = {p};
    end
end

save([path_output '/' savename], 'all_accuracies', 'all_tests', 'all_masks', 'mean_accuracy_table', 'pval_accuracy_table', 'accuracy_table');

%%
function output = checkDataset(ds)
    % combine several parameters together in an array for manual check
    output = [ds.sa.labels mat2cell(ds.sa.targets, ones(length(ds.sa.targets), 1)) mat2cell(ds.sa.chunks, ones(length(ds.sa.chunks), 1))];
    output = cell2table(output);
    output.Properties.VariableNames = {'labels', 'targets', 'chunks'};
end

%% functions
function fullpath = fpath(fstruct)
    fullpath = [fstruct.folder '/' fstruct.name];
end
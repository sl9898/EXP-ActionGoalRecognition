% 2022-07-01 Shuchen Liu
% subject-specific MVPA searchlight
%   - leave-one-run-out cross-validation
%   - SVM classifer
%   - 4 voxels radius for each searchlight
%   - decoding targets
%       - decoding 0 (sanity check): open vs close within successful actions
%       - decoding A: open vs close within failed actions
%       - decoding B: open vs close across outcome within object
%       - decoding C: open vs close across outcome and object bv

clearvars -except subvec
warning off

path_GLM = '../output.BuildGLM';
path_GLM_output = 'MVPA.GLM_Output_sm3_9conds_BVmask00';
path_output = '../output.MVPA/N32_Searchlight_sm3_9conds_BVmask00_svm'; % where to save results
save_format = {'nii'}; %  'vmp'

folders_sub = dir([path_GLM '/PSUB*']);
nsub = length(folders_sub);
if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:29 31:38]; %[2 4:12 14 16:22 24:29 31:38];
%     subvec = 31:38;
end

%% specify which decoding to run
test_code = 0:12; % [1:4];

%% start searchlight
tic
for isub = subvec

    subfolder = [folders_sub(isub).folder '/' folders_sub(isub).name];
    data_fn = [subfolder '/' path_GLM_output '/SPM.mat:beta']; % input: betas from 1st level SPM.mat with items as conditions

    %% define dataset -- 1st-level betas
%     mask = [subfolder '/' path_GLM_output '/mask.nii'];
%     mask = '/Users/liusc/Downloads/ANALYSIS/scripts99_SL/helper_mask/MNI_ave_GM_66x52x56.nii'; % 2022-12-13 bugged

%     2023-02-08 trying without mask
%     mask = '/Users/liusc/Downloads/ANALYSIS/output.MvpaGLM_Group_sm3_9conds_BVmask00_N32/cond0002_main/mask.nii';
%     ds = cosmo_fmri_dataset(data_fn, 'mask', mask);
    ds = cosmo_fmri_dataset(data_fn); % 2023-02-14 no mask

    nrun = max(ds.sa.chunks);
%     ds.sa.targets = repmat(1:16, 1, nrun)'; % 8 main conditions x 2 exemplars
    ds.sa.targets = repmat(1:9, 1, nrun)'; % 8 main conditions + catch
    ds = cosmo_remove_useless_data(ds);
    
    % 2022-07-06
    % break each run into two chunks, so that the two beta estimates per condition per run are used separately
%     ds.sa.chunks = sort(repmat(1:nrun*2, 1, 8))';

    %% check if labels and chunks are defined correctly
    checkTargets = [ds.sa.labels mat2cell(ds.sa.targets, ones(length(ds.sa.targets), 1)) mat2cell(ds.sa.chunks, ones(length(ds.sa.chunks), 1))];
            
    %% define classifier 
    measure = @cosmo_crossvalidation_measure; % crossvalidation
    measure_args = struct();
    measure_args.classifier = @cosmo_classify_svm;
    measure_args.r_searchlight = 4; % nvoxels_per_searchlight = 100;
    measure_args.normalization = 'demean';
%     measure_args.normalize = cfg.normalize; % 2022-12-05
    measure_args.normalize = 3; % 2023-02-03
    
    %% define a spherical neighborhood with ~100 voxels around each voxel
    nbrhood = cosmo_spherical_neighborhood(ds, 'radius', measure_args.r_searchlight);  % searchlight by sphere

    %% start decoding
    for itest = 1:length(test_code)
        thistest = test_code(itest);
        switch thistest 
            case 0 % ---- catch vs random cond
                decoding_name = {'00_Goal_CatchVsRandCond'};
                ds_slice = cosmo_slice(ds, ismember(ds.sa.targets, [1 9]), 1); 
                measure_args.partitions = cosmo_nfold_partitioner(ds_slice);

            case 1 % ---- decoding 0 (sanity check): open vs close successful within objects
                decoding_name = {'01_Goal_Success_WithinObject'};
                ds_slice = cosmo_slice(ds, contains(ds.sa.labels, 'Success'), 1); % success actions only
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;
                
                % each row in partition_labels is a pair of {training, testing} data label
                % all pairings specified here will be done in one call of cosmo_searchlight
                % and then the reuslts will be averaged by cosmo_searchlight
                partition_labels = {'Bottle', 'Bottle'; 'Zipper', 'Zipper'}; % {training, testing}
                measure_args.partitions = getPartition(ds_slice, partition_labels); % custom partition function

            case 2 % ---- decoding 0 (sanity check): open vs close successful across objects
                decoding_name = {'02_Goal_Success_AcrossObject'};
                ds_slice = cosmo_slice(ds, contains(ds.sa.labels, 'Success'), 1); % success actions only
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;

                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;

                partition_labels = {'Zipper', 'Bottle'; 'Bottle', 'Zipper'}; % {training, testing}
%                 measure_args.partitions = getPartition(ds_slice, partition_labels);
                % 2022-12-02 changed to match Moritz's decoding scheme: making use of samples in all runs for cross decoding
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels);

            case 3 % ---- decoding A (sanity check): open vs close failed within objects
                decoding_name = {'03_Goal_Fail_WithinObject'};
                ds_slice = cosmo_slice(ds, contains(ds.sa.labels, 'Fail'), 1); % failed actions only
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;
                
                partition_labels = {'Bottle', 'Bottle'; 'Zipper', 'Zipper'}; % {training, testing}
                measure_args.partitions = getPartition(ds_slice, partition_labels);

            case 4 % ---- decoding A (sanity check): open vs close failed across objects
                decoding_name = {'04_Goal_Fail_AcrossObject'};
                ds_slice = cosmo_slice(ds, contains(ds.sa.labels, 'Fail'), 1); % failed actions only
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;

                partition_labels = {'Zipper', 'Bottle'; 'Bottle', 'Zipper'}; % {training, testing}
%                 measure_args.partitions = getPartition(ds_slice, partition_labels);
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02

            case 5 % ---- decoding B: open vs close, across outcome, within objects
                decoding_name = {'05_Goal_AcrossOutcome_WithinObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;

                partition_labels = {'SuccessBottle', 'FailBottle'; 'SuccessZipper', 'FailZipper'; 'FailBottle', 'SuccessBottle'; 'FailZipper', 'SuccessZipper'};
%                 measure_args.partitions = getPartition(ds_slice, partition_labels);             
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Fail')) = 2;
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02

            case 6 % ---- decoding C: open vs close, across outcome, across objects
                decoding_name = {'06_Goal_AcrossOutcome_AcrossObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Close')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Open')) = 2;

                partition_labels = {'SuccessBottle', 'FailZipper'; 'SuccessZipper', 'FailBottle'; 'FailBottle', 'SuccessZipper'; 'FailZipper', 'SuccessBottle'};
%                 measure_args.partitions = getPartition(ds_slice, partition_labels);
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;
                ds_slice.sa.cross = ones(size(ds_slice.sa.targets));
                ds_slice.sa.cross(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.cross(contains(ds_slice.sa.labels, 'Fail')) = 2;
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02
            
            case 7 % ---- scheme 2: success vs failure, within goals, within objects
                decoding_name = {'07_SvF_WithinGoal_WithinObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Fail')) = 2;

                partition_labels = {'Open.*Bottle', 'Open.*Bottle'; 'Open.*Zipper', 'Open.*Zipper'; 'Close.*Bottle', 'Close.*Bottle'; 'Close.*Zipper', 'Close.*Zipper';};
                measure_args.partitions = getPartition(ds_slice, partition_labels);
            
            case 8 % ---- scheme 2: success vs failure, within goals, across objects
                decoding_name = {'08_SvF_WithinGoal_AcrossObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Fail')) = 2;

                partition_labels = {'Open.*Bottle', 'Open.*Zipper'; 'Open.*Zipper', 'Open.*Bottle'; 'Close.*Bottle', 'Close.*Zipper'; 'Close.*Zipper', 'Close.*Bottle';};
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02
            
            case 9 % ---- scheme 2: success vs failure, across goals, within objects
                decoding_name = {'09_SvF_AcrossGoal_WithinObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Fail')) = 2;

                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Open')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Close')) = 2;

%                 partition_labels = {'SuccessBottle', 'FailBottle'; 'SuccessZipper', 'FailZipper'; 'FailBottle', 'SuccessBottle'; 'FailZipper', 'SuccessZipper'};
                partition_labels = {'Open.*Bottle', 'Close.*Bottle'; 'Open.*Zipper', 'Close.*Zipper'; 'Close.*Bottle', 'Open.*Bottle'; 'Close.*Zipper', 'Open.*Zipper';};
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02
            
            case 10 % ---- scheme 2: success vs failure, across goals, across object
                decoding_name = {'10_SvF_AcrossGoal_AcrossObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Success')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'Fail')) = 2;

                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;
                ds_slice.sa.cross = ones(size(ds_slice.sa.targets));
                ds_slice.sa.cross(contains(ds_slice.sa.labels, 'Open')) = 1;
                ds_slice.sa.cross(contains(ds_slice.sa.labels, 'Close')) = 2;

%                 partition_labels = {'SuccessBottle', 'FailBottle'; 'SuccessZipper', 'FailZipper'; 'FailBottle', 'SuccessBottle'; 'FailZipper', 'SuccessZipper'};
                partition_labels = {'Open.*Bottle', 'Close.*Zipper'; 'Open.*Zipper', 'Close.*Bottle'; 'Close.*Bottle', 'Open.*Zipper'; 'Close.*Zipper', 'Open.*Bottle';};
                measure_args.partitions = getPartition_cross(ds_slice, partition_labels); % 2022-12-02

            case 11 % ---- control tests: open vs close end states, within objects
                decoding_name = {'11_EndState_WithinObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'CloseFail')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'OpenSuccess')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'CloseSuccess')) = 2;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'OpenFail')) = 2;

%                 partition_labels = {'SuccessBottle', 'FailBottle'; 'SuccessZipper', 'FailZipper'; 'FailBottle', 'SuccessBottle'; 'FailZipper', 'SuccessZipper'};
                partition_labels = {'Open.*Bottle', 'Close.*Bottle'; 'Open.*Zipper', 'Close.*Zipper'; 'Close.*Bottle', 'Open.*Bottle'; 'Close.*Zipper', 'Open.*Zipper';};
                measure_args.partitions = getPartition(ds_slice, partition_labels);

            case 12 % ---- control tests: open vs close end states, across objects
                decoding_name = {'12_EndState_AcrossObject'};
                ds_slice = cosmo_slice(ds, ~contains(ds.sa.labels, 'Catch'), 1);
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'CloseFail')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'OpenSuccess')) = 1;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'CloseSuccess')) = 2;
                ds_slice.sa.targets(contains(ds_slice.sa.labels, 'OpenFail')) = 2;

                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Bottle')) = 1;
                ds_slice.sa.chunks(contains(ds_slice.sa.labels, 'Zipper')) = 2;

%                 partition_labels = {'SuccessBottle', 'FailZipper'; 'SuccessZipper', 'FailBottle'; 'FailBottle', 'SuccessZipper'; 'FailZipper', 'SuccessBottle'};
                partition_labels = {'Open.*Bottle', 'Close.*Zipper'; 'Open.*Zipper', 'Close.*Bottle'; 'Close.*Bottle', 'Open.*Zipper'; 'Close.*Zipper', 'Open.*Bottle';};
                measure_args.partitions = getPartition(ds_slice, partition_labels);

        end

        checkTargets_sliced = checkDataset(ds_slice, measure_args.partitions);
        
        %% do decoding (with custom function runDecoding)
        [results_svm, output_fn] = runDecoding(ds_slice, decoding_name, nbrhood, measure, measure_args, isub, path_output, save_format);
        fprintf('================== mvpa11_searchlight: subject %0.2d %s done\n', isub, decoding_name{1});
    end
    

end

function output = checkDataset(ds, partitions)
    % combine several parameters together in an array for manual check
    output = [ds.sa.labels mat2cell(ds.sa.targets, ones(length(ds.sa.targets), 1)) mat2cell(ds.sa.chunks, ones(length(ds.sa.chunks), 1))];
    output = cell2table(output);
    output.Properties.VariableNames = {'labels', 'targets', 'chunks'};

    if nargin > 1
        par_mat = nan(length(ds.sa.labels), length(partitions.train_indices));
        for i = 1:length(partitions.train_indices)
            par_mat(partitions.train_indices{i}, i) = 1;
            par_mat(partitions.test_indices{i}, i) = 2;
        end
        output.partitions = par_mat;
    end
    
end

function [results_svm, output_fn] = runDecoding(ds_slice, target_type, nbrhood, measure, measure_args, isub, path_output, saveformat)
% do searchlight decoding

r_searchlight = measure_args.r_searchlight;
for k = 1:length(target_type)
    %% define configs
    fprintf('================== Computing Subject %d %s...\n', isub, target_type{k});
    path_save = fullfile(path_output, target_type{k});
    mkdir(path_save);
    
    %% run searchlight
    results_svm = cosmo_searchlight(ds_slice, nbrhood, measure, measure_args, 'nproc', 9); % , 'nproc', 6
    
    %% visualization
    cosmo_plot_slices(results_svm);

    %% save data
    for iformat = 1:length(saveformat)
        try
            output_fn = sprintf('%s/PSUB%0.2d_%s_svm_r%dvx.%s', path_save, isub, target_type{k}, r_searchlight, saveformat{iformat});
            if isfile(output_fn)
                % fprintf([output_fn ' already exists! skipping... \n']);
                % continue
            end
            cosmo_map2fmri(results_svm, output_fn); % Write output to a NIFTI file
        end
    end
    save(fullfile(path_save, sprintf('/PSUB%0.2d_%s_svm_r%dvx.mat', isub, target_type{k}, r_searchlight)), 'results_svm');
end
end

function partitions = getPartition(ds, labels)
% leave-one-chunk-out partition
% labels: Nx2 cell arrays
% - col 1 is label for training data, col 2 is for testing data
% - each row is a pair of training/testing labels. partitions for all rows will be combined in one call of cosmo_searchlight
samples_train = {};
samples_test = {};

for ir = 1:size(labels, 1)
    label_train = labels{ir, 1};
    label_test = labels{ir, 2};
    for ic = 1:max(ds.sa.chunks) % each chunk will be the testing data once
        
        % find training/testing data by label keyword specified
%         tmp_train = find(contains(ds.sa.labels, label_train) & ds.sa.chunks ~= ic);
%         tmp_test = find(contains(ds.sa.labels, label_test) & ds.sa.chunks == ic);
        tmp_train = find(~cellfun(@isempty,regexp(ds.sa.labels, label_train)) & ds.sa.chunks ~= ic);
        tmp_test = find(~cellfun(@isempty,regexp(ds.sa.labels, label_test)) & ds.sa.chunks == ic);
        if ~isempty(tmp_train) && ~isempty(tmp_test)
            samples_train = [samples_train {tmp_train}];
            samples_test = [samples_test {tmp_test}]; 
        end

    end
end

partitions.train_indices = samples_train;
partitions.test_indices = samples_test;
end

function partitions = getPartition_cross(ds, labels)
% partition for cross-decoding
% training data will include samples from all runs
% labels: Nx2 cell arrays
% - col 1 is label for training data, col 2 is for testing data
% - each row is a pair of training/testing labels. partitions for all rows will be combined in one call of cosmo_searchlight
samples_train = {};
samples_test = {};

for ir = 1:size(labels, 1)
    label_train = labels{ir, 1};
    label_test = labels{ir, 2};

    tmp_train = find(~cellfun(@isempty,regexp(ds.sa.labels, label_train)));
    tmp_test = find(~cellfun(@isempty,regexp(ds.sa.labels, label_test)));

    if ~isempty(tmp_train) && ~isempty(tmp_test)
        samples_train = [samples_train {tmp_train}];
        samples_test = [samples_test {tmp_test}]; 
    end

end

partitions.train_indices = samples_train;
partitions.test_indices = samples_test;
end
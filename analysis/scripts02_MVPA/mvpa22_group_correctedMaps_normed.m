% 2022-08-29 Shuchen Liu
% searchlight group analysis: corrected maps

clearvars -except subvec
path_mvpa = '../output.MVPA/N32_Searchlight_sm3_9conds_BVmask00_svm';
% path_mvpa = '../output.MVPA/N32_Control_Searchlight_reverseLabels_2';

folders_setting = dir(path_mvpa);
folders_setting = folders_setting(~contains({folders_setting.name},'.'));

if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:29 31:38];
end

chance = 0.5;
method = 2; % 1 = 'TFCE', 2 = 'monte carlo'
sliced = 'sliced'; % 'sliced' / 'unsliced' whether to select only voxels that appear in over half the subjects
slice_threshold = 0.5;
niter = 10000;

% applying corrected map from decoding 01 as mask to latter decodings --2023-04-03
% mask = 'mask_CorrectedMap01.nii';

% for p = 0.005
mask = 'mask_CorrectedMap01_p005.nii';

if strcmp(sliced, 'sliced')
    path_output = sprintf('../output.MVPA/N%0.2d_Group_corrected_sm3_9conds_BVmask00_svm_%s_%0.2f_normed_01masked', length(subvec), sliced, slice_threshold);
%     path_output = sprintf('../output.MVPA/N%0.2d_Group_ReverseLabel_2_corrected_sm3_9conds_BVmask00_svm_%s_%0.2f_normed', length(subvec), sliced, slice_threshold);
else
    path_output = sprintf('../output.MVPA/N%0.2d_Group_corrected_sm3_9conds_BVmask00_svm_%s_normed_01mask', length(subvec), sliced);
%     path_output = sprintf('../output.MVPA/N%0.2d_Group_ReverseLabel_2_corrected_sm3_9conds_BVmask00_svm_%s_normed', length(subvec), sliced);
end
if ~isfolder(path_output) mkdir(path_output); end

for is = 2:7 %1:length(folders_setting)
    flist_sub = dir([fpath(folders_setting(is)) '/*.nii']);
    subs = regexp([flist_sub.name], '(?<=SUB)(.\d)', 'match');
    subs = str2num(cell2mat(subs'));
    flist_sub = flist_sub(ismember(subs, subvec),:);

    typeMVPA = folders_setting(is).name;

    nsub = length(flist_sub);

    for isub = 1:nsub
        % 2023-02-15 forgot to add mask in searchlight. adding it here -- OOD
        
        if exist('mask', 'var') && ~isempty(mask)
            ds = cosmo_fmri_dataset(fpath(flist_sub(isub)), 'mask', mask);
        else
            ds = cosmo_fmri_dataset(fpath(flist_sub(isub)));
        end

        ds.samples(ds.samples == 0) = NaN;
        ds.samples = ds.samples - chance;
        ds.samples(isnan(ds.samples)) = 0;

        % assign chunks
        n_samples = size(ds.samples,1);
        ds.sa.chunks = ones(n_samples,1)*isub;
        ds.sa.targets = 1;

        % store results
        ds_cell{isub} = ds;
    end

    %% stack datasets
    ds_all = cosmo_stack(ds_cell);
    if strcmp(sliced, 'sliced')
        if slice_threshold == 1
            feature_msk = mean(ds_all.samples(1:length(subvec),:)~=0)>=slice_threshold;
        else
            feature_msk = mean(ds_all.samples(1:length(subvec),:)~=0)>slice_threshold;
        end
        ds_slice = cosmo_slice(ds_all, feature_msk, 2);
    else
        ds_slice = ds_all;
    end

    %% do perm test
    cluster_nbrhood = cosmo_cluster_neighborhood(ds_slice, 'fmri', 3);
    h0_mean = 0;
    if method == 1
        args = struct();
        args.h0_mean = h0_mean;
        args.niter = niter; % number of null iterations
        args.cluster_stat = 'tfce';
    
        stat_map = cosmo_montecarlo_cluster_stat(ds_slice, cluster_nbrhood, args, 'nproc', 9);

        cosmo_map2fmri(stat_map, sprintf('%s/Group_TFCE_%s_h%0.2f_n%d_%s.nii', ...
            path_output, typeMVPA, args.h0_mean, args.niter, sliced));

    elseif method == 2
        args = struct();
        args.niter = niter;
        args.cluster_stat = 'maxsize';
%         h0_mean = chance;
        args.p_uncorrected = 0.001; % moritz set to 0.001; originally 0.05;
        args.h0_mean = h0_mean; 

        stat_map = cosmo_montecarlo_cluster_stat(ds_slice, cluster_nbrhood, args, 'nproc', 9);
        cosmo_map2fmri(stat_map, sprintf('%s/Group_MonteCarlo_%s_p%0.3f_h%0.2f_n%d_%s.vmp', ...
            path_output, typeMVPA, args.p_uncorrected, args.h0_mean, args.niter, sliced));
    end


end

%% functions
function fullpath = fpath(fstruct)
    fullpath = [fstruct.folder '/' fstruct.name];
end
% allfigs =render_surface(data, gii, views, isThreshold, expThreshold, savepath, settitle)
% 2021-07-22 Shuchen Liu
% render a .nii image with script, using SPM funtions

% if isempty(views)
%    views = {'left'} ;
% end
% samples = data;

clear;
% subvec = [2 4:12 14 16:22]; % 2022-09
% subvec = [2 4:12 14 16:22 24:30]; % 2022-11-29 
subvec = [2 4:12 14 16:22 24:29 31:38]; % 2023-02-06
normed = 0;
    
curpath = pwd();
path_mvpa = '../output.MVPA/N32_Searchlight_sm3_9conds_BVmask00_svm';
path_save = '../output.MVPA/BV_N32_Group_Stats_sm3_9conds_BVmask00_svm_masked';
mkdir(path_save);
folders_setting = dir(path_mvpa);
folders_setting = folders_setting(~contains({folders_setting.name},'.'));
folders_setting = folders_setting(2:7);

% flist_mask = dir('../output.MVPA/N32_Group_corrected_sm3_9conds_BVmask00_svm_sliced_0.50_normed_01masked/*.nii');
flist_mask = dir('../output.MVPA/N32_Group_Mask_fromCorrected/*.nii');

if normed 
    path_save = [path_save '_normed'];
end

chance = 0.5;
nanmode = 'omitnan';

for is = 1:length(folders_setting)
% flist_mvpa = dir([path_mvpa '/**/*.nii']);
    flist_mvpa = dir([fpath(folders_setting(is)) '/PSUB*.nii']);
    subs = regexp([flist_mvpa.name], '(?<=SUB)(.\d)', 'match');
    subs = str2num(cell2mat(subs'));
    flist_mvpa = flist_mvpa(ismember(subs, subvec),:);

    mask = fpath(flist_mask(is));
    
    ds_cell = {};
    all_vol = [];
    for im = 1:length(flist_mvpa)
        fn_samples = fpath(flist_mvpa(im));
        
        if exist('mask', 'var') && ~isempty(mask)
            ds = cosmo_fmri_dataset(fn_samples, 'mask', mask);
        else
            ds = cosmo_fmri_dataset(fn_samples);
        end

        ds_cell{im} = ds;
    end

    %% stack datasets
    ds_all = cosmo_stack(ds_cell);

    %% save mean
    ds_mean = ds;
    ds_mean.samples = mean(ds_all.samples, 'omitnan');

%     cosmo_map2fmri(ds_mean, sprintf('%s/Group_MVPA_%s_unsm_%s_mean (n=%d).nii', ...
%         path_save, folders_setting(is).name(1:end-4), nanmode, length(flist_mvpa)));
%     cosmo_map2fmri(ds_mean, sprintf('%s/Group_MVPA_%s_unsm_%s_mean (n=%d).vmp', ...
%         path_save, folders_setting(is).name(1:end-4), nanmode, length(flist_mvpa)));
%     
    %% save t 
    tail = 'right';
    [~,pval,~,results] = ttest(ds_all.samples, chance, 'Tail', tail, 'Alpha', 0.05); % 2022-12-05
    % corrected on 2023-08-11 (previously added 'dim', 4, making everything 'inf'

    tstat = results.tstat;
    ds_t = ds_mean;
    ds_t.samples = tstat;
    ds_t.samples(ds_t.samples == -Inf) = NaN;
%     cosmo_map2fmri(ds_t, sprintf('%s/Group_MVPA_%s_unsm_%s_a%0.2d_t_%s (n=%d).nii', path_save, folders_setting(is).name(1:end-4), nanmode, chance*100, tail, length(flist_mvpa)));
    cosmo_map2fmri(ds_t, sprintf('%s/Group_MVPA_%s_unsm_%s_a%0.2d_t_%s (n=%d).vmp', path_save, folders_setting(is).name(1:end-4), nanmode, chance*100, tail, length(flist_mvpa)));
    
end

%% functions
function fullpath = fpath(fstruct)
    fullpath = [fstruct.folder '/' fstruct.name];
end

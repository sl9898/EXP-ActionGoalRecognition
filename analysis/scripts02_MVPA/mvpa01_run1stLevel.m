
% 2022-06-22 Shuchen Liu
% pilot: 1st level by item for MVPA

clearvars -except subvec
path_scans = '../input.Preprocessed_Scans';
path_GLM = '../output.BuildGLM';
path_GLM_output = 'MVPA.GLM_Output_sm3_9conds_BVmask00';
path_multicond = 'MVPA.MultiCond_9conds';
path_savebatch = 'saved_batch/Item_MVPA';
PREFIX = 's3waf';
TR = 1.5;
NSLICES = 45;

folders_sub_scans = dir([path_scans '/PSUB*']);
folders_sub_GLM = dir([path_GLM '/PSUB*']);
nsub = length(folders_sub_scans);
if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:29 31:38]; % 1:nsub;
end

for isub = subvec %1 %:nsub
    matlabbatch = {};
    subfolder_GLM = [folders_sub_GLM(isub).folder '/' folders_sub_GLM(isub).name];
    subfolder_scans = [folders_sub_scans(isub).folder '/' folders_sub_scans(isub).name];
    
    folders_run = dir([subfolder_scans '/*_WAR_run*']);
    nrun = length(folders_run);
    
    matlabbatch{1}.spm.stats.fmri_spec.dir              = cellstr([subfolder_GLM '/' path_GLM_output]); % specify output folder
    matlabbatch{1}.spm.stats.fmri_spec.timing.units     = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT        = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t    = NSLICES;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0   = 23; % slice scanned at 690s (slice timing ref) is the 22,23,24-th slice of the time sequence
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0; %% added on 2022-12-13 % commented out on 2022-12-12 

    %% 2022-12-12 using an explicit mask from Moritz
    matlabbatch{1}.spm.stats.fmri_spec.mask = {'/Users/liusc/Downloads/ANALYSIS/scripts99_SL/helper_mask/MNI_ave_GM_66x52x56.nii,1'};
%     % commented out try without mask --- 2023-02-08
   
    for irun = 1:nrun
        % select scans
        subfolder_run = [folders_run(irun).folder '/' folders_run(irun).name];
        f_scans = spm_select('FPList', subfolder_run, sprintf('^%s.*.nii$', PREFIX)); % input functional scans
        matlabbatch{1}.spm.stats.fmri_spec.sess(irun).scans = cellstr(f_scans);
        
        % load multi conds, outliers regressors and head motion regressors
        file_multicond = spm_select('FPList', [subfolder_GLM '/' path_multicond], ['.*run0' num2str(irun) '*.mat']); % event onsets
        file_headmotion = spm_select('FPList', subfolder_run, '^rp_af.*.txt$');
        if isempty(file_headmotion)
            error('Headmotion file missing for S%0.2d!!!', isub);
        end

        matlabbatch{1}.spm.stats.fmri_spec.sess(irun).multi = cellstr(file_multicond);
        matlabbatch{1}.spm.stats.fmri_spec.sess(irun).multi_reg   = cellstr(file_headmotion);
    end
    
    %% Model Estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr(fullfile([subfolder_GLM '/' path_GLM_output],'SPM.mat'));
    
    %% Save batch
    savepath = [subfolder_GLM '/' path_savebatch];
    if ~isfolder(savepath) mkdir(savepath); end
    save([savepath '/' folders_sub_scans(isub).name '_batch_GLM_spec_' path_GLM_output], 'matlabbatch');
    
    spm_jobman('run', matlabbatch);
    fprintf('mvpa01_run1stLevel: subject %0.2d done...\n', isub);

end
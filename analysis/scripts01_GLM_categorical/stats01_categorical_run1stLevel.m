% 2022-06-22 Shuchen Liu
% catch: fMRI model specs and estimation

clearvars -except subvec
path_scans = '../input.Preprocessed_Scans';
path_GLM = '../output.BuildGLM';
path_GLM_output = 'GLM_Output_mthres80';
path_multicond = 'MultiCond';
path_savebatch = 'saved_batch';
PREFIX = 's8waf';
TR = 1.5;
NSLICES = 45;

folders_sub_scans = dir([path_scans '/PSUB*']);
folders_sub_GLM = dir([path_GLM '/PSUB*']);
nsub = length(folders_sub_scans);
if ~exist('subvec','var')
    subvec = 33; %[2 4:12 14 16:22 24:30]; %[2 4:12 14]; % [2 4:9]; % 1:nsub;
end

% parfor ISUB = 1:length(subvec)
for isub = subvec %1 %:nsub
%     isub = subvec(ISUB);
%     clear matlabbatch
    subfolder_GLM = [folders_sub_GLM(isub).folder '/' folders_sub_GLM(isub).name];
    subfolder_scans = [folders_sub_scans(isub).folder '/' folders_sub_scans(isub).name];
    
    folders_run = dir([subfolder_scans '/*_WAR_run*']);
    nrun = length(folders_run);
    
    matlabbatch = {};
    matlabbatch{1}.spm.stats.fmri_spec.dir              = cellstr([subfolder_GLM '/' path_GLM_output]); % specify output folder
    matlabbatch{1}.spm.stats.fmri_spec.timing.units     = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT        = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t    = NSLICES;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0   = 23; % 23 slice scanned at 690s (slice timing ref) is the 22,23,24-th slice of the time sequence
%     matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
%     matlabbatch{1}.spm.stats.fmri_spec.mask = {'/Users/liusc/Downloads/MNI_ave_wholeBrain_66x52x56.nii,1'};
   
    for i = 1:nrun
        % select scans
        subfolder_run = [folders_run(i).folder '/' folders_run(i).name];
        f_scans = spm_select('FPList', subfolder_run, sprintf('^%s.*.nii$', PREFIX));
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans = cellstr(f_scans);
        
        % load multi conds, outliers regressors and head motion regressors
        irun = regexp(folders_run(i).name, '(?<=run)(.*)', 'match');
        irun = str2double(irun{1});
        file_multicond = spm_select('FPList', [subfolder_GLM '/' path_multicond], ['.*run0' num2str(irun) '*.mat']);
        file_headmotion = spm_select('FPList', subfolder_run, '^rp_af.*.txt$');
        if isempty(file_headmotion)
            error('Headmotion file missing for S%0.2d!!!', isub);
        end

        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi = cellstr(file_multicond);
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi_reg   = cellstr(file_headmotion);
%         matlabbatch{1}.spm.stats.fmri_spec.sess(i).hpf = 157;
    end
    
    %% Model Estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr(fullfile([subfolder_GLM '/' path_GLM_output],'SPM.mat'));
    
    %% Save batch
    savepath = [subfolder_GLM '/' path_savebatch];
    if ~isfolder(savepath) mkdir(savepath); end
    save([savepath '/' folders_sub_scans(isub).name '_batch_GLM_spec'], 'matlabbatch');
    
    spm_jobman('run', matlabbatch);

end
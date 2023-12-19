% 2023-02-10 Shuchen Liu
% Project GO pilot: preprocessing

clearvars -except subvec
datapath = ['../data_converted'];
folders_sub = dir([datapath '/*SUB*']);
nsub = length(folders_sub);
TR = 1.5;
NSLICES = 45;

if ~exist('subvec','var')
    subvec = 31; % 1:nsub;
end

% Initialise SPM
spm('Defaults','fMRI'); 
spm_jobman('initcfg');

%% preprocessing
for isub = subvec %1 %:nsub
    clear matlabbatch
    matlabbatch = {};
    f_all = [];
    
    % get the folders for all runs
    folders_run = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/ep2d*']);
    nrun = length(folders_run);

    % select structural scan
    folder_str = dir([folders_sub(isub).folder  '/' folders_sub(isub).name '/T1*']);
    a = spm_select('FPList', [folder_str(1).folder '/' folder_str(1).name], '^s.*\.nii$');

    % load slice timing mat
    load([folders_sub(isub).folder  '/' folders_sub(isub).name '/' folders_sub(isub).name '_SliceTime.mat']);


    %% select functional files
    for irun = 1:nrun
        % select functional scans for all runs
        f = spm_select('FPList', [folders_run(irun).folder '/' folders_run(irun).name], '^f.*\.nii$');
        f_all = [f_all; f];
        
        %% Slice Timing Correction
        matlabbatch{1}.spm.temporal.st.scans{1,irun} = cellstr(f);
        matlabbatch{1}.spm.temporal.st.so = SliceTime(irun, :);

        %% Realign: Estimate
        matlabbatch{2}.spm.spatial.realign.estwrite.data{1,irun} = cellstr(spm_file(f,'prefix','a'));
    end

    %% Slice Timing
    matlabbatch{1}.spm.temporal.st.nslices = NSLICES;
    matlabbatch{1}.spm.temporal.st.tr = TR;
    matlabbatch{1}.spm.temporal.st.ta = TR-TR/NSLICES;
    matlabbatch{1}.spm.temporal.st.refslice = 690; % ms, the middle timepoint
    
    %% Realignment
    matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 1;
    matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [0 1];
    
    %% Run batch
    %     spm_jobman('run', matlabbatch(1:3));
%     spm_jobman('run', matlabbatch(1:2));

    %% Coregister: Estimate (headers are changed for source and other)
    realigned_meanImg = spm_file(f_all(1,:),'prefix','meana');
    matlabbatch{3}.spm.spatial.coreg.estimate.ref = cellstr(a);
    matlabbatch{3}.spm.spatial.coreg.estimate.source = cellstr(realigned_meanImg);
    matlabbatch{3}.spm.spatial.coreg.estimate.other = cellstr(spm_file(f_all,'prefix','a'));

    %% Segment T1 (Segmentation)
    matlabbatch{4}.spm.spatial.preproc.channel.vols = cellstr(a);
    matlabbatch{4}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{4}.spm.spatial.preproc.channel.write = [0 1];
    matlabbatch{4}.spm.spatial.preproc.warp.write = [0 1];

    %% Normalize functional scans (Normalize: write)
    matlabbatch{5}.spm.spatial.normalise.write.subj.def = cellstr(spm_file(a,'prefix','y_','ext','nii')); % deform field from segmentation
    matlabbatch{5}.spm.spatial.normalise.write.subj.resample = [cellstr(realigned_meanImg); cellstr(spm_file(f_all,'prefix','a'))];
    matlabbatch{5}.spm.spatial.normalise.write.woptions.vox  = [3 3 3];

    %% Normalize and reslice T1
    matlabbatch{6}.spm.spatial.normalise.write.subj.def = cellstr(spm_file(a,'prefix','y_','ext','nii'));
    matlabbatch{6}.spm.spatial.normalise.write.subj.resample = cellstr(spm_file(a,'prefix','m','ext','nii'));
    matlabbatch{6}.spm.spatial.normalise.write.woptions.vox  = [1 1 1];

    %% Smooth for Univariate
    matlabbatch{7}.spm.spatial.smooth.data = cellstr(spm_file(f_all,'prefix','wa'));
    matlabbatch{7}.spm.spatial.smooth.fwhm = [8 8 8];
    matlabbatch{7}.spm.spatial.smooth.prefix = 's8';
     
    %% Smooth for MVPA decoding
    matlabbatch{8}.spm.spatial.smooth.data = cellstr(spm_file(f_all,'prefix','wa'));
    matlabbatch{8}.spm.spatial.smooth.fwhm = [3 3 3];
    matlabbatch{8}.spm.spatial.smooth.prefix = 's3';

    %% Run SPM job
    spm_jobman('run', matlabbatch(7:8));
    
    %% Save batch
    savepath = [folders_sub(isub).folder '/' folders_sub(isub).name '/' folders_sub(isub).name '_batch_v230210'];
    save(savepath, 'matlabbatch');
    fprintf('Subject %d done!\n', isub);

end

%% Finished!
alert_finished = audioplayer( [sin(1:.6:400), sin(1:.7:400), sin(1:.4:400)], 22050);
% play(alert_finished);
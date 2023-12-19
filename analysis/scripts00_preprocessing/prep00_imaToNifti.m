% 2022-06-16 Shuchen Liu
% main: convert .DCM files to nifti format (.img), which spm can recognize
warning off

clearvars -except subvec
curpath = pwd();
path_data = '../data_raw';
path_save = '../data_converted'; % where to save your converted files
mkdir(path_save);

if ~exist('subvec','var')
    subvec = [4:12 14 16:22 24:29 31:38];
    subvec = 31;
end

for isub = subvec
%     folder_sub = dir([path_data sprintf('/*SUB%0.2d', isub)]);
    folder_sub = dir('/Users/liusc/Downloads/ANALYSIS/data_raw/*_SUB01_GO');
    subfolders = dir(fullfile(folder_sub.folder, folder_sub.name));
    folders_runs = subfolders(contains({subfolders.name}, 'run'));
    folders_T1 = subfolders(contains({subfolders.name}, 'T1'));
    savepath_T1 = fullfile(path_save, folder_sub.name, 'T1_MEMPRAGE_10mm_p3RMS_0003');
    mkdir(savepath_T1);
%     subfolders = subfolders([subfolders.isdir]);
%     subfolders = subfolders(logical(~strcmp({subfolders.name},'.').* ~strcmp({subfolders.name},'..')));
    
    %% combine T1 scans into 1 files
    load('batch_combineT1Scans.mat');
    matlabbatch{1}.spm.util.import.dicom.data = cellstr(spm_select('FPList', [folders_T1(1).folder '/' folders_T1(1).name], '.*\.dcm$'));
    matlabbatch{1}.spm.util.import.dicom.root = 'flat';
    matlabbatch{1}.spm.util.import.dicom.outdir = {savepath_T1};
    matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';

    spm_jobman('run', matlabbatch);

    %% convert functional scans
    for ifolder  = 1:length(folders_runs)
        
        %% get the headers of all files
        all_dcm = dir([folders_runs(ifolder).folder '/' folders_runs(ifolder).name '/**/*.dcm']);
        for i = 1:length(all_dcm)
            filename = fullfile(all_dcm(i).folder, all_dcm(i).name);
            hdr = spm_dicom_headers(filename); % conert filenames to spm headers
            %% convert to .img
%             savepath = fullfile(path_save, folders_sub(isub).name, folders_runs(ifolder).name);
            cd(path_save)
            spm_dicom_convert(hdr, 'all', 'patid', 'nii');
            cd(curpath);
        end
    
    end
end

% 2022-12-07 Shuchen Liu
% Project GO: preprocessing
% delete unnecessary files created in preprocessing

clearvars -except subvec
datapath = ['../input.Preprocessed_Scans'];
folders_sub = dir([datapath '/*SUB*']);
files_to_delete = {'war', 's3war','s8war', 'swar'};

if ~exist('subvec','var')
%     subvec = 31:38;
%     subvec = 31;
    subvec = [4:12 16:22 24:30];
end

%% preprocessing
for isub = subvec %1 %:nsub
    % get the folders for all runs
%     folders_run = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/ep2d*']);
    folders_run = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/Fun*']);
    nrun = length(folders_run);

    %% Clean up unnecessary files
    for irun = 1:nrun
        for iformat = 1:length(files_to_delete)
            thisformat = files_to_delete{iformat};
            delete([folders_run(irun).folder '/' folders_run(irun).name '/' thisformat '*.img']);
            delete([folders_run(irun).folder '/' folders_run(irun).name '/' thisformat '*.hdr']);
            delete([folders_run(irun).folder '/' folders_run(irun).name '/' thisformat '*.nii']);
        end
    end
end
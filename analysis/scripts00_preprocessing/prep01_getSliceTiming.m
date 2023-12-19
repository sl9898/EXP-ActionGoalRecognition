% 2022-06-17 Shuchen Liu
% main: get slice timing specs from .dcm files
% inherited from fyp code

clearvars -except subvec
path_raw = '../data_raw';
path_converted = '../data_converted';

folders_sub = dir([path_raw '/*S*']);
folders_sub = folders_sub(~startsWith({folders_sub.name}, '.') & [folders_sub.isdir]);
nsub = length(folders_sub);

if ~exist('subvec','var')
    subvec = 99; % 1:nsub;
end

all_hdr = {};
for isub = subvec       
    SliceTime = [];
    
    % get the folders for all runs
    folders_run = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/run*']);
    nrun = length(folders_run);
    
    for irun = 1:nrun
        % get the index of the run from the folder name
        tmp = split(folders_run(irun).name, ' ');
        index = tmp{end};
        
        % read the first .ima file of the run based on the index
        files_dcm = dir([path_raw '/' folders_sub(isub).name '/' folders_run(irun).name '/**/*.dcm']);
        files_dcm = files_dcm(~startsWith({files_dcm.name}, '.'));
        hdr = spm_dicom_headers([files_dcm(1).folder '/' files_dcm(1).name]);
        all_hdr = [all_hdr; hdr];
        SliceTime = [SliceTime; hdr{1}.Private_0019_1029];
    end
    
    %% save slice timing
    savepath = [path_converted '/' folders_sub(isub).name '/' folders_sub(isub).name '_SliceTime'];
    save(savepath, 'SliceTime');
end


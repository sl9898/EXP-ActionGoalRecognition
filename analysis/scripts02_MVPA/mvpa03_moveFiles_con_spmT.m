% 2022-12-13 Shuchen Liu
% Action Goal Project
% move con*.nii and spmT*.nii from each subjects to a new folder


clearvars -except subvec
path_GLM = '../output.BuildGLM';
path_GLM_output = 'MVPA.GLM_Output_sm3_9conds_BVmask00';
path_new = '../output.Categorical_contrast_sm3_9conds_BVmask00';
file_contrast = 'Categorical_ContrastMatrix.xlsx';

folders_sub = dir([path_GLM '/PSUB*']);
nSub = length(folders_sub);
[num,txt,raw] = xlsread(file_contrast,1);

if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:30];
end

for isub = subvec

    subname = folders_sub(isub).name;
    subname = regexp(subname, 'SUB(?<=SUB)(.*\d)', 'match');
    subname = subname{1};
    path_sub = [folders_sub(isub).folder '/' folders_sub(isub).name];
    
    flist_con = dir([path_sub '/' path_GLM_output '/con*']);
    flist_spmT = dir([path_sub '/' path_GLM_output '/spmT*']);
        
    ncon = length(flist_con);
    for i = 1:ncon
        newpath_con = [path_new '/' flist_con(i).name(1:(end-4)) '_' raw{i+1,2}];
        if ~isfolder(newpath_con) mkdir(newpath_con); end
        
        movefile([flist_con(i).folder '/' flist_con(i).name], [newpath_con '/' flist_con(i).name(1:(end-4)) '_' raw{i+1,2} '_' subname '.nii']);
        movefile([flist_spmT(i).folder '/' flist_spmT(i).name], [newpath_con '/' flist_spmT(i).name(1:(end-4)) '_' raw{i+1,2} '_' subname '.nii']);
    end
    
end




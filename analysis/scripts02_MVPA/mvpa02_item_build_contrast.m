% 2022-08-19 Shuchen Liu
% pilot: build and run contrast

clearvars -except subvec
path_GLM = '../output.BuildGLM';
path_GLM_output = 'MVPA.GLM_Output_sm3_9conds_BVmask00';
path_savebatch = 'saved_batch/Item_MVPA';

file_contrast = 'Categorical_ContrastMatrix.xlsx';
folders_sub_GLM = dir([path_GLM '/PSUB*']);
nsub = length(folders_sub_GLM);

if ~exist('subvec','var')
    subvec = 1; % 1:nsub;
end

%% read contrast config xlsx
[num,txt,raw] = xlsread(file_contrast,1);
ncont = 9; %size(num, 1);

for isub = subvec
    clear matlabbatch
    load('../utilities.batch_templates/batch_tmp_contrast.mat')
    subfolder_GLM = [folders_sub_GLM(isub).folder '/' folders_sub_GLM(isub).name];
    
    tmp_cont = matlabbatch{1,1}.spm.stats.con.consess{1};
    
    matlabbatch{1}.spm.stats.con.spmmat = cellstr([subfolder_GLM '/' path_GLM_output '/SPM.mat']);
    matlabbatch{1}.spm.stats.con.consess = cell(1, ncont);
    matlabbatch{1}.spm.stats.con.delete = 1;    %%% 1=delete existing contrasts; 0=don't delete
    for ic = 1:ncont
        matlabbatch{1}.spm.stats.con.consess{ic}              = tmp_cont;
        matlabbatch{1}.spm.stats.con.consess{ic}.tcon.name    = raw{ic+1, 2};
        matlabbatch{1}.spm.stats.con.consess{ic}.tcon.weights = num(ic, :)';
        matlabbatch{1}.spm.stats.con.consess{ic}.tcon.sessrep = 'replsc';
    end
    
    %% Save batch
    savepath = [subfolder_GLM '/' path_savebatch];
    if ~isfolder(savepath) mkdir(savepath); end
    save([savepath '/' folders_sub_GLM(isub).name '_batch_MVPA_contrast'], 'matlabbatch');

    %%
    spm_jobman('run',matlabbatch);
         
end
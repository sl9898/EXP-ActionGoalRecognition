% 2022-08-04 Shuchen Liu
% build group level analysis

clearvars -except subvec
path_cont = ['../output.Categorical_contrast_mthres80'];
file_contrast = 'Categorical_ContrastMatrix.xlsx';

% folders_sub_GLM = dir('../output.BuildGLM/PSUB*');
% nsub = length(folders_sub_GLM);

folders_cont = dir([path_cont '/con*']);
ncont = length(folders_cont);
[num,txt,raw] = xlsread(file_contrast, 1); %% read contrast config xlsx

if ~exist('subvec','var')
%     subvec = [2 4:12 14 16:22 24:30];
    subvec = [2 4:12 14 16:22 24:29 31:38];
end
path_group = sprintf('../output.Univariate_Group_mthres80_N%0.2d', length(subvec));

spm('Defaults','fMRI'); 
spm_jobman('initcfg');
curpath = pwd();

for ic = 1:9 % ncont (single cond vs basedline after 9)
    clear matlabbatch
    load('../utilities.batch_templates/batch_tmp_groupLevel.mat')
    savepath = [path_group '/' txt{ic+1,1} '_' txt{ic+1,2}];
    if ~isfolder(savepath) mkdir(savepath); end
    
    flist_con = spm_select('FPList', [folders_cont(ic).folder '/' folders_cont(ic).name], '^con.*\.nii$');

     % filter subjects
    subs = regexp(string(flist_con), '(?<=SUB)(.\d)', 'match');
    subs = double([subs{:}]);
    flist_con = flist_con(ismember(subs, subvec),:);
    
    matlabbatch{1}.spm.stats.factorial_design.dir = cellstr(savepath);
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = cellstr(flist_con);
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1; % ? why 1
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = txt{ic+1,2};

    matlabbatch{4}.spm.stats.results.spmmat = cellstr(fullfile(savepath,'SPM.mat'));
    matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf;
    matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'FWE';
    matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
    matlabbatch{4}.spm.stats.results.conspec.extent = 0;
    matlabbatch{4}.spm.stats.results.print = false;
    matlabbatch{4}.spm.stats.results.export{1}.pdf = true;

%     matlabbatch{5}.spm.stats.results.spmmat = cellstr(fullfile(data_path,'canonical','SPM.mat'));
% matlabbatch{5}.spm.stats.results.conspec.contrasts = Inf;
% matlabbatch{5}.spm.stats.results.conspec.threshdesc = 'FWE';
    
    %% Save batch
    savepath = [path_group '/saved_batch/' txt{ic+1,1} '_' txt{ic+1,2} '_batch_groupLevel.mat'];
    if ~isfolder([path_group '/saved_batch/']) mkdir([path_group '/saved_batch/']); end
    save(savepath, 'matlabbatch');
    spm_jobman('run', matlabbatch);

    cd(curpath)
end

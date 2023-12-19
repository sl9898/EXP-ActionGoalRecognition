% 2022-07-08 Shuchen Liu
% Render and generate reports
% small script to show some basic way to render volume data on surfaces using SPM

clear 
close all
clc
addpath('../utilities.functions');

threshold_p = 0.001;
views = {'left','right','bottom','top','back','front'};
gii = fullfile(spm('dir'), 'canonical', 'cortex_20484.surf.gii'); % which surface to use
path_confolders = ['../output.Categorical_contrast_nii/'];
path_save = '../reports';
folders_setting = dir(path_confolders);

for is = 1:length(folders_setting)
    figure
    folders_cons = dir([fpath(folders_setting(is)) '/con*']);
    df = 1;
    
    for ic = 1:length(folders_cons)
        fcon = spm_select('FPlist', fpath(folders_cons(ic)), '^con.*\.nii$');
        fspmT = spm_select('FPlist', fpath(folders_cons(ic)), '^spmT.*\.nii$');
        
        con_name = split(folders_cons(ic).name, '_');
        con_name = join(con_name(2:end), ' ');
        
        %% render
        samples = fspmT;
        strThreshold.t_val = spm_read_vols(spm_vol(fspmT));
        strThreshold.df = df;
        strThreshold.threshold = threshold_p;
        strThreshold.expression = sprintf('(1-tcdf(t_val, df)) >= %f', threshold_p);
        savepath = sprintf('%s/Group_%s/%s_p%0.3f.jpg', path_save, folders_setting(is).name, folders_cons(ic).name, threshold_p);
        settitle = sprintf('Group %s, %s, p < %0.3f', 'Pilot', con_name{1}, threshold_p);
        all_figs = render_surface_t(samples, gii, views, true, strThreshold, savepath);
        stitch(all_figs, settitle);
        close all
    end
end

%% functions
function fullpath = fpath(fstruct)
    fullpath = [fstruct.folder '/' fstruct.name];
end
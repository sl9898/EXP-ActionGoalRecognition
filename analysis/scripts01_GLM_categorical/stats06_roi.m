% 2022-08-21 Shuchen Liu

clear
addpath('../utilities.functions');

path_cont = '../output.Categorical_Stats_Group_MNI_mthres10';
path_roi = '../input.ROIs';

flist_mask = dir([path_roi '/*nii']);
flist_mask = flist_mask(contains({flist_mask.name}, 'Caspers2010'));

folders_cont = dir([path_cont '/con*']);
ncont = length(folders_cont);

for im = 1:length(flist_mask)
    ROI = fullfile(flist_mask(im).folder, flist_mask(im).name);
    fprintf('======================== ROI: %s ========================\n', flist_mask(im).name);

    for ic = 2 %1:ncont
        load(fullfile(folders_cont(ic).folder, folders_cont(ic).name, 'SPM.mat'));

        ROI_data = Extract_ROI_Data(ROI, SPM.xY.P);
        
        %% do t-test: group comparison of average activation in each ROI
        [h, p, ~, stats] = ttest(ROI_data);
        if p < 0.05
            fprintf('========= Contrast: %s =========\n', folders_cont(ic).name);
            fprintf('t-test: p = %f, t = %0.3f\n',p, stats.tstat);
        end
        
    end
    disp(' ');
end
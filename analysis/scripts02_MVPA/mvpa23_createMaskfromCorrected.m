% 2023-05-25 create mask from MCC corrected maps

clear;
curpath = pwd();
path_save = '../output.MVPA/N32_Group_Mask_fromCorrected';
mkdir(path_save);

corrected_maps = dir('../output.MVPA/N32_Group_corrected_sm3_9conds_BVmask00_svm_sliced_0.50_normed_01masked/*.nii');

threshold = 1.649; % threshold for significance for MCC 

for is = 1:length(corrected_maps)

    mask = fpath(corrected_maps(is));
    thisdecoding = regexp(corrected_maps(is).name, '(?<=MonteCarlo_)(.*)(?=_p0)', 'match');
    thisdecoding = thisdecoding{1};
    
    ds = cosmo_fmri_dataset(mask);

    if is == 6
        ds.samples(ds.samples < 1.6) = 0;
        ds.samples(ds.samples >= 1.6) = 1;
    else
        ds.samples(ds.samples < threshold) = 0;
        ds.samples(ds.samples >= threshold) = 1;
    end
    
    cosmo_map2fmri(ds, sprintf('%s/Group_Mask_correctedMap_%s (n=32).nii', path_save, thisdecoding));
    
end

%% functions
function fullpath = fpath(fstruct)
    fullpath = [fstruct.folder '/' fstruct.name];
end

% 2021-07-04 Shuchen Liu
% move preprocessed scans and head motion files and to new folder

clearvars -except subvec PREFIX
path_data = '../data_converted';
path_new = '../input.Preprocessed_Scans';
% PREFIX = 's3wa';

if ~isfolder(path_new) mkdir(path_new); end
folders_sub = dir([path_data '/*SUB*']);
nSub = length(folders_sub);
if ~exist('subvec','var')
    subvec = [2 4:12 14 16:22 24:30];
end

for isub = subvec % 3:nSub
    
    
    path_sub = [folders_sub(isub).folder '/' folders_sub(isub).name];
%     path_sub = folders_sub(contains({folders_sub.name}, num2str(isub, '%0.2d')));
%     path_sub = [path_sub.folder '/' path_sub.name];
    
    folders_run = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/ep2d*']);
    folder_t1 = dir([folders_sub(isub).folder '/' folders_sub(isub).name '/T1*']);
    nrun = length(folders_run);
    
    for irun = 1:nrun
        %% move preprocessed functional scans (swar*)
        newpath_scans = sprintf('%s/PSUB%0.2d_GO/FunImg_WAR_run%0.2d', path_new, isub, irun);
        
        if ~isfolder(newpath_scans) mkdir(newpath_scans); end

        flist_new = dir([newpath_scans '/' PREFIX '*']);
%         if isempty(flist_new)
        flist_scans = dir([folders_run(irun).folder '/' folders_run(irun).name '/' PREFIX '*']);
        for f = 1:length(flist_scans)
            status = movefile([flist_scans(f).folder '/' flist_scans(f).name], [newpath_scans '/' flist_scans(f).name]);
        end
%         end
        
        %% move head motion files (.txt)
        file_headmotion = dir([folders_run(irun).folder '/' folders_run(irun).name '/rp_af*.txt']);
%         if isempty(dir([newpath_scans '/*.txt'])) && ~isempty(file_headmotion)
%             copyfile([file_headmotion(1).folder '/' file_headmotion(1).name], sprintf('%s/%s', newpath_scans, file_headmotion.name));
%         end
        % 2022-12-07 move rp_swarf*.txt from old pipeline back, and move rp_af*.txt over
%         old_txt = dir([newpath_scans '/rp_*.txt']);
%         if ~strcmp(old_txt(1).name(1:5),'rp_af')
%             movefile([old_txt(1).folder '/' old_txt(1).name], sprintf('%s/%s', file_headmotion(1).folder, old_txt(1).name));
%         end
        
        % move over new head files
        copyfile([file_headmotion(1).folder '/' file_headmotion(1).name], sprintf('%s/%s', newpath_scans, file_headmotion.name));
        
    end
    
    %% move preprocessed structural scan (wms*)
%     newpath_str = sprintf('%s/PSUB%0.2d_GO/StructImg_WMS', path_new, isub);
%     if ~isfolder(newpath_str) mkdir(newpath_str); end
%     flist_new = dir([newpath_str '/wmrs*']);
% %     if isempty(flist_new)
%     file_wmrs = dir([folder_t1(1).folder '/' folder_t1(1).name '/wmrs*']);
%     try
%         movefile([file_wmrs(1).folder '/' file_wmrs(1).name], [newpath_str '/' file_wmrs(1).name]);
%     end
%     end
    
    fprintf('Subject %d done!\n', isub);
end



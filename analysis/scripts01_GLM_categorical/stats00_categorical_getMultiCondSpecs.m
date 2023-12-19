% 2022-06-22 Shuchen Liu
% pilot
% get multiple condition specs from onset info
% by conditions (8 main + 1 catch)

clearvars -except subvec

trialinfo_path = '../input.CondOnsets';
path_output = '../output.BuildGLM';

mat_sub = dir([trialinfo_path '/EventOnsets_*.mat']);
nsub = length(mat_sub);

if ~exist('subvec','var')
    subvec = 1; % 1:nsub;
end

%% get basic condition info
load allCondNames
% load([mat_sub(1).folder '/' mat_sub(1).name]);
% trials = struct2table(trials);
% conds = unique(trials.category)';
% conds = conds(1:9); % ignore baseline and resting for now
conds = allCondNames;
ncond = length(conds);

%% build specs for individual subjects
for isub = subvec
    load([mat_sub(isub).folder '/' mat_sub(isub).name]);
    trials = struct2table(trials);

    nrun = max(trials.run);
    
    savepath = sprintf('%s/PSUB%0.2d_%s/MultiCond', path_output, isub, subid);
    if ~isfolder(savepath) mkdir(savepath); end
    
    if isub == 1
        load '../input.CondOnsets/OnsetsDelay_PSUB01'
    end
    
    for irun = 1:nrun
        names = {};
        onsets = {};
        durations  = {};
        idx_emptycond = [];
        for ic = 1:ncond
            thiscond = conds{ic};
            index = intersect(find(trials.run == irun), find(strcmp(trials.category, thiscond)));
            
            if ~isempty(index)
                names = [names trials.category(index(1))'];
                if isub == 1
                    onsets = [onsets {trials.onset(index)'+delays(irun)}];
                else
                    onsets = [onsets {trials.onset(index)'}];
                end
%                 durations = [durations zeros(1, length(index))];
                durations = [durations 6*ones(1, length(index))];
            end
        end
        
        index_empty = find(isempty(onsets));
        save(sprintf('%s/Categorical_MultiCond_%s_run%0.2d.mat', savepath, subid, irun), 'durations', 'names', 'onsets');
    end
      
end
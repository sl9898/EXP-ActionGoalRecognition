% 2022-07-01 Shuchen Liu
% pilot
% by 8 actions x 2 exemplars

clearvars -except subvec

group = '';
trialinfo_path = '../input.CondOnsets';
path_output = '../output.BuildGLM';

mat_sub = dir(sprintf('%s/EventOnsets_%s*.mat', trialinfo_path, group));
nsub = length(mat_sub);
if ~exist('subvec','var')
    subvec = 19; % 1:nsub;
end

%% get basic condition info
load allCondNames
load([mat_sub(1).folder '/' mat_sub(1).name]);
trials = struct2table(trials);
% conds = unique(trials.event)';
% conds(conds == -1 | conds > 128) = [];
% action x outcome x object x exemplar
% load allCondNames
% conds = unique(trials.category);
% % conds = [strcat(conds(2:9),'_1'); strcat(conds(2:9),'_2'); conds(1)];
% % conds = [strcat(conds(2:9),'_1'); strcat(conds(2:9),'_2')]; % no catch condition
% conds = [conds(2:9); conds(1)];
conds = allCondNames;
ncond = length(conds);

%% build specs for individual subjects
for isub = subvec
    load([mat_sub(isub).folder '/' mat_sub(isub).name]);
    trials = struct2table(trials);
    nrun = max(trials.run);
    
    savepath = sprintf('%s/PSUB%s%0.2d_%s/MVPA.MultiCond_9conds', path_output, group, isub, subid);
    if ~isfolder(savepath) mkdir(savepath); end
    
    if isub == 1
        load '../input.CondOnsets/OnsetsDelay_PSUB01'
    end
    
    %% across all runs
    names = {};
    onsets = {};
    durations  = {};
    stim_names = {};
    cond_names = {};
    idx_cell = cell(ncond, 1);
    for i = 1:size(trials, 1)
        if strcmp(trials.category(i), 'Catch')
            trial_thiscond = 'Catch';
%             continue
        elseif ~isempty(trials.stimulus{i})
%             trial_thiscond = [trials.category{i} '_' trials.stimulus{i}(9)]; % 16 conds
            trial_thiscond = trials.category{i}; % 8 conds
        else
            continue
        end
        tmp_icond = find(strcmp(conds, trial_thiscond));
        idx_cell{tmp_icond} = [idx_cell{tmp_icond} i];
    end

    for ic = 1:ncond        
        index = idx_cell{ic};

        if ~isempty(index)
            names = [names conds{ic}];
            if isub == 1
                onsets = [onsets {trials.onset(index)' + delays(trials.run(index))}];
            else
                onsets = [onsets {trials.onset(index)'}];
            end
            durations = [durations 6*ones(1, length(index))];
            stim_names = [stim_names {trials.stimulus(index)'}];
%             cond_names = [cond_names {trials.category(index(1))'}];
            cond_names = [cond_names conds{ic}];
        end
    end

    index_empty = find(isempty(onsets));
    save(sprintf('%s/Item_MultiCond_%s_all.mat', savepath, subid), 'durations', 'names', 'onsets','stim_names','cond_names');

    %% by run
    for irun = 1:nrun
        names = {};
        onsets = {};
        durations  = {};
        stim_names = {};
        cond_names = {};
        idx_cell = cell(ncond, 1);
        trials_thisrun = trials(trials.run == irun, :);
        for i = 1:size(trials_thisrun, 1)
            if strcmp(trials_thisrun.category(i), 'Catch')
                trial_thiscond = 'Catch';
%                 continue
            elseif ~isempty(trials_thisrun.stimulus{i})
%                 trial_thiscond = [trials.category{i} '_' trials.stimulus{i}(9)]; % 16 conds
                trial_thiscond = trials_thisrun.category{i}; % 8 conds
            else
                continue
            end
            tmp_icond = find(strcmp(conds, trial_thiscond));
            idx_cell{tmp_icond} = [idx_cell{tmp_icond} i];
        end
    
        for ic = 1:ncond        
            index = idx_cell{ic};
    
            if ~isempty(index)
                names = [names conds{ic}];
                if isub == 1
                    onsets = [onsets {trials_thisrun.onset(index)' + delays(trials_thisrun.run(index))}];
                else
                    onsets = [onsets {trials_thisrun.onset(index)'}];
                end
                durations = [durations 6*ones(1, length(index))];
                stim_names = [stim_names {trials_thisrun.stimulus(index)'}];
    %             cond_names = [cond_names {trials.category(index(1))'}];
                cond_names = [cond_names conds{ic}];
            end
        end
    
        index_empty = find(isempty(onsets));
        save(sprintf('%s/Item_MultiCond_%s_run%0.2d.mat', savepath, subid, irun), 'durations', 'names', 'onsets','stim_names','cond_names');
    end

    fprintf('mvpa00_item_getMultiCondSpecs: %0.2d done...\n', isub)
end
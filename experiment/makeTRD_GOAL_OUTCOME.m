% function makeTRD_GOAL_OUTCOME(iSub)
%CREATES TRD FILE FOR A SIMPLE EXPERIMENT THAT SHOWS MOVIES
%example call: makeTRD_CADMEG_video(99)

iSub = 1;
debug = 0;

addpath(genpath('./support_scripts'));

cfg.experimentName = 'GOAL_OUTCOME';
videoFolderName = '/videos/';
path_STMinfo = 'STMinfo.mat';

% experimental conditions (not the catch trials)
cfg.nConditions = 8; % 8 conditions (action x outcome x object)
cfg.nActionVideosPerCondition = 16; % number of videos per condition: 2 exemplars x 2 view x 2 hand x 2 flip
cfg.nActionVideos = cfg.nConditions * cfg.nActionVideosPerCondition;
cfg.nBlocks = 3;
cfg.nTrialsPerBlock = 16;
cfg.nRuns = 8;
cfg.nTrials =  cfg.nTrialsPerBlock * cfg.nBlocks; % per run
cfg.nRepetitionsPerVideo = ceil((cfg.nRuns * cfg.nBlocks * cfg.nTrialsPerBlock)/cfg.nActionVideos);   %EACH VIDEO IS SHOWN 3 TIMES
cfg.nRepetitionsPerMainCond = cfg.nTrials * cfg.nRuns / cfg.nConditions;

% CATCH TRIALS
cfg.nCatchTrials = 48; % 6*8 = 48 trials in total 
cfg.nCatchTrialsPerBlock = 2;

% ALL TRIALS
cfg.nTotalConditions = cfg.nConditions + 1;
cfg.nTotalTrialsPerBlock = cfg.nTrialsPerBlock + cfg.nCatchTrialsPerBlock;
cfg.nTotalTrials = cfg.nTotalTrialsPerBlock * cfg.nBlocks; % per run
cfg.nRepetitionsPerBlock = cfg.nTrialsPerBlock/cfg.nConditions; %only the normal trials, not the catch ones. since they don't repeat 
% lsc: this is the the nRep of main condition, not unique videos, which are
% more than n trial per run

cfg.nVideos = cfg.nActionVideos + cfg.nCatchTrials;

% Video specifications
cfg.nFramesPerVideo = 180;
cfg.defaultFrameDuration = 2; % under 60 FPS?

% BUTTON CODES
cfg.ResponseCode = 1;
cfg.noResponseCode = 0;


%--------------------------------------------------------------------------
%STIMULI
%--------------------------------------------------------------------------
%% load STMinfo file where all info about stimuli are saved in proper order
load(path_STMinfo);

%% setting stimuli parameters
%WHAT KIND OF RANDOMIZATION DO YOU WANT TO IMPLEMENT?
% lsc: wrote my own constrained random code -- 2022-05-27
cfg.randType =  'random_constrained'; % {'random', 'counterbalanced'}
cfg.nTransitions = 1; % if randType = random_constrained, max number of transitions 
cfg.maxNTransitions = 7;
cfg.minNTransitions = 3;

%WE WILL USE ONE BITMAP
cfg.onsetFramesBitmaps = [1];
cfg.nBitmaps = length(cfg.onsetFramesBitmaps);

%HOW MANY SINGLE IMAGES DO WE HAVE IN THE FOLDER "STIMULI" BEFORE THE FIRST IMAGE APPEARS THAT
%BELONGS TO A VIDEO?
cfg.nSingleFramesToShow = 2; %{empty page, fixation page}

%WHICH PAGE DO YOU WANT TO SHOW BEFORE EACH VIDEO?
cfg.preVidPage = 2; %1=empty, 2=fixCross
cfg.preVidDuration =  60 * 2;

% lsc: so the ISI is pre + post? #? fix or empty?
% lsc: changed to 0. I think the code only uses preVidDur to calculate desired onset time
%WHICH PAGE DO YOU WANT TO SHOW AFTER EACH VIDEO?
cfg.postVidPage = 1; %1=empty, 2=fixCross
cfg.postVidDuration = 0;

% lsc frequency range is 55-120 Hz per fMRI center
%BASELINE OF REST BETWEEN BLOCKS
cfg.restPage = 2; % fix page
cfg.restDuration = 60 * 6; %(IN FRAMES; THIS CORRESPONDS TO 30 ms WITH A REFRESH RATE OF 60 HZ)

cfg.warmUpPage = 2; % fix page
cfg.warmUpDuration = 60 * 10; %(IN FRAMES; THIS CORRESPONDS TO 2 SECONDS WITH A REFRESH RATE OF 60 HZ)

cfg.coolDownPage = 1; % empty page
cfg.coolDownDuration = 60 * 16; %(IN FRAMES; THIS CORRESPONDS TO 2 SECONDS WITH A REFRESH RATE OF 60 HZ)


% SPECIFY THE ORDER OF THE MATFILES (CONDITONS, VERSIONS,...)
% 8 Conditions * 16 Exemplars
cfg.OrderMatfilesActions = reshape(cfg.nSingleFramesToShow+1:cfg.nSingleFramesToShow+cfg.nActionVideos, cfg.nActionVideosPerCondition,cfg.nConditions);

% 16 "conditions" in total, which are for balancing randomization. no real catch trial condition
% it's reshaped to 8, 16, each col is a condition
catchFileStart = max(cfg.OrderMatfilesActions(:))+1;
catchTrialFiles = STMinfoT(strcmp(STMinfoT.i_Type,'2'),:);
G_byConditions = findgroups(catchTrialFiles(:, {'Outcome/State', 'Object', 'Exemplar', 'View'}));
catchFileIdxSort = sortrows([G_byConditions [catchFileStart:catchFileStart+127]'], 1);
cfg.OrderMatfilesCatchTrials = reshape(catchFileIdxSort(:,2), 8, 16);

% lsc: fMRI center said frequency range is 55-120 Hz -- 2022-05-27
cfg.refreshRateHz = 60;
cfg.frameDurMS = 1000/60;


%% Design
%--------------------------------------------------------------------------
%DESIGN
%--------------------------------------------------------------------------

% lsc: edited main trials random selection -- 2022-05-27 
% - balance within run: action x outcome x object x exemplar
% - for view/hand/flip, at least once per level within each run per balanced combination

ActionVecs = [];

for iCond=1:cfg.nConditions
    myActions = cfg.OrderMatfilesActions(:,iCond);
    
    % equal number of trials for exemplar 1 and 2 in each run
    exemplar1 = myActions(1:size(myActions,1)/2)';
    exemplar2 = myActions(size(myActions,1)/2+1:size(myActions,1))';
    
    % check if other factors are "near balance"
    checkIndex = [14 15 16];
    fprintf('Main Cond %d...finding solution for trial balance... :        \n', iCond);
    count=1;
    balanceFine = 0;
    while balanceFine == 0 
        balanceFine = 1;
        randExemplar1 = [];
        randExemplar2 = [];
        for i = 1:cfg.nRepetitionsPerVideo
            randExemplar1 = [randExemplar1 Shuffle(exemplar1)];
            randExemplar2 = [randExemplar2 Shuffle(exemplar2)];
        end
        
        % 
        balanceExemplar1 = checkFactorBalance(randExemplar1-cfg.nSingleFramesToShow, STMinfo, checkIndex, cfg.nRepetitionsPerVideo);

        if balanceExemplar1 == 1
            balanceExemplar2 = checkFactorBalance(randExemplar2-cfg.nSingleFramesToShow, STMinfo, checkIndex, cfg.nRepetitionsPerVideo);
            balanceFine = min([balanceExemplar1, balanceExemplar2]);
        else
            balanceFine = 0;
        end
        
        if balanceFine == 0
            fprintf('\b\b\b\b\b\b\b%06d\n', count);
            count=count+1;
        end
        
        if debug == 1
            balanceFine = 1; % lsc: #delete
        end
    end
    
    % combining exemplar 1 and 2 with the same number of trials in each run
    tempNRep = cfg.nRepetitionsPerVideo;
    thisCondVec = [];
    for j = 1:length(randExemplar1)/tempNRep
        thisCondVec = [thisCondVec; Shuffle([randExemplar1((j-1)*tempNRep+1:j*tempNRep), randExemplar2((j-1)*tempNRep+1:j*tempNRep)])'];
    end
    ActionVecs(iCond, :) = thisCondVec;
end

ActionVecs;

%% catch trial sequence
% 2022-05-27
% we only need 48 out of 128 for the entire session. balance those 48 vids
% - restrict the random sampling so that the most important factors are balanced (ini state, object, exemplar, view)
% - factor action, hand and flipped are sampled such that each level appears at least once over the seeison
nNeededCatchTrials = cfg.nRuns * cfg.nBlocks * cfg.nCatchTrialsPerBlock;
nRepetitionsPerCatchTrial = ceil(nNeededCatchTrials/cfg.nCatchTrials);
CatchTrialVec=[];

nCatchBalanceCond = 16;

for iCond = 1:nCatchBalanceCond
    myCatchActions = cfg.OrderMatfilesCatchTrials(:,iCond);
    
    % check if other factors are "near balance"
    checkIndex = [10 15 16];
    fprintf('Catch Cond %d...finding solution for trial balance... :        \n', iCond);
    count=1;
    balanceFine = 0;
    while balanceFine == 0 
        randPickCatchVid = randsample(myCatchActions, cfg.nCatchTrials/nCatchBalanceCond);
        balanceFine = checkFactorBalance(randPickCatchVid-cfg.nSingleFramesToShow, STMinfo, checkIndex, cfg.nCatchTrials/nCatchBalanceCond);
        if balanceFine == 0
            fprintf('\b\b\b\b\b\b\b%06d\n', count);
            count=count+1;
        end
    end
    
    CatchTrialVec = [CatchTrialVec;randPickCatchVid];
    CatchTrialVec = Shuffle(CatchTrialVec);
end

CatchTrialVec = reshape(CatchTrialVec, cfg.nRuns, cfg.nCatchTrialsPerBlock*cfg.nBlocks);


%--------------------------------------------------------------------------
%%%%%%%% MW: start loop for creating the runs of a session
%--------------------------------------------------------------------------

% to get the video info (actor, object, filming angle..) get the vidnames:
%% generate run sequences
transitionsFine = 0;
count = 1;
fprintf('...finding solution ... :        \n');

% unshuffled sequence of conditions
condSeqPerBlock = [repmat(1:cfg.nConditions, 1, cfg.nRepetitionsPerBlock), repmat(9, 1, cfg.nCatchTrialsPerBlock)]; % by block

while transitionsFine == 0
    trialVecAllRun = [];
    transitionsFine = 1;
    transitions = zeros(cfg.nTotalConditions,cfg.nTotalConditions); % 81 possibilities

    for iRun = 1:cfg.nRuns
        
        %CREATE A COLUMN VECTOR THAT CONTAINS THE MOVIENUMBERS IN RANDOM ORDER
        %ALTERNATING WITH ZEROS (WHICH INDICATE FIXATION PERIODS)
        
        %------------------------------------------
        
        switch cfg.randType
            case 'random_constrained'

                constraintsFine = 0;
                while constraintsFine==0
                    
                    [randIdx, iRunTransistions] = generateSeqBalancedTransitions(condSeqPerBlock, cfg.nTransitions, cfg.nBlocks);
                    randIdx = randIdx + 900; % add the 90 to not confuse this code with the condition code later
                    
                    % lsc: originally no rep of any condition. changed to no rep of catch trial 
                    constraintsFine = 1;
                    if randIdx(1) == 909 || iRunTransistions(9, 9) > 0
                        % disp('First trial is catch!');
                        constraintsFine = 0;
                    end
                end

                transitions = transitions + iRunTransistions; 
                
                if min(transitions(1:end-1)) + (cfg.nRuns - iRun) < cfg.minNTransitions && max(transitions(:)) > cfg.maxNTransitions
                    transitionsFine = 0;
                    break
                end
        end

        if transitionsFine == 0
            break
        end

        % after passing the constraints, add rest trial between blocks and add to the final Vector
        trialVec = [];
        for iBlock = 1:cfg.nBlocks
            trialVec = [trialVec; randIdx(((iBlock-1)*cfg.nTotalTrialsPerBlock+1):iBlock*cfg.nTotalTrialsPerBlock)';0]; % 0 for rest page
        end
        trialVecAllRun = [trialVecAllRun trialVec];
    end
    
    % test if transitions are near-balanced over the session (~5-6x)
    if transitionsFine == 0
        fprintf('\b\b\b\b\b\b\b%06d\n', count);
        count = count + 1;
    elseif min(transitions(1:end-1)) >= cfg.minNTransitions && max(transitions(:)) <= cfg.maxNTransitions
        transitionsFine = 1;
        fprintf('found solution with balanced transitions');
        transitions
    else
        transitionsFine = 0;
        fprintf('\b\b\b\b\b\b\b%06d\n', count);
        count = count + 1;
    end

    if debug == 1
        break
    end

end

for iRun = 1 : cfg.nRuns
    cfg.outputName = sprintf('./trd/%s_SUB%02d_RUN%02d.trd', cfg.experimentName, iSub, iRun);
    
    % lsc: start/stop specifies which cols to take out of ActionVecs
    % Each row of ActionVecs is one main condition, and each column is a repetition (variants may differ)
    start = 1 + (iRun * cfg.nActionVideosPerCondition*cfg.nRepetitionsPerVideo/cfg.nRuns) - cfg.nActionVideosPerCondition*cfg.nRepetitionsPerVideo/cfg.nRuns;
    stop = iRun * cfg.nActionVideosPerCondition*cfg.nRepetitionsPerVideo/cfg.nRuns;
    ActionVecsRun = ActionVecs(1:cfg.nConditions,start:stop);

    % replace with condition codes of action trials...
    trialVec = trialVecAllRun(:, iRun);
    for iCond=1:cfg.nConditions
        trialVec(trialVec==900+iCond)=ActionVecsRun(iCond,:);
    end
    % ...and now with the catch trials
    trialVec(trialVec == 900+cfg.nTotalConditions) = CatchTrialVec(iRun,:);
    
    %------------------------------------------
    
    % add warmup
    trialVecComplete = [1; trialVec]; %1=warmUp
    
    % replace last baseline with coolDown
    trialVecComplete = [trialVecComplete(1:end-1)];
    trialVecComplete = [trialVecComplete;2]; %2=coolDown
    
    %------------------------------------------
    %------------------------------------------
    
    %% create trials
    nextOnsetTime = 0;
    TrialsInBlockCount=0;
    for i = 1:length(trialVecComplete)
        
        if trialVecComplete(i) == 0 %REST PERIOD
            restTrial = createRestTrial(cfg.restPage, cfg.restDuration);
            trial(i).code = 0;
            trial(i).tOnset = nextOnsetTime;
            trial(i).pageNo = restTrial.pageNo;
            trial(i).dur = restTrial.dur;
            
            % STM
            for iSTM = 1:size(STMinfo, 2)/2
                trial(i).usrDefCol(iSTM) = -1; %'placeholder'  % lsc: change all placeholder from 0 to -1
            end
            
            %TO CODE THE TYPE OF BLOCK, WILL BE USED TO SET THE CORRECT
            %RESPONSE
            trial(i).firstCol = -1; %'placeholder'
            %NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
            trial(i).correctResponse = -1; %USE AN INVALID RESPONSE CODE
            
            %TO RE-START WITH THE VALUE OF K = 1 EVERY TIME
            k = 1;
            
            %nextOnsetTime = nextOnsetTime + cfg.preVidDuration;
            %NOTE: nextOnsetTime assumes units in seconds, not frames!
            nextOnsetTime = ceil(nextOnsetTime + ((cfg.restDuration * cfg.frameDurMS)/1000));
            
        elseif trialVecComplete(i) == 1 % warmUp
            warmUpTrial = createwarmUpTrial(cfg.warmUpPage, cfg.warmUpDuration);
            trial(i).code = 1;
            trial(i).tOnset = nextOnsetTime;
            trial(i).pageNo = warmUpTrial.pageNo;
            trial(i).dur = warmUpTrial.dur;
            
            % STM
            for iSTM = 1:size(STMinfo, 2)/2
                trial(i).usrDefCol(iSTM) = -1; %'placeholder'
            end
            
            %TO CODE THE TYPE OF BLOCK, WILL BE USED TO SET THE CORRECT
            %RESPONSE
            trial(i).firstCol = -1; %'placeholder'
            %NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
            trial(i).correctResponse = -1; %USE AN INVALID RESPONSE CODE
            
            %TO RE-START WITH THE VALUE OF K = 1 EVERY TIME
            k = 1;
            
            %nextOnsetTime = nextOnsetTime + cfg.preVidDuration;
            %NOTE: nextOnsetTime assumes units in seconds, not frames!
            nextOnsetTime = ceil(nextOnsetTime + ((cfg.warmUpDuration * cfg.frameDurMS)/1000));
            
        elseif trialVecComplete(i) == 2 % coolDown
            coolDownTrial = createcoolDownTrial(cfg.coolDownPage, cfg.coolDownDuration);
            trial(i).code = 2;
            trial(i).tOnset = nextOnsetTime;
            trial(i).pageNo = coolDownTrial.pageNo;
            trial(i).dur = coolDownTrial.dur;
            
            % STM
            for iSTM = 1:size(STMinfo, 2)/2
                trial(i).usrDefCol(iSTM) = -1; %'placeholder'
            end
            
            %TO CODE THE TYPE OF BLOCK, WILL BE USED TO SET THE CORRECT
            %RESPONSE
            trial(i).firstCol = -1; %'placeholder'
            %NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
            trial(i).correctResponse = -1; %USE AN INVALID RESPONSE CODE
            
            %TO RE-START WITH THE VALUE OF K = 1 EVERY TIME
            k = 1;
            
            %nextOnsetTime = nextOnsetTime + cfg.preVidDuration;
            %NOTE: nextOnsetTime assumes units in seconds, not frames!
            nextOnsetTime = ceil(nextOnsetTime + ((cfg.coolDownDuration * cfg.frameDurMS)/1000));
            
            
        else  %MOVIE CLIP
            TrialsInBlockCount = TrialsInBlockCount + 1;
            if TrialsInBlockCount == cfg.nTotalTrialsPerBlock + 1
                TrialsInBlockCount=1;
            end
            % code relevant information
            
            % first STM: the action number
            trial(i).firstCol = trialVecComplete(i) - cfg.nSingleFramesToShow;
            
            % STM 1-16 (I extract all info here)
            for iSTM = 1:size(STMinfo, 2)/2
                STMvalue = str2double(STMinfo{trialVecComplete(i)-2,iSTM});
                trial(i).usrDefCol(iSTM) = STMvalue;
            end
            
            % trial code
            for iCond=1:cfg.nConditions
                if ismember(trialVecComplete(i), cfg.OrderMatfilesActions(:,iCond))==1
                    trial(i).code = iCond+cfg.nSingleFramesToShow;
                end
            end

            % CATCH TRIALS
            if ismember(trialVecComplete(i),cfg.OrderMatfilesCatchTrials)==1
                trial(i).code = cfg.nSingleFramesToShow + cfg.nTotalConditions;
                trial(i).correctResponse = cfg.ResponseCode;
            else
                trial(i).correctResponse = cfg.noResponseCode;
            end
            
            
            %thisClip = createClip((trialVecComplete(i)-cfg.nSingleFramesToShow), cfg);
            thisClip = createClip(TrialsInBlockCount, cfg); % each block with videos from 1-18
            trial(i).tOnset = nextOnsetTime;
            trial(i).pageNo = thisClip.pageNo;
            trial(i).dur = thisClip.dur;
            trial(i).startRTpage = 1;
            trial(i).endRTpage = cfg.nFramesPerVideo + trial(i).startRTpage;
            
            
            k = (k + 1);
            
            nextOnsetTime = ceil(nextOnsetTime +((cfg.nFramesPerVideo*cfg.defaultFrameDuration + cfg.preVidDuration)/60));
                        
        end
    end

    %WRITE TRIAL-DEFINITION FILE
    writeTRD(trial, cfg.outputName)
end
% end

function clip = createClip(stimulusNumber, cfg)
%READ IN THE INDEX OF THE FIRST FRAME OF THE VIDEO
% idxStart = cfg.onsetFramesVideos(stimulusNumber);
% idxEnd = idxStart +  cfg.nFramesPerVideo - 1;
clip.pageNo = 1; % idxStart:idxEnd;
clip.dur = 1; % ones(1, cfg.nFramesPerVideo)*cfg.defaultFrameDuration;

%ADD FIXATION BEFORE AND EMPTY SCREEN AT END OF EACH VIDEO
clip.pageNo = [cfg.preVidPage       clip.pageNo  cfg.postVidPage];
clip.dur =    [cfg.preVidDuration   clip.dur     cfg.postVidDuration];
end


function restTrial = createRestTrial(restPage, restDur)
restTrial.code = 0;    %USE INVALID TRIAL CODE
restTrial.tOnset = -1;  %USE INVALID ONSET TIME, TO BE POPULATED LATER
restTrial.pageNo = [restPage 1];
restTrial.dur = [restDur 1];          %ONE FRAME DURATION
restTrial.startRTpage = 1;  %THIS TRIAL ONLY HASE ONE PAGE, SETTING THE START
%PAGE FOR RESPONSE COLLECTION TO 1 MEANS THAT
%NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
restTrial.endRTpage = restTrial.startRTpage;
restTrial.correctResponse = -1; %USE AN INVALID RESPONSE CODE
end

function warmUpTrial = createwarmUpTrial(warmUpPage, warmUpDur)
warmUpTrial.code = 0;    %USE INVALID TRIAL CODE
warmUpTrial.tOnset = -1;  %USE INVALID ONSET TIME, TO BE POPULATED LATER
warmUpTrial.pageNo = [warmUpPage 1];
warmUpTrial.dur = [warmUpDur 1];          %ONE FRAME DURATION
warmUpTrial.startRTpage = 1;  %THIS TRIAL ONLY HASE ONE PAGE, SETTING THE START
%PAGE FOR RESPONSE COLLECTION TO 1 MEANS THAT
%NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
warmUpTrial.endRTpage = warmUpTrial.startRTpage;
warmUpTrial.correctResponse = -1; %USE AN INVALID RESPONSE CODE
end

function coolDownTrial = createcoolDownTrial(coolDownPage, coolDownDur)
coolDownTrial.code = 0;    %USE INVALID TRIAL CODE
coolDownTrial.tOnset = -1;  %USE INVALID ONSET TIME, TO BE POPULATED LATER
coolDownTrial.pageNo = [coolDownPage 2 1];
coolDownTrial.dur = [coolDownDur 1 1];          %ONE FRAME DURATION
coolDownTrial.startRTpage = 1;  %THIS TRIAL ONLY HASE ONE PAGE, SETTING THE START
%PAGE FOR RESPONSE COLLECTION TO 1 MEANS THAT
%NO RESPONSE WILL BE COLLECTED DURING THIS TRIAL
coolDownTrial.endRTpage = coolDownTrial.startRTpage;
coolDownTrial.correctResponse = -1; %USE AN INVALID RESPONSE CODE
end


function writeTRD(trial, outputName)
%fid = 1;
%OPEN A TEXT FILE WITH THE NAME SPECIFIED IN OUTPUT NAME
fid = fopen(outputName, 'wt');
%IN THE FIRST LINE, PRINT THE NUMBER OF TRIALS
fprintf(fid, '%5d\n', length(trial));
%THEN, FOR EACH SINGLE TRIAL, FILL ALL THE COLUMNS FROM LEFT TO RIGHT
for iTrial = 1:length(trial)
    %FORMAT OF A SINGLE TRIAL IN A TRD FILE
    %CODE TONSET    p1 d1 p2 d2 ... pn dn  startRTonPage correctResponse
    
    fprintf(fid, '%4d\t', trial(iTrial).code);
    fprintf(fid, '%8.2f\t', trial(iTrial).tOnset);
    
    fprintf(fid, '%2d\t\t', trial(iTrial).firstCol); %STM 1
    
    for iSTM = 1:8
        fprintf(fid, '%d\t\t', trial(iTrial).usrDefCol(iSTM)); % STM 2-9
    end
    
    
    %TWO ENTRIES PER PAGE TO DISPLAY: pageNumber, pageDuration
    for iPage = 1:length(trial(iTrial).pageNo)
        fprintf(fid, '%4d\t %4d\t',...
            trial(iTrial).pageNo(iPage), trial(iTrial).dur(iPage));
    end
    %ON WHICH PAGE DOES RT COLLECTION START?
    fprintf(fid, '%4d\t', trial(iTrial).startRTpage);
    %ON WHICH PAGE DOES RT COLLECTION END?
    fprintf(fid, '%4d\t', trial(iTrial).endRTpage);
    %WHAT IS THE CORRECT RESPONSE BUTTON (1: LEFT, 3: RIGHT, -1: NOT
    %SPECIFIED)
    fprintf(fid, '%d', trial(iTrial).correctResponse);
    %END OF LINE
    fprintf(fid, '\n');
end
if (fid > 1)
    fclose(fid);
end
end

function balanceFine = checkFactorBalance(randIndex, STMinfo, checkIndex, binLength)
balanceFine = 1;
for iFactor = checkIndex
    thisFactor = STMinfo(randIndex, iFactor);
    for j = 1:length(thisFactor)/binLength
        factorThisRun = thisFactor((j-1)*binLength+1:j*binLength);
        if length(unique(factorThisRun)) == 1
            balanceFine = 0;
%             fprintf('Factor %d repeating!\n', iFactor);
            return
        end
    end
end

return 
end

function [seq, temptransitions] = generateSeqBalancedTransitions(condsPerBlock, nLimit, nBlock)
N = length(unique(condsPerBlock));
nTrialsPerBlock = length(condsPerBlock);
nTrials = nTrialsPerBlock * nBlock;
balanced = 0;
bigcount = 0;
while balanced == 0
    bigcount = bigcount + 1;
    % fprintf('Re-shuffle entire sequence... %d\n', bigcount);
    temptransitions = zeros(N,N);
    balanced = 1;
    seq = [];
    for iBlock = 1:nBlock
        seq = [seq Shuffle(condsPerBlock)];
    end

    for i = 2:length(seq)
        pos1 = seq(i-1);
        pos2 = seq(i);
        if temptransitions(pos1, pos2) == 0
            temptransitions(pos1, pos2) = temptransitions(pos1, pos2) + 1;
        elseif temptransitions(pos1, pos2) == 1
            % fprintf('Shuffling the 2nd half... :        \n');
            count = 0;
            pre_seq = seq(1:i-1);
            seqToShuffle = seq(i:end);
            nRemains = mod(length(seqToShuffle), nTrialsPerBlock);

            if nRemains ~= 1
                if nRemains == 2
                    nRep = 10;
                else
                    nRep = 100;
                end
                while temptransitions(pos1, pos2) >= nLimit && count <= nRep
                    count = count + 1;
%                     post_seq = Shuffle(seqToShuffle);
                    post_seq = seqToShuffle;
    
                    if nRemains > 0
                        post_seq(1:nRemains) = Shuffle(seqToShuffle(1:nRemains));
                    else
                        post_seq(1:nTrialsPerBlock) = Shuffle(condsPerBlock);
                    end
                    
    %                     seqToShuffle = reshape(seqToShuffle, nTrialsPerBlock, []);
    %                     seqToShuffle = Shuffle(seqToShuffle); 
    %                     post_seq(nRemains+1:end) = reshape(seqToShuffle, 1, []) ;
    
%                     old_pos2 = pos2;
                    pos2 = post_seq(1);
                end
            else
                balanced = 0;
                break
            end
            
            % fprintf('Pos (%d, %d) was [%d, %d], shuffled to [%d, %d]\n', i-1, i, pos1, old_pos2, pos1, pos2);
            seq = [pre_seq post_seq];
            pos1 = seq(i-1);
            pos2 = seq(i);

            temptransitions(pos1, pos2) = temptransitions(pos1, pos2) + 1;
            if temptransitions(pos1, pos2) > nLimit
                balanced = 0;
                break
            end 

        else
            temptransitions(pos1, pos2) = temptransitions(pos1, pos2) + 1;
            balanced = 0;
        end
    end

%     balanced = 1;
end
end
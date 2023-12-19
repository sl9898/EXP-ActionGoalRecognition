function run_GOAL_OUTCOME(iSub,iRun)
% lsc
% call run_GOAL_OUTCOME(99,0) to run a demo of 16 main trials and 3 catch trials (~2.5min)
% call run_GOAL_OUTCOME(1,1) (for example) to run 1 for subj 1 (~7.5min)
% there are 8 runs for each subject
% clear
commandwindow
ExpInfo.tStartExp = clock;
Screen('Preference', 'SkipSyncTests', 1); % lsc: added this to run properly on my Macbook. delete to run properly on PC #set
Screen('Preference', 'VisualDebugLevel', 0);
warning off
Cfg.debug = 0; % open PTB in small window
Cfg.fMRIsync = 1; % 1=wait for scanner trigger
changeRes = 0; % 1=change resolution of the screen (avoid if possible)

 %% set paths
currentPath = pwd;
path_videos = sprintf('videos'); % videos_old : original videos (60 frames, 2s)
path_STMinfo = 'STMinfo.mat';
path_inputfiles = sprintf('%s/trd',currentPath);
path_output_log = sprintf('%s/log',currentPath);
path_output_result = sprintf('%s/res',currentPath);
mkdir(path_output_log);
mkdir(path_output_result);

%% Logfile
Cfg.experimentName = 'GOAL_OUTCOME';
diary(sprintf('log/%s Log_%sSUB%02d_RUN%02d.txt', datestr(now, 'yymmddhhMMss'), Cfg.experimentName,iSub,iRun))

fn_out = sprintf('%s/%s_SUB%02d_RUN%02d.mat',path_output_result,Cfg.experimentName,iSub,iRun);
if exist(fn_out, 'file') && iRun~=0 % Ask user if they want to overwrite the file.
    promptMessage = sprintf('This file already exists:\n%s\nDo you want to overwrite it?', fn_out);
    titleBarCaption = 'Overwrite?';
    buttonText = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'No');
    if strcmpi(buttonText, 'No')
        fn_out = sprintf('%s/%s_SUB%02d_RUN%02d %s.mat',path_output_result,Cfg.experimentName, iSub, iRun, datestr(now, 'yymmddhhMMss'));
    end
elseif exist(fn_out, 'file') && iRun == 0
    fn_out = sprintf('%s/%s_SUB%02d_RUN%02d %s.mat',path_output_result,Cfg.experimentName, iSub, iRun, datestr(now, 'yymmddhhMMss'));
end

%% settings
Cfg.background = [90 90 90]; % [128, 128, 128]; % screen background color
 
% video settings
Cfg.fps = 30; % frames per second
Cfg.nFrames = 180 ; % lsc: we have 180 frames at 30fps
Cfg.vidDuration = 6;
Cfg.rectSize = [300 400] * 1.5; % height/width of grey empty background; should correspond to size of video
Cfg.stimDispSize = fliplr(Cfg.rectSize); % lsc #set

% trial settings
Cfg.warmUpDuration = 10; % in seconds, fix cross before experiment starts
Cfg.coolDownDuration = 16; % in seconds, empty screen after experiment end
Cfg.restDuration = 6; % in seconds, fix cross during baseline between blocks
Cfg.beforeVidDuration = 0; % in seconds, fix cross before each trial
Cfg.fixDurationITI = 2 ; % in seconds, fix cross at the end of trial
Cfg.delayBuffer = 0.8; % for optimal timing; video will be loaded in the fix phase of the preceding trial (in the last e.g. 0.5 s of fixDurationITI)
% lsc #set find the fastest buffer time that works

% some PTB settings
% DisableKeysForKbCheck([46 116]); % for some reason, these keys sometimes make trouble on Windows %lsc: commented out bc MRI trigger is "=+" (46)
KbName('UnifyKeyNames'); %Switch KbName into unified mode: It will use the names of the OS-X platform on all platforms in order to make this script portable
quitKey = KbName('q'); % experiment can be stopped with the q key
responseKeys = KbName({'space','DownArrow', '1!', '2@','3#','5%'}); % 49; % lsc: #set

Cfg.triggerCode = KbName({'=+'}); %  % MRI sync trigger code

Cfg.codeCondCatch = 11; % code for catch trial condition (2+8+1)


%% load input file
if iRun == 0 && iSub == 99 % use a shortened demo input file
    inputfile_fn = sprintf('%s/%s_SUB99_RUN01.trd',path_inputfiles,Cfg.experimentName);
    Cfg.warmUpDuration = 2; % make shorter for practice block
    Cfg.coolDownDuration = 2; % make shorter for practice block
    Cfg.restDuration = 2; % make shorter for practice block
    Cfg.fMRIsync = 1;
elseif iRun == 0 && iSub == 0 % use a shortened demo input file
    inputfile_fn = sprintf('%s/%s_SUB00_RUN01.trd',path_inputfiles,Cfg.experimentName);
    Cfg.warmUpDuration = 2; % make shorter for practice block
    Cfg.coolDownDuration = 2; % make shorter for practice block
    Cfg.restDuration = 1; % make shorter for practice block
    Cfg.fMRIsync = 0; 
else
    inputfile_fn = sprintf('%s/%s_SUB%02d_RUN%02d.trd',path_inputfiles,Cfg.experimentName,iSub,iRun);
end
if exist(inputfile_fn, 'file') ~= 2
    makeTRD_GOAL_OUTCOME(iSub);
end
fid = fopen(inputfile_fn);
aline = fgetl(fid); % first line; could be a header; in our case: num of trials
counter = 0;
while 1 % loop through each line of the inputfile
    counter = counter + 1;
    aline = fgetl(fid); % get line of txt file
    disp(aline); % display it in terminal
    if ~ischar(aline) || (counter==20 && iRun==999), break, end % leave loop if (1) no line anymore or (2) after 2 blocks (for demo) (option 2 not used at the moment)
    ExpInfo.TrialInfo(counter).trial.all = textscan(aline, '%d');
    % get the relevant info:
    ExpInfo.TrialInfo(counter).trial.code = ExpInfo.TrialInfo(counter).trial.all{1}(1);
    ExpInfo.TrialInfo(counter).trial.stimCode = ExpInfo.TrialInfo(counter).trial.all{1}(3);
end
fclose(fid);

%% find stimulus names (should correspond with stim numbers in inputfile)
load(path_STMinfo);
vid_names = STMinfoT.Filename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% START PTB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    
    ExpInfo.tStartPTB = clock;
    AssertOpenGL; % Make sure we run on OpenGL PTB; Abort if we don't
    screen = max(Screen('Screens')); % Open onscreen window. We use the display with the highest number on multi-display setups:
    [screenWidth, screenHeight]=Screen('WindowSize', screen);
    
    Cfg.fMRIdispScreenNum = 0;
    
    %ResolutionTest
    if changeRes==1
        newW = 1280; % 1024 768
        newH = 800;% 720;
        oldRes=SetResolution(screen,newW,newH);
    end
    
    if Cfg.debug==1 % open screen as window
        Cfg.Screen.rect = [1 1 720 540]; % [1 1 580 460];
        [win wRect] = Screen('OpenWindow', screen, Cfg.background, Cfg.Screen.rect);
        ShowCursor; % keep showing the mouse cursor
    else % open full screen
        [win wRect] = Screen('OpenWindow', screen, Cfg.background);
        % lsc #edit hide cursor? edit screen number?
        % lsc #set
        % HideCursor(1); % Hide the mouse cursor - for some reason this does not always work well.. 
        SetMouse(0,0,Cfg.fMRIdispScreenNum); % x,y,screen number - 1 should be the presentation screen
        SetMouse(0,0,0); % x,y,screen number - 0 should be the home/Matlab screen - we do this to ensure that the last set mouse is the mouse on the home screen
    end

    drawDesRect = [wRect(3), wRect(4), wRect(3), wRect(4)]/2 + [-Cfg.stimDispSize Cfg.stimDispSize]/2; 
    
    %% prepare textures of picture trials
    I = uint8(repmat(175,Cfg.rectSize(1),Cfg.rectSize(2),3)); % prepare a light grey image
    emptyTex = Screen('MakeTexture', win, I, [], 1);
    
    % for fixation cross, we print a plus:
    fixText = '+';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% BEFORE DATA COLLECTION STARTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % collect some timing info
    ExpInfo.dateTime = clock;
    ExpInfo.dateStr = datestr(now);
    fprintf('day/month/year: %02d/%02d/%04d, time: %02d:%02d:%02d\n',ExpInfo.dateTime(3),ExpInfo.dateTime(2),ExpInfo.dateTime(1),ExpInfo.dateTime(4),ExpInfo.dateTime(5),round(ExpInfo.dateTime(6)));
    
    % Show instructions...
    tsize = 20;
    Screen('TextSize', win, tsize);
    [x, y]=Screen('DrawText', win, 'Please observe the actions.', 40, 10 + tsize);
    if ~(iRun == 0 && iSub == 0)
        [x, y]=Screen('DrawText', win, 'Press the response button if the action was different', 40, y + 10 + tsize);
        Screen('DrawText', win, 'the experiment will start soon...', 40, y + 10 + tsize); % prepare screen
    end
    
    % Flip to show the instruction screen:
    Screen('Flip',win);
    disp('waiting for keypress/trigger to start experiment..');
    ExpInfo.tWaitForTrigger = clock;
    
    [keyboardid,name] = GetKeyboardIndices;
    kbId_scanner = keyboardid(end); % lsc: #set check keyboard id index
    
    %% scanner sync
    waitfortrigger = tic;
    if Cfg.fMRIsync == 1

        %Wait for scanner trigger
        keylist_trigger = zeros(1,256);
        keylist_trigger(Cfg.triggerCode) = 1; % set keys you interested in to 1
        keylist_trigger(quitKey) = 1;
        KbQueueCreate(kbId_scanner, keylist_trigger);
        KbQueueStart(kbId_scanner); %%start listening

        pressed = 0;
        while ~pressed
	        [pressed, keypressed] = KbQueueCheck(kbId_scanner); %check response
            if keypressed(Cfg.triggerCode)
                ExpInfo.tTriggerPressed = clock;
                triggerPressed = tic;
            elseif keypressed(quitKey)
                sca;
                ListenChar(0);
            end
        end

        KbQueueRelease(kbId_scanner);

    else
         KbStrokeWait(-1); % Wait for keypress + release...
         ExpInfo.tTriggerPressed = clock;
    end
    
    disp('go!');
    fprintf('From tWaitForTrigger to tTriggerPressed: %0.4f s\n', etime(ExpInfo.tTriggerPressed, ExpInfo.tWaitForTrigger));
    fprintf('Time since tTriggerPressed: %0.4f s\n', etime(clock, ExpInfo.tTriggerPressed));
    
    ListenChar(2)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% START TRIALS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    expOnset = tic;
    ExpInfo.tStartAllTrials = clock;
    for iTrial = 1:length(ExpInfo.TrialInfo)
        
        trialOnset = tic;
        ExpInfo.monitoring.tTrialLoopStarts{iTrial} = clock;
        
        if ExpInfo.TrialInfo(iTrial).trial.code == 0 % baseline between blocks (0)

            ExpInfo.monitoring.tMeasuredTrialStarts{iTrial} = clock;
            ExpInfo.monitoring.tMeasuredStimStarts{iTrial} = clock;
            
            Screen('DrawTexture', win, emptyTex);
            Screen('TextSize', win, 25); Screen('TextFont',win,'Arial'); DrawFormattedText(win, fixText,'center','center',[255 255 255]);
            Screen('Flip',win);
            ExpInfo.TrialOnset(iTrial) = toc(expOnset);
            ExpInfo.DesiredTrialOnset(iTrial) = ExpInfo.DesiredTrialOnset(iTrial-1) + ExpInfo.DesiredTrialDur(iTrial-1);
            ExpInfo.DesiredTrialDur(iTrial) = Cfg.restDuration;
            ExpInfo.t = clock;
            
            % Wait...
            WaitSecs(Cfg.restDuration-Cfg.delayBuffer);
            ExpInfo.monitoring.tMeasuredStimEnds{iTrial} = clock;
            ExpInfo.monitoring.MeasuredVidDur(iTrial) = toc(trialOnset);
            fprintf('trial %d: fixation block, desired onset: %0.3f, measured: %0.3f\n',iTrial,ExpInfo.DesiredTrialOnset(iTrial), ExpInfo.TrialOnset(iTrial));
            
        elseif ExpInfo.TrialInfo(iTrial).trial.code == 1 % warm up (1)
            
            ExpInfo.monitoring.tMeasuredStimStarts{iTrial} = clock;
            ExpInfo.monitoring.tMeasuredTrialStarts{iTrial} = clock;

            Screen('DrawTexture', win, emptyTex);
            Screen('TextSize', win, 25); Screen('TextFont',win,'Arial'); DrawFormattedText(win, fixText,'center','center',[255 255 255]);
            Screen('Flip',win);
            ExpInfo.TrialOnset(iTrial) = toc(expOnset);
            ExpInfo.DesiredTrialOnset(iTrial) = 0;
            ExpInfo.DesiredTrialDur(iTrial) = Cfg.warmUpDuration;
            
            % Wait...
            WaitSecs(Cfg.warmUpDuration-Cfg.delayBuffer);
            ExpInfo.monitoring.tMeasuredStimEnds{iTrial} = clock;
            ExpInfo.monitoring.MeasuredVidDur(iTrial) = toc(trialOnset);
            fprintf('trial %d: warm up phase, desired onset: %0.3f, measured: %0.3f\n',iTrial,ExpInfo.DesiredTrialOnset(iTrial), ExpInfo.TrialOnset(iTrial));
            
        elseif ExpInfo.TrialInfo(iTrial).trial.code == 2 % cool down (2)
            
            % lsc: in the last trial, the fixation after the stimuli offset
            % lasts only 1.2s bc of the delayBuffer. so we add the buffer
            % back here
            WaitSecs(Cfg.delayBuffer);

            ExpInfo.monitoring.tMeasuredStimStarts{iTrial} = clock;
            ExpInfo.monitoring.tMeasuredTrialStarts{iTrial} = clock;

            Screen('DrawTexture', win, emptyTex);
            Screen('Flip',win);
            ExpInfo.TrialOnset(iTrial) = toc(expOnset);
            ExpInfo.DesiredTrialOnset(iTrial) = ExpInfo.DesiredTrialOnset(iTrial-1) + ExpInfo.DesiredTrialDur(iTrial-1);
            ExpInfo.DesiredTrialDur(iTrial) = Cfg.coolDownDuration;
            
            % Wait...
            WaitSecs(Cfg.coolDownDuration); % lsc: changed from Cfg.warmUpDuration-Cfg.delayBuffer
            ExpInfo.monitoring.tMeasuredStimEnds{iTrial} = clock;
            ExpInfo.monitoring.MeasuredVidDur(iTrial) = toc(trialOnset);
            fprintf('trial %d: cool down phase desired onset: %0.3f, measured: %0.3f\n\n',iTrial,ExpInfo.DesiredTrialOnset(iTrial), ExpInfo.TrialOnset(iTrial));
            
            %% analyze responses for display
            fprintf('Analyzing behavior results...\n');
            analyseBhvRes(iSub,iRun,ExpInfo);
            % analyseTiming(iSub,iRun,Cfg.experimentName);
            
        elseif ExpInfo.TrialInfo(iTrial).trial.code > 2 % video trials
            video_nr = ExpInfo.TrialInfo(iTrial).trial.stimCode; % get the video number from the input file
            moviename = sprintf('%s/%s',path_videos, vid_names{video_nr}); % .. and use the number to specify which video to load
            
            preFixOnset = tic;

            ExpInfo.monitoring.tMeasuredTrialStarts{iTrial} = clock;
            
            % load the file
            stim = load(moviename);
            
            for iFrame = 1:Cfg.nFrames
                %tmpcdata = stim.MAT(:,:,iFrame); % black/white videos
                tmpcdata = stim.MAT(:,:,:,iFrame); % RGB videos
                %tmpcdata=imresize(tmpcdata,1.5); % in case we want to resize the video
                Stimuli.tex(iFrame) = Screen('MakeTexture', win, tmpcdata, [], 1); % get the frames of the video for PTB
                Stimuli.pts(iFrame) = (iFrame - 1) * 1/Cfg.fps; % 'pts' contains a so called presentation timestamp. That is the time (in seconds since start of movie)
            end
            
            
            %% show fix cross before stimulus presentation
            Screen('DrawTexture', win, emptyTex);
            Screen('TextSize', win, 25); Screen('TextFont',win,'Arial'); DrawFormattedText(win, fixText,'center','center',[255 255 255]);
            Screen('Flip',win);
            
            ExpInfo.DesiredTrialOnset(iTrial) = ExpInfo.DesiredTrialOnset(iTrial-1) + ExpInfo.DesiredTrialDur(iTrial-1);
            ExpInfo.DesiredTrialDur(iTrial) = Cfg.beforeVidDuration + Cfg.vidDuration + Cfg.fixDurationITI;
            
            while ExpInfo.DesiredTrialOnset(iTrial) > toc(expOnset) % toc(preFixOnset) < Cfg.beforeVidDuration
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Video playback and key response RT collection loop:
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            movietexture = 0;     % Texture handle for the current movie frame.
            afterStim = 0;
            RT = -1;    % Variable to store reaction time.
            lastpts = 0;          % Presentation timestamp of last frame.
            onsettime = -1;       % Realtime at which the event was shown to the subject.
            buttonCode = -1;
            
            VidOnset = tic; % video onset time
            ExpInfo.monitoring.MeasuredTrialOnset(iTrial) = toc(trialOnset);
            ExpInfo.TrialOnset(iTrial) = toc(expOnset);
            
            ExpInfo.monitoring.tMeasuredFrameLoopStarts{iTrial} = clock;

            iFrame = 1;
            %% begin video loop
            while toc(VidOnset) < Cfg.vidDuration + Cfg.fixDurationITI - Cfg.delayBuffer
                
                if iFrame <= Cfg.nFrames
                    %% load the texture
                    movietexture = Stimuli.tex(iFrame);  % the texture
                    pts = Stimuli.pts(iFrame); % and the time point (after video onset) when the texture should be shown
                    
                    % Is the time point reached for presentation?
                    if toc(VidOnset) < pts
                        movietexture = 0; % No. Too early for presentation
                    else

                        % Yes. Draw the texture into backbuffer:
%                         Screen('DrawTexture', win, movietexture);
                        Screen('DrawTexture', win, movietexture, [], drawDesRect); % lsc #set uncomment to adjust display size
                        % Flip the display to show the image at next retrace:
                        % vbl will contain the exact system time of image onset on
                        % screen: This should be accurate in the sub-millisecond
                        % range.
                        vbl = Screen('Flip', win);
                        
                        if iFrame == 1
                            onsettime = vbl; % for most accurate timing, define the onset of first frame as video onset for RT measurement
%                             VidOnset = tic; % also update the onset for the duration of first frame
                            ExpInfo.monitoring.tMeasuredStimStarts{iTrial} = clock;
                        elseif iFrame == Cfg.nFrames % is last frame shown?
                            lastpts=1;
                        end
                        
                        % Delete the texture. We don't need it anymore:
                        Screen('Close', movietexture);
                        movietexture=0;
                        
                        %% some monitoring to check if timing is correct:
                        ExpInfo.monitoring.pts(iTrial,iFrame) = pts;
                        ExpInfo.monitoring.vbl(iTrial,iFrame) = vbl - onsettime;
                        ExpInfo.monitoring.toc(iTrial,iFrame) = toc(VidOnset);
                        iFrame  = iFrame+1;
                    end
                end

                
                if toc(VidOnset) > Cfg.vidDuration && afterStim==0
                    %% show empty screen after the end of stimulus presentation (inter trial interval)
                    Screen('DrawTexture', win, emptyTex);
                    Screen('TextSize', win, 25); Screen('TextFont',win,'Arial'); DrawFormattedText(win, fixText,'center','center',[255 255 255]);
                    Screen('Flip',win);
                    ExpInfo.monitoring.tMeasuredStimEnds{iTrial} = clock;
                    afterStim=1;
                end
                
                %% Done with drawing. Check the keyboard for subjects response:
                [keyIsDown, secs, keyCode] = KbCheck(keyboardid);
                if (keyIsDown==1)
                    if ismember(find(keyCode==1),responseKeys) % key pressed to indicate detection of event?
                        buttonCode = find(keyCode==1);
                        RT = secs - onsettime;
                        ExpInfo.TrialInfo(iTrial).Response.tResponse = clock;
                    elseif keyCode(quitKey) % quit button press?
                        sca;
                    end
                end
%                 
%                 keylist_response = zeros(1,256);
%                 keylist_response(responseKeys) = 1; % set keys you interested in to 1
%                 keylist_response(quitKey) = 1;
%                 KbQueueCreate(keyboardid(end), keylist_response); 
%                 KbQueueStart(keyboardid(end)); % start listening
%         
%                 [pressed, keypressed] = KbQueueCheck(kbId_scanner); %check response
%                 if max(keypressed(responseKeys)) > 0
%                     disp('yay!');
%                     buttonCode = find(keypressed>1);
%                     RT = secs - onsettime;
%                     ExpInfo.TrialInfo(iTrial).Response.tResponse = clock;
%                 elseif keypressed(quitKey)
%                     sca;
%                 end
                
            end % ...of display loop...
            ExpInfo.monitoring.MeasuredVidDur(iTrial) = toc(VidOnset);
            
            % Wait for subject to release keys:
%             KbReleaseWait;
            
            %% monitor responses etc
            ExpInfo.TrialInfo(iTrial).Response.RT = RT;
            ExpInfo.TrialInfo(iTrial).Response.key = buttonCode;
            ExpInfo.TrialInfo(iTrial).trial.stimulus = vid_names{video_nr};
            fprintf('trial %d, button: %d (%s), desired onset: %0.3f, measured: %0.3f\n',iTrial, buttonCode, vid_names{video_nr}, ExpInfo.DesiredTrialOnset(iTrial), ExpInfo.TrialOnset(iTrial));
            if buttonCode(1) == -1
                if ExpInfo.TrialInfo(iTrial).trial.code == Cfg.codeCondCatch  % miss
                    fprintf('missed catch trial\n');
                end
            else
                if ExpInfo.TrialInfo(iTrial).trial.code == Cfg.codeCondCatch  % hit
                    fprintf('hit - RT: %0.2f s\n',RT);
                elseif ExpInfo.TrialInfo(iTrial).trial.code ~= Cfg.codeCondCatch  % false alarm
                    fprintf('false alarm!\n');
                end
            end
            
        end % Trial done. Next trial...

        ExpInfo.monitoring.tMeasuredTrialEnds{iTrial} = clock;
    end

    ExpInfo.tEndAllTrials = clock;
    save(sprintf('%0.2d', iRun), 'ExpInfo');
    
    %% Done with the experiment. Close onscreen window and finish.
    ShowCursor;
    fprintf('Done!\n');
    sca;
    if changeRes==1
        SetResolution(screen,oldRes.width,oldRes.height);
    end
%     fprintf('day/month/year: %02d/%02d/%04d, time: %02d:%02d:%02d\n',ExpInfo.dateTime(3),ExpInfo.dateTime(2),ExpInfo.dateTime(1),ExpInfo.dateTime(4),ExpInfo.dateTime(5),round(ExpInfo.dateTime(6)));
    fprintf('Finish time: %s\n', datestr(now));
    
    sca; % close PTB screen
    ListenChar(0);

    ExpInfo.tEndExp = clock;
    
    %% Save results file
    ExpInfo.Cfg = Cfg;
    save(fn_out, 'ExpInfo', 'Cfg')

    return;
    
catch
    % Error handling: Close all windows and movies, release all ressources.
    sca;
    ListenChar(0);
    if changeRes==1
        SetResolution(screen,oldRes.width,oldRes.height);
    end
    psychrethrow(psychlasterror);
end

diary OFF
% clear all;



%=========================================================================
% ACT4 - Simon Says (MNS Localizer) - Experimental task for fMRI
%
% Created July 2010
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%
% 07/14 - Script created (BS)
% 07/20 - Initial version completed (BS)
%=========================================================================
clear all; clc;
%---------------------------------------------------------------
%% PRINT VERSION INFORMATION TO SCREEN
%---------------------------------------------------------------
script_name='SIMON SAYS TASK';
creation_date='07-24-10';
fprintf('%s (created %s)\n',script_name, creation_date);
%---------------------------------------------------------------
%% GET USER INPUT
%---------------------------------------------------------------

% get subject ID
subjectID=input('\nEnter subject ID: ');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ');
end;

% is this a scan?
MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
while isempty(find(MRIflag==[1 2]));
    disp('ERROR: input must be 0 or 1. Please try again.');
    MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
end

% are you using the buttonbox or keyboard?
if MRIflag==1  % then always use the button box
    deviceflag=1;
else            % then use the button box during in-scanner tests, and keyboard when not in the scanner
    deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    while isempty(find(deviceflag==[1 2]));
        disp('ERROR: input must be 1 or 2. Please try again.');
        deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    end
end

%---------------------------------------------------------------
%% WRITE TRIAL-BY-TRIAL DATA TO LOGFILE
%---------------------------------------------------------------
d=clock;
logfile=sprintf('sub%d_simonsays.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%---------------------------------------------------------------
%% DETERMINE ORDER AND GET ORDER VARIABLE
%---------------------------------------------------------------
cd trialcodes/simonsays
load order.mat
cd ../../

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
nTrials=15;     % number of trials (per run)
nRuns=1;        % number of runs

%---------------------------------------------------------------
%% SET UP INPUT DEVICES
%---------------------------------------------------------------

% from agatha's code, uses's Don's hid_probe.m
fprintf('\n\n===============');
fprintf('\nSUBJECT RESPONSES - CHOOSE DEVICE:')
fprintf('\n===============\n');
inputDevice = hid_probe;

fprintf('\n\n===============');
fprintf('\nEXPERIMENTER RESPONSE - CHOOSE DEVICE:')
fprintf('\n   (if laptop at scanner, "5", if laptop elsewhere, "4", if imac, "5")')
fprintf('\n===============\n');
experimenter_device = hid_probe;

%---------------------------------------------------------------
%% INITIALIZE SCREENS
%---------------------------------------------------------------
AssertOpenGL;
screens=Screen('Screens');
screenNumber=max(screens);
w=Screen('OpenWindow', screenNumber,0,[],32,2);
[wWidth, wHeight]=Screen('WindowSize', w);
xcenter=wWidth/2;
ycenter=wHeight/2;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% colors
grayLevel=0;    
black=BlackIndex(w); % Should equal 0.
white=WhiteIndex(w); % Should equal 255.
Screen('FillRect', w, grayLevel);
Screen('Flip', w);

% text
theFont='Arial';
theFontSize=44;
Screen('TextSize',w,44);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);

% movie defaults
rate=1;     % playback rate
movieSize=1;     % 1 is fullscreen
maxTime=5;  % maximum time (in secs) to display each movie
dstRect = CenterRect(ScaleRect(Screen('Rect', w),movieSize,movieSize),Screen('Rect', w)); 

% define cues (messages to the subject)
cueWATCH='WATCH SIMON';
cueWAIT='WAIT';
cueDO='REPEAT ONCE';
cueDOTWICE='REPEAT TWICE';
cueCORRECT='Correct!';
cueINCORRECT='Incorrect!';
cueSTILL='HOLD STILL';
FIXATION='+';

% compute default Y position (vertically centered)
numlines = length(strfind(FIXATION, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X positions 
bbox=Screen('TextBounds', w, cueSTILL);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueSTILLPosX = dh;
bbox=Screen('TextBounds', w, cueWATCH);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueWATCHPosX = dh;
bbox=Screen('TextBounds', w, cueWAIT);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueWAITPosX = dh;
bbox=Screen('TextBounds', w, cueDO);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueDOPosX = dh;
bbox=Screen('TextBounds', w, cueDOTWICE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueDOTWICEPosX = dh;
bbox=Screen('TextBounds', w, cueCORRECT);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueCORRECTPosX = dh;
bbox=Screen('TextBounds', w, cueINCORRECT);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cueINCORRECTPosX = dh;
% compute X position for FIXATION
bbox=Screen('TextBounds', w, FIXATION);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;

%---------------------------------------------------------------
%% ASSIGN RESPONSE KEYS
%---------------------------------------------------------------
if deviceflag==1 % input from button box (can choose this if not scanning)
    respset=['b','y','g','r','t'];
    trigger=KbName('t');
    buttonOne=KbName('b');
    buttonTwo=KbName('y');
    buttonThree=KbName('g');
    buttonFour=KbName('r');
else                % input from keyboard
    respset=['u' 'i' 'o' 'p'];
    trigger=KbName('t'); % won't use this but just in case I accidentally make the code look for it
    buttonOne=KbName('u');
    buttonTwo=KbName('i');
    buttonThree=KbName('o');
    buttonFour=KbName('p');
end
HideCursor;

%---------------------------------------------------------------
%% GET AND LOAD STIMULI
%---------------------------------------------------------------

DrawFormattedText_new(w, 'LOADING', 'center','center',white, 600, 0, 0);
Screen('Flip',w);
fmt='mov';
cd('stimuli/simonsays');
d=dir(['*.' fmt]);
[nStim junk]=size(d);
movieSequence=cell(nStim,1);
movieName=cell(nStim,1);
movieMov=zeros(nStim,1);
for i=1:nStim,
    fname=d(i).name;
    tmp=regexprep(fname,'_',' ');
    movieSequence(i)={regexprep(tmp,'.mov','')};
    [movie movieduration fps imgw imgh] = Screen('OpenMovie', w, fname);
    movieMov(i) = movie;
    movieName{i}=fname;
end;
cd ../../
%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% The first column is trial number
% The second column is the stimulus index
% The third column is intended video cue duration
% The fourth column is intended video duration
% The fifth column is intended IEI duration
% The sixth column is intended key sequence duration
% The seventh column is intended ITI duration
% The eigth column is intended onset for trial
% The ninth column is intended onset for video
% The tenth column is intended onset for key sequence cue
% The eleventh column is actual onset of video
% The twelth column is actual duration of video
% The thirteenth column is actual onset of key sequence
% The fourteenth column is actual duration of key sequence
% The fifthteenth column is whether key sequence was incorrect (0) or
% correct (1)
% 16 - whether sub is told to repeat ONCE or TWICE
Seeker=zeros(15,16);
Seeker(:,1:10)=trialcode;

% compute repeat once or twice trials
repeatTimes=[1 2]';
for i=1:nTrials;
    curSeq=char(movieSequence(Seeker(i,2)));
    if length(curSeq)<5,
        Seeker(i,16)=2;
    else
        Seeker(i,16)=1; 
    end;
end;
    
% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
DrawFormattedText_new(w, 'The run is about to begin. Remember to keep your head as still as possible.', 'center','center',white, 600, 0, 0);
Screen('Flip',w);

%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
if MRIflag==1, % wait for experimenter keypress (experimenter_device) and then trigger from scanner (inputDevice)
    timerON = 1;
    while timerON
        [timerPressed,time] = KbCheck(experimenter_device);
        scannerSTART = time;
        if timerPressed
            timerON = 0;
        end
    end
%     Screen('DrawText',w,FIXATION,fixPosX,PosY);
%     Screen('Flip', w);   
    secs=KbTriggerWait(trigger,inputDevice);	% wait for trigger, return system time when detected
    anchor=secs;		% anchor timing here (because volumes are discarded prior to trigger)
    DisableKeysForKbCheck(trigger);     % So trigger is no longer detected
    triggerOFFSET = secs - scannerSTART;  % difference between experimenter keypress and when trigger detected
else % If using the keyboard, allow any key as input
    noresp=1;
    scannerSTART = GetSecs;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(experimenter_device);
        if keyIsDown && noresp
            noresp=0;
            triggerOFFSET = secs - scannerSTART;
		anchor=secs;	% anchor timing here
        end
    end
end;
WaitSecs(0.001);

%---------------------------------------------------------------
%% TRIAL PRESENTATION!!!!!!!
%---------------------------------------------------------------

anchor2=GetSecs; 	% just to test difference between trigger anchor and this one

% present FIXATION cross until first trial cue onset
Screen('DrawText',w,FIXATION,fixPosX,PosY);
Screen('Flip', w);    
while GetSecs - anchor < Seeker(1,8)    
end;  

try

for t=1:nTrials,
       
    % present WATCH cue
    Screen('DrawText',w,cueWATCH,cueWATCHPosX,PosY);
    Screen('Flip', w);
    WaitSecs(0.75);
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    % During this period, prepare stimulus for presentation
    Screen('SetMovieTimeIndex', movieMov(Seeker(t,2)), 0);
    Screen('PlayMovie', movieMov(Seeker(t,2)), rate, 0, 0);

    % Present MOVIE
   WaitSecs('UntilTime', anchor + Seeker(t,9));
   stimStart=GetSecs;
    while(1)
        if (abs(rate)>0)
            [tex] = Screen('GetMovieImage', w, movieMov(Seeker(t,2)), 1);
            if tex<=0 | (maxTime > 0 && GetSecs - stimStart >= maxTime)
                break;
            end;
            Screen('DrawTexture', w, tex,[],dstRect);
            Screen('DrawingFinished',w);
            Screen('Flip', w);
            Screen('Close', tex);
        end;
    end;
    Screen('Flip', w);
    Screen('PlayMovie', movieMov(Seeker(t,2)), 0);
    Screen('CloseMovie', movieMov(Seeker(t,2)));
    movieEnd=GetSecs;
    actualStimulus{t}=movieName(Seeker(t,2));
    Seeker(t,11)=stimStart-anchor;
    Seeker(t,12)=movieEnd-stimStart;
    
    % DURING IEI, PRESENT "STILL" CUE
    Screen('FillRect', w, white);
    Screen('TextColor',w,black);
    Screen('DrawText',w,cueSTILL,cueSTILLPosX,PosY);
    Screen('Flip', w);
    
    % PREPARE FOR THE UPCOMING EVENT
    Screen('FillRect', w, black);
    Screen('TextColor',w,white);
    if Seeker(t,16)==1,
         Screen('DrawText',w,cueDO,cueDOPosX,PosY);
    elseif Seeker(t,16)==2,
        Screen('DrawText',w,cueDOTWICE,cueDOTWICEPosX,PosY);
    end;
    KbQueueCreate(inputDevice);
    while KbCheck; end % Wait until all keys are released.
    % build correct key sequence variable
    curSeq=char(movieSequence(Seeker(t,2)));
    if length(curSeq)<5,
        curSeq=[curSeq curSeq];
    end;
    correctSeq=zeros(length(curSeq),1);
    actualSeq=zeros(length(curSeq),1);
    for s=1:length(curSeq),
        if str2num(curSeq(s))==1,
            correctSeq(s)=buttonOne;
        elseif str2num(curSeq(s))==2,
            correctSeq(s)=buttonTwo;
        elseif str2num(curSeq(s))==3,
            correctSeq(s)=buttonThree;
        end;
    end;
    
    % Present KEY SEQUENCE CUE
    Screen('Flip',w, anchor + Seeker(t,10));
    seqStart=GetSecs;
    Seeker(t,13)=seqStart-anchor;
    keyCount=0;
    KbQueueStart;
    while (GetSecs-seqStart<5) && keyCount<length(curSeq)
       [pressed, firstPress]=KbQueueCheck;
       if pressed
          keyCount=keyCount+1;
          actualSeq(keyCount)=find(firstPress);
       end;
   end;
   KbQueueRelease;
   Seeker(t,14)=GetSecs-seqStart;
   if isequal(actualSeq,correctSeq),
      Seeker(t,15)=1;
      Screen('DrawText',w,cueCORRECT,cueCORRECTPosX,PosY);
   else
       Seeker(t,15)=0;
       Screen('DrawText',w,cueINCORRECT,cueINCORRECTPosX,PosY);
   end;
   Screen('Flip', w);
   WaitSecs(1);
   % DURING IEI, PRESENT "STILL" CUE
   Screen('FillRect', w, white);
   Screen('TextColor',w,black);
   Screen('DrawText',w,cueSTILL,cueSTILLPosX,PosY);
   Screen('Flip', w);
   if t<nTrials,
         WaitSecs('UntilTime', anchor + Seeker(t+1,8));
   elseif t==nTrials,
         WaitSecs(Seeker(15,7));
   end;
   Screen('FillRect', w, black);
   Screen('TextColor',w,white); 
   
    % PRINT TRIAL INFO TO LOG FILE
    try,
        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',Seeker(t,1:12));
    catch,   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
    end;
end;    % end of trial loop

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

totalTime=GetSecs-anchor;

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('simonsays_%d_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','subjectID', 'anchor', 'anchor2','triggerOFFSET'); 
catch
	fprintf('couldn''t save %s\n saving to simonsays_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;

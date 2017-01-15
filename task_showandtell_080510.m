%=========================================================================
% ACT4 - Show & Tell Study - Experimental task for fMRI
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
script_name='SHOW & TELL, WHY & HOW STUDY';
creation_date='07-14-10';
fprintf('%s (created %s)\n',script_name, creation_date);
%---------------------------------------------------------------
%% GET USER INPUT
%---------------------------------------------------------------

% subject ID
subjectID=input('\nEnter subject ID: ');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ');
end;

% run number
runNum=input('Enter run number (1 or 2): ');
while isempty(find(runNum==[1 2])),
  runNum=input('Run number must be 1 or 2 - please re-enter: ');
end;

% scanning?
MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
while isempty(find(MRIflag==[1 2]));
    disp('ERROR: input must be 0 or 1. Please try again.');
    MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
end

% are you using the buttonbox or keyboard?
if MRIflag==1  % then always use the button box
    deviceflag=1;
else            
    deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    while isempty(find(deviceflag==[1 2]));
        disp('ERROR: input must be 1 or 2. Please try again.');
        deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    end
end

%---------------------------------------------------------------
%% OPEN LOGFILE 
%---------------------------------------------------------------
d=clock;
logfile=sprintf('sub%d_showandtell.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%---------------------------------------------------------------
%% DETERMINE ORDER AND GET TRIALORDER VARIABLE
%---------------------------------------------------------------

% seed random number generator
rand('state',sum(100*clock));

% determine version number (based on subjectID)
if (rem(subjectID,2))
    verNum=1;
else
    verNum=2;
end;

% get appropriate order variable
if runNum==1,
   orderNum=1;
   inputfile='order1.mat';
elseif runNum==2,
    orderNum=2;
   inputfile='order2.mat';
end;
cd trialcodes/showandtell
load(inputfile);
cd ../../

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
nTrials=60;     % number of trials (per run)
nRuns=2;        % number of runs
nShapematch=24; % total # of shapematch trials (across both runs)
actualStimulus=cell(nTrials,1);     % actual stimulus displayed for each trial

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
%% INITIALIZE SCREENS, CUES AND COMPUTE SCREEN POSITIONING
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
theFontSize=40;
Screen('TextSize',w,40);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);

% movie defaults
rate=1;     % playback rate
movieSize=.75;     % 1 is fullscreen
maxTime=5;  % maximum time (in secs) to display each movie
dstRect = CenterRect(ScaleRect(Screen('Rect', w),movieSize,movieSize),Screen('Rect', w)); 

% cues
whyCue='Why is she doing it?';
howCue='How is she doing it?';
shapeCue='Which shape matches?';
fixation='+';

% compute default Y position (vertically centered)
numlines = length(strfind(whyCue, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for cues
bbox=Screen('TextBounds', w, whyCue);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
cuePosX = dh;
bbox=Screen('TextBounds', w, shapeCue);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
shapeCuePosX = dh;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
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
%% GET AND PRELOAD STIMULI
%---------------------------------------------------------------

DrawFormattedText_new(w, 'LOADING', 'center','center',white, 600, 0, 0);
Screen('Flip',w);
fmt='mov';
fmtimg='png';
cd('stimuli/showandtell');
if verNum==1,
    cd('set1');
    d=dir(['*.' fmt]);
    [nStim junk]=size(d);
    movieVerb=cell(nStim,1);
    for i=1:nStim,
        fname=d(i).name;
        tmp=regexprep(fname,'_',' ');
        movieVerb(i)={regexprep(tmp,'.mov','')};
    end;
    cd('../set2');
    d=dir(['*.' fmt]);
    [nStim junk]=size(d);
    movieName=cell(nStim,1);
    movieMov=zeros(nStim,1);
    for i=1:nStim,
        fname=d(i).name;
    	[movie movieduration fps imgw imgh] = Screen('OpenMovie', w, fname);
        movieMov(i) = movie;
        movieName{i}=fname;
    end;
elseif verNum==2,
    cd('set2');
    d=dir(['*.' fmt]);
    [nStim junk]=size(d);
    movieVerb=cell(nStim,1);
    for i=1:nStim,
        fname=d(i).name;
        tmp=regexprep(fname,'_',' ');
        movieVerb(i)={regexprep(tmp,'.mov','')};
    end;
    cd('../set1');
    d=dir(['*.' fmt]);
    [nStim junk]=size(d);
    movieName=cell(nStim,1);
    movieMov=zeros(nStim,1);
    for i=1:nStim,
        fname=d(i).name;
    	[movie movieduration fps imgw imgh] = Screen('OpenMovie', w, fname);
        movieMov(i) = movie;
        movieName{i}=fname;
    end;
end;
cd('../shapematch');
d=dir(['*.' fmtimg]);
shapematchStim=cell(nShapematch,1);
shapematchName=cell(nShapematch,1);
shapematchTex=cell(nShapematch,1);
for i=1:nShapematch,
    fname=d(i).name;
    shapematchStim{i}=fname;
    shapematchName{i}=imread(fname);
    shapematchTex{i}=Screen('MakeTexture',w,shapematchName{i});
end;
cd ../../
screen=imread('trainingscreen_showandtell.png');
trainingSCREEN=Screen('MakeTexture',w,screen);
cd ../

% compute x-positioning for verbal stimuli
for i=1:length(movieVerb);
    bbox=Screen('TextBounds', w, char(movieVerb(i)));
    [rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
    verbPosX(i) = dh;
end;

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% 1 - trial #
% 2 - condition: 1=WhyVIDEO, 2=WhyTEXT, 3=HowVIDEO,4=HowTEXT, 5=CATCH
% 3 - stimulus index
% 4 - intended cue duration
% 5 - intended stimulus duration
% 6 - intended ITI duration
% 7 - intended cue onset for that trial
% 8 - intended stimulus onset for that trial
% 9 - intended time offset for the trial (cue + stim + ITI)
% 10 - actual stimulus onset for that trial 
% 11 - RT to stimulus onset for that trial
% 12 - skip index: 0=Valid Trial; 1=Skip (No Response)
% 13 - shape match correct? (1=YES, 0=NO or Not shapematch);

Seeker=zeros(60,13);
Seeker(:,1:9)=trialcode;

% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
if runNum==1,
    Screen('DrawTexture', w, trainingSCREEN);
else
    DrawFormattedText_new(w, 'Run 2 is about to begin. Remember to keep your head as still as possible.', 'center','center',white, 600, 0, 0);
end;
Screen('Flip',w);
%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
if MRIflag==1, % wait for experimenter keypress (experimenter_device) and then trigger from scanner (inputDevice)
    timer_started = 1;
    while timer_started
        [timerPressed,time] = KbCheck(experimenter_device);
        STARTscanner = time;
        if timerPressed
            timer_started = 0;
        end
    end
    secs=KbTriggerWait(trigger,inputDevice);	% wait for trigger, return system time when detected
    anchor=secs;		% anchor timing here (because volumes are discarded prior to trigger)
    DisableKeysForKbCheck(trigger);     % So trigger is no longer detected
    triggerOFFSET = secs - STARTscanner;  % difference between experimenter keypress and when trigger detected
else % If using the keyboard, allow any key as input
    noresp=1;
    STARTscanner = GetSecs;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(experimenter_device);
        if keyIsDown && noresp
            noresp=0;
            triggerOFFSET = secs - STARTscanner;
		anchor=secs;	% anchor timing here
        end
    end
end;
WaitSecs(0.001);

%---------------------------------------------------------------
%% TRIAL PRESENTATION!!!!!!!
%---------------------------------------------------------------

anchor2=GetSecs; 	% just to test difference between trigger anchor and this one

% present fixation cross until first trial cue onset
Screen('DrawText',w,fixation,fixPosX,PosY);
Screen('Flip', w);    
while GetSecs - anchor < Seeker(1,7)    
end;  

% WaitSecs('UntilTime', anchor + Seeker(1,7));

try

for t=1:nTrials,
       
    % Present trial cue
    if Seeker(t,2)==1 | Seeker(t,2)==2,
        Screen('DrawText',w,whyCue,cuePosX,PosY);
    elseif Seeker(t,2)==3 | Seeker(t,2)==4,
        Screen('DrawText',w,howCue,cuePosX,PosY);
    elseif Seeker(t,2)==5,
        Screen('DrawText',w,shapeCue,shapeCuePosX,PosY);
    end;
    Screen('Flip', w);
    WaitSecs(1.5);
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    % During this period, prepare stimulus for presentation
    if Seeker(t,2)==1 || Seeker(t,2)==3,
        Screen('SetMovieTimeIndex', movieMov(Seeker(t,3)), 0);
        Screen('PlayMovie', movieMov(Seeker(t,3)), rate, 0, 0);
    elseif Seeker(t,2)==2 || Seeker(t,2)==4,
        Screen('DrawText', w,movieVerb{Seeker(t,3)},verbPosX(Seeker(t,3)),PosY);
    elseif Seeker(t,2)==5,
        Screen('DrawTexture', w, shapematchTex{Seeker(t,3)});
        shapeTMP=char(shapematchStim(Seeker(t,3)));
        if str2num(shapeTMP(1))==1,
           correctKey=buttonOne;
        elseif str2num(shapeTMP(1))==2,
           correctKey=buttonTwo;
        end;
    end;

    % Present Stimulus
    
   if Seeker(t,2)==1 || Seeker(t,2)==3    % present movie
       
       endMovie=0;
	 WaitSecs('UntilTime', anchor + Seeker(t,8));
       stimStart=GetSecs;
       while (endMovie<2)
            while(1)
                if (abs(rate)>0)
                    [tex] = Screen('GetMovieImage', w, movieMov(Seeker(t,3)), 1);
                    if tex<=0 | (maxTime > 0 && GetSecs - stimStart >= maxTime)
                        reactionTime=0;
                        endMovie=2;
                        break;
                    end;
                    Screen('DrawTexture', w, tex,[],dstRect);
                    Screen('DrawingFinished',w);
                    Screen('Flip', w);
                    Screen('Close', tex);
                end;
                % Has the user stopped with movie with an appropriate button press? 
                endMovie=0;
                [keyIsDown,secs,keyCode]=KbCheck;
                if (keyIsDown==1 && keyCode(buttonOne))
                    reactionTime=secs-stimStart;
                    endMovie=2;
                    Screen('PlayMovie', movieMov(Seeker(t,3)), 0);
                    Screen('CloseMovie', movieMov(Seeker(t,3)));
                    Screen('Flip', w);
                    break;
                end;
            end;
            if reactionTime==0,
                Screen('Flip', w);
                Screen('PlayMovie', movieMov(Seeker(t,3)), 0);
                Screen('CloseMovie', movieMov(Seeker(t,3)));
            end;
        end;
       actualStimulus{t}=movieName(Seeker(t,3));
       Seeker(t,10)=stimStart-anchor;
       Seeker(t,11)=reactionTime;

   else    % present text or catch stimulus
       Screen('Flip',w, anchor + Seeker(t,8));
       stimStart=GetSecs;
       Seeker(t,10)=stimStart-anchor;
       if Seeker(t,2)==2 || Seeker(t,2)==4,
           actualStimulus{t}=movieVerb(Seeker(t,3));
       else
           actualStimulus{t}=shapematchName(Seeker(t,3));
       end;
       while GetSecs - stimStart < Seeker(t,5), 
           [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown==1 && (keyCode(buttonOne) || keyCode(buttonTwo)),  
                Seeker(t,11)=secs-stimStart;
                if Seeker(t,2)==5,
                    Seeker(t,13)=keyCode(correctKey);
                end;                   
                Screen('DrawText',w,fixation,fixPosX,PosY);
                Screen('Flip', w);    
           end;
       end;
   end;
   
    % Present fixation cross during intertrial interval
    Screen('DrawText',w,fixation,fixPosX,PosY);
    Screen('Flip', w);
    noresp=1;
    if Seeker(t,11)==0,   % if they did not respond to stimulus, look for button press
       while GetSecs - anchor < Seeker(t,9),
       [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown==1 && (keyCode(buttonOne) || keyCode(buttonTwo)),  
                Seeker(t,11)=secs-stimStart;
                noresp=0;
                if Seeker(t,2)==5,                  
                    Seeker(t,13)=keyCode(correctKey);
                end;
           end;
       end;
    end
    WaitSecs('UntilTime', anchor + Seeker(t,9));
    
    % Should this trial be skipped in analysis? (i.e. because of no respose)
    if Seeker(t,11)==0,
       Seeker(t,12)=1;
    end;
   
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

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('showandtell_%d_run%d_order%d_%s_%02.0f-%02.0f.mat',subjectID,runNum,orderNum,date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','actualStimulus','subjectID','runNum','orderNum','verNum','triggerOFFSET'); % if give feedback, add:  'error', 'rt', 'count_rt',
catch
	fprintf('couldn''t save %s\n saving to act4_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% AFTER RUN 1, CHECK IN WITH SUBJECT
%---------------------------------------------------------------
if runNum==1,
    DrawFormattedText_new(w, 'The first run is over. If you are ready to begin the second run, press #1. If you have a question or concern, press #2.', 'center','center',white, 600, 0, 0);
    Screen('Flip',w);
    noresp=1;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
        if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo)),  
            noresp=0;
        end;
    end;
end;
if keyCode(buttonOne),
    fprintf('\n---------------------------');
    fprintf('\n-SUBJECT IS READY TO MOVE ON-');
    fprintf('\n---------------------------\n');
elseif keyCode(buttonTwo),
    fprintf('\n----------------------');
    fprintf('\n-SUBJECT HAS A QUESTION-');
    fprintf('\n----------------------\n');
end;

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;


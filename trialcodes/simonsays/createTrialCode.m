% CREATE TRIAL CODE (MNS Localizer)
clear all; clc;

% define scan information
nTrials=15;
numSlices=34;
TR=2;
% 12 trials - 2 events per trial - 5-7 secs between each trial
% Event 1 - watch him do it
% Event 2 - do it yourself
% Variable duration between event 1 and event 2
stimOrder=randperm(nTrials);

% Element 1
% cue = 1 sec
% stim = 6 sec max
% 2-5 sec variable interval
% Element 2
% 5 sec total
jitSample=[0:(TR/numSlices):4];
goodJit=0;
while goodJit==0,
    IDX=randperm(52);
    IDX=IDX(1:nTrials);
    ITI=jitSample(IDX)+5;
    IEI=jitSample(IDX)+2;
    if mean(ITI)==6 & mean(IEI)==3,
        goodJit=1;
    end;
end;

restBegin = 2;           % time before onset of first trial
restEnd = 6;                % time after offset of last trial

% initialize TRIALCODE variable
trialcode=zeros(nTrials,10);
trialcode(:,1)=1:nTrials;
trialcode(:,2)=stimOrder;
trialcode(:,3)=1;
trialcode(:,4)=5;
trialcode(:,5)=IEI;
trialcode(:,6)=5;
trialcode(:,7)=ITI;
trialcode(1,8)=restBegin;
trialcode(1,9)=restBegin+1;
trialcode(end,7)=restEnd;

for i=2:nTrials,
    trialcode(i,8)=sum(trialcode(i-1,3:8));
    trialcode(i,9)=trialcode(i,8)+1;
end;

for i=1:nTrials,
    trialcode(i,10)=sum(trialcode(i,[3 4 5 8]));
end;
save order.mat trialcode





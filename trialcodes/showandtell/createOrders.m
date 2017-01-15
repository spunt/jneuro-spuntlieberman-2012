% PRODUCE RANDOMLY JITTERED ONSET VECTOR
% This uses slice number and TR information, and produces an 
% approximately exponentially distributed sample of jitter values
clear all; clc;

% define scan information
numSlices=36;
TR=2;
% define durations
stimDur=5;
cueDur=2;
trialDur=stimDur+cueDur;
restBegin = 2;           % time before onset of first trial
restEnd = 6;                % time after offset of last trial
% define ITI information
meanITI=3;
minITI=2;
maxITI=5;
% define trial information (per run)
nTrials=60;

% condition order 

cd optimizedOrder
load ORDER
cd ..
%ORDER=Shuffle(cat(1,[ones(12,1)],[ones(12,1)*2],[ones(12,1)*3],[ones(12,1)*4],[ones(12,1)*5]));

% initialize TRIALCODE variable
trialcode=zeros(nTrials,9);
trialcode(:,1)=1:nTrials;
trialcode(:,2)=ORDER;
trialcode(:,4)=cueDur;
trialcode(1,7)=restBegin;
trialcode(1,8)=restBegin+cueDur;
trialcode(end,6)=restEnd;
% trialcode(1,1)=restBegin;

% define a vector of values representing jitter values
jitSample=[minITI:(TR/numSlices):maxITI];
jitSample=cat(2,jitSample,[minITI:(TR/numSlices):(maxITI-1)],[minITI:(TR/numSlices):(maxITI-2)],[minITI:(TR/numSlices):(maxITI-2)],[minITI:(TR/numSlices):(maxITI-2)]);
nSample=length(jitSample);

% find distribution of jitters with the desired mean
goodJit=0;
while goodJit==0,
    tempJit=Shuffle(jitSample);
    jitters=tempJit(1:59);
    if mean(jitters)==meanITI,
       goodJit=1;
    end;
end;
trialcode(1:end-1,6)=jitters;

% now define rest of trialcode
for i=1:nTrials,
     if trialcode(i,2)==5;
         trialcode(i,5)=3;
     else
         trialcode(i,5)=5;
     end;
end;

for i=2:nTrials,
    trialcode(i,7)=sum(trialcode(i-1,4:7));
    trialcode(i,8)=trialcode(i,7)+cueDur;
end;

for i=1:nTrials,
    trialcode(i,9)=sum(trialcode(i,4:7));
end;

% figure out trial orders

trialOrder=randperm(24)';
trialOrder1=trialOrder(1:12);
trialOrder2=trialOrder(13:24);

trialcode(find(trialcode(:,2)==5),3)=trialOrder1;
trialcode(find(trialcode(:,2)==4),3)=trialOrder1;
trialcode(find(trialcode(:,2)==3),3)=trialOrder2;
trialcode(find(trialcode(:,2)==2),3)=trialOrder2;
trialcode(find(trialcode(:,2)==1),3)=trialOrder1;

% tmp=randperm(12);
% tmpIDX1=tmp(1:6)';
% tmpIDX2=find(trialcode(:,2)==5);
% finalIDX=tmpIDX2(tmpIDX1);
% trialcode(finalIDX,2)=6;

save order1a.mat trialcode

for i=1:length(trialcode),
    if trialcode(i,2)==4,
       trialcode(i,2)=1;
    elseif trialcode(i,2)==3,
        trialcode(i,2)=2;
    elseif trialcode(i,2)==2,
        trialcode(i,2)=3;
    elseif trialcode(i,2)==1,
        trialcode(i,2)=4;
    end;
end;

trialcode(find(trialcode(:,2)==5),3)=trialOrder2;
trialcode(find(trialcode(:,2)==4),3)=trialOrder2;
trialcode(find(trialcode(:,2)==3),3)=trialOrder1;
trialcode(find(trialcode(:,2)==2),3)=trialOrder1;
trialcode(find(trialcode(:,2)==1),3)=trialOrder2;

save order2a.mat trialcode





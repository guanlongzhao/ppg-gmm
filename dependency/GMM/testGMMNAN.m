s=dbstatus;%retains break points
save('s.mat','s')
clear classes
load('s.mat','s')
dbstop(s);
close all
clc
dbstop if error
dbstop if warning

%test of missing data
%from their interspeech 2010 paper

%gather data
db=spk('C:\databases\rgo_ema\mat\');
db.populateDB(10,1,{'artData'});

feature='artData';
count=0;
for i=1:length(db.utterances)
    count=count+size(db.utterances(i).(feature),1);
end

temp=zeros(count,size(db.utterances(1).(feature),2));
left=1;
for i=1:length(db.utterances)
    right=left+size(db.utterances(i).(feature),1)-1;
    temp(left:right,:)=db.utterances(i).(feature);
    left=right+1;
end
[r,c]=find(isnan(temp));
temp(r,:)=[];%delete all rows with nan


%train gmm
mix = gmm(size(temp,2), 32, 'full');
options = foptions;
mix = gmminit(mix, temp, options);
options = foptions;
mix = gmmem(mix, temp, options);

%% test reconstruction
test=temp(2000:3000,:);
%%%for full row
% nanRow=8;
% test(:,nanRow)=NaN;
% P=~isnan(test);
%%%random deletion
P=rand(size(test));
P=P>.10;% 5 percent nan

[R,Rp,modes]=GMcondrec(test,mix.centres,mix.covars,mix.priors',P,100);

%% plots
% plot(temp(2000:3000,nanRow))
% hold on
% plot(R.cmean(:,nanRow),'r')
% plot(R.gmode(:,nanRow),'r')
% plot(R.cmode(:,nanRow),'r')
% s=fieldnames(R);
% plot(temp(2000:3000,nanRow))
% hold on
% for i=1:length(s)
%     plot(Rp.(s{i})(:,nanRow),'r');
% end

%% measure error

s=fieldnames(R);
x=test;
for i=1:length(s)
    t=abs(x-Rp.(s{i})).^2;
    t=sqrt(sum(t,2));
    mse(i)=mean(t);
end

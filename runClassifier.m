function [results]=runClassifier(zscorez,classification,subjects,labels,channels,cutOffCommonChannel,plotWeights,topFilter)
%NOTE - Full functionality is only available for the SVM, e.g. weights etc.
% Using correlation classifier with more caution as it has been less well
% road tested


%find unique identifiers
uniqueSubjects=unique(subjects);

%rename zscored patterns to patterns
patterns=zscorez;

clear zscorez
   
%get patterns for each label type; 
patternsCond1=patterns(labels==1,:);
patternsCond2=patterns(labels==-1,:);
   
%get subjects sorted by labels
subjCond1=subjects(labels==1,:);
subjCond2=subjects(labels==-1,:);
  
%make labels
labelCond1=labels(labels==1);
labelCond2=labels(labels==-1); 
        
%do for each subject
        for s=1:size(uniqueSubjects,1)
        
        %something in here to make sure list of subjects is same for cond 1 & 2?
   
        %make select test and training indicators
        subjectTest=uniqueSubjects{s};   
   
        subjectTestIndCond1=strcmp(uniqueSubjects{s},subjCond1);
        subjectTrainIndCond1=~strcmp(uniqueSubjects{s},subjCond1);
   
        subjectTestIndCond2=strcmp(uniqueSubjects{s},subjCond2);
        subjectTrainIndCond2=~strcmp(uniqueSubjects{s},subjCond2);
   
        %select train patterns
        trainPatCond1=patternsCond1(subjectTrainIndCond1,:);
        trainPatCond2=patternsCond2(subjectTrainIndCond2,:);
   
        %train labels
        trainLabelCond1=labelCond1(subjectTrainIndCond1);
        trainLabelCond2=labelCond2(subjectTrainIndCond2);
   
        %select test
        testPatCond1=patternsCond1(subjectTestIndCond1,:);
        testPatCond2=patternsCond2(subjectTestIndCond2,:);
   
        %test labels
        testLabelCond1=labelCond1(subjectTestIndCond1);
        testLabelCond2=labelCond2(subjectTestIndCond2);
   
        %summarise train
        meanTrainPatCond1=nanmean(trainPatCond1,1);
        meanTrainPatCond2=nanmean(trainPatCond2,1);
   
                if classification==1
   
                %select good channels    
                selectChannels=[meanTrainPatCond1;meanTrainPatCond2;testPatCond1;testPatCond2];
                goodChannel=intersect(find(~sum(isnan(selectChannels))>0),channels);
   
                %make mean pattern as training data
                finalTrainData=[meanTrainPatCond1;meanTrainPatCond2];
                finalTestData=[testPatCond1;testPatCond2];
   
                %train and test only selecting non-nan channels
                SVMModel = fitcsvm(finalTrainData(:,goodChannel),[1,-1],'KernelFunction','linear','Standardize',false);
                [label,score] = predict(SVMModel,finalTestData(:,goodChannel));
                
   
                %calculate results
                results.labels{s}=label;
                acc=sum(label==[1;-1]);
                results.correct(s)=acc;
                results.score{s}=score;
                results.noChannels{s}=length(goodChannel);
                results.whichChannel{s}=goodChannel;
                results.weightVector{s}=SVMModel.Beta;
                %display([subjectTest, ': N CH: ',num2str(length(goodChannel)),' : ',num2str(goodChannel), ' : ',num2str(acc)]);

                clear goodChannel acc SVMModel label score selectChannels finalTrainData finalTestData subject* train* test* mean*
   
   elseif classification==2
                
                %select good channels
                selectChannels=[meanTrainPatCond1;testPatCond1;meanTrainPatCond2;testPatCond2];
                goodChannel=intersect(find(~sum(isnan(selectChannels))>0),channels);
       
                %is correlation higher to mean pattern for condition 1 than to
                %condition 2 for test condition 1 etc.
                cond1_cong=corrcoef(meanTrainPatCond1(:,goodChannel),testPatCond1(:,goodChannel),'rows','pairwise');
                cond1_incong=corrcoef(meanTrainPatCond2(:,goodChannel),testPatCond1(:,goodChannel),'rows','pairwise');
                
                %correct prediction?
                if cond1_cong(1,2) > cond1_incong(1,2)
                cond1_acc=1;    
                else
                cond1_acc=0;  
                end
        
                cond2_cong=corrcoef(meanTrainPatCond2,testPatCond2,'rows','pairwise');
                cond2_incong=corrcoef(meanTrainPatCond1,testPatCond2,'rows','pairwise');
       
                if cond2_cong(1,2) > cond2_incong(1,2)
                cond2_acc=1;    
                else
                cond2_acc=0;  
                end
       
                results.totalCorrect(s)=sum([cond1_acc,cond2_acc]);
                results.noChannels{s}=length(goodChannel);
                results.whichChannel{s}=goodChannel;

                clear cond1_cong cond1_incong cond2_cong cond2_incong cond1_acc cond2_acc selectChannels goodChannel subject* train* test* mean*
                
               % display([subjectTest, ': N CH: ',num2str(length(goodChannel)),' : ',num2str(goodChannel), ' : ',num2str(results.totalCorrect(s))]);

                else
                    error('what classification?')
                end         
   
    end

if classification==1
results.totalCorrect=sum(results.correct);
results.total=size(labels,1);
results.propCorrect=sum(results.correct)./results.total;
results.binomialProbability = 1-binocdf(results.totalCorrect,results.total,0.5);

%get summary classifier weights by taking a set % that appear in all
%participants
getCommonChannels=[];
for zz=1:size(results.whichChannel,2)
getCommonChannels=[getCommonChannels,results.whichChannel{zz}];
end
whatChannels=unique(getCommonChannels);

%how frequently does each channel appear
for zz=1:length(whatChannels)
summaryChannels(zz)=sum(getCommonChannels==whatChannels(zz))/size(uniqueSubjects,1);
end

%which channels appear at greater than x proportion of subjects
getAboveCutOffChannels=whatChannels(summaryChannels>=cutOffCommonChannel);
dataWeights=[nanmean(patternsCond1);nanmean(patternsCond2)];

%train a model on the average data for cond 1 and 2 - only using the channels that appear x number of participants  
SVMModel = fitcsvm(dataWeights(:,getAboveCutOffChannels),[1,-1],'KernelFunction','linear','Standardize',false);

%get the weights of that model and multiply by the average pattern for each
%condition
results.betaWeights=SVMModel.Beta';
trainedCutOffWeights_cond1=SVMModel.Beta'.*dataWeights(1,getAboveCutOffChannels);
trainedCutOffWeights_cond2=SVMModel.Beta'.*dataWeights(2,getAboveCutOffChannels);

%final weight vector of interest
results.Cond1Cond2_Weights=[trainedCutOffWeights_cond1;trainedCutOffWeights_cond2];

%get positive Weights
[sortPosWeights pI]=sort(results.Cond1Cond2_Weights(1,:),'descend');
%gat a % from top
getValues=round((topFilter./100)*(length(pI)));
%select most important %
posW=sortPosWeights(1:getValues);
%get channel labels corresponing to column in excell sheet
indices1=getAboveCutOffChannels(pI);
%get top % of positive weights
topInd1=indices1(1:getValues);

%now the negative condition
[sortNegWeights nI]=sort(results.Cond1Cond2_Weights(2,:),'ascend');
negW=sortNegWeights(1:getValues);
indices2=getAboveCutOffChannels(nI);
topInd2=indices2(1:getValues);

if plotWeights==1
figure
imagesc(results.betaWeights);
colorbar
for i=1:length(getAboveCutOffChannels)
   text(i,1,num2str(getAboveCutOffChannels(i)));
   if mod(i,2)==0
   text(i,0.5,sprintf('%1.2f',results.betaWeights(i)));
   else 
   text(i,0.6,sprintf('%1.2f',results.betaWeights(i)));
   end
end
title('Raw Weight Values')

figure;
subplot(2,1,1)
imagesc(sortPosWeights);
colorbar;
for i=1:length(sortPosWeights)
    if mod(i,2)==0
   text(i,1,num2str(indices1(i)));
   text(i,0.5,sprintf('%1.2f',sortPosWeights(i)));
   
    else
    text(i,1,num2str(indices1(i))); 
    text(i,0.6,sprintf('%1.2f',sortPosWeights(i)));
    end
end
title('Weights x patterns - cond1')
hold on

subplot(2,1,2)
imagesc(sortNegWeights);
colorbar;
for i=1:length(sortNegWeights)
     if mod(i,2)==0
     text(i,1,num2str(indices2(i)));
     text(i,0.5,sprintf('%1.2f',sortNegWeights(i)));
     else
     text(i,1,num2str(indices2(i)));
     text(i,0.6,sprintf('%1.2f',sortNegWeights(i)));
     end
end
title('Weights x patterns - cond2')

figure;
subplot(2,1,1)
imagesc(posW);

for i=1:length(topInd1)
    if mod(i,2)==0
    text(i,1,num2str(topInd1(i))) 
    text(i,0.5,sprintf('%1.2f',posW(i)));    
    else
    text(i,1,num2str(topInd1(i))) 
    text(i,0.6,sprintf('%1.2f',posW(i))); 
    end
end
%colormap autumn

title('Top pos weights x Patterns - Cond 1')
colorbar
hold on
subplot(2,1,2)

imagesc(negW)

for i=1:length(topInd2)
    if mod(i,2)
    text(i,1,num2str(topInd2(i))); 
    text(i,0.5,sprintf('%1.2f',negW(i))); 
    else
    text(i,1,num2str(topInd2(i)));
    text(i,0.6,sprintf('%1.2f',negW(i))); 
    end
end

%colormap autumn
colorbar
title('Top neg weights x Patterns - Cond 2')
else
    
end
%store away sorted Weights
results.sortedPosWeightValues=posW;
results.sortedPosWeightInd=topInd1;
results.sortedNegWeightValues=negW;
results.sortedPosWeightInd=topInd2;

clear posW negW topInd1 topInd2 sortNegWeights sortPosWeights indices1 indices2 nI pI

elseif classification==2
    %no weights to plot
results.totalCorrect=sum(results.totalCorrect);
results.total=size(labels,1);
results.propCorrect=sum(results.totalCorrect)./results.total;
results.binomialProbability = 1-binocdf(results.totalCorrect,results.total,0.5);

else
error('what?')
end
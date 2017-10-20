function [results]=runClassifier(zscorez,classification,subjects,labels,channels,plotting)

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

elseif classification==2
results.totalCorrect=sum(results.totalCorrect);
results.total=size(labels,1);
results.propCorrect=sum(results.totalCorrect)./results.total;
results.binomialProbability = 1-binocdf(results.totalCorrect,results.total,0.5);

else
error('what?')
end
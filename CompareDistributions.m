clear all
close all

%get first dataset
[getFile,getPath]=uigetfile('*.mat','select data set 1');
load(getFile);
dataSet1=empiricalResults;
metaResults.file1=[getPath,'_',getFile];
clear empiricalResults getFile getPath

pause(0.5);

%get second dataset
[getFile,getPath]=uigetfile('*.mat','select data set 2');
load(getFile);
dataSet2=empiricalResults;
metaResults.file2=[getPath,'_',getFile];

clear empiricalResults getFile getPath

%get permutation distribution1
for i=1:size(dataSet1.permutationsData,2)
    extractDistDataSet1(i)=dataSet1.permutationsData(i).results.propCorrect;
end

%get permutation distribution2
for i=1:size(dataSet2.permutationsData,2)
    extractDistDataSet2(i)=dataSet2.permutationsData(i).results.propCorrect;
end

%get a permutation difference distribution centred around 0
for i=1:size(dataSet1.permutationsData,2)
   nullDifferenceDistribution(i)=extractDistDataSet1(i)-extractDistDataSet2(i);
end

%find out the difference in classification with the real data
empiricalDifference=dataSet1.propCorrect-dataSet2.propCorrect;

%make a figure
figure;
%should be distributed around 0
hist(nullDifferenceDistribution,length(nullDifferenceDistribution));hold on
[oc v]=hist(nullDifferenceDistribution,length(nullDifferenceDistribution));
line(repmat(empiricalDifference,1,max(oc)+1),0:max(oc),'color','r','LineWidth',4)
xlabel('Prop correct')
ylabel('observations')


%work out the rank and assoicated p value

%add the observed value into the distribution - e.g. 100 randomisation
%becomes 101
combine=[empiricalDifference,nullDifferenceDistribution];
%sort them
sortedValues=sort(combine,'descend');

%take the absolute value
metaResults.absDist=abs(combine);
%take the absolute value of observed result (e.g. actual data)
metaResults.absValue=abs(empiricalDifference);

%sort the absolute value of the difference distribution
sortedValues=sort(metaResults.absDist);

%how many difference values are greater than or equal to the observed
%value?
metaResults.rank=sum(sortedValues>=metaResults.absValue);

%make into a percentage with +1 distribution
metaResults.prob=metaResults.rank/length(metaResults.absDist);

%store null difference distribution and the observed difference
metaResults.nullDifferenceDistribution=nullDifferenceDistribution;
metaResults.empiricalDifference=empiricalDifference;

figure;
%should be distributed around 0
hist(sortedValues,length(sortedValues));hold on
[oc v]=hist(sortedValues,length(sortedValues));
line(repmat(metaResults.absValue,1,max(oc)+1),0:max(oc),'color','r','LineWidth',4)
xlabel('Prop correct')
ylabel('observations')

%get name for analysis
analysisTag=input('Analysis name? ','s');

%get time
timez=clock;

%save it out
saveFileName=[analysisTag,'_',date,'_',num2str(timez(3)),'_',num2str(timez(2)),'_',num2str(timez(1)),'_',num2str(timez(4)),'_',num2str(timez(5)),'.mat'];

save(saveFileName,'metaResults');

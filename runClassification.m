clear all;
close all;

%load file
[getFile,getPath]=uigetfile('*.csv','select your data');
extractData=importdata([getPath,'/',getFile]);

%get info from user
z_method=input('z-scoring?, 0=off,1=by trial,2=by channel,3=both?  ');
plotting=input('Visualise the pattern?   ','s');
classification=input('SVM or correlation classifier? 1=SVM, 2=Correlational ');
channels=input('Select channels (NB. if no data in channel these will be dropped out) :');
%channels=[16 17 19 31 32 33];

perms=input('No. of permutations ');

%get patterns, labels and subject information
patterns=extractData.data(:,1:end-1);
labels=extractData.data(:,end);
subjects=extractData.rowheaders;

%z score data - make sure check diff zscore types work
[zscorez]=classificationZScore(patterns,z_method);

clear patterns

if strcmp(plotting,'y')  
plot_patterns(zscorez,labels,channels)
else
end

%empirical classification
[results]=runClassifier(zscorez,classification,subjects,labels,channels,plotting);
empiricalResults=results;
clear results;

for p=1:perms
%permuted classification to establish null
%permute pattern
[permuted_pattern]=runPermute(zscorez,subjects,labels);
permutations(p).pattern=permuted_pattern;

%send to classifier
[results]=runClassifier(permuted_pattern,classification,subjects,labels,channels,plotting);

permutations(p).results=results;
dist(p)=results.propCorrect;
clear permuted_pattern results
end

display(['Empirical Proportion correct: ',num2str(empiricalResults.propCorrect)])
display(['Empirical Binomical test, p: ',num2str(empiricalResults.binomialProbability)])

combine=[empiricalResults.propCorrect,dist];
sortedValues=sort(combine,'descend');
%take least optimistic in case of ties
rank_empiricalValue=max(find(sortedValues==empiricalResults.propCorrect));
prob_empiricalValue=rank_empiricalValue./(length(combine)-1);

display(['Ranked value: ',num2str(rank_empiricalValue)]);
display(['Permuted labels, p: ',num2str(prob_empiricalValue)]);

ch=input('Do you want to see channel info? y/n ','s');

if strcmp(ch,'y')

for i=1:size(empiricalResults.noChannels,2)
   display(['no. chs: ',num2str(cell2mat(empiricalResults.noChannels(i))),' ; which : ',num2str(cell2mat(empiricalResults.whichChannel(i)))])
end
else
display('declined :)')
end

if strcmp(plotting,'y')  
figure
hist(dist,length(dist));
hold on
[oc v]=hist(dist,length(dist));
line(repmat(empiricalResults.propCorrect,1,max(oc)+1),0:max(oc))
xlabel('Prop correct')
ylabel('observations')
else
end
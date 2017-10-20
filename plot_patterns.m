function plot_patterns(zscorez,labels,channels)

label1=nanmean(zscorez(labels==1,:));
label2=nanmean(zscorez(labels==-1,:));
viewz=[label1;label2];
goodChannel=intersect(find(~sum(isnan(viewz))>0),channels);


figure;
imagesc(viewz(:,goodChannel))
xlabel('Channels')
ylabel('Conditions')
colorbar







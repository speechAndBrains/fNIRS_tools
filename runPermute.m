function [permuted_pattern]=runRandomClassifier(zscorez,subjects,labels)

%find unique identifiers
uniqueSubjects=unique(subjects);
getSubs=size(uniqueSubjects,1);

    %totally randomise eveything
     s=RandStream('mt19937ar','Seed',0);
     
    patterns1=zscorez(labels==1,:);
    patterns2=zscorez(labels==-1,:);
     for ss=1:getSubs
        yy=randperm(length(unique(labels)));
        ind(ss,:)=yy;
        clear yy
    end

    permPattern1=[];
    permPattern2=[];

for pp=1:size(ind,1)

    if ind(pp,1)==1
    permPattern1=[permPattern1;patterns1(pp,:)];
    elseif ind(pp,1)==2
    permPattern1=[permPattern1;patterns2(pp,:)];
    end
   
    if ind(pp,2)==1
    permPattern2=[permPattern2;patterns1(pp,:)];
    elseif ind(pp,2)==2
    permPattern2=[permPattern2;patterns2(pp,:)];
    end
end



    permuted_pattern=[permPattern1;permPattern2];
end
   
   
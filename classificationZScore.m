function [zscorez] = classificationZScore(patterns,z_method)

%choose z scoring method
if z_method==0
     
        %do nothing 
        zscorez=patterns;  
   
elseif z_method==1
         
            %get rows
                for r=1:size(patterns,1)
                %calculate mean and std of rows ignoring nans
                xmean=nanmean(patterns(r,:));
                xstd=nanstd(patterns(r,:));
                        %generate new pattern zscoring by row summaries
                        for c=1:size(patterns,2)
                        zscorez(r,c) = (patterns(r,c) - xmean)/xstd;
                        end
                        
                        clear xmean xstd
                end
       
elseif z_method==2
            %get columns
            for c=1:size(patterns,2)
            %calculate mean and std of columns ignoring nans
            xmean=nanmean(patterns(:,c));
            xstd=nanstd(patterns(:,c));
            
                        %generate new pattern zscoring by column summaries                       
                        for r=1:size(patterns,1)
                        zscorez(r,c) = (patterns(r,c) - xmean)/xstd;
                        end
                        
                        clear xmean xstd
            end
            
elseif z_method==3
   %start with columns
            for c=1:size(patterns,2)
            %calculate mean and std of columns ignoring nans
            xmean=nanmean(patterns(:,c));
            xstd=nanstd(patterns(:,c));   
            
                        %generate new pattern zscoring by column summaries                       
                        for r=1:size(patterns,1)
                        zscorez(r,c) = (patterns(r,c) - xmean)/xstd;
                        end
                        
                        clear xmean xstd
            end
     
            clear patterns;
            patterns=zscorez;
            clear zscorez
       
            for r=1:size(patterns,1)
                        
                %calculate mean and std of rows ignoring nans
                xmean=nanmean(patterns(r,:));
                xstd=nanstd(patterns(r,:));
                       
                %generate new pattern zscoring by row summaries
                 for c=1:size(patterns,2)
                 zscorez(r,c) = (patterns(r,c) - xmean)/xstd;
                 end
        
                 clear xmean xstd
            end
             
else
            
            error('incorrect choice for z-scoring')
end
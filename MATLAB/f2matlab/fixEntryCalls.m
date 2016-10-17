% Fix entry's
for ii=find(~cellfun('isempty',allEntrys))
 %for ii=1:length(allEntrys)
 if ~isempty(allEntrys{ii})
  temp3=regexp(funstr,['\]=',fun_name{ii},'\('],'end');
  temp1=find(~cellfun('isempty',temp3));
  for jj=temp1(:)'
   if isempty(strfind(funstr{jj},'whichEntry'))
    funstr{jj}=[funstr{jj}(1:temp3{temp1(1)}),'1,',funstr{jj}(temp3{temp1(1)}+1:end)];
   end % if isempty(strfind(funstr{jj},
  end % for temp1
  
  for kk=1:length(allEntrys{ii})
   [temp4,temp3]=regexp(funstr,['\]=',allEntrys{ii}{kk},'\('],'start','end');
   temp1=find(~cellfun('isempty',temp3));
   for jj=temp1(:)'
    if isempty(strfind(funstr{jj},'whichEntry'))
     funstr{jj}=[funstr{jj}(1:temp4{jj}-1),']=',fun_name{ii},'(',num2str(kk+1),',',funstr{jj}(temp3{jj}+1:end)];
    end % if isempty(strfind(funstr{jj},
   end % for temp1   
  end % for kk=1:length(allEntrys{ii})

  %'eeeeeeentrys',funstr,kb  
  
 end % if ~isempty(allEntrys{ii})
end % for ii=1:length(allEntrys)
 
 
 
 
 
 
 
  
 

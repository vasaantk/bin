function IOlist=readWriteIOlist(varIn,RW)
 
 IOlist={};
 
 for ii=1:length(varIn)
  if iscell(varIn{ii}) %an implied do loop, make a list
   cl=length(varIn{ii});
   %if there is a cell inside this, then it is a nested list
   if any(cellfun('isclass',varIn{ii},'cell'))
    IOlist={IOlist{:},readWriteIOlist(varIn{ii},RW)};
   else
%%%    IDL(1)=evalin('caller',varIn{ii}{end-2});
%%%    IDL(2)=evalin('caller',varIn{ii}{end-1});
%%%    IDL(3)=evalin('caller',varIn{ii}{end  });
%%%
%%%    IDL(3)=evalin('caller','evalin(''caller'',''a2'')');

    for jj=num2str(varIn{ii}{cl-2}):num2str(varIn{ii}{cl-1}):num2str(varIn{ii}{cl})
     for k=1:cl-4
       IOlist={IOlist{:},regexprep(varIn{ii}{k},['\<',varIn{ii}{cl-3},'\>'],sprintf('%d',jj))};
     end % for kk=1:cl-4
    end
   end % if any(cellfun('isclass',
  end
 end % for ii=1:length(varIn)

end 

 
 
 
 
 
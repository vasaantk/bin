function [out,outbefore,outafter]=getTopLevelStrings(str,loc,tofind,i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)

%This routine is trying to find tofind's that are on the top level 
%  and not in a string, (), []

out=[];

temp=findstr(funstr{i},tofind);

%'ttttt1',temp,keyboard

for ii=1:length(temp)
 if temp(ii)==length(funstr{i})
  out=[out,temp(ii)];
 else
  [outflag,howmany,subscripts,centercomma,parens]=inwhichlast_f(i,temp(ii),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
  if outflag==0
   %if in a /   / then no. ?????
   % if it is in a string, then no
   if validSpot(str,temp(ii))
    out=[out,temp(ii)];
   end
%%%  elseif outflag==1
%%%   temp1=find(~isspace(funstr{i}));
%%%   if ~any(temp1(find(temp1<parens(1),1,'last'))==funstrwords_e{i})
%%%    out=[out,temp(ii)];
%%%   end
  
%%%   if strcmp(tofind,'dai')
%%%     funstr{i},temp1,';;;;;;;',kb
%%%    end
  
  end
 end % if inwhichlast_f(i,
end % for ii=1:length(temp)


outbefore=out(out<loc);
if ~isempty(outbefore), outbefore=outbefore(end); else, outbefore=0; end

outafter=out(out>loc);
if ~isempty(outafter), outafter=outafter(1); else, outafter=length(funstr{i}); end



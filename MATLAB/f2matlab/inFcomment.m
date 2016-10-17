function out=inFcomment(str,locs,f77or90)

%%%out=false(1,length(locs));
%%%temp=find(str=='%');
%%%if ~isempty(temp)
%%% temp=min(temp(~inastring_f(str,temp)));
%%% if ~isempty(temp)
%%%  for ii=1:length(locs)
%%%   if temp<=locs(ii)
%%%    out(ii:end)=true;
%%%    break
%%%   end
%%%  end
%%% end
%%%end
%%%
%%%
%%%

% if f77or90 is 0, then f77 style

out=false(1,length(locs));

temp=find(str=='!');
for jj=1:length(temp)
 if jj==1 && temp(1)==1
  out(:)=true;
  break
 else
  temp1=inastring_f(str,temp(jj)) || inaDQstring_f(str,temp(jj));
  if ~temp1
   out(locs>=temp(jj))=true;
   break
  end
 end
end


if (strcmpi(str(1),'c')|(strcmpi(str(1),'d')&&isempty(regexpi(str,'^data')))) & ~f77or90
 out(:)=true;
end

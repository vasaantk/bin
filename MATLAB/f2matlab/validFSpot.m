function out=validFSpot(str,loc,f77or90)

% if f77or90 is 0, then f77 style

if nargin<3
 f77or90='!'; %f77, so a "c" on column 1 is a comment
              %f77or90=0; %f77, so a "c" on column 1 is a comment
end
isml=0;
if ischar(f77or90)
 if f77or90=='!'
  f77or90=1;
 else
  if f77or90=='%'
   isml=1;
  end
  f77or90=0;
 end % if f77or90=='!'
end


for i=1:length(loc)
 out(i)=~incomment(str,loc(i)) && ~inastring_f(str,loc(i)) && ~inaDQstring_f(str,loc(i)) &&...
        (~inFcomment(str,loc(i),f77or90 | isml));
end
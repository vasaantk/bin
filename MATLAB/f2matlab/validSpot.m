function out=validSpot(str,loc,commentMarker)

if nargin<3, commentMarker='%'; end

for i=1:length(loc)
 out(i)=~incomment(str,loc(i),commentMarker) && ~inastring_f(str,loc(i)) && ~inaDQstring_f(str,loc(i));
end
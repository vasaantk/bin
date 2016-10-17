function out=inastring_f(str,loc)


str_orig=str;
out=[];

for i=1:length(loc)
 str=str_orig;
 str(loc(i))='='; %so loc doesn't count if it is a '
 temp=str=='''';
 temp1=cumsum(temp);
 out(i)=temp1(loc(i))/2 ~= round(temp1(loc(i))/2);
end




% this doesn't parse matlab correctly because of the transpose single quote.
%%%str(loc)='='; %so loc doesn't count if it is a '
%%%temp=str=='''';
%%%temp1=cumsum(temp);
%%%out=temp1(loc)/2 ~= round(temp1(loc)/2);
%'ooooo',kb
%this should work unless there are transform() commands in the fortran


% Now if there is an odd situation of an unterminated string in this line, there is a problem.
%  Consider:
%
%   call erprnt(1,1,1,iza(l),0,0,0,0,'29hCannot recognize isotope           !/*mt7c       11*/
%   &zaid,i6')                                                                 !/*mt7c       12*/
%
% so for these cases, call it not in a string????
%%%if ~isempty(out) && temp1(end)/2~=round(temp1(end)/2);
%%% out=~(out & temp1(loc)==temp1(end));
%%%end







%Well this misses things like write(*,*)'str', problem is, there shoudl be difference in quote interp
%between fortran and ml sources, sooooo

%%%%these can start a quote, or they could end, but they will not be a transpose
%%%% borrowed from matlab.el
%%%[strStart_b,strStart_e]=regexp(str,'(^''|[^\]\}\)a-zA-Z0-9_.]'')','start','end');
%%%[strEnd_b,strEnd_e]=regexp(str,['(''[^''\n\r]*(''''[^''\n\r]*)*'')([^'']|$)'],'start','end');
%%%%have to match up
%%%temp=zeros(1,length(str));
%%%good=ismember(strEnd_b,strStart_e);
%%%temp(strEnd_b(good))=1;
%%%temp(strEnd_e(good)-1)=-1;
%%%out=logical(cumsum(temp));
%%%out=out(loc);











%%%'ooooooo',kb
%%%
%%%a=['''a''''b.''c)''d].''e}''']
%%%'a''b.'c)'d].'e}'
%%%a=['''a''''''b.''c)''d].''e}''']
%%%'a'''b.'c)'d].'e}'
%%%a=['1-2''a''''''b.''c)''d].''e}''']
%%%1-2'a'''b.'c)'d].'e}'
function [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,oneline,fs_goodHasAnyQuote)

s=length(funstr);
if nargin<4
 fs_goodHasAnyQuote=zeros(1,s);
end
%%%if any(strfind(version,'R14')) %& 0 %0.d0 returns d0 as a word for this regexp version !
getNumstrWordstr
lo=oneline;hi=oneline;
ind=oneline;
empty=isempty(funstr{ind});
bad1=strncmp(funstr{ind},'!',1);
bad2=strncmp(funstr{ind},'%',1);
%%%empty=cellfun('isempty',{funstr{ind}});
%%%bad1=strncmp({funstr{ind}},'!',1);
%%%bad2=strncmp({funstr{ind}},'%',1);
%if any(bad1|bad2), kb, end
good=~(empty|bad1|bad2);%|force;

if ~isempty(regexp(funstr{ind},['[''"!%]'],'once'))
 fs_goodHasAnyQuote(oneline)=1;
end % if ~isempty(regexp(funstr{ind},

if ~good
 fs_good=fs_good(fs_good<lo|fs_good>hi);
%%% fs_goodHasAnyQuote=fs_goodHasAnyQuote(fs_goodHasAnyQuote<lo|fs_goodHasAnyQuote>hi);
else
 if ~any(fs_good==ind)
  fs_good=[fs_good(fs_good<lo),ind,fs_good(fs_good>hi)];
 end
%%% if ~isempty(regexp(funstr{ind},['[''"]'],'once'))
%%%  fs_goodHasAnyQuote=[fs_goodHasAnyQuote(fs_goodHasAnyQuote<lo),ind,fs_goodHasAnyQuote(fs_goodHasAnyQuote>hi)];
%%% end % if ~isempty(regexp(funstr{ind},
 goodind=ind;
 [funnum1,funnum2,funnum3]=regexp(funstr{goodind},numstr,'match','start','end');
 assignin('caller','goodind',goodind);
 assignin('caller','funpart',funnum1);
 evalin('caller','funstrnumbers{goodind}=funpart;')
 assignin('caller','funpart',funnum2);
 evalin('caller','funstrnumbers_b{goodind}=funpart;')
 assignin('caller','funpart',funnum3);
 evalin('caller','funstrnumbers_e{goodind}=funpart;')
 [funword1,funword2,funword3]=regexp(funstr{goodind},wordstr,'match','start','end');
 assignin('caller','funpart',funword1);
 evalin('caller','funstrwords{goodind}=funpart;')
 assignin('caller','funpart',funword2);
 evalin('caller','funstrwords_b{goodind}=funpart;')
 assignin('caller','funpart',funword3);
 evalin('caller','funstrwords_e{goodind}=funpart;')
 %'fffsssssssssss',keyboard
end

%should I get rid of empty lines?
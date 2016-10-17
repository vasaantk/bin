function  funstr=filestr2funstr_2(filestr,ForM,want_rc,justifyTO,changeComment);

% function  funstr=filestr2funstr(filestr,ForM,want_rc);
%   note that this really assumes a free-form file
%
%   converts filestr to funstr
%
%   ForM =1, file is fortran, ForM=0 is matlab (not implemented)
%
%   want_rc is 0 ==> Do nothing with continuations (default)
%
%   want_rc is 1 ==> remove continuations to make long lines (closest to fortran)
%
%   want_rc is 2 ==> remove continuations to make long lines, 
%                    removes whitespace preceeding as well as after &'s
%
%   justifyTO => line length to justify to, default is no justifcation
%                  (for no justification, justify => inf or zero)
%
%   changeComment is 1 => change the comment marker to '%' or 0 for no change
%
%
%inCont key:
%
% positive number => location of valid & continution
% -1 => empty line in a continuation
% -2 => full comment in a continuation
% less than 200000 => full comment not in a continuation (-200001 for ! at location 1)
% less than 100000 => -(number+10000) is the location of the ! for a comment after other code
%
% inCont means that the next line is part of the line

if nargin<3
 want_rc=0;
end % if nargin<3
if nargin<4
 justifyTO=inf;
end % if nargin<4
if nargin<5
 changeComment=0;
end

r=char(10);
if ~strcmpi(filestr(length(filestr)),r), filestr=[filestr,r]; end

funstr=strread(filestr,'%s','delimiter',r,'whitespace','');
funstr=strtrim(funstr);

%determine lines that are in a continuation
inCont=findConts(funstr);


% get rid of blank lines in continueations
temp5=find(cellfun('isempty',funstr));
foo1=intersect(temp5,find(inCont==-1));
ind=[1:length(funstr)];
foo2=setdiff(ind,foo1);
funstr=funstr(foo2);
inCont=inCont(foo2);

%move comments after continuations up
for ii=fliplr(find(inCont(:)'>0))
 %funstr{ii}
 foo2=nextNonSpace(funstr{ii},inCont(ii));
 if foo2<=length(funstr{ii})
  if funstr{ii}(foo2)=='!'
   % switch them around
   funstr=[funstr(1:ii-1);funstr{ii}(foo2:end);strtrim(funstr{ii}(1:foo2-1));...
           funstr(ii+1:end)];
   inCont=[inCont(1:ii-1),0,inCont(ii:end)];
  end % if funstr{ii}(foo2)=='!'
 end % if nextNonSpace(funstr{ii},
end % for ii=1:length(funstr)

%now move the comments at the end of any nonContinuation line up
for ii=fliplr(find( inCont(:)'<(-100000) & inCont(:)'>(-200000) ))
 ind=-(inCont(ii)+100000);
 funstr=[funstr(1:ii-1);funstr{ii}(ind:end);...
           funstr{ii}(1:ind-1);funstr(ii+1:end)];
 %inCont=[inCont(1:ii-1),0,inCont(jj+1:ii-1),inCont(ii+1:end)];
end % for ii=(find( inCont(:)'<(-100000) & inCont(:)'>(-200000) ))

inCont=findConts(funstr);

% move full line comments up as well
for ii=(find(inCont(:)'==-2))
 %'huuuuuuuuuuuuu222',ii,funstr{ii},kb
 for jj=ii-1:-1:1
  if inCont(jj)==0
   funstr=[funstr(1:jj);funstr{ii};funstr(jj+1:ii-1);funstr(ii+1:end)];
   inCont=[inCont(1:jj),0,inCont(jj+1:ii-1),inCont(ii+1:end)];
   break
  end % if inCont(jj)==0
 end % for jj=ii-1:1
end % for ii=find(inCont(:)'==-2)

%'huuuuuuuuuuuuu',kb

% Now remove the continuations themselves
keep=ones(1,length(funstr));
if want_rc
 for ii=length(funstr):-1:1
  foo1=regexp(funstr{ii},'^\s*&');
  if ~isempty(foo1)
   if want_rc==1
    funstr{ii}=funstr{ii}(foo1+1:end);
   elseif want_rc==2
    foo2=nextNonSpace(funstr{ii},foo1);
    funstr{ii}=funstr{ii}(foo2:end);
   end % if want_rc==1
  end % if ~isempty(foo1)
  if inCont(ii)>0
   if want_rc==1
    funstr{ii}=[funstr{ii}(1:end-1),funstr{ii+1}];
   elseif want_rc==2
    foo2=lastNonSpace(funstr{ii},length(funstr{ii}));
    foo3=nextNonSpace(funstr{ii+1},0);
    funstr{ii}=[funstr{ii}(1:foo2),funstr{ii+1}(foo3:end)];
   end % if want_rc==1
   keep(ii+1)=0;
  end % if ~isempty(foo1)
 end % for ii=length(funstr):-1:1
end % if want_rc
funstr=funstr(find(keep));

% switch the comments to matlab style if desired (should all start at location 1)
if changeComment
 funstr=regexprep(funstr,'^\s*!','%');
end % if changeComment

% justify if requested
if justifyTO && ~isinf(justifyTO)
 funstr=justify_funstr(funstr,justifyTO);
 %filestr=justify_rg(filestr,justifyTO,1);
end % if justifyTO && ~isinf(justifyTO)






function inCont=findConts(funstr)
% what lines are in continutations?
inCont=zeros(1,length(funstr));
temp0=regexp(funstr,['&']);
temp1=find(~cellfun('isempty',temp0));
for ii=temp1(:)'
%%% if ~isempty(strfind(funstr{ii},'nsatpres, ofirstsatpres, olastsatpres'))
%%%  funstr,funstr{ii},kb
%%% end
 for jj=length(temp0{ii}):-1:1
  if temp0{ii}(jj)~=1
   %this test already has the quote tests in it
   if ~incomment(funstr{ii},temp0{ii}(jj),'!') && (length(funstr{ii})>0 && funstr{ii}(1)~='%')
    % We might be in string, or might be continuing a string
    goon=0;
    if ii>1 && inCont(ii-1)>0 && mod(length(find(funstr{ii-1}(1:inCont(ii-1))=='''')),2)==1 && mod(length(find(funstr{ii}(1:temp0{ii}(jj))=='''')),2)==0
     goon=1;
    end
    if inastring_f(funstr{ii},temp0{ii}(jj)) || inaDQstring_f(funstr{ii},temp0{ii}(jj)) || goon
     if funstr{ii}(end)=='&' % in a string, but the & is at the end of the line, so in cont
      inCont(ii)=temp0{ii}(jj);
     end
    else %not in a comment, not in a string, so this is a continuation
     inCont(ii)=temp0{ii}(jj);
    end
    break
   end
  end
 end
 % There may be more continuation lines after this one
 if inCont(ii)
  for jj=ii+1:length(funstr)
   % the next line is empty, so it counts as a cont line
   if isempty(funstr{jj})
    inCont(jj)=-1;
    continue
   end
   % first character is a ! or % so it counts, too
   if funstr{jj}(1)=='!' || funstr{jj}(1)=='%'
    inCont(jj)=-2;
    continue
   end % if funstr{jj}(1)
   if inCont(jj)==0
    break
   end % if inCont(jj)==0
  end % for jj=ii+1:length(funstr)
 end % if inCont(ii)
end % for ii=temp1(:)'

% Find the locations of the bang in the line
temp0=regexp(funstr,['!']);
temp1=find(~cellfun('isempty',temp0));
for ii=temp1(:)'
 if ~inCont(ii)
  for jj=1:length(temp0{ii})
   if temp0{ii}(jj)>1
    if ~(inastring_f(funstr{ii},temp0{ii}(jj))||inaDQstring_f(funstr{ii},temp0{ii}(jj))) &&...
         funstr{ii}(1)~='&'
     inCont(ii)=-temp0{ii}(jj)-100000; break
    end % if ~(inastring_f(funstr{ii},
   else
    inCont(ii)=-temp0{ii}(jj)-200000; break
    break
   end % if ~(inastring_f(funstr{ii},
  end % for jj=1:length(temp0{ii})
 end % if ~inCont(ii)
end % for ii=temp1(:)'




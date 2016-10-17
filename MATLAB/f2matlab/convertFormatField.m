function out=convertFormatField(in,firstOrLast,isString)
global sp
sp='';
%this changes the fortran format field into the fprintf equivalent
%%%if ~isempty(strfind(in,'dates'))
%%% 'aaaaaaaaaaaa',in,length(in),kb
%%%end

if nargin<3, isString=0; end
if exist('firstOrLast','var') && ischar(firstOrLast) && strcmpi(firstOrLast,'r')
 isread=1; firstOrLast=0;
else
 isread=0;
end
if nargin<2, firstOrLast=0; end

out='';
inorig=in;
in=strtrim(in);
%in(in=='"')='''';
if any(strcmpi(in,{'sp','ss'}))
 %do nothing for now...
 return
end

%%%if ~isempty(strfind(in,'ii'))
%%% 'iiiiiiiiiiiiii',in,kb
%%%end

temp2=find(in=='>',1,'first');
if ~isempty(temp2)
 if ~inastring_f(in,temp2)
  in=[in(1:temp2),'(',in(temp2+1:end),')'];
 end % if ~inastring_f(in,
end % if ~isempty(temp2)
if any(in=='(') % we have a recursive definition
                %'aaaaaaaa1112',in,kb
 temp=find(in=='(');
 temp2=find(in=='>',1,'last');
 if ~isempty(temp2)
  if ~inastring_f(in,temp2)
   temp=temp(find(temp>temp2,1,'first'));
  end
 else
  temp=temp(1);
 end
 if ~inastring_f(in,temp) & ~inastring2_f(in,temp)
  rs='1';
  %'eeeeeeeee',in,keyboard
  if ~isempty((in(1:temp-1)))
   rs=(strrep(strrep(in(1:temp-1),'<',''),'>',''));
   %rs=str2num(strrep(strrep(in(1:temp-1),'<',''),'>',''));
  end
  tempr=findrights_f(temp,in);
  groups=getTopGroupsAfterLoc(in(temp+1:tempr-1),0);
  groupsStr='';
  for ii=1:length(groups)
   temp1=',';if ii==length(groups), temp1='';end
   if ii==1 | ii==length(groups)
    groupsStr=[groupsStr,convertFormatField(groups{ii},1),temp1];
   else
    groupsStr=[groupsStr,convertFormatField(groups{ii}),temp1];
   end
  end
  groupsStr=['[',groupsStr,']'];
  out=['repmat(',groupsStr,' ,1,',(rs),')'];
  %out=['repmat(',groupsStr,' ,1,',num2str(rs),')'];
  %'rrrrrrrrrrr',groups,groupsStr,out,kb
  return
 end
end

%',,,,,,,,,,,,,,,',in,out,kb
% first thing to do is to determine if it's a string
if any(in=='''') | isString
 out=in;
 if length(out)>2
  if strcmp(out(1:2),'''''')
   if ~strcmp(out(3),'''')
    out=out(2:end);
   end
  end
  % actually test the last 2 non white space, non / characters
  temp3=find(~isspace(out) & out~='/') ;
  if temp3(end)>2
   if strcmp(out(temp3(end)-1:temp3(end)),'''''')
    if ~strcmp(out(temp3(end)-2),'''')
     out=[out(1:temp3(end)-1),out(temp3(end)+1:end)];
    end
   end
  end
 end
else %OK, it's not a string
 
 %'errrrrrrrrrrr',in,out,keyboard
 %does it have a letter in it?
 % also fix the slashes to have commas in between them and call recursively
 
 if any(isletter(in))
  letterLoc=find(isletter(in));
  %move the p spec to the end
  if strcmpi(in(letterLoc(1)),'p')
   in=[in(letterLoc(1)+1:end),'p',in(1:letterLoc(1)-1)];
   letterLoc=find(isletter(in));
   %'aaaaaaaaa',kb
  end % if any(strcmpi(in(letterLoc),
  %does it have a repeat specification
  rs=[];
  if letterLoc>1
   rs=num2str(in(1:letterLoc-1));
  end
  b1=find(in=='<',1,'first');
  if ~isempty(b1)   b2=find(in=='>',1,'first');  rs=in(b1+1:b2-1);  end
  
  letters=find(isletter(in));
  letterSpec=in(letters(1));
  rest2='';
  if length(letters)==2 && strcmpi(in(letters(2)),'p')
   rest =in(letters(1)+1:letters(2)-1);
   rest2=in(letters(2):end);
  else
   rest=in(letters(end)+1:end);
  end
  preOut='';
  postOut='';
  %'errrrrrrrrrrr111',in,out,keyboard
  if ~isempty(rs)
   preOut='repmat(';
   postOut=[',1,',rs,')'];
  end
  switch letterSpec
    case {'l','L'}
      out=[preOut,'''%',rest,'l','',sp,'''',postOut];
    case {'t','T'}
      out=[preOut,'''%',rest,'t','',sp,'''',postOut];
    case {'x','X'}
      out=['''%',rs,'x',''''];
      %out=[preOut,''' ''',postOut];
    case {'f','F'}
      out=[preOut,'''%',rest,'f',rest2,'',sp,'''',postOut];
    case {'g','G'}
      out=[preOut,'''%',rest,'g','',sp,'''',postOut];
    case {'e','E','d','D'}
      out=[preOut,'''%',rest,lower(letterSpec),rest2,'',sp,'''',postOut];
%%%    case {'e','E','d','D'}
%%%      out=[preOut,'''%',rest,'f','',sp,'''',postOut];
    case {'h','H'}
      %in,'kkkkkkkkkkkkkk',kb
      out=['''',sp,'',in(letters(1)+1:end),''''];
    case {'a','A'}
%%%      if ~isempty(rs)
       out=[preOut,'''%',rest,'c','',sp,'''',postOut];
%%%      else
%%%       out=[preOut,'''%',rest,'s','',sp,'''',postOut];
%%%      end
%%%   case {'e','E'}
%%%    funstr{i},'99999999999999',kb
    case {'m'} % for *g
      out=[preOut,'''%',rest,'*g',rest2,'',sp,'''',postOut];
    case {'i','I'}
       out=[preOut,'''%',rest,'d','',sp,'''',postOut];
    case {'b','B'}
      out=[preOut,'''''',postOut];
    case {'p','P'} %multiplier:
      % http://h21007.www2.hp.com/portal/download/files/unprot/fortran/docs/lrm/lrm0398.htm#format_spec
       out=[preOut,'''''',postOut];
      % why did I have the following for read statements???????
%%%    case {'i','I'}
%%%      if isread
%%%       out=[preOut,'''%',rest,'u','',sp,'''',postOut];
%%%      else 
%%%       out=[preOut,'''%',rest,'i','',sp,'''',postOut];
%%%      end
    case {'z','Z'}
      out=[preOut,'''%',rest,'z','',sp,'''',postOut];
    otherwise
      in
      error('encountered an unknown format spec !!!!!!!!!!!!!!!!!!')
      in
      out=[preOut,'''%',rest,'f','',sp,'''',postOut];
  end  
 else
  switch in
    case ':'
      out=' ''\n '' ';
      out=' ''\n'' ';
    case '$' %this is supposed to suppress a linefeed
      out='''''';
    otherwise
      out=in;
  end
 end
end

% change over /'s
% out,in,out,'00000000000',kb

temp=find(out=='/');
temp2=find(out=='''');
if isempty(temp2)
 temp1=find(~inastring_f(out,temp));
else
 if isempty(temp)
  temp1=find(~inastring_f(out,temp));
 else
  temp1=find(~inastring_f(out,temp)|temp>temp2(end));
 end % if isempty(temp)
end % if isempty(temp2)
for ii=length(temp1):-1:1
 out=[out(1:temp(temp1(ii))-1),' ''\n '' ',out(temp(temp1(ii))+1:end)];
end

%'+++++++++++++',in, out,kb

end
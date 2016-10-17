%'wwwwwwwwwwww',funstr{i},kb
%get rid of unit=, note we assume that is the first subscript!
funstr{i}=regexprep(funstr{i},['\s*unit\s*=\s*'],'');
[s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
outflag(1)=1;
[howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
write1Asterisk=strcmp('*',strtrim(subscripts{1}));
write1_6=strcmp('6',strtrim(subscripts{1}));
if howmany>1
 write2Asterisk=strcmp('*',strtrim(subscripts{2}));
else
 write2Asterisk=0;   centercomma=parens(2);   subscripts{2}='';
end

nums=find(funstrnumbers_b{i}>=centercomma(1) & funstrnumbers_b{i}<=parens(2));
wrds=find(funstrwords_b{i}>=centercomma(1) & funstrwords_b{i}<=parens(2));
if isempty(strfind(subscripts{2},'''(')) & length(nums)~=1
 % we have a local format to try and deal with
 %punt
 %write2Asterisk=1;
end

temp5='writef';
if write1Asterisk | write1_6
 thisfid='1';
else
 temp4=fidStr;
 if ~isempty(find(funstrwords_b{i}>parens(1) & funstrwords_b{i}<centercomma(1) ,1))
  if any(strcmp(funstrwords{i}{find(funstrwords_b{i}>parens(1),1)},localVar(:,1)))
   temp4='';
  end
 end
 thisfid=[temp4,strtrim(subscripts{1})];
end  

%%%if ~isempty(strfind(funstr{i},'reel'))
%%% 'aaaaaaaaaaaa1',funstr{i},kb
%%%end

if strcmp(strtrim(subscripts{1}),'1') && any(fn16==1)
 thisfid='1001';
end
if strcmp(strtrim(subscripts{1}),'6') && any(fn16==6)
 thisfid='1006';
end

if write2Asterisk %then this has no other format statement

 % so put one in
 groups=getTopGroupsAfterLoc(funstr{i},parens(2));
 %now build up fprintf strings
 formatStr='''(';
 for ii=1:length(groups)
%%%    if any(strcmp(funstrwords{i},'twoa1'))
%%%    write1Asterisk,write2Asterisk,funstr{i},'----------------22',kb
%%%    end
  if ~isempty(groups{ii})
   %assume first word is var to be read in, find type and size, then make a fmt string
   thisVar=groups{ii};
   foo=regexp(groups{ii},'\<\w+\>','match');
   if ~isempty(foo)
    thisVar=foo{1};
   end % if ~isempty(foo)
%%%   if any(groups{ii}=='(')
%%%    thisVar=groups{ii}(1:find(groups{ii}=='(',1,'first')-1);
%%%   end
   fid=find(strcmp(strtrim(thisVar),{localVar{:,1}}));
   if isempty(fid)
    %could be a string
    if thisVar(find(~isspace(thisVar),1,'first'))=='''' || any(groups{ii}=='''')
     %temp0=find(thisVar=='''');
     formatStr=[formatStr,'a'];
    else
     %most likely a implied do loop?
     formatStr=[formatStr,'m'];
    end
   else
    switch localVar{fid,3}
      case 'character'
        %fortran read actually just gets the next token. E.g.
        %   read (15,*) abs,xx , (y(j),J=1,8) where abs is character*4 on
        %       1.0    0.8478   0.9437   0.0957   0.5399   0.5291  -0.3421
        %       2.0    0.8640   0.9329   0.0644   0.5132   0.5022  -0.3124
        formatStr=[formatStr,'a'];
        %formatStr=[formatStr,'a',num2str(localVar{fid,2})];
      case 'real'
        formatStr=[formatStr,'g'];
      case 'integer'
        formatStr=[formatStr,'i'];
      otherwise
        formatStr=[formatStr,'g'];
    end
   end
   if ii~=length(groups)
    formatStr=[formatStr,','];
   end
  end % if ~isempty(groups{ii})
 end % for ii=1:length(groups)
 formatStr=[formatStr,')'''];
 
 subscripts{2}=formatStr;

 
 
end


%'bbbbbbbbbb',funstr{i},kb

goon=0;
if any(subscripts{2}=='(') %there may be format specifiers in the write(,here)
 pl=find(subscripts{2}=='(');
 for ii=1:length(pl)
  if inastring_f(subscripts{2},pl(ii))
   goon=1;
  end
 end
 temp3=strtrim(subscripts{2});
 if temp3(1)=='(', goon=1; end
end

%there may be a variable write(here,)
if isempty(find(thisfid==''''))
 temp8=find(funstrwords_b{i}<centercomma & funstrwords_b{i}>parens(1));
 if ~isempty(temp8)
  temp8=find(strcmp({localVar{:,1}},funstrwords{i}{temp8(1)}));
  if ~isempty(temp8)
   if strcmp(localVar{temp8,3},'character')
    if any(thisfid==':') && isempty(strfind(thisfid,'(1:)'))
     thisfid=['''',thisfid,''''];
    end
   end % if strcmp(localVar{temp8,
  end % if ~isempty(temp8)
 end % if ~isempty(temp8)
end % if isempty(find(subscripts{2}==''''))

goonvar=0; cellArray=0; %there may be a variable write(,here)
if isempty(find(subscripts{2}==''''))
 temp8=find(funstrwords_b{i}>centercomma & funstrwords_b{i}<parens(2));
 if ~isempty(temp8)
  temp8=find(strcmp({localVar{:,1}},funstrwords{i}{temp8(1)}));
  if ~isempty(temp8)
   if strcmp(localVar{temp8,3},'character')
    goonvar=1;
    if ~isempty(localVar{temp8,5})
     cellArray=1;
    end
   end % if strcmp(localVar{temp8,
  end % if ~isempty(temp8)
 end % if ~isempty(temp8)
end % if isempty(find(subscripts{2}==''''))


%%% if any(strcmpi(funstrwords{i},'tyuio'))
%%%  '-----------',funstr{i},subscripts{2},thisfid,keyboard
%%%%%% end


goonimag=1;
if goon %any(subscripts{2}=='(') %format specifiers in the write(,here)
 pl=find(subscripts{2}=='(');
 pr=find(subscripts{2}==')');
 groups=getTopGroupsAfterLoc(subscripts{2}(pl(1)+1:pr(end)-1),0);
 
 groupsStr='';
 for ii=1:length(groups)
  temp1=',';if ii==length(groups), temp1='';end
  %this may be a string but with DQ{1} there
  global DQ
  isString=0;
  if any(~cellfun('isempty',regexp(groups{ii},DQ)))
   isString=1;
  end
  temp2=convertFormatField(groups{ii},[],isString);
  if isempty(temp2), temp1=''; end
  groupsStr=[groupsStr,temp2,temp1];
 end
 %'aaaaaaaaaaaa3',funstr{i},kb
 
elseif goonvar %no asterisk on 2, no paren in sub2, but looks like a var is there
 if cellArray
  groupsStr=['cell2mat(',strtrim(subscripts{2}),')'];
 else
  groupsStr=strtrim(subscripts{2});
 end
 %funstr{i},'ccccccccc2',kb
else %no asterisk on 2, no paren in sub2, must be a format statement

 groupsStr='';
 whichFormat=find(strcmp({formats{:,1}},...
                         strrep(strrep(strrep(subscripts{2},'fmt',''),'=',''),' ','')));
 if ~isempty(whichFormat)
%%%   for ii=1:formats{whichFormat,3}
%%%    temp=',';if ii==formats{whichFormat,3}, temp=' '' \n''';end
%%%    %funstr{i},temp,formats{whichFormat,4}{ii},'ccccccccc',kb
%%%    groupsStr=[groupsStr,convertFormatField(formats{whichFormat,4}{ii}),temp];
%%%   end
  groupsStr=['format_',num2str(formats{whichFormat,1})];
 else
  groupsStr=['''%f'''];
 end
end % if goon %any(subscripts{2}=='(') %format specifiers in the write(,

groupsStr=['[',groupsStr,']'];

%%%'bbbbbbbbbb22',funstr{i},kb
temp11='write';
convertRW




%end
%%%  if strcmp(subscripts{2},'620')
%%%   funstr{i},'ddddddddd11',kb
%%%  end















%%%if write2Asterisk %then this has no other format statement
%%%                  %'oooooooooooooooooo',funstr{i},kb
%%% %find top level commas after write() and separate into fprintf's
%%% temp7=parens(2); temp8=nextNonSpace(funstr{i},parens(2));
%%% if funstr{i}(temp8)==',',  temp7=temp8;  end
%%% [groups,temp4]=getTopGroupsAfterLoc(funstr{i},temp7);
%%% temp4=[parens(2),temp4];
%%%
%%% %now build up fprintf strings
%%% groupFormatStr='';
%%%%%% if write1_6 && any(fn16==6)
%%%%%%  groupsStr=[temp5,'(','1006',',','['''];
%%%%%% elseif strcmp(strtrim(subscripts{1}),'1') && any(fn16==1)
%%%%%%  groupsStr=[temp5,'(','1001',',','['''];
%%%%%% else
%%%  groupsStr=[temp5,'(',thisfid,',','['''];
%%%%%% end % if write1_6 && any(fn16==6)
%%% groupsTemp='';
%%% %'bbbbbbbbbb2',funstr{i},groups,groupsStr,kb 
%%% for ii=1:length(groups)
%%%  %find the first word after the toplevel comma here and see if its a string or char
%%%  goonimag=0;
%%%  temp3=find(funstrwords_b{i}>temp4(ii));
%%%  if ~isempty(temp3)
%%%   %'rrrrrrrr',funstr{i},kb
%%%   temp6=find(strcmp(funstrwords{i}{temp3(1)},{localVar{:,1}}));
%%%   tempstr=strtrim(groups{ii});
%%%   if (~isempty(temp6) && strcmp(localVar{temp6,3},'character')) || ...
%%%        any(strcmp(funstrwords{i}{temp3(1)},{'deblank'})) || ...
%%%        tempstr(1)=='['
%%%     goonimag=1;
%%%   end
%%%  end % if ~isempty(temp3)
%%%  %'aaaaaaaaaaaa1',funstr{i},kb
%%%  temp='';%if ii==length(groups), temp='\n'; else temp=''; end
%%%  if isempty(groups{ii}) % do nothing
%%%   thisFormat='';
%%%  elseif strncmp(fliplr(deblank(groups{ii})),'''',1) | goonimag
%%%   thisFormat='%s';
%%%  else
%%%   thisFormat='%0.15g';
%%%  end
%%%  groupsTemp=[groupsTemp,',',groups{ii}];
%%%  groupFormatStr=[groupFormatStr,thisFormat,sp2,temp];
%%% end
%%% groupsStr=[groupsStr,groupFormatStr,''']',groupsTemp,');'];
%%% 
%%% %now put it together
%%% funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),groupsStr];
%%% 
%%% % not sure this is necessary here
%%%%%% out=funstr{i};
%%%%%% temp=find(out=='/');
%%%%%% temp1=find(~inastring_f(out,temp));
%%%%%% for ii=length(temp1):-1:1
%%%%%%  temp2=''; if ii==length(temp1), temp2=','; end
%%%%%%  bar=find(~isspace(out));
%%%%%%  bar=bar(bar>temp(temp1(ii)));
%%%%%%  bar=bar(1);
%%%%%%  if isletter(out(bar))
%%%%%%   temp2=',';
%%%%%%  end
%%%%%%  out=[out(1:temp(temp1(ii))-1),', ''\n '' ',temp2,out(temp(temp1(ii))+1:end)];
%%%%%% end
%%%%%% funstr{i}=out;
%%% 
%%% %'bbbbbbbbbb',funstr{i},groupsStr,groupFormatStr,groupsTemp,kb
%%% 
%%%else % not an asterisk on subscript 2
%%% goon=0;
%%% if any(subscripts{2}=='(') %there may be format specifiers in the write(,here)
%%%  pl=find(subscripts{2}=='(');
%%%  for ii=1:length(pl)
%%%   if inastring_f(subscripts{2},pl(ii))
%%%    goon=1;
%%%   end
%%%  end
%%%  temp3=strtrim(subscripts{2});
%%%  if temp3(1)=='(', goon=1; end
%%% end
%%%
%%% %there may be a variable write(here,)
%%% if isempty(find(thisfid==''''))
%%%  temp8=find(funstrwords_b{i}<centercomma & funstrwords_b{i}>parens(1));
%%%  if ~isempty(temp8)
%%%   temp8=find(strcmp({localVar{:,1}},funstrwords{i}{temp8(1)}));
%%%   if ~isempty(temp8)
%%%    if strcmp(localVar{temp8,3},'character')
%%%     if any(thisfid==':') && isempty(strfind(thisfid,'(1:)'))
%%%      thisfid=['''',thisfid,''''];
%%%     end
%%%    end % if strcmp(localVar{temp8,
%%%   end % if ~isempty(temp8)
%%%  end % if ~isempty(temp8)
%%% end % if isempty(find(subscripts{2}==''''))
%%% 
%%% goonvar=0; cellArray=0; %there may be a variable write(,here)
%%% if isempty(find(subscripts{2}==''''))
%%%  temp8=find(funstrwords_b{i}>centercomma & funstrwords_b{i}<parens(2));
%%%  if ~isempty(temp8)
%%%   temp8=find(strcmp({localVar{:,1}},funstrwords{i}{temp8(1)}));
%%%   if ~isempty(temp8)
%%%    if strcmp(localVar{temp8,3},'character')
%%%     goonvar=1;
%%%     if ~isempty(localVar{temp8,5})
%%%      cellArray=1;
%%%     end
%%%    end % if strcmp(localVar{temp8,
%%%   end % if ~isempty(temp8)
%%%  end % if ~isempty(temp8)
%%% end % if isempty(find(subscripts{2}==''''))
%%% 
%%% 
%%%%%% if any(strcmpi(funstrwords{i},'tyuio'))
%%%%%%  '-----------',funstr{i},subscripts{2},thisfid,keyboard
%%%%%%%%% end
%%%
%%% 
%%% goonimag=1;
%%% if goon %any(subscripts{2}=='(') %format specifiers in the write(,here)
%%%  pl=find(subscripts{2}=='(');
%%%  pr=find(subscripts{2}==')');
%%%  groups=getTopGroupsAfterLoc(subscripts{2}(pl(1)+1:pr(end)-1),0);
%%%  
%%%  groupsStr='';
%%%  for ii=1:length(groups)
%%%   temp1=',';if ii==length(groups), temp1='';end
%%%   %this may be a string but with DQ{1} there
%%%   global DQ
%%%   isString=0;
%%%   if any(~cellfun('isempty',regexp(groups{ii},DQ)))
%%%    isString=1;
%%%   end
%%%   groupsStr=[groupsStr,convertFormatField(groups{ii},[],isString),temp1];
%%%  end
%%%  %'aaaaaaaaaaaa3',funstr{i},kb
%%% 
%%% elseif goonvar %no asterisk on 2, no paren in sub2, but looks like a var is there
%%%  if cellArray
%%%   groupsStr=['cell2mat(',strtrim(subscripts{2}),')'];
%%%  else
%%%   groupsStr=strtrim(subscripts{2});
%%%  end
%%%  %funstr{i},'ccccccccc2',kb
%%% else %no asterisk on 2, no paren in sub2, must be a format statement
%%%
%%%  groupsStr='';
%%%  whichFormat=find(strcmp({formats{:,1}},...
%%%                          strrep(strrep(strrep(subscripts{2},'fmt',''),'=',''),' ','')));
%%%  if ~isempty(whichFormat)
%%%%%%   for ii=1:formats{whichFormat,3}
%%%%%%    temp=',';if ii==formats{whichFormat,3}, temp=' '' \n''';end
%%%%%%    %funstr{i},temp,formats{whichFormat,4}{ii},'ccccccccc',kb
%%%%%%    groupsStr=[groupsStr,convertFormatField(formats{whichFormat,4}{ii}),temp];
%%%%%%   end
%%%   groupsStr=['format_',num2str(formats{whichFormat,1})];
%%%  else
%%%   groupsStr=['''%f'''];
%%%  end
%%% end % if goon %any(subscripts{2}=='(') %format specifiers in the write(,
%%%
%%% groupsStr=['[',groupsStr,']'];
%%% 
%%% temp11='write';
%%% convertRW
%%%
%%%
%%%
%%%
%%%end
%%%%%%  if strcmp(subscripts{2},'620')
%%%%%%   funstr{i},'ddddddddd11',kb
%%%%%%  end








%%%%new version was tested on the following file:
%%%program test2
%%%real y(2),b(10),r(2,3)
%%%integer, parameter :: maxnam = 100
%%%integer i,lun(8),j,jj
%%%character*36 string,abs
%%%complex :: c1,c2
%%%
%%%CHARACTER*4 C,cc
%%%DOUBLE PRECISION T, r1, k, s
%%%real*8 D(2),D2(2),dd(10),E,ee
%%%LOGICAL L,M
%%%lun(1)=1
%%%lun(2)=2
%%%OPEN (88,FILE='test2.dat',STATUS='unknown')
%%%
%%%C='abcd'
%%%cc='efgh'
%%%t=1.1
%%%r1=2.2
%%%k=3.3
%%%s=4.4
%%%D=5.5
%%%D2=6.6
%%%dd=7.7
%%%E=8.8
%%%ee=9.9
%%%L=.false.
%%%M=.true.
%%%
%%%! data in file => d, format fields => ff, IO list after read statement =? IO
%%%!least to geatest
%%%WRITE (88,99002)
%%%99002 FORMAT (1x,45('-'),//'  Beta t ')
%%%
%%%WRITE (88,99005) d
%%%99005 FORMAT (1x,45('-'),//'  Beta t ',20x,g15.5,'Number of Cycles'//)
%%%
%%%write(88,*) 'case 3 - d,IO,ff'
%%%WRITE (88,'(f14.3,a4,f13.2,a4)') T,c,R1
%%%
%%%write (88, *) 'case 3a- not enough data in line, same # format fields than IO list'
%%%WRITE (88,'(2f14.3,"  were")') T,R1
%%%
%%%write (88, *) 'case 1 - ff,IO,d'
%%%write(88,30) (d(j),j=lun(1),lun(2),1),c,d2,cc,d(1)
%%%30 format (10x,2f14.3,a4)
%%%
%%%write (88, *) 'case 1a- enough data in line, same # format fields than IO list'
%%%write(88,31) (d(j),j=1,2),c,d2,cc
%%%31 format (2(2f14.3,a4))
%%%
%%%write (88, *) 'case 2 - IO,ff,d'
%%%write (88,'(20x,2(2f14.3,5("-"),a4,"+++++"),"what about this?")') d2,cc
%%%
%%%write (88, *) 'case 2a- IO=ff,d'
%%%write (88,'(2f14.3,a4)') d2,cc
%%%
%%%write (88, *) 'case 4 - d,ff,IO'
%%%write (88,40) T,d,r1,t
%%%40 format ('beging',2x,2f14.3,'this is %error','  wt')
%%%
%%%write (88, *) 'case 5 - IO,d,ff'
%%%write (88,'(2(f14.3,a4))') e,c
%%%
%%%write (88, *) 'case 6 - ff,d,IO'
%%%write (88,'(2f14.3)') (dd(j),j=1,10)
%%%
%%%write (c,'(f4.2)') d(1)
%%%print *,'c=',c
%%%
%%%read (c,'(f15.4)') d2(2)
%%%print *,'d2=',d2
%%%
%%%b=[1,2,3,4,5,6,7,8,9,10]
%%%r(1,:)=[1,2,3]
%%%r(2,:)=[3,4,5]
%%%
%%%
%%%print *,'doneeeeee'
%%%
%%%end program test2










%%% if goon %any(subscripts{2}=='(') %format specifiers in the write(,here)
%%%  pl=find(subscripts{2}=='(');
%%%  pr=find(subscripts{2}==')');
%%%  groups=getTopGroupsAfterLoc(subscripts{2}(pl(1)+1:pr(end)-1),0);
%%%  
%%%  groupsStr='';
%%%  for ii=1:length(groups)
%%%   temp1=',';if ii==length(groups), temp1='';end
%%%   %this may be a string but with DQ{1} there
%%%   global DQ
%%%   isString=0;
%%%   if any(~cellfun('isempty',regexp(groups{ii},DQ)))
%%%    isString=1;
%%%   end
%%%   groupsStr=[groupsStr,convertFormatField(groups{ii},[],isString),temp1];
%%%  end
%%%  temp=''; if write1Asterisk | write1_6, temp=',''\n'''; end
%%%  groupsStr=['[',groupsStr,temp,']'];
%%%  %'aaaaaaaaaaaa3',funstr{i},kb
%%% 
%%%  % this might be a string conversion
%%%  nums=find(funstrnumbers_b{i}>=parens(1) & funstrnumbers_b{i}<=centercomma(1));
%%%  wrds=find(funstrwords_b{i}>=parens(1) & funstrwords_b{i}<=centercomma(1));
%%%  goonimag=1;
%%%  if ~isempty(wrds)
%%%   temp6=find(strcmp(funstrwords{i}{wrds(1)},{localVar{:,1}}));
%%%   if isempty(temp6)
%%%    if strcmp(funstrwords{i}{wrds(1)},this_fun_name) || ...
%%%         strcmp(funstrwords{i}{wrds(1)},[this_fun_name,'Result'])
%%%     temp6=1;
%%%    end
%%%   end
%%%   %'dddddddd1234',funstr{i},kb
%%%   if ~isempty(temp6)
%%%    if strcmp(localVar{temp6,3},'character') || ...
%%%         strcmp(funstrwords{i}{wrds(1)},this_fun_name)
%%%     funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),subscripts{1},'=sprintf(',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%     goonimag=0;
%%%    end % if strcmp(localVar{temp6,
%%%   end % if ~isempty(temp6)
%%%  end % if ~isempty(wrds)
%%%  if goonimag %formatted write
%%%   funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),temp5,'(',thisfid,',',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%  end
%%% 
%%% else %no asterisk on 2, no paren in sub2, must be a format statement
%%%%%%      funstr{i},'ccccccccc2',kb
%%%  groupsStr='';
%%%  whichFormat=find(strcmp({formats{:,1}},...
%%%                          strrep(strrep(strrep(subscripts{2},'fmt',''),'=',''),' ','')));
%%%  if ~isempty(whichFormat)
%%%%%%   for ii=1:formats{whichFormat,3}
%%%%%%    temp=',';if ii==formats{whichFormat,3}, temp=' '' \n''';end
%%%%%%    %funstr{i},temp,formats{whichFormat,4}{ii},'ccccccccc',kb
%%%%%%    groupsStr=[groupsStr,convertFormatField(formats{whichFormat,4}{ii}),temp];
%%%%%%   end
%%%   groupsStr=['format_',num2str(formats{whichFormat,1})];
%%%  else
%%%   groupsStr=[''];
%%%  end
%%%  %funstr{i},groupsStr,'ccccccccc',kb
%%%  if ~isempty(groupsStr)
%%%   %groupsStr=['[',groupsStr,'''\n'']'];
%%%   %groupsStr=['[',groupsStr,']'];
%%%   % if thisfid is a variable name and it is a string, then sprintf with output instead
%%%   fidIsVar=find(strcmp(thisfid,localVar(:,1)));
%%%   if ~isempty(fidIsVar) && strcmp(localVar{fidIsVar,3},'character')
%%%    funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),thisfid,'=sprintf(',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%   else
%%%    if ~isempty(strtrim(funstr{i}(parens(2)+1:end-1)))
%%%     temp9=[',',funstr{i}(parens(2)+1:end-1)];
%%%    else
%%%     temp9='';
%%%    end
%%%     funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),temp5,'(',thisfid,',',groupsStr,temp9,');'];
%%%   end
%%%  else
%%%   [groups,temp4]=getTopGroupsAfterLoc(funstr{i},parens(2));
%%%   %'dssaaaaaaaaaa',funstr{i},kb
%%%   funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'disp({',funstr{i}(parens(2)+1:end-1),'});'];
%%%  end
%%%  %groupsStr,funstr{i},kb
%%% 
%%% 
%%% 
%%% end

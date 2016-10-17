%'dddddddddddd111',funstr,kb

%get rid of unit=, note we assume that is the first subscript!
funstr{i}=regexprep(funstr{i},['\s*unit\s*=\s*'],'');
[s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);

outflag(1)=1;
[howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
if howmany>0
 write1Asterisk=strcmp('*',subscripts{1}(~isspace(subscripts{1})));
 write1_6=strcmp('5',strtrim(subscripts{1}));
 if howmany>1
  write2Asterisk=strcmp('*',strtrim(subscripts{2}));  
 else
  write2Asterisk=0;
  centercomma=parens(2);
  subscripts{2}='';
 end
else %this is a read *,
 write1Asterisk=1;
 write1_6=0;
 if strcmp(nextNonSpace(funstr{i},funstrwords_e{i}(j)),'*')
  write2Asterisk=1;
 else

  %TODO need to fix the whole read routine!
  % probably have a format specifier here
%%%      [groups,commas]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(j))
%%%      funstr{i}=[funstr{i}(1:funstrwords_e{i}(j)),'(*,',groups{1},')',funstr{i}(commas(1)+1:end)];

  %so that get getTopGroupsAfterLoc below is OK
  parens=[funstrwords_e{i}(j),funstrwords_e{i}(j)];
  %'dddddddddd',kb
 end
end
if write1Asterisk | write1_6
 thisfid='1';     temp4=thisfid;
else
 temp4=fidStr;
 if ~isempty(find(funstrwords_b{i}>parens(1) & ...
                  funstrwords_b{i}<parens(2),1))
  temp3=funstrwords{i}{find(funstrwords_b{i}>parens(1) & ...
                            funstrwords_b{i}<parens(2),1)};
  if any(strcmp(temp3,localVar(:,1))) ||...
       (~isempty(findstr(temp3,MLapp)) && any(strcmp(temp3(1:end-3),localVar(:,1))))
   temp4='';
  end
 end
 thisfid=[temp4,strtrim(subscripts{1})];
 %thisfid=[fidStr,subscripts{1}(~isspace(subscripts{1}))];
end

if howmany>0
 if strcmp(strtrim(subscripts{1}),'1') && any(fn16==1)
  thisfid='1001';
 end
 if strcmp(strtrim(subscripts{1}),'6') && any(fn16==6)
  thisfid='1006';
 end
end

%%%  if write1Asterisk & write2Asterisk
%%%   write1Asterisk,write2Asterisk,funstr{i},'----------------',kb
%%%  end % if write1Asterisk & write2Asterisk   
if write1Asterisk | write1_6
 [groups,centercomma]=getTopGroupsAfterLoc(funstr{i},parens(2));
 centercomma=[parens(2),centercomma,length(funstr{i})];
 %'ffffffff',funstr{i},kb
 funstr{i}='';
 whichFormat=find(strcmp(strtrim(groups{1}),{formats{:,1}}));
 if ~isempty(str2num(groups{1})) && length(groups)==2 && ~isempty(whichFormat)
  funstr{i}=[funstr{i},groups{2},'=input('''',','''s'');'];
  %funstr{i}=[funstr{i},groups{2},'=input('''',','',formats{whichFormat(1),7},');'];
 else
  for ii=1:length(groups)
   if ~strcmpi('*',strtrim(groups{ii}))
    temp7={}; temp7{1}=''; temp7{2}='';
    temp5=find(funstrwords_b{i}>centercomma(ii)&funstrwords_b{i}<centercomma(ii+1),1,'first');
    fid=[];
    if ~isempty(temp5)
     fid=find(strcmp(funstrwords{i}{temp5},{localVar{:,1}}));
    end
    %fid=find(strcmp(strtrim(groups{ii}),{localVar{:,1}}));
    if ~isempty(fid) && ~strcmpi('character',localVar{fid(1),3})
     temp7{1}='str2num(';  temp7{2}=')';
    end
    funstr{i}=[funstr{i},groups{ii},'=',temp7{1},'input('''',','''s'')',temp7{2},';'];
   end
  end % for ii=1:length(groups)
 end
 %'mmmmmmmmmmmm',funstr{i},keyboard
%%%   if howmany>0
%%%    funstr{i}=['input(''',strrep(funstr{i}(parens(2)+1:end),';',''),''');'];
%%%   else
%%%    funstr{i}=['input(''',strrep(funstr{i}(funstrwords_e{i}(j)+1:end),';',''),''');'];
%%%   end
%%%   warning('interactive input not written yet for f2matlab')
else %formatted read or * in 2nd

 
 
 if write2Asterisk %then this has no other format statement (list-directed read)
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
    if any(groups{ii}=='(')
     thisVar=groups{ii}(1:find(groups{ii}=='(',1,'first')-1);
    end
    fid=find(strcmp(strtrim(thisVar),{localVar{:,1}}));
    if isempty(fid)
     %most likely a implied do loop?
     formatStr=[formatStr,'m'];
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
%%%    % does thisfid point to a string or variable?
%%%
%%%    temp5='fscanf';     if isempty(temp4), temp5='sscanf'; end
%%%    if strncmp(fliplr(deblank(groups{ii})),'''',1)
%%%     groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%s',sp,'',temp,''',size(',groups{ii},'));'];
%%%    else
%%%     groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%g',sp,'',temp,''',size(',groups{ii},'));'];
%%%    end   
%%%   else
%%%    %groupsStr=[groupsStr,'fscanf(',thisfid,',''%s',sp,'',temp,''',1);'];
%%%    groupsStr=[groupsStr,'fgetl(',thisfid,');'];
%%%   end
%%%  end
%%%  %now put it together
%%%  funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),groupsStr];
  
  subscripts{2}=formatStr;
 end
 
 
 
 
 
 goon=0;
 if any(subscripts{2}=='(') %there may be format specifiers in the write(,here)
  pl=find(subscripts{2}=='(');
  for ii=1:length(pl)
   if inastring_f(subscripts{2},pl(ii))
    goon=1;
   end
  end % for ii=1:length(pl)
 end

 
 %goon,funstr{i},kb
 if goon %any(subscripts{2}=='(') %format specifiers in the write(,here)
  pl=find(subscripts{2}=='(');
  pr=find(subscripts{2}==')');
  groups=getTopGroupsAfterLoc(subscripts{2}(pl(1)+1:pr(end)-1),0);
  
  groupsStr='';
  for ii=1:length(groups)
   temp1=',';if ii==length(groups), temp1='';end
   groupsStr=[groupsStr,convertFormatField(groups{ii},'r'),temp1];
  end
 else
  groupsStr='';
  whichFormat=find(strcmp({formats{:,1}},...
                          strrep(strrep(strrep(subscripts{2},'fmt',''),'=',''),' ','')));
  %funstr{i},'ffffffffffffffffffffffffffff',kb
  if ~isempty(whichFormat)
%%%       for ii=1:formats{whichFormat,3}
%%%        temp=',';if ii==formats{whichFormat,3}, temp='';end
%%%        groupsStr=[groupsStr,convertFormatField(formats{whichFormat,4}{ii},'r'),temp];
%%%       end
   groupsStr=['format_',num2str(formats{whichFormat,1})];
  else
   groupsStr='''%f''';
  end
 end
 groupsStr=['[',groupsStr,']'];
 
 temp11='read';
 convertRW
  

 
 %funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',funstr{i}(parens(2)+1:end-1),']=readf(',thisfid,',',groupsStr,',',num2str(length(find(groupsStr=='%'))),');'];
 %funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'readf(',thisfid,',',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
 
 
 
 
  
  
%%%  temp6='';
%%%  if ~isempty(strtrim(funstr{i}(parens(2)+1:end-1)))
%%%   temp6=['[',funstr{i}(parens(2)+1:end-1),']='];
%%%  end
%%%  funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),temp6,'readf(',thisfid,',',groupsStr,',',num2str(formats{whichFormat,3}),');'];
%%%%%%      funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',funstr{i}(parens(2)+1:end-1),']=readf(',thisfid,',',groupsStr,',',num2str(length(find(groupsStr=='%'))),');'];
%%%%funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'readf(',thisfid,',',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%%groupsStr,funstr{i},kb

end
%'dddddddddddd',funstr,kb



%%% if write2Asterisk %then this has no other format statement (list-directed read)
%%%                   % so put one in
%%%  groups=getTopGroupsAfterLoc(funstr{i},parens(2));
%%%  %now build up fprintf strings
%%%  groupsStr='';
%%%  for ii=1:length(groups)
%%%   if ii==length(groups), temp=''; else temp=''; end
%%%%%%    if any(strcmp(funstrwords{i},'twoa1'))
%%%%%%    write1Asterisk,write2Asterisk,funstr{i},'----------------22',kb
%%%%%%    end
%%%   if ~isempty(groups{ii})
%%%    % does thisfid point to a string or variable?
%%%    temp5='fscanf';     if isempty(temp4), temp5='sscanf'; end
%%%    if strncmp(fliplr(deblank(groups{ii})),'''',1)
%%%     groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%s',sp,'',temp,''',size(',groups{ii},'));'];
%%%    else
%%%     groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%g',sp,'',temp,''',size(',groups{ii},'));'];
%%%    end   
%%%   else
%%%    %groupsStr=[groupsStr,'fscanf(',thisfid,',''%s',sp,'',temp,''',1);'];
%%%    groupsStr=[groupsStr,'fgetl(',thisfid,');'];
%%%   end
%%%  end
%%%  %now put it together
%%%  funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),groupsStr];
%%%  
%%% 
%%% end


%fortran test file that helped me do the readFmt:

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
%%%OPEN (88,FILE='test2.dat',ERR=20)
%%%
%%%! data in file => d, format fields => ff, IO list after read statement =? IO
%%%!least to geatest
%%%print *,'case 3 - d,IO,ff'
%%%READ (88,'(f4.3,a4,f3.2,a4)',end=20) T,c,R1
%%%print *,'T,c,R1=',T,c,R1
%%%
%%%print *,'case 3a- not enough data in line, same # format fields than IO list'
%%%READ (88,'(2f4.3)',end=20) T,R1
%%%print *,'T,R1=',T,R1
%%%
%%%print *,'case 1 - ff,IO,d'
%%%read(88,30) (d(j),j=lun(1),lun(2),1),c,d2,cc 
%%%30 format (2f4.3,a4)
%%%print *,'d,c,d2,cc=',d,c,d2,cc
%%%
%%%print *,'case 1a- enough data in line, same # format fields than IO list'
%%%read(88,31) (d(j),j=1,2),c,d2,cc 
%%%31 format (2(2f4.3,a4))
%%%print *,'d,c,d2,cc=',d,c,d2,cc
%%%
%%%print *,'case 2 - IO,ff,d'
%%%read (88,'(t4,2(2f4.3,t8,a4))') d2,cc
%%%print *,'d2,cc =',d2,cc 
%%%
%%%print *,'case 2a- IO=ff,d'
%%%read (88,'(2f4.3,a4)') d2,cc
%%%print *,'d2,cc =',d2,cc 
%%%
%%%print *,'case 4 - d,ff,IO'
%%%read (88,40) T,d,r1
%%%40 format (2f4.3)
%%%print *,'T,d,r1=',T,d,r1
%%%
%%%print *,'case 5 - IO,d,ff'
%%%read (88,'(2(f4.3,a4))') e,c
%%%print *,'e,c=',e,c
%%%
%%%print *,'case 6 - ff,d,IO'
%%%read (88,'(2f4.3)') (dd(j),j=1,10)
%%%print *,'dd=',dd
%%%
%%%
%%%!!!
%%%!!!
%%%!!!
%%%!!!READ (88,'(10f4.3)',end=20) dd,(e,j=1,3)!,L,M,J,K,S,T,C,A,B
%%%!!!READ (88,'(10f4.3)',end=20) 
%%%!!!read (88,10) T,R1
%%%!!!10 format (2f4.3)
%%%
%%%!!!string='22'
%%%!!!i=11
%%%!!!READ (string,'(i)') i
%%%
%%%print *,'string=',string
%%%print *,'i=',i
%%%
%%%b=[1,2,3,4,5,6,7,8,9,10]
%%%r(1,:)=[1,2,3]
%%%r(2,:)=[3,4,5]
%%%
%%%string='ply'
%%%abs='ply'
%%%if (string==abs) then
%%% print *,'eqqqqqq'
%%%end if
%%%
%%%20 print *,'d=',d
%%%print *,'e,c,ee,c,ddc=',e,c,ee,cc
%%%print *,'dd=',dd
%%%print *,'T,R1,k,s=',T,R1,k,s
%%%print *,'doneeeeee'
%%%
%%%
%%%end program test2
%%%
%%%
%%%%and test2.dat
%%%
%%%6.7
%%%6.8
%%%6.3 7.4 3.3 1.0 2.0 3.0 4.0 5.0
%%%6.4 7.5 3.4 1.1 2.1 3.1
%%%6.5 7.5 3.5 1.5 2.5 3.5 4.1 5.1
%%%6.6 7.2 3.7 1.6 6.6 7.6 3.9 1.6 7.7 3.7 1.7 
%%%6.2 2.5 3.4 1.7
%%%6.3
%%%6.4 2.7 3.6
%%%6.5 2.8 3.7
%%%6.1 2.9 6.5 2.8 3.7
%%%6.6 6.5 2.8 3.7
%%%6.7
%%%6.8
%%%6.9
%%%6.0
%%%6.1
%%%6.2
%%%6.3




























%%%%'dddddddddddd111',funstr,kb
%%%
%%%%get rid of unit=, note we assume that is the first subscript!
%%%funstr{i}=regexprep(funstr{i},['\s*unit\s*=\s*'],'');
%%%[s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%
%%%outflag(1)=1;
%%%[howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%if howmany>0
%%% write1Asterisk=strcmp('*',subscripts{1}(~isspace(subscripts{1})));
%%% write1_6=strcmp('5',strtrim(subscripts{1}));
%%% if howmany>1
%%%  write2Asterisk=strcmp('*',strtrim(subscripts{2}));  
%%% else
%%%  write2Asterisk=0;
%%%  centercomma=parens(2);
%%%  subscripts{2}='';
%%% end
%%%else %this is a read *,
%%% write1Asterisk=1;
%%% write1_6=0;
%%% if strcmp(nextNonSpace(funstr{i},funstrwords_e{i}(j)),'*')
%%%  write2Asterisk=1;
%%% else
%%%
%%%  %TODO need to fix the whole read routine!
%%%  % probably have a format specifier here
%%%%%%      [groups,commas]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(j))
%%%%%%      funstr{i}=[funstr{i}(1:funstrwords_e{i}(j)),'(*,',groups{1},')',funstr{i}(commas(1)+1:end)];
%%%
%%%  %so that get getTopGroupsAfterLoc below is OK
%%%  parens=[funstrwords_e{i}(j),funstrwords_e{i}(j)];
%%%  %'dddddddddd',kb
%%% end
%%%end
%%%if write1Asterisk | write1_6
%%% thisfid='1';     temp4=thisfid;
%%%else
%%% temp4=fidStr;
%%% if ~isempty(find(funstrwords_b{i}>parens(1) & ...
%%%                  funstrwords_b{i}<parens(2),1))
%%%  temp3=funstrwords{i}{find(funstrwords_b{i}>parens(1) & ...
%%%                            funstrwords_b{i}<parens(2),1)};
%%%  if any(strcmp(temp3,localVar(:,1))) ||...
%%%       (~isempty(findstr(temp3,MLapp)) && any(strcmp(temp3(1:end-3),localVar(:,1))))
%%%   temp4='';
%%%  end
%%% end
%%% thisfid=[temp4,strtrim(subscripts{1})];
%%% %thisfid=[fidStr,subscripts{1}(~isspace(subscripts{1}))];
%%%end
%%%%%%  if write1Asterisk & write2Asterisk
%%%%%%   write1Asterisk,write2Asterisk,funstr{i},'----------------',kb
%%%%%%  end % if write1Asterisk & write2Asterisk   
%%%if write1Asterisk
%%% groups=getTopGroupsAfterLoc(funstr{i},parens(2));
%%% funstr{i}='';
%%% %'ffffffff',kb
%%% whichFormat=find(strcmp(strtrim(groups{1}),{formats{:,1}}));
%%% if ~isempty(str2num(groups{1})) && length(groups)==2 && ~isempty(whichFormat)
%%%  funstr{i}=[funstr{i},groups{2},'=input('''',','''s'');'];
%%%  %funstr{i}=[funstr{i},groups{2},'=input('''',','',formats{whichFormat(1),7},');'];
%%% else
%%%  for ii=1:length(groups)
%%%   funstr{i}=[funstr{i},groups{ii},'=input('''',','''s'');'];
%%%  end % for ii=1:length(groups)
%%% end
%%% %'mmmmmmmmmmmm',funstr{i},keyboard
%%%%%%   if howmany>0
%%%%%%    funstr{i}=['input(''',strrep(funstr{i}(parens(2)+1:end),';',''),''');'];
%%%%%%   else
%%%%%%    funstr{i}=['input(''',strrep(funstr{i}(funstrwords_e{i}(j)+1:end),';',''),''');'];
%%%%%%   end
%%%%%%   warning('interactive input not written yet for f2matlab')
%%%elseif write2Asterisk %then this has no other format statement (list-directed read)
%%%                      %find top level commas after write() and separate into fscanf's
%%% groups=getTopGroupsAfterLoc(funstr{i},parens(2));
%%% %now build up fprintf strings
%%% groupsStr='';
%%% for ii=1:length(groups)
%%%  if ii==length(groups), temp=''; else temp=''; end
%%%%%%    if any(strcmp(funstrwords{i},'twoa1'))
%%%%%%    write1Asterisk,write2Asterisk,funstr{i},'----------------22',kb
%%%%%%    end
%%%  if ~isempty(groups{ii})
%%%   % does thisfid point to a string or variable?
%%%   temp5='fscanf';     if isempty(temp4), temp5='sscanf'; end
%%%   if strncmp(fliplr(deblank(groups{ii})),'''',1)
%%%    groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%s',sp,'',temp,''',size(',groups{ii},'));'];
%%%   else
%%%    groupsStr=[groupsStr,groups{ii},'=',temp5,'(',thisfid,',''%g',sp,'',temp,''',size(',groups{ii},'));'];
%%%   end   
%%%  else
%%%   %groupsStr=[groupsStr,'fscanf(',thisfid,',''%s',sp,'',temp,''',1);'];
%%%   groupsStr=[groupsStr,'fgetl(',thisfid,');'];
%%%  end
%%% end
%%% %now put it together
%%% funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),groupsStr];
%%%else %formatted read
%%% goon=0;
%%% if any(subscripts{2}=='(') %there may be format specifiers in the write(,here)
%%%  pl=find(subscripts{2}=='(');
%%%  for ii=1:length(pl)
%%%   if inastring_f(subscripts{2},pl(ii))
%%%    goon=1;
%%%   end
%%%  end % for ii=1:length(pl)
%%% end
%%% %goon,funstr{i},kb
%%% if goon %any(subscripts{2}=='(') %format specifiers in the write(,here)
%%%  pl=find(subscripts{2}=='(');
%%%  pr=find(subscripts{2}==')');
%%%  groups=getTopGroupsAfterLoc(subscripts{2}(pl(1)+1:pr(end)-1),0);
%%%  
%%%  groupsStr='';
%%%  for ii=1:length(groups)
%%%   temp1=',';if ii==length(groups), temp1='';end
%%%   groupsStr=[groupsStr,convertFormatField(groups{ii},'r'),temp1];
%%%  end
%%%  groupsStr=['[',groupsStr,']'];
%%%  funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',funstr{i}(parens(2)+1:end-1),']=readf(',thisfid,',',groupsStr,',',num2str(length(find(groupsStr=='%'))),');'];
%%%  %funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'readf(',thisfid,',',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%  %funstr{i},'ffffffffffffffffffffffffffff',kb
%%% else
%%%  groupsStr='';
%%%  whichFormat=find(strcmp({formats{:,1}},...
%%%                          strrep(strrep(strrep(subscripts{2},'fmt',''),'=',''),' ','')));
%%%  %funstr{i},'ffffffffffffffffffffffffffff',kb
%%%  if ~isempty(whichFormat)
%%%%%%       for ii=1:formats{whichFormat,3}
%%%%%%        temp=',';if ii==formats{whichFormat,3}, temp='';end
%%%%%%        groupsStr=[groupsStr,convertFormatField(formats{whichFormat,4}{ii},'r'),temp];
%%%%%%       end
%%%   groupsStr=['format_',num2str(formats{whichFormat,1})];
%%%  else
%%%   groupsStr='''%f''';
%%%  end
%%%  %groupsStr=['[',groupsStr,'''\n'']'];
%%%  groupsStr=['[',groupsStr,']'];
%%%  temp6='';
%%%  if ~isempty(strtrim(funstr{i}(parens(2)+1:end-1)))
%%%   temp6=['[',funstr{i}(parens(2)+1:end-1),']='];
%%%  end
%%%  funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),temp6,'readf(',thisfid,',',groupsStr,',',num2str(formats{whichFormat,3}),');'];
%%%%%%      funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',funstr{i}(parens(2)+1:end-1),']=readf(',thisfid,',',groupsStr,',',num2str(length(find(groupsStr=='%'))),');'];
%%%%funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'readf(',thisfid,',',groupsStr,',',funstr{i}(parens(2)+1:end-1),');'];
%%%%groupsStr,funstr{i},kb
%%% end
%%%end
%%%%'dddddddddddd',funstr,kb






%This version of readFmt.m works, but not in octave.

%%%function [readErrFlag,readEndFlag]=readFmt(fidIn,formatIn,varargin)
%%%% attempts to be able to reproduce fortran's formatted read statements
%%% varargin=strtrim(varargin);
%%% %extract format fields from formatIn
%%% percents=find(formatIn=='%');
%%% formatFields=cell(1,length(percents));
%%% for ii=1:length(percents)
%%%  if ii==length(percents)
%%%   formatFields{ii}=strtrim(formatIn(percents(ii):end));
%%%  else
%%%   formatFields{ii}=strtrim(formatIn(percents(ii):percents(ii+1)-1));
%%%  end
%%%  %matlab seems to have some issue with the decimal digits. Get rid of width and decimal spec
%%%  if any(formatFields{ii}=='.')
%%%   formatFields{ii}=formatFields{ii}([1,end]);
%%%  end % if any(formatFields{end}=='.
%%% end % for ii=1:length(percents)
%%% ;%We should treat everything like a %#c not a %#s
%%% formatFields=strrep(formatFields,'s','c');
%%% %Now form the IO list for assigning the calling workspace
%%% IOlist={};
%%% for ii=1:length(varargin)
%%%  if iscell(varargin{ii}) %an implied do loop, make a list
%%%   IDL(1)=evalin('caller',varargin{ii}{3});
%%%   IDL(2)=1;
%%%   if length(varargin{ii})==5
%%%    IDL(2)=evalin('caller',varargin{ii}{4});
%%%    IDL(3)=evalin('caller',varargin{ii}{5});
%%%   else
%%%    IDL(3)=evalin('caller',varargin{ii}{4});
%%%   end
%%%   for jj=IDL(1):IDL(2):IDL(3)
%%%    IOlist={IOlist{:},regexprep(varargin{ii}{1},['\<',varargin{ii}{2},'\>'],sprintf('%d',jj))};
%%%   end
%%%%%%   jjl=IDL(1):IDL(2):IDL(3);
%%%%%%   IOlist(length(IOlist)+1:length(IOlist)+1+length(jjl)-1)=cell(1,length(jjl));
%%%%%%   for jj=1:length(jjl)
%%%%%%    IOlist{jj}=regexprep(varargin{ii}{1},['\<',varargin{ii}{2},'\>'],sprintf('%d',jj));
%%%%%%   end
%%%  elseif ischar(varargin{ii}) %regular string input, so one IOlist item per element of array
%%%                              %assume no vector indexing on non scalars with subscripts
%%%   if any(varargin{ii}=='(') || any(varargin{ii}=='{') || ...
%%%        evalin('caller',['ischar(',varargin{ii},')'])
%%%    IOlist={IOlist{:},varargin{ii}};
%%%   else
%%%    %'wait',keyboard
%%%    %assume this is a single variable
%%%    for jj=1:evalin('caller',['prod(size(',varargin{ii},'))'])
%%%     IOlist={IOlist{:},[varargin{ii},'(',num2str(jj),')']};
%%%    end % for jj=1:evalin('caller',
%%%   end % if any(varargin{ii}=='(')
%%%  else
%%%   warning('readFmt didn''t understand what it was given')
%%%   (varargin{ii})
%%%   return
%%%  end
%%% end % for ii=1:length(varargin)
%%%     %TODO: I read it in w textscan, then sprintf it into a string.
%%%     %     why not just read in the correct with as a string in all cases (numeric and string)?
%%%     %now start assigning
%%% readErrFlag=false;readEndFlag=false;
%%% tempPos=0; currentPos=0;
%%% whereFF=1;nFF=length(formatFields);
%%% %we want to execute at least one fgetl
%%% if isnumeric(fidIn) %fidIn is a file ID
%%%  dataLine=fgetl(fidIn); if dataLine==-1, readEndFlag=true; return; end
%%% elseif ischar(fidIn) %they are trying to read a string
%%%  dataLine=fidIn;
%%% end % if isnumeric(fidIn)
%%% for ii=1:length(IOlist)
%%%  if any(~isspace(dataLine(currentPos+1:end)))
%%%   %assume there is at least one format field...
%%%   %determine whether we count the next ff (don't if it is a tab field)
%%%   if strcmp(formatFields{whereFF}(end),'t')
%%%    currentPos=str2num(formatFields{whereFF}(2:end-1))-1;
%%%    whereFF=whereFF+1;
%%%   end % if strcmp(formatFields{whereFF}(end),
%%%   ;%get the next value in dataLine with the next formatField
%%%   isLog=0;
%%%   if strcmpi(formatFields{whereFF}(end),'l'), formatFields{whereFF}(end)='c'; isLog=1; end
%%%   [val,foo,readErrFlag,tempPos]=sscanf(dataLine(currentPos+1:end),formatFields{whereFF},1);
%%%   if isLog
%%%    if ~isempty(regexpi(val,'f')), val=0; else, val=1; end
%%%    %if ~isempty(regexpi(val{1},'f')), val{1}=0; else, val{1}=1; end
%%%    formatFields{whereFF}(end)='l';
%%%   end
%%%   currentPos=currentPos+tempPos-1;
%%%   %now assign that to the corresponding IOlist value in the caller workspace
%%%   switch formatFields{whereFF}(end)
%%%     case {'f','g','u','i'}
%%%       evalin('caller',[IOlist{ii},'=',sprintf('%g',val),';']);
%%%       %evalin('caller',[IOlist{ii},'=',sprintf(formatFields{whereFF},val{1}),';']);
%%%     case {'l'}
%%%       evalin('caller',[IOlist{ii},'=',sprintf('%d',val),';']);
%%%     case {'s'}
%%%       evalin('caller',[IOlist{ii},'(1:',sprintf('%d',length(val)),')=''',val,''';']);
%%%       evalin('caller',[IOlist{ii},'(',sprintf('%d',length(val)),'+1:end)='' '';']);
%%%     case {'c'}
%%%       evalin('caller',[IOlist{ii},'(1:',sprintf('%d',length(val)),')=''',val,''';']);
%%%       evalin('caller',[IOlist{ii},'(',sprintf('%d',length(val)),'+1:end)='' '';']);
%%%   end
%%%   whereFF=whereFF+1;
%%%   % if we run out of ff first, then get a new line and reset ff
%%%  else %we have run out of data on this dataLine, so this IOlist spot gets 
%%%       %a zero or empty string until we run out of ff
%%%   switch formatFields{whereFF}(end)
%%%     case {'f','g','u','i'}
%%%       evalin('caller',[IOlist{ii},'=0;']);
%%%     case {'s','c'}
%%%       evalin('caller',[IOlist{ii},'='''';']);
%%%   end % switch formatFields{whereFF}(end)
%%%   whereFF=whereFF+1;
%%%  end % if any(~isspace(dataLine(currentPos+1:end)))
%%%  if whereFF>nFF && ii<length(IOlist)
%%%   if isnumeric(fidIn)
%%%    dataLine=fgetl(fidIn); if dataLine==-1, readEndFlag=true; break; end
%%%    currentPos=0;
%%%    whereFF=1;
%%%   elseif ischar(fidIn) %they are trying to read a string
%%%    readEndFlag=true; break;
%%%   end % if isnumeric(fidIn)
%%%  end % if whereFF>nFF && ii<length(IOlist)
%%% end % for ii=1:length(IOlist0
%%% ;%finished the IOlist, anything else in the line is ignored
%%%end % function [readErrFlag,
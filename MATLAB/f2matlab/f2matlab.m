function [filestr,numErrors,extraFunctions,localVar,varp,typeDefs]=f2matlab(filename,varargin)
%f2matlab(filename)
% Call with the full function name as a string, including extension.
%
% f2matlab assumes all the pertinent program elements are in this one file.
%  So, put all modules, functions, subroutines, etc into one file.
%
% I now also do conversion/translation/validation/optimization consulting.
% Please refer to my webpage:
% http://engineering.dartmouth.edu/~benjamin_e_barrowes/consulting/consultingIndex.html

% Some flags
want_kb=0;  % 1 ==> if keyboard mode is desired after some conversion steps
want_ze=1;  % 1 ==> direct f2matlab to zero all array variables.
want_fi=1;  % 1 ==> direct f2matlab to try to put fix()'s around declared integers.

want_smm=1; % 1 ==> try to deal with shape mismatching on in/out vars, 0 ==> don't
want_row=1; % 1 ==> 1-D fortran arrays become row vecs (default), if 0 then column vecs
            %        !!!! don't forget to change the definition in mlPointer
want_lc=0;  % 1 ==> try to preserve case on variable names

want_cla=0; % 1 ==> deal with possible command line arguments, 0 ==> don't
want_pst=1; % 1 ==> have local variables be persistent by default (fortran behavior), 0 => not
want_vai=1; % 1 ==> add "varargin" to the input args on all functions (useful in some cases)

want_for=1; % 1 ==> increment for loop vars on exit
want_MP=0;  % 1 ==> change all the local vars in the main program to have an MP suffix 
want_gl=0;  % 1 ==> use global statements instead of module decs in subprograms

want_arr=1; % 1 ==> try to reshape >1d arrays on input, 0 ==> don't
want_fun=1; % 1 ==> ensure function inputs are changed in calling workspace, 0 ==> don't
            
want_exf=0; % 1 ==> add in extra files at the end of this file (eg readFmt, writef, etc.)
            % 0 ==> copy these files into the current directory
            %-1 ==> do nothing (hope matlab can find them on the path)

%other variables
want_fb=1;  % 1 ==> provides feedback at key steps in the conversion process
want_ifi=0; % 1 ==> leave include files inline if there are functions in it
wantIndent=0;%1 ==> try to indent file with emacs after conversion
want_lmc=1; %run last minute changes if nonzero
want_point=0;%1 ==> use new mlPointer class, 0 ==> use old way
global want_ALLpoint
want_ALLpoint=1&want_point;%1 ==> use new mlPointer class for ALL non-scalars
if want_ALLpoint, want_point=1; end

%%%%% most reliable translation
%%%want_kb=0;
%%%want_ze=1;
%%%want_fi=1;
%%%want_smm=1;
%%%want_row=1;
%%%want_lc=0;
%%%want_cla=1;
%%%want_pst=1;
%%%want_vai=1;
%%%want_for=1;
%%%want_MP=0;
%%%want_gl=0;
%%%want_arr=1;
%%%want_fun=1;
%%%want_exf=1;

%%% [0,1,1,1,1,0,1,1,1,1,0,0,1,1,0]

% set flags here temporarily
%%%want_kb=0;
%%%want_ze=1;
%%%want_fi=1;
%%%want_smm=1;
%%%want_row=1;
%%%want_lc=0;
%%%want_cla=1;
%%%want_pst=1;
%%%want_vai=1;
%%%want_for=1;
%%%want_MP=0;
%%%want_gl=0;
%%%want_arr=1;
%%%want_fun=1;
%%%want_exf=1;




% Remember ---------------------------------------------------------------------------
% use examineFortranVariablesFromCore to compare workspaces between fortran and matlab

global fortranFileSuffixes files originalDir pathsTOadd originalFileSuffix informationRun sublistF sublist_files bcom
global modLocalVar modVarp modTypeDefs
if isempty(modLocalVar),   modLocalVar={};  end
if isempty(informationRun), informationRun=0; end

subfun=0; goon=0; ismod=0; switches=[]; tStart=cputime;
if ~isempty(varargin) && isnumeric(varargin{1}) && varargin{1}(1)~=inf
 % assume they are passing in switches move other varargin down 1
 switches=varargin{1};
 if length(varargin)>1
  varargin={varargin{2:end}};
 else
  varargin={};
 end
end
assignSwitches
if ~isempty(varargin)
 if ischar(varargin{1})
  subfun=1;
  goon=1;
 elseif varargin{1}==inf
  %There still might be switches
  if length(varargin)>1 && ~isempty(varargin{2})
   switches=varargin{2};
   assignSwitches
  end
  %we have a module declaration file
  ismod=1;   varargin={};   goon=0; want_ze=1;
  if isempty(modLocalVar)
   modLocalVar={};
  end
 end
else
 goon=1;
end
if goon
 global funstr_all s_all fs_good_all inout whichsub  
end
global sublist_all modUsedMods numstr wordstr changeCase tempcc tempccMP allTypeDefs suborfun allLocalVar allEntrys allExtWords imlPath MLapp
global productionRun
tt1=now;

%Load keywords and function words.
MLkeywords={'break';'catch';'for';'global';'otherwise';'persistent';'switch';'try';'refresh'};
MLapp='_ml';  protVar='PROTECTED'; f2m_temp='f2m_t';
shapeVar='_shape';  origVar='_orig';
needRS={}; %need resizing of arrays
fortranVarOrRes={'cycle','type'};
type_words={'program';'subroutine';'function'}; %keep this order of words for suborfun later
type_words2={'program';'function';'subroutine';'module';'blockdata';'interface'};
keywordsbegin={'for';'while';'switch';'if';'do';'else';'elseif';'case';'call';'global';'where';'elsewhere'};
var_words={'real';'complex';'integer';'logical';'character';'implicit';'intrinsic';'dimension';'common';'double';'precision';'doubleprecision';'intent';'allocatable';'pointer';'equivalence';'external';'parameter';'save';'automatic';'private';'public';'static';'optional';'volatile';'data';'type';'recursive';'elemental';'namelist'};
operators={'=>' '=';'**' '.^';'/' './';'*' '.*'};
logicalops={'/=' '~=';'.and.' '&';'.or.' '|';'.neqv.' '~=';'.eqv.' '==';'.le.' '<=';'.eq.' '==';'.ge.' '>=';'.gt.' '>';'.lt.' '<';'.ne.' '~=';'.true.' 'true';'.false.' 'false'};
TFops={'.true.','true','ttttttt';'.false.','false','fffffff'};
branchops={'end do' 'end';'end  do' 'end';'end if' 'end';'end  if' 'end';'enddo' 'end';'endif' 'end';'end select' 'end';'do while' 'while';'do  while' 'while';'else if' 'elseif';'case default' 'otherwise';'select case' 'switch'};
funwords=getfunwordsonly;
funwordsML=getfunwordsonlyML;
funwordsMLR=getReservedMLfunwords; MLR_suffix='_ffn';
funwordsNoRemoveEq={'random_seed';'open';'write';'format';'date_and_time'};
getNumstrWordstr
implicit=implicitRules;
r=char(10);
fortranfunwords={'dble';'aimag';'do';'enddo';'endif';'int';'iji';'true';'false';'cmplx';'conj'};
fs_good=[]; dumvar='dumvar'; commonvars=cell(0); persistentVars=cell(0);
formats=cell(0,2);
extwords=cell(0);
entrys=cell(0);
numErrors=0;
setUpLocalVar
statementFunction=cell(0);   statementFunctionLines=[];
varPrefix='$_#_$_#_'; perRep='`';
global DQ
DQ{1}='a1213141516171819100001_';
DQ{2}=DQ{1};DQ{2}(1)='b';
DQ{3}='-123repwithsinglequote321-';
DQ{4}='removeThisStringAtEnd';
MPstr={'MP','L'};
global fn16
extraFunctions=[];
sublist=cell(0,9);
usedMods=[];
varp=cell(0);
typeDefs=cell(0,2);
if ~subfun && ~ismod
 if isempty(modUsedMods)
  modUsedMods=cell(0,2);
 end
 allTypeDefs=cell(0,2);
 changeCase=cell(0,1);
 suborfun=[];
end
globVar={}; % for want_gl
vallocRep='_function_handle_ph';
brack2paren={'*BR2PAR1','*BR2PAR2'}; %when you want to protect a bracket to stay a parenthesis
resultVar='';
noKeep='removeThisLineFromTheProgram';
needData=0;needDataStr='firstCall';
funNameSuffix='%functionCalledOnThisLine';
funHandleNameSuffix='%functionHandleCalledOnThisLine';
needThings=zeros(1,1);
blockDataList={}; %list of blockdata names
if isempty(bcom), bcom='!!!beb~'; end
if ~isempty(productionRun) && productionRun==1
 wantIndent=1;
end
%needThings(1) => need unitmlfid for opening files


%First read the function into funstr.
if ~subfun
 if ~ismod
  fprintf(1,'-----------------------------------------------------------\n')
  fprintf(1,'|      f2matlab -- Ben Barrowes, Barrowes Consulting      |\n')
  fprintf(1,'-----------------------------------------------------------\n')
  fn16=[];
 end
 allLocalVar={}; allLocalVar{1}='placeholder';
 allExtWords={}; allExtWords{1}='placeholder';
 allEntrys={};   allEntrys{1}='placeholder';
 funstr=cell(1,1);
 funstr_all=cell(1,1);
 if 1%exist(filename,'file')==2
  fid=fopen(filename); filestr=fscanf(fid,'%c'); fclose(fid);
  if length(filestr)==0, return; end
  filestr=regexprep(filestr,[wordstr,'__fv2\>'],['$1_fv']);
  filestr=regexprep(filestr,'''//''','');
  %'derrrrrrrrrrr',filestr,kb
  if ~isempty(bcom)
   filestr=regexprep(filestr,bcom,'');
  end
  %filestr=regexprep(filestr,'\<use\> i_',bcom);
  
  disp(['Before includes ',filename,' (',num2str(cputime-tStart),' elapsed)']);
  takeCareOfIncludeFiles_fast

%%%  if strcmpi(filename,'readcontancompartsdt.beb')
%%%   'iiiiiiiiiii 11111111',filestr,kb
%%%  end

  filestr=regexprep(filestr,'\%end(\W)','%eml$1'); %in case end is a var in a derived type
  ;% protect percents from being replaced later
  if ~ismod
   %filestr=regexprep(filestr,'\%',perRep);
   filestr=strrep(filestr,'%',perRep);
  end
  if ~strcmpi(filestr(length(filestr)),r), filestr=[filestr,r]; end

%%%  % remove blank lines (fortran doesn't care, but the readin routine
%%%  % doens't continue lines correctly with blank lines.
%%%  while ~isempty(strfind(filestr,[r,r]))
%%%   filestr=strrep(filestr,[r,r],r);
%%%  end

  if filestr(1)=='!' || filestr(1)=='%'
   filestr=['%',r,filestr]; 
  end

  
%%%  if ~isempty(strfind('writesteam',filename))
%%%  'tttttttt1122',filename,kb
%%%  end
  funstr=filestr2funstr_2(filestr,1,2,inf,1);

  
  
%%%  %fix ! comments (change to %) and semicolons
%%%  filestr=regexprep(filestr,...
%%%                    ['[ \t\f\v]*\&[ \t\f\v]*[\r\n]+[ \t\f\v]*[\&]*([ \t\f\v\r\n]*)'],'$1');
%%%  funstr=strread(filestr,'%s','delimiter',r);  
%%%  funstr=strtrim(funstr);
%%%  temp3=cellfun('isempty',funstr);
%%%  temp8=cellfun('isempty',regexp(funstr,'^&'));
%%%  temp9=cellfun('isempty',regexp(funstr,'&$'));
%%%  temp1=regexp(funstr,['[!;]'],'once');
%%%  for i=find(~cellfun('isempty',temp1))'
%%%   temp2=find(funstr{i}=='!');
%%%   if ~isempty(temp2)
%%%    for j=1:length(temp2)
%%%     if temp2(j)==1
%%%      funstr{i}(1)='%';
%%%     else
%%%      %showall(funstr),funstr{i},i,'cccccccccccc22',kb
%%%      if temp2(j)<=length(funstr{i}) && validSpot(funstr{i},temp2(j))
%%%       goon=1;
%%%       %let's put these back before this line if this is a good line
%%%       if temp2(j)>1 && any(~isspace(funstr{i}(1:temp2(j)-1))) && i>1
%%%        for ii=i-1:-1:1
%%%         %temp3=isempty(funstr{ii});
%%%         %temp3=find(~isspace(funstr{ii}),1,'first');
%%%         %temp4=find(~isspace(funstr{ii}),1,'last');
%%%%%%         ii
%%%%%%         funstr{ii}
%%%%%%         'ffffffffeeeeeeeeeee10',showall(funstr),kb
%%%         if temp3(ii) || (temp9(ii) && temp8(ii+1))
%%%%%%          if temp3(ii) || (temp8(ii) && temp9(ii) && temp8(ii+1))
%%%%%%         if isempty(temp3) || (funstr{ii}(temp3)~='&' && funstr{ii}(temp4)~='&' &&...
%%%%%%                               funstr{ii+1}(find(~isspace(funstr{ii+1}),1,'first'))~='&')
%%%%%%       funstr{ii}(temp4)~='&'
%%%          funstr{ii}=[funstr{ii},r,'%',funstr{i}(temp2(j)+1:end)];
%%%          funstr{i}=funstr{i}(1:temp2(j)-1);
%%%          goon=0;
%%%          %funstr,funstr{i},i,ii,'cccccccccccc',kb
%%%          break
%%%         end
%%%        end
%%%       end
%%%       if goon
%%%        funstr{i}=[funstr{i}(1:temp2(j)-1),r,'%',funstr{i}(temp2(j)+1:end)];
%%%       end
%%%      end % if temp3
%%%     end % if j==1
%%%    end % for j=1:length(temp2)
%%%   end % if ~isempty(temp2)
%%%   temp2=find(funstr{i}==';');
%%%   if ~isempty(temp2)
%%%    for j=length(temp2):-1:1
%%%%%%     temp3=~inastring_f(funstr{i},temp2(j)) && ~inaDQstring_f(funstr{i},temp2(j)) &&...
%%%%%%           ~incomment(funstr{i},temp2(j));
%%%     if validSpot(funstr{i},temp2(j))
%%%      funstr{i}=[funstr{i}(1:temp2(j)-1),r,funstr{i}(temp2(j)+1:end)];
%%%     end % if temp3
%%%    end % for j=length(temp2):-1:1
%%%   end % if ~isempty(temp2)
%%%  end % for i=1:length(funstr)
%%%  %put it into a string and then back again to catch the new returns
%%%  for i=1:length(funstr)
%%%   if isempty(funstr{i}) || funstr{i}(end) ~= r
%%%    funstr{i}=[funstr{i},r];
%%%   end
%%%  end
%%%  filestr=[funstr{:}];
%%%  rets=findstr(r,filestr);
%%%  rets=[0 rets];
%%%  funstr=strread(filestr,'%s','delimiter',r);
%%%  %funstr=strread(filestr,'%s','delimiter',r);  
  
  
  
  
 
  if want_fb&&~subfun&&~ismod,disp(['Read in the file ',filename,' (',num2str(cputime-tStart),' elapsed)']);end
  %'ffffffffeeeeeeeeeee09',showall(funstr),kb
 
 else
  error(['I can''t find the file ',filename,'...']);
 end
 %funstr=regexprep(funstr,{'\s+(';'(\s+';'\s+)';'\s+[';'[\s+';'\s+]'},{'(';'(';')';'[';'[';']'});
 %funstr=regexprep(funstr,'[ ]+(','(');
 %funstr=regexprep(funstr,'\s+(','(');

 
 funstr=deblank(funstr);
 %make sure has only enddo, no white space between
 funstr=regexprep(funstr,'end\s+do','enddo','ignorecase');
 funstr=regexprep(funstr,'endmodule','end module','ignorecase');
 funstr=regexprep(funstr,'endprogram','end program','ignorecase');
 funstr=regexprep(funstr,'endfunction','end function','ignorecase');
 funstr=regexprep(funstr,'endsubroutine','end subroutine','ignorecase');
 funstr=regexprep(funstr,'double\s+precision','doubleprecision','ignorecase');
 funstr=regexprep(funstr,'end\s+if','endif','ignorecase');
 funstr=regexprep(funstr,'block\s+data','blockdata','ignorecase');
 funstr=regexprep(funstr,['\.\<',TFops{1,2},'\>\.'],[TFops{1,2},TFops{1,3}],'ignorecase');
 funstr=regexprep(funstr,['\.\<',TFops{2,2},'\>\.'],[TFops{2,2},TFops{2,3}],'ignorecase');
 funstr=regexprep(funstr,['\<',TFops{1,2},'\>'],[TFops{1,2},MLapp],'ignorecase');
 funstr=regexprep(funstr,['\<',TFops{2,2},'\>'],[TFops{2,2},MLapp],'ignorecase');
 funstr=regexprep(funstr,['^(\<byte\>)'],'integer','ignorecase');
 funstr=regexprep(funstr,['^(\<no type\>)'],'real','ignorecase');
 funstr=regexprep(funstr,['(\.not\.)([a-z_A-Z])'],'$1 $2','ignorecase');
 
 %fix named or labeled do loops real quick
 funstr=regexprep(funstr,['\s*([a-z_A-Z]{1,1}\w*:)\s(do)(.*)'],['$2 $3 % $1'],'ignorecase');
 funstr=regexprep(funstr,['\s*(enddo)(.+)'],['$1 % $2'],'ignorecase');


 
 s=length(funstr);
 %whos,'gggggggg',funstr,keyboard

 if want_kb,disp('Just read the function in'); showall_f(funstr), keyboard, end
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
 %'jjjjjjjjjjjj',kb
 %get words that need to have their case preserved
 if want_lc && ~ismod
  caseProtectedML=getCaseProtectedML;
  changeCase={};
  %change all to lower case except strings and comments and variables
  for i=fliplr(fs_good)
   if ~isempty(funstrwords{i})
    temp=any(strcmpi(funstrwords{i}{1},{var_words{:},type_words{:}}));
    if temp
%%%     if any(strcmpi(funstrwords{i},'m2v2'))
%%%      funstr{i},kb
%%%     end
     for j=1:length(funstrwords{i})
      if ~(any(strcmpi(funstrwords{i}{j},var_words)) || ...
           any(strcmpi(funstrwords{i}{j},type_words)) ||... 
           any(strcmpi(funstrwords{i}{j},funwords)) ||... 
           incomment(funstr{i},funstrwords_b{i}(j)) || ...
           inastring_f(funstr{i},funstrwords_b{i}(j)) )
       % is the fortran ridiculous enough to have the word "end" as a variable?
       if strcmp(funstrwords{i}{j},'end')
        funstr{i}(funstrwords_b{i}(j):funstrwords_e{i}(j))='eml';
        funstrwords{i}{j}='eml';
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       end
       %we have a variable, save it
       changeCase{length(changeCase)+1}=funstrwords{i}{j};
      end % if temp && ~any(strcmpi(funstrwords{i}{j},
     end % for j=1:length(funstrwords{i})
%%%   if any(strcmp(funstrwords{i},'eml'))
%%%    funstr{i},kb
%%%   end
    end % if temp    
   end % if ~isempty(funstrwords{i})
  end % for i=fliplr(fs_good)
  [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'!',fs_goodHasAnyQuote);
  changeCase={changeCase{:},sublist{:,1}};
  changeCase={changeCase{~cellfun('isempty',{changeCase{:}})}};
  [temp1,temp2,temp3]=unique(lower(changeCase));
  keepSomeCases
  changeCase={changeCase{temp2}};
  temp1=strcmp(changeCase,lower(changeCase));
  changeCase={changeCase{~temp1}};
  temp2=find(ismember(lower(changeCase),caseProtectedML));
  for i=1:length(temp2)
   changeCase{temp2(i)}=lower(changeCase{temp2(i)});
  end
  %'freeeeeeee',changeCase,funstr,kb
  tempcc=changeCase;
  for i=1:length(changeCase)
   tempcc{i}=['\<',changeCase{i},'\>'];
  end
  % don't allow the small words to be capitalized
  temp5=3;
  temp1=find(cellfun('length',changeCase)<temp5);
  changeCase(temp1)=lower(changeCase(temp1));
 
%%%  % Now, if one of these words does appear in a string, then go with the 
%%%  %  capitalization in the string
%%%  temp=regexp(funstr,[''''],'once');
%%%  temp2=find(~cellfun('isempty',temp));
%%%  %'fffffffffff',kb
%%%  for i=temp2(:).'
%%%   for j=1:length(funstrwords{i})
%%%    if length(funstrwords{i}{j})>=ccLim && inastring_f(funstr{i},funstrwords_b{i}(j)) && ...
%%%         ~incomment(funstr{i},funstrwords_b{i}(j)) && ...
%%%         (funstr{i}(funstrwords_b{i}(j)-1)=='''' && ...
%%%          length(funstr{i})>funstrwords_e{i}(j) && ...
%%%          (funstr{i}(funstrwords_e{i}(j)+1)=='''' )) && ...
%%%         inwhichlast_f(i,funstrwords_b{i}(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==1
%%%     temp3=find(strcmpi(funstrwords{i}{j},changeCase));
%%%     if ~isempty(temp3)
%%%      changeCase{temp3(1)}=funstrwords{i}{j};
%%%     end
%%%    end
%%%   end
%%%  end
  
 end % if want_lc

 
 % change no line feed $ sign in formats
 temp0=find(~cellfun('isempty',regexpi(funstr,['(format|write)(.+)\$(\s*)\)'])))';
 for i=temp0
  [temp,temp1,temp2]=regexpi(funstr{i},['\$(\s*)\)']);
  temp4=',';
  if funstr{i}(lastNonSpace(funstr{i},temp(1)))==','
   temp4='';
  end % if funstr{i}(lastNonSpace(funstr{i},
  temp5='''';
  if strcmpi(funstrwords{i}{1},'write')
   temp5='"';
  end % if strcmpi(funstrwords{i}{1},
  funstr{i}=[funstr{i}(1:temp(1)-1),temp4,temp5,'$',temp5,')',funstr{i}(temp1(1)+1:end)];
  [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
  
  %'vvvvvvvvvvvvvvvv22',showall(funstr),kb 
 end % for i=temp0
 
 
 %lower case all those lines with no ' or % in them
 %  and $ => _ ($ can be part of var names in fortran)
 temp=regexp(funstr,['[''"]'],'once');
 temp1=regexp(funstr,['[%]'],'once');
 temp2=find(cellfun('isempty',temp) & cellfun('isempty',temp1));
 temp4=find(~(cellfun('isempty',temp) & cellfun('isempty',temp1)));
 funstr(temp2)=lower({funstr{temp2}}).';

 
 
%%% if strcmpi(filename,'test2.f90')
%%%  funstr,kb
%%% end
 
 
 
 
 
 
 
 funstr(temp2)=regexprep({funstr{temp2}},'\$','_').';

 
 
 
 %funstr,kb
 
 
 
 
 
 %change all to lower case except strings and comments
 if isempty(files)
  for i=temp4(:).'
   %for i=find(~cellfun('isempty',temp))'
   for j=1:length(funstrwords{i})
%%%   if any(strcmpi(funstrwords{i},'RlSAT'))
%%%    funstr{i},'\\\\\\\\\\\\',kb
%%%   end
    if validSpot(funstr{i},funstrwords_b{i}(j))
     funstr{i}(funstrwords_b{i}(j):funstrwords_e{i}(j))=...
         lower(funstr{i}(funstrwords_b{i}(j):funstrwords_e{i}(j)));
    else
     %break %in a comment or quote, so no further test on this line
    end % if ~temp2(j)
   end % for j=1:length(funstrwords{i})
  end % for i=fs_good
 end

 for i=temp4(:).'
  temp3=find(funstr{i}=='$');
  for j=1:length(temp3)
   if ~incomment(funstr{i},temp3(j)) && ~inastring_f(funstr{i},temp3(j)) && ...
        (length(funstrwords{i})>0 && ~strcmp(funstrwords{i}{1},'format'))
    funstr{i}(funstr{i}=='$')='_';
    %'pppppppp1',funstr{i},keyboard
   end % if ~incomment(funstr{i},
  end % for j=1:length(temp3)
 end % for i=temp4(:).
  
 
 % replace val and loc
 for i={'val','loc'}
  % added the [^a-z_A-Z0-9)] part because %val could be part of a type ref
  temp1=regexpi(funstr,['[^a-z_A-Z0-9)]',perRep,i{1},'\W']);
  temp2=find(~cellfun('isempty',temp1));
  if ~isempty(temp2)
   for j=1:length(temp2)
    if validSpot(funstr{temp2(j)},temp1{temp2(j)}(1))
     %'derrrrrgg',funstr{temp2(j)},kb
     funstr{temp2(j)}=regexprep(funstr{temp2(j)},[perRep,i{1}],[i{1},vallocRep]);
    end % if validSpot(funstr{i},
   end % for j=1:length(temp2)
  end
 end

%%% % Fix the logical operators
 for j=1:length(logicalops)
  funstr=strrep(funstr,logicalops{j,1},logicalops{j,2});
 end
%%% for j=1:length(logicalops)
%%%  temp2=strrep(funstr,logicalops{j,1},logicalops{j,2});
%%%  temp1=cellfun(@isequal,temp2,funstr);
%%%  funstr=temp2;
%%%  if any(~temp1)
%%%   for j=find(~temp1(:)')
%%%    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,j,fs_goodHasAnyQuote);
%%%   end
%%%  end
%%% end
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr); 
 
 
 %funstr,kb
 
 % see if the program tries to open 1 or 6 as a file
 if ~isempty(find(~cellfun('isempty',regexpi(funstr,'open\s*\(\s*unit\s*\=\s*1')))) | ...
      ~isempty(find(~cellfun('isempty',regexpi(funstr,'open\s*\(\s*\s*1'))))
  fn16=unique([fn16,1]);
 end
 if ~isempty(find(~cellfun('isempty',regexpi(funstr,'open\s*\(\s*unit\s*\=\s*6')))) | ...
      ~isempty(find(~cellfun('isempty',regexpi(funstr,'open\s*\(\s*\s*6'))))
  fn16=unique([fn16,6]);
 end
 
 % may have problems with "2." type stuff in octave, so add a 0 there
 %if (exist ('OCTAVE_VERSION'))
 % tempstr='(\b[0-9]+\.)([^0-9])';
 % temp2=regexprep(funstr,tempstr,'$10$2');
 %else
  % updatefunstr_f grabs words incorrectly for numbers like 0.d0, so...
  tempstr='\<(\d+\.)([eEdDqQ][+-]?\d+)+';
  temp2=regexprep(funstr,tempstr,'$10$2');
  %end
 temp1=cellfun(@isequal,temp2,funstr);
 funstr=temp2;
 if any(~temp1)
  for j=find(~temp1(:)')
   [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,j,fs_goodHasAnyQuote);
  end
 end

%%% if strcmpi(filename,'stest.beb')
%%%  'dddooooooooooodddddddddd',kb
%%% end

 % get rid of _kind on the end of numbers
 %if (exist ('OCTAVE_VERSION'))
 % tempstr='(((\b[0-9]+)?\.)?\b[0-9]+([eEdDqQ][-+]?[0-9]+)?)(_\w+)';
 %else
 tempstr='(\<(\d+\.\d+|\d+\.|\.\d+|\d+)([eEdDqQ][+-]?\d+)?)(_\w+)';
 %end
 % But only want to do non-strings

 [tempstr,temp1,temp2,temp3]=regexp(funstr,tempstr,'start','end','tokens','tokenExtents');
 for ii=find(~cellfun('isempty',tempstr))'
  for jj=length(temp1{ii}):-1:1
   if validSpot(funstr{ii},tempstr{ii}(jj))
    funstr{ii}=[funstr{ii}(1:tempstr{ii}(jj)-1),temp2{ii}{jj}{1},funstr{ii}(temp1{ii}(jj)+1:end)];
   end % if validSpot(funstr{temp2(j)},
  end % for jj=length(temp1{ii})
 end % for ii=find(~cellfun('isempty',
 

 
 %'vvvvvvvvvvvvvvvv',showall(funstr),kb
 
 if ~ismod
  %change all perRep back to % (if in a comment) or . (not)
  %tempstr=repmat('|',1,length(perRep));
  %funstr=regexprep(funstr,perRep,tempstr);
  temp=regexp(funstr,perRep);
  for i=find(~cellfun('isempty',temp))'
%%%   if any(strcmpi(funstrwords{i},'IterationAbsoluteAggregateTarget')) && any(strcmpi(funstrwords{i},'target'))
%%%    funstr{i},'\\\\\\\\\\\\',kb
%%%   end
   for j=length(temp{i}):-1:1
    temp2=incomment(funstr{i},temp{i}(j)) || inastring_f(funstr{i},temp{i}(j)) ...
          || inaDQstring_f(funstr{i},temp{i}(j));
    if temp2
     funstr{i}(temp{i}(j))='%';
     %funstr{i}=[funstr{i}(1:temp{i}(j)-1),'%',funstr{i}(temp{i}(j)+6:end)];
    else
     funstr{i}(temp{i}(j))='.';
     %funstr{i}=[funstr{i}(1:temp{i}(j)-1),'.',funstr{i}(temp{i}(j)+6:end)];
    end
    % don't really need to update because of this change
    %[s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   end % for j=1:length(funstrwords{i})
  end % for i=fs_good
 end

 if want_fb&&~subfun&&~ismod,disp(['preliminary simple changes (set 1) (',num2str(cputime-tStart),' elapsed)']);end

 %'ffffffff12345',funstr,kb
 
 % change all print statements to write statements
 temp=regexp(funstr,['\<print\W'],'once');
 for i=find(~cellfun('isempty',temp))'
  %funstr{i},'ssssssssssprint',kb
  temp1=find(strcmpi('print',funstrwords{i}),1,'first');
  if ~isempty(funstrwords{i}) && ~isempty(temp1)
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp1))
    %if ~isempty(funstrwords{i}) && strcmpi(funstrwords{i}{1},'print') && ~incomment(funstr{i},funstrwords_b{i}(1))
    [temp2,temp3]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(temp1));
    %if any(strcmp(funstrwords{i},'real')), funstr{i},temp2,temp3,'eeeeeeeeeeeee11',kb,end
    tempstr=[funstr{i}(1:funstrwords_b{i}(temp1)-1),'write(*,',temp2{1},') '];
    if ~isempty(temp3)
     tempstr=[tempstr,funstr{i}(temp3+1:end)];
    end
    funstr{i}=tempstr;
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   end % if ~isempty(funstrwords{i})
  end % if ~isempty(funstrwords{i}) && ~isempty(temp1)
 end % for i=find(~cellfun('isempty',

 % 'ffffffff1234',funstr,kb
 
 %fix some write statement quote issues
 temp2=regexp(funstr,['write'],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=fliplr(temp3)
  for j=length(funstrwords{i}):-1:1
   if j<=length(funstrwords{i})
    if strcmpi(funstrwords{i}{j},'write')
     if ~incomment(funstr{i},funstrwords_b{i}(j))&&~inastring_f(funstr{i},funstrwords_b{i}(j))
      %'-----------',funstr{i},funstrwords{i},kb
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany>1
       temp4=strtrim(regexprep(subscripts{2},'fmt\s*=\s*','','ignorecase'));
       %'-----------11',funstr{i},funstrwords{i},kb
       if temp4(1)=='"' || temp4(1)==''''
        temp6=nextNonSpace(temp4,1);
        if temp4(temp6)=='('
         temp4=['(',temp4(temp6+1:end)];
         goon=0;
        end
       end
       if temp4(end)=='"' || temp4(end)==''''
        temp6=lastNonSpace(temp4,length(temp4));
        if temp4(temp6)==')'
         temp4=[temp4(1:temp6-1),')'];
         goon=0;
        end
       end       
%%%       temp4=regexprep(temp4,['"\s*\('],['('],'once');
%%%       temp4=regexprep(temp4,['''\s*\('],['('],'once');
%%%       temp4=fliplr(regexprep(fliplr(temp4),['"\s*\)'],[')'],'once'));
%%%       temp4=fliplr(regexprep(fliplr(temp4),['''\s*\)'],[')'],'once'));
       % if first ' is acutally a '', then change all the '' to '
       temp5=strfind(temp4,'''');
       if ~isempty(temp5)
        if temp4(temp5(1)+1)==''''
         temp4=regexprep(temp4,'''''','''');
        end
       end
       funstr{i}=[funstr{i}(1:centercomma(1)),temp4,funstr{i}(parens(2):end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       %if any(strcmp(funstrwords{i},'breite')), funstr{i},'eeeeeeeeeeeee',kb,end
       %'ssssssssssssss',funstr{i},temp4,kb
      end
     end
    end
   end
  end
 end % for i=temp3

 %'ffffffff123',funstr,kb
 
 
  %split up the one line if statements
 temp1=0;
 for i=fliplr(fs_good)
  if ~isempty(funstrwords{i})
%%%       if any(strcmpi(funstrwords{i},'HISTOGRAM'))
%%%        'iiiiiiiiiiiii',funstr{i},keyboard
%%%       end     
   if strcmp(funstrwords{i}{1},'if')
    if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(1))
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     if any(strcmp('then',funstrwords{i}))
      funstr{i}=[funstr{i}(1:parens(2))];
     else
      funstr(i+3:end+2)=funstr(i+1:end);
      tempstr=funstr{i};
      funstr{i}=[tempstr(1:parens(2))];
      funstr{i+1}=[tempstr(parens(2)+1:end)];
      funstr{i+2}=['endif;'];
      temp1=1;
     end % if ~strcmp('end',
    end % if validSpot(funstr{i},
   end % if strcmp(funstrwords{i}{1},
  end % if ~isempty(funstrwords{i})
 end % for i=fliplr(fs_good)
 if temp1
  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
 end

 
 
 
 % if '' is in a single quote string '   ', then change to DQ{1}
 temp2=regexp(funstr,[''''''],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=temp3
  if ~isempty(funstr{i})
   temp1=strfind(funstr{i},'''''');
   %if any(strcmp(funstrwords{i},'jack')), funstr{i},'eeeeeeeeeeeee',kb,end
   %   while ~isempty(temp1)
    for jj=length(temp1):-1:1
     if ~incomment(funstr{i},temp1(jj))
      if inastring_f(funstr{i},temp1(jj))
%%%      if length(funstr{i})>temp1(jj) && funstr{i}(temp1(jj)+1)=='''' && ...
%%%           ~inastring_f(funstr{i},temp1(jj))
%%%       goon=1;
%%%       for j=1:length(funstrwords{i})
%%%        if strcmpi(funstrwords{i}{j},'write')
%%%         [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%         if howmany>0
%%%          if temp1(jj)>parens(1) && temp1(jj)<parens(2)
%%%           goon=0;break
%%%          end
%%%         end
%%%        end
%%%       end
%%%       if goon
       if strcmpi(funstrwords{i}{1},'write') || strcmpi(funstrwords{i}{1},'print')
        funstr{i}=[funstr{i}(1:temp1(jj)-1),DQ{1},DQ{1},funstr{i}(temp1(jj)+2:end)];
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       else
        funstr{i}=[funstr{i}(1:temp1(jj)-1),DQ{1},funstr{i}(temp1(jj)+2:end)];
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       end
        %funstr{i},kb
%%%        break
%%%       else
%%%        funstr{i}=[funstr{i}(1:temp1(jj)-1),DQ{2},funstr{i}(temp1(jj)+2:end)];
%%%       end
       %funstr{i},funstr{i}(1:temp1(jj)),'ccccccccccc',kb
      end % if length(funstr{i})>temp1(jj) && funstr{i}(temp1(jj)+1)=='''' && .
     end % if inaDBDQstring_o(funstr{ii},
    end % for jj=length(temp1):-1:1
        %    temp1=strfind(funstr{i},'''''');
        %   end % while ~isempty(temp1)
  end % if ~isempty(funstr{ii})
 end

 % if ' is in a double quote string " ", then change to '', unless it's in a write or a format
 temp2=regexp(funstr,['"'],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=temp3
  %for i=1:s
  if ~isempty(funstr{i})
   temp1=strfind(funstr{i},'''');
   if ~isempty(temp1)
    for jj=length(temp1):-1:1
     if inaDQstring_f(funstr{i},temp1(jj)) && ~incomment(funstr{i},temp1(jj))
%%%      goon=1;
%%%      for j=1:length(funstrwords{i})
%%%       if strcmpi(funstrwords{i}{j},'write')
%%%        [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%        if howmany>0
%%%         if temp1(jj)>parens(1) && temp1(jj)<parens(2)
%%%          goon=0;break
%%%         end
%%%        end
%%%       end
%%%      end
%%%      if strcmpi(funstrwords{i}{1},'print')
%%%       %'pppppppppppp',kb
%%%       [temp5,temp6]=getTopGroupsAfterLoc(funstr{i},1);
%%%       if length(temp6)>0 && (temp1(jj)>funstrwords_e{i}(1) && temp1(jj)<temp6(1))
%%%        goon=0;break
%%%       end % if length(temp6)>0 && (temp1(jj)>funstrwords_e{i}(1) && temp1(jj)<temp6(1))
%%%      end % if strcmpi(funstrwords{i}{1},
%%%      if goon
       funstr{i}=[funstr{i}(1:temp1(jj)-1),DQ{1},funstr{i}(temp1(jj)+1:end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
%%%      end
     end % if inaDBDQstring_o(funstr{ii},
    end % for jj=length(temp1):-1:1
   end % if ~isempty(temp1)
  end % if ~isempty(funstr{ii})
 end

 
 
 
 % if "" is in a double quote string " ", then change to "
 temp2=regexp(funstr,['""'],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=temp3
  if ~isempty(funstr{i})
   temp1=strfind(funstr{i},'""');
   if ~isempty(temp1)
    for jj=length(temp1):-1:1
     %'puuuuuuuuuuu',funstr{i},temp1,jj,kb
     if inaDQstring_f(funstr{i},temp1(jj)) && ~incomment(funstr{i},temp1(jj))
       funstr{i}=[funstr{i}(1:temp1(jj)-1),DQ{2},funstr{i}(temp1(jj)+2:end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end % if inaDBDQstring_o(funstr{ii},
    end % for jj=length(temp1):-1:1
   end % if ~isempty(temp1)
  end % if ~isempty(funstr{ii})
 end


 
 %fix the " to be '
 %funstr=strrep(funstr,'"','''');
 temp2=regexp(funstr,['"'],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=temp3
  if ~isempty(funstr{i})
   temp1=strfind(funstr{i},'"');
   if ~isempty(temp1)
    for jj=length(temp1):-1:1
     if ~inastring_f(funstr{i},temp1(jj))
      %funstr{i}=[funstr{i}(1:temp1(jj)-1),'''',funstr{i}(temp1(jj):end)];
      funstr{i}(temp1(jj))='''';
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end % if inastring_f(funstr{ii},
    end % for jj=length(temp1):-1:1
   end % if ~isempty(temp1)
  end % if ~isempty(funstr{ii})
 end


 
 

 

 %'nnnnnnnnnnnnnnn11',showall(funstr),kb 
 %fix the freestanding /
 temp2=regexp(funstr,['/'],'once')';
 temp3=find(~cellfun('isempty',temp2));
 for i=temp3
  %if i==18, funstr{i}, 'dddddddddddddd',kb,end
  if ~isempty(funstrwords_b{i}) && (~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(1)))
   if ~isempty(funstrwords{i}) && any(strcmp(funstrwords{i}{1},{'write','format'}))
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    temp4=funstr{i}(parens(1):parens(2));
    for ii=length(temp4):-1:1
     if temp4(ii)=='/'
%%%      temp4
%%%      temp4(1:ii)
%%%      't44444',kb
      if temp4(nextNonSpace(temp4,(ii)))~=')' && temp4(nextNonSpace(temp4,(ii)))~=',' && temp4(nextNonSpace(temp4,(ii)))~='''' ...
           && ~inastring_f(temp4,ii) && ~inaDQstring_f(temp4,ii)
       temp1='/,';
       % watch out for e.g. 115 FORMAT(I4,6E12.5/(6E12.5),5/)
       if isnumber(temp4(ii-1)) && isempty(regexpi(temp4(ii-2),'[\.lgedfi]'))
        temp1=repmat('/,',1,str2num(temp4(ii-1)));
        temp4(ii-1)=' ';
        if temp4(nextNonSpace(temp4,(ii)))==','
         temp1=temp1(1:end-1);
        end
       end
       temp4=[temp4(1:ii-1),temp1,temp4(ii+1:end)];
      end % if temp4(ii+1)~=')' && temp4(ii+1)~=',
      if temp4(ii)=='/' && temp4(lastNonSpace(temp4,(ii)))~='(' && temp4(lastNonSpace(temp4,(ii)))~=',' && temp4(lastNonSpace(temp4,(ii)))~='''' ...
           && ~inastring_f(temp4,ii) && ~inaDQstring_f(temp4,ii)
       temp1=',/';
       % watch out for e.g. 115 FORMAT(I4,6E12.5/(6E12.5),5/)
       if isnumber(temp4(ii-1)) && isempty(regexpi(temp4(ii-2),'[\.lgedfi]'))
        temp1=repmat(',/',1,str2num(temp4(ii-1)));
        temp4(ii-1)=' ';
        if temp4(lastNonSpace(temp4,(ii)))==',' || temp4(lastNonSpace(temp4,(ii)))=='('
         temp1=temp1(2:end);
        end
       end
       temp4=[temp4(1:ii-1),temp1,temp4(ii+1:end)];
       %temp4=[temp4(1:ii-1),',',temp4(ii:end)];
      end % if temp4(ii+1)~=')' && temp4(ii+1)~=',
     end
     if temp4(ii)==''''
      if temp4(nextNonSpace(temp4,(ii)))~=')' && temp4(nextNonSpace(temp4,(ii)))~=',' && temp4(nextNonSpace(temp4,(ii)))~='/' && temp4(nextNonSpace(temp4,(ii)))~='''' ...
           && ~inastring_f(temp4,ii+1) && ~inaDQstring_f(temp4,ii+1)
       temp4=[temp4(1:ii),',',temp4(ii+1:end)];
      end % if temp4(ii+1)~=')' && temp4(ii+1)~=',
      if temp4(lastNonSpace(temp4,(ii)))~='(' && temp4(lastNonSpace(temp4,(ii)))~=',' && temp4(lastNonSpace(temp4,(ii)))~='/' && temp4(lastNonSpace(temp4,(ii)))~='''' ...
           && ~inastring_f(temp4,ii-1) && ~inaDQstring_f(temp4,ii-1)
       temp4=[temp4(1:ii-1),',',temp4(ii:end)];
      end % if temp4(ii+1)~=')' && temp4(ii+1)~=',
     end
    end % for ii=1:length(temp4)
    funstr{i}=[funstr{i}(1:parens(1)-1),temp4,funstr{i}(parens(2)+1:end)];
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    %temp4, funstr{i}, '-0987777777',kb
   end % if any(strcmp(funstrwords{i}{1},
  end
 end % for i=temp3


 %'nnnnnnnnnnnnnnn',showall(funstr),kb
 
 
 
 tempstr=cell(size(MLkeywords));
 temp3=cell(size(MLkeywords));
 for i=1:length(MLkeywords)
  tempstr{i}=[MLkeywords{i},MLapp];
  temp3{i}=['\<',MLkeywords{i},'\>'];
 end
 
 temp=regexp(funstr,[''''],'once');
 temp1=regexpi(funstr,['%|(^\d*\s*format)'],'once');
 temp2=find(cellfun('isempty',temp)&cellfun('isempty',temp1));
 funstr(temp2)=regexprep({funstr{temp2}},{temp3{:}},{tempstr{:}})';
 funstr(temp2)=regexprep({funstr{temp2}},'[ ]+\(','(');
 % we also have to fix vars that are ok in fortran, but not in ML, like 'if' 
 %'sssssssssssss',funstr,kb
 funstr(temp2)=regexprep({funstr{temp2}},'\<if\>(\s*)([^ \(]|$)',['if',MLapp,'$1$2'])';
 funstr(temp2)=regexprep({funstr{temp2}},'\<case\>(\s*)([^ \(]|$)',['case',MLapp,'$1$2'])';
 funstr(temp2)=regexprep({funstr{temp2}},['\<case',MLapp,'\>(\s*)(default)'],['case$1default'])';
 
%%% funstr(temp2)=regexprep({funstr{temp2}},'\<conj\>(\s*)([^\(]|$)',['conj',MLapp,'$1$2'])';
%%% funstr(temp2)=regexprep({funstr{temp2}},'^cycle$','ccccyyyycccclllleeee')';
%%% funstr(temp2)=regexprep({funstr{temp2}},'\<cycle\>',['cycle',MLapp])';
%%% funstr(temp2)=regexprep({funstr{temp2}},'^ccccyyyycccclllleeee$','cycle')';

 if want_fb&&~subfun&&~ismod,disp(['preliminary simple changes (set 2) (',num2str(cputime-tStart),' elapsed)']);end
 
 % change over matlab reserved words to varML
 for i=find(~cellfun('isempty',temp))'
  for j=length(funstrwords{i}):-1:1
   %if any(strcmp(funstrwords{i},'equity')), funstr{i},j,funstrwords{i},end
   temp=find(strcmp(funstrwords{i}{j},MLkeywords));
   if ~isempty(temp)
    if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_e{i}(j))
     funstr{i}=[funstr{i}(1:funstrwords_e{i}(j)),MLapp,funstr{i}(funstrwords_e{i}(j)+1:end)];
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    end % if ~inastring_f(funstr{i},
   end % if ~isempty(temp)
  end
  % if
  %temp4=regexp(funstr{i},'\<if\>(\s*)([^\(]|$)');
  [temp4,temp5]=regexp(funstr{i},'\<if\>(\s+)');
  for j=length(temp4):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp4(j))
    funstr{i}=[funstr{i}(1:temp4(j)-1),'if',funstr{i}(temp5(j)+1:end)];
   end
  end
  [temp4,temp5]=regexp(funstr{i},'\<if\>([^\(]|$)');
  for j=length(temp4):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp4(j))
    funstr{i}=[funstr{i}(1:temp4(j)-1),'if',MLapp,funstr{i}(temp4(j)+2:end)];
   end
  end
%%%  temp4=regexp(funstr{i},'\<if\>');
%%%  for j=length(temp4):-1:1
%%%   if ~inastring_f(funstr{i},temp4(j)) & ~incomment(funstr{i},temp4(j))
%%%    funstr{i}=regexprep(funstr{i},'\<if\>(\s+)',['if'],j);
%%%    funstr{i}=regexprep(funstr{i},'\<if\>([^ \(]|$)',['if',MLapp,'$1'],j);
%%%   end % if ~inastring_f(funstr{i},
%%%  end
  % case
  %temp4=regexp(funstr{i},'\<case\>(\s*)([^\(]|$)');
  temp4=regexp(funstr{i},'\<case\>');
  for j=length(temp4):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp4(j))
    temp5=nextNonSpace(funstr{i},temp4(j)+3);
    if temp5<=length(funstr{i}) && funstr{i}(temp5)~='(' && funstr{i}(temp5)~='d'
     funstr{i}=[funstr{i}(1:temp4(j)+3),MLapp,funstr{i}(temp4(j)+4:end)];
%%%     funstr{i}=regexprep(funstr{i},'\<case\>(\s*)([^\(]|$)',['case',MLapp,'$1$2'],j);
%%%     funstr{i}=regexprep(funstr{i},['case',MLapp,'(\s*)default'],['case$1default'],j);
    end
   end % if ~inastring_f(funstr{i},
   %'cccccccccc',funstr(i),kb
  end % for j=length(temp4):-1:1
      % conj
%%%  temp4=regexp(funstr{i},'\<conj\>(\s*)([^\(]|$)');
%%%  for j=length(temp4):-1:1
%%%   if ~inastring_f(funstr{i},temp4(j)) & ~incomment(funstr{i},temp4(j))
%%%    funstr{i}=regexprep(funstr{i},'\<conj\>(\s*)([^\(]|$)',['conj',MLapp,'$1$2'],j);
%%%   end % if ~inastring_f(funstr{i},
%%%  end % for j=length(temp4):-1:1
% cycle
%%%  temp4=regexp(funstr{i},'\<cycle\>');
%%%  for j=length(temp4):-1:1
%%%   if ~inastring_f(funstr{i},temp4(j)) & ~incomment(funstr{i},temp4(j))
%%%    funstr{i}=regexprep(funstr{i},'\<cycle\>',['cycle',MLapp],j);
%%%   end
%%%  end
 end % for i=1:s
 
 % save
 temp=regexp(funstr,'\<save\>');
 for i=find(~cellfun('isempty',temp))'
  for j=length(temp{i}):-1:1
   goon=0;
   if ~inastring_f(funstr{i},temp{i}(j)) && ~incomment(funstr{i},temp{i}(j))
    while 1
     %if this is the only thing on this line, then it will be commented later
     if length(funstrwords{i})==1 && length(funstrnumbers{i})==0
      break
     end
     if (temp{i}(j)+3)==length(funstr{i}) %this ends the line, so change
      goon=1;
      break
     end
     % save :: statement so don't change
     if ~isempty(findstr(funstr{i},'::'))
      break
     end
     if isletter(funstr{i}(nextNonSpace(funstr{i},temp{i}(j)+3)))
      if temp{i}(j)~=1
       goon=1;
       break
      else
       goon=0;
       break
      end
     else
      if funstr{i}(nextNonSpace(funstr{i},temp{i}(j)+3))=='/'
       goon=0;
       break
      else
       goon=1;
       break
      end
     end
     break
    end
   end
   if goon
    %'freeeeeeeee',funstr{i},kb
    funstr{i}=regexprep(funstr{i},'\<save\>',['save',MLapp],j);
   end
  end % for j=length(temp{i}):-1:1
 end

 % select
 temp=regexp(funstr,'\<select\>');
 for i=find(~cellfun('isempty',temp))'
  for j=length(temp{i}):-1:1
   goon=1;
   temp1=find(strcmpi('select',funstrwords{i}));
   if validFSpot(funstr{i},temp{i}(j))
    if temp1(j)>1 && strcmpi(funstrwords{i}{temp1(j)-1},'end')
     goon=0;
    end % if temp1(j)>1 && strcmpi(funstrwords{i}{temp1(j)-1},
    if temp1(j)<length(funstrwords{i}) && strcmpi(funstrwords{i}{temp1(j)+1},'case')
     goon=0;
    end % if temp1(j)<length(funstrwords{i}) && strcmpi(funstrwords{i}{temp1(j)+1},
   end % if validFSpot(funstr{i},
   if goon
    %'freeeeeeeee',funstr{i},kb
    funstr{i}=regexprep(funstr{i},'\<select\>',['select',MLapp],j);
   end
  end % for j=length(temp{i}):-1:1
 end

 %fix the semicolon
 temp=regexp(funstr,'[^;]$'); %if funstr{i}(end)~=';', funstr{i}=[funstr{i},';']; end
 temp=(~cellfun('isempty',temp));
 for i=fs_good
  %Deblank front and back
  funstr{i}=deblank(funstr{i});
  %Ensure semilcolon at end
  if temp(i) & ~isempty(funstr{i})
   funstr{i}=[funstr{i},';'];
  end
 end

 %sometimes use statements have a pointer on them !!! fix that TODO
 funstr=regexprep(funstr,['^[ ]*use(.*)=>'],['use$1']);
 
 
%%% % character varname*(#) need to be changed to varname(#)
%%% funstr=regexprep(funstr,['(character) (.+\w)\*\((.+)\)'],['$1\*$3 $2']);
 
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr); 

 %'a[][][][][][][][][]',funstr.',kb
 
 % 'end' when used as a variable
 temp=regexp(funstr,'\<end\>');
 for i=find(~cellfun('isempty',temp))'
  temp1=find(strcmp(funstrwords{i},'end'));
  if ~isempty(temp1)
   for j=length(temp1):-1:1
    if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp1(j)))
     goon=0;
     if temp1(j)==length(funstrwords{i}) || (temp1(j)<length(funstrwords{i}) && ...
          ~any(strcmp(funstrwords{i}{temp1(j)+1},{type_words2{:},'select'})))
      goon=1;
     end
     if ~(funstrwords_b{i}(temp1(j))>1 && ...
          any( ~isspace(funstr{i}(1:funstrwords_b{i}(temp1(j))-1)) & ...
               ~isnumber(funstr{i}(1:funstrwords_b{i}(temp1(j))-1))    )) %for "99999 end" etc.
      goon=0;
     end
     if goon
      funstr{i}(funstrwords_b{i}(temp1(j)):funstrwords_e{i}(temp1(j)))='eml';
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end
    end % if validSpot(funstr{i},
   end % for j=length(temp1):-1:1
  end % if ~isempty(j)
%%%    if any(strcmp(funstrwords{i},'start'))
%%%     funstr{i},kb
%%%    end
  
 end % for i=find(~cellfun('isempty',
 
 
 % type
 temp=regexp(funstr,'\<type\>');
 for i=find(~cellfun('isempty',temp))'
  temp2=find(strcmp(funstrwords{i},'type'));
  for j=length(temp2):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp2(j)))
    if temp2(j)==2 && strcmp(funstrwords{i}{1},'end') % is an end type
     continue
    end
    if any(nextNonSpace(funstr{i},funstrwords_e{i}(temp2(j)))==funstrwords_b{i}) %word after
     continue
    end
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp2(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    %'rttttttttttt',funstr,funstr{i},kb
    if howmany>0 
     if any(nextNonSpace(funstr{i},parens(2))==funstrwords_b{i}) || ...
          funstr{i}(nextNonSpace(funstr{i},parens(2)))==':' || ...
          funstr{i}(nextNonSpace(funstr{i},parens(2)))==','
      continue
     end
    end
    if inastring_f(funstr{i},funstrwords_b{i}(temp2(j))) || ...
         incomment(funstr{i},funstrwords_b{i}(temp2(j)))
     continue
    end
    %'ewqqqqqqqqqqqqqqqqq',funstr{i},kb
    funstr{i}=[funstr{i}(1:funstrwords_e{i}(temp2(j))),MLapp,funstr{i}(funstrwords_e{i}(temp2(j))+1:end)];
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    %'how did we do?',funstr{i},kb
   end
  end % for j=length(temp4):-1:1
 end % for i=find(~cellfun('isempty',

 
 funstr_all=funstr;
 s_all=s;
 fs_good_all=fs_good;
 if want_fb&&~subfun&&~ismod,disp(['Done with preliminary simple changes (',num2str(cputime-tStart),' elapsed)']);end
else
 funstr=funstr_all;
 s=s_all;
 fs_good=fs_good_all;
end

%%%% done with initial ~subfun if statement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%'rttttttttttt',funstr.',kb
%%%aa=find(strcmp({sublist{:,4}},'interface'))



%Get the base filename, and the program entry name
temp=findstr(filename,'.');
if ~isempty(temp)
 filename_base=filename(1:temp(end)-1);
else
 filename_base=filename;
end
if ~subfun
 this_fun_name=filename_base;
else
 this_fun_name=varargin{1};
end

%%%if strcmp(this_fun_name,'readhalfjunctiont')
%%% 'reeeeeeee78901',funstr,keyboard
%%%end

%change structure/record to derived types (CVF obsolete)
if ~subfun & ~ismod
 temp1=regexp(funstr,'\<structure\>');
 for i=s:-1:1
  if ~isempty(temp1{i})
   if validSpot(funstr{i},temp1{i}(1))
    funstr{i}=regexprep(funstr{i},{'^structure\>','\/'},{'type',''});
    %which word is this?
    temp2=find(funstrwords_b{i}==temp1{i}(1));
    %is this and end structure?
    if temp2==2 && strcmpi(funstrwords{i}{temp2-1},'end')
     funstr{i}=[funstr{i}(1:funstrwords_b{i}(temp2)-1),' type',funstr{i}(funstrwords_e{i}(temp2)+1:end)];
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    end
    %'sssssssss',funstr{i},kb
   end
  end
 end
 temp1=regexp(funstr,'^record\>\s*\/');
 for i=s:-1:1
  if ~isempty(temp1{i})
   if validSpot(funstr{i},temp1{i}(1))
    funstr{i}=regexprep(funstr{i},{'^record\>'},{'type'});
    %Switch the /'s to ()
    temp2=strfind(funstr{i},'/');
    if length(temp2)<2
     error(['problem converting record to type',r,funstr{i}]);
    end
    funstr{i}(temp2(1))='(';    funstr{i}(temp2(2))=')';
   end
  end
 end
end

%'ssssssssssssssssssstrrrrrrr',funstr,kb

% don't allow fortran routines to be named funwordsMLR
if ~subfun
 [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'%',fs_goodHasAnyQuote);
 [temp1,temp2,temp3]=intersect({sublist{:,1}},funwordsMLR);
 if ~isempty(temp1)
  % change that subprogram name in the entire file
  for i=1:length(temp1)
   funstr=regexprep(funstr,[funwordsMLR{temp3(i)},'(\s*)\('],[funwordsMLR{temp3(i)},MLR_suffix,'$1('],'ignorecase');
   sublist{temp2(i),1}=[funwordsMLR{temp3(i)},MLR_suffix];
  end % for i=1:length(temp1)
 end % if ~isempty(temp1)
end % if ~subfun
 


% get rid of interfaces... who needs 'em? and duplicate entrys????
if ~subfun
 %[sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'!',fs_goodHasAnyQuote);
 if ~ismod, sublist_all=sublist; end %this includes interface routine names
 fid=0;
 temp6=true(1,s);
 for i=size(sublist,1):-1:1
  if strcmp(sublist{i,4},'interface')
   temp6(sublist{i,2}:sublist{i,3})=false;
   fid=1;
  end % if strcmp(sublist{i,
  if (i>1 && any(strcmp(sublist{i,1},{sublist{1:i-1,1}})))
   % these duplicate routines might be contain'ed functions, so leave them
   %temp6(sublist{i,2}:sublist{i,3})=false;
   fid=1;
   warning(['****** found the duplicate routine: ',sublist{i,1},r,'*************** using the earlier one (code order)'])
  end % if strcmp(sublist{i,
 end
 %'hhhhhhhhhhhhhhoppppppppp',sublist,funstr,temp6,kb
 funstr={funstr{temp6}};
 if fid==1
  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
  [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'%',fs_goodHasAnyQuote);
 end % if fid==1
end






%%%if strcmpi(filename,'test1.spg')
%%% 'errrrrrrrrrrrrr',sublist,modLocalVar,kb
%%%end

%adjust things for modules
if ~ismod & ~subfun
 %Put the capitals back in sublist
%%% if want_lc
%%%  for i=1:size(sublist,1)
%%%   sublist{i,1}=regexprep(sublist{i,1},tempcc,changeCase,'ignorecase');
%%%  end % for i=1:size(sublist,
%%% end % if want_lc

 %sublist,sublist_all,ismod, subfun, modLocalVar, '//////44444444444', kb
 module_adj
 if isempty(modLocalVar), modLocalVar={}; end
 if isempty(modVarp), modVarp={}; end
 if isempty(modTypeDefs), modTypeDefs={}; end
 %now call f2matlab on that new module script
 fprintf(1,'********* Taking care of the modules (if there are any) ***\n')
 temp4=1;
 %1by1 adjust temp4 for 1by1
 if ~isempty(files)
  temp4=find(strcmpi({files.name},sublist{i,1}));
  if isempty(temp4)
   if ~isempty(strfind(sublist{i,1},MLapp))
    temp4=find(strcmpi({files.name},sublist{i,1}(1:end-length(MLapp))));
   end
   if isempty(temp4)
    error(['Could not find the module ',sublist{i,1},' in files'])
   end
  end % if isempty(temp4)
  if length(temp4)>1
   foo=1;
   if length(temp4)==length(unique({files(temp4).path}))
    temp4=temp4(find(strcmpi({files(temp4).path},pwd)));
    foo=0;
   end
   if foo
    error(['Found more than one module in files for ',sublist{i,1}])
   end % if foo
  end % if length(temp4>1)
      %'ttttttt4',sublist,files,%kb
 end % if ~isempty(files)

 % Now go through the modules in this file
 for i=1:size(sublist,1)
  %for i=size(sublist,1):-1:1
  if strcmp(sublist{i,4},'module')
   %'llllllllllllllll',sublist{i,1},kb
   if want_lc
    eval(['[temp,temp1,temp2,temp3,temp5,temp6]=f2matlab(''',...
          [regexprep(sublist{i,1},tempcc,changeCase,'ignorecase'),'.m'],''',inf);']);
   else
    [temp,temp1,temp2,temp3,temp5,temp6]=f2matlab([sublist{i,1},'.m'],inf,switches);
%%%    eval(['[temp,temp1,temp2,temp3,temp5,temp6]=f2matlab(''',...
%%%          [sublist{i,1},'.m'],''',inf);']);
   end
%%%   if strcmpi(this_fun_name,'mod4')
%%%    sublist,sublist_all,ismod, subfun, modLocalVar, '////////2222', kb
%%%   end
   modLocalVar{temp4,1}=sublist{i,1};
   modLocalVar{temp4,2}=temp3;
   modLocalVar{temp4,3}={};
   modVarp{temp4,1}=sublist{i,1};
   modVarp{temp4,2}=temp5;
   modTypeDefs{temp4,1}=sublist{i,1};
   modTypeDefs{temp4,2}=temp6;
   temp4=temp4+1;
  end % if strcmp(sublist{i,
 end % for i=size(sublist,

%%% % Find duplicates names in modules
%%% foo=cat(1,modLocalVar{:,2});
%%% if ~isempty(foo)
%%%  foo=foo(:,1);
%%%  for ii=1:size(modLocalVar,1)
%%%   if ~isempty(modLocalVar{ii,2})
%%%    bar=modLocalVar{ii,2}(:,1);
%%%    bar2={};
%%%    for jj=1:length(bar)
%%%     if ~strcmpi(bar{jj},'dumvar') && length(find(strcmp(bar{jj},foo)))>1
%%%      bar2={bar2{:},bar{jj}};
%%%      'dupppppppppppp',modLocalVar,ii,foo,bar,bar2,kb
%%%     end % if length(find(strcmp(bar{jj},
%%%    end
%%%    modLocalVar{ii,3}=bar2;
%%%   end % if ~isempty(modLocalVar{ii,
%%%  end % for ii=1:size(modLocalVar,
%%% end % if ~isempty(foo)
 
 %sublist,sublist_all,ismod, subfun, modLocalVar, '////////33333333333', kb
 
 [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'%',fs_goodHasAnyQuote);
 sublist_all=sublist;
 sublistF=sublist;
 suborfun=zeros(1,size(sublist,1));
 suborfun(find(strcmpi({sublist{:,4}},type_words{2})))=1; %subroutines
 suborfun(find(strcmpi({sublist{:,4}},type_words{3})))=2; %function
 
 %sublist,ismod, subfun, modLocalVar, '////////22', kb
end % if ~ismod

%%%if strcmpi(this_fun_name,'mod4')
%%% sublist,sublist_all,ismod, subfun, modLocalVar, '////////', kb
%%%end

% if the entire file was only modules, then we are done at this point
if ~subfun & ~ismod & size(sublist,1)==0
 return
end
oneBYone=~informationRun && exist('files','var')==1 && ~isempty(files) && ...
         (size(sublist,1)==1 && ~strcmp(sublist{1,4},'module'));


%We only want to work with this segment of the file,
if subfun
 temp=this_fun_name;
else
 temp=[];
end
if ~subfun 

 whichsub=1;
 segmentStarts=[sublist{:,2}];
 fun_name=sublist(:,1);

 this_fun_name=sublist{1,1};
 numSegs=length(segmentStarts);
 
 if oneBYone
  fun_name={files.name};
  allLocalVar={files.localVar};
  allExtWords={files.extwords};
  allEntrys  =  {files.entrys};
  inout      =   {files.inout};
  suborfun=[files(:).typenum];
%%%  suborfun=zeros(1,length(files));
%%%  suborfun(find(strcmpi({files.type},type_words{2})))=1; %subroutines
%%%  suborfun(find(strcmpi({files.type},type_words{3})))=2; %function
  whichsub=find(strcmpi({files.name},this_fun_name));
  subfun=suborfun(whichsub);
  temp1=1;
  if length(whichsub)>1
   for ii=1:length(whichsub)
    if strcmpi(pwd,files(whichsub(ii)).path)
     temp1=ii; break
    end % if strcmpi(pwd,
   end % for ii=1:length(whichsub)
   whichsub=whichsub(temp1)
  end
  if isempty(sublist_files) %only want to go through thisonce. Then save it in sublist_files.
   sublist=cell(length(files),11);
   for ii=1:length(files)
    if ~isempty(files(ii).sublist)
     sublist(ii,:)=files(ii).sublist;
    end % if ~isempty(files(ii).
   end
   sublist_files=sublist;
  else
   sublist=sublist_files;
  end
  %'a++++++++before',fun_name,this_fun_name,segmentStarts,whichsub,files,kb
  sublist_all=sublist;
 end % if ~informationRun
  
else
 whichsub=varargin{2};
 segmentStarts=varargin{3};
 fun_name=varargin{4};
 numSegs=length(segmentStarts);
 %sublist=sublist_all;
end


%%%fun_name,this_fun_name,temp5,temp2,segmentStarts,whichsub
%%% 'werrrrrrrrr',kb 

%varargin,whichsub,segmentStarts,fun_name,funstr,sublist,sublist_all,'[[[[[[[[[[ppppppppppp',kb

%Assign funstr and fs_good to scope only this segment if it is not a module
if ~ismod && ~oneBYone
 if ~isempty(segmentStarts)
  if ~isempty(sublist_all{whichsub,5})
   funstr={funstr{segmentStarts(whichsub):sublist_all{whichsub,5}}}';
   fs_good=fs_good((fs_good>=segmentStarts(whichsub))&(fs_good<=sublist_all{whichsub,5}));
   fs_good=fs_good-(fs_good(1)-1);
  else
   funstr={funstr{segmentStarts(whichsub):sublist_all{whichsub,3}}}';
   fs_good=fs_good(fs_good>=segmentStarts(whichsub)&fs_good<=sublist_all{whichsub,3});
   fs_good=fs_good-(fs_good(1)-1);
  end % if ~isempty(sublist_all{whichsub,
 end
end % if ~ismod


%funstr,varargin,whichsub,segmentStarts,fun_name,sublist,sublist_all,'[[[[[[[[[[uuuuuuuuuuu',kb

[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
if ~isempty(intersect(type_words,funstrwords{1}))
 showall_f(funstr(1),1);
end
disp(['    Number of lines:   ',num2str(s)])



%find all the format statements and their labels
temp=find(~cellfun('isempty',regexp(funstr,'\<format\>')));
if ~isempty(temp)
 for i=temp(:)'
  %for i=fs_good
  if any(strcmp(funstrwords{i},'format'))
   temp=find(strcmpi(funstrwords{i},'format'));
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp(1)))
    %funstr(i),formats,'ffffffffffff',keyboard
    %if ~inastring_f(funstr{i},funstrwords_b{i}(temp(1)))
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    if howmany>0
     %fix a format issue like this 
     %  106 FORMAT (6x(I10),6x(I15),6x(I15))
     tempstr=funstr(i);
     temp2=regexprep(funstr{i}(parens(1)+1:parens(2)-1),...
                     ['\s*(\d*x)\s*\(([a-z_A-Z0-9.]+)\)'],['$1,$2']);
     funstr{i}=[funstr{i}(1:parens(1)),temp2,funstr{i}(parens(2):end)];
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     
     for j=fliplr(find(funstrwords_b{i}>parens(1) & funstrwords_b{i}<parens(2)))
      if any(strcmp(funstrwords{i}{j},{funwords{:},{fortranVarOrRes{:}}})) && ~inastring_f(funstr{i},funstrwords_b{i}(j))
       funstr{i}=[funstr{i}(1:funstrwords_e{i}(j)),MLapp,funstr{i}(funstrwords_e{i}(j)+1:end)];
      end
     end
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     
     %if strcmp(funstrnumbers{i}{1},'1001'), funstr{i},formats,kb,'ffffffffff',end
     %funstr{i},formats,kb,'ffffffffffop',kb
     
     %found a format statement
     % there may be a string/num combo such as e20.13'tepoch='e20.13 that we have to split up
     goon=1;
     while goon
      goon=0;
      for ii=1:length(subscripts)
       temp=breakOffFirstFormat(subscripts{ii});
       temp3=length(temp);
       if temp3>1
        for jj=(length(subscripts):-1:ii+1) +(temp3-1)
         subscripts{jj}=subscripts{jj-(temp3-1)};
        end
        for jj=(1:length(temp))
         subscripts{jj+ii-1}=temp{jj};
        end
        goon=1;
       end
      end
     end
     %percent signs in formats need to be doubled to %% for matlab
     subscripts=regexprep(subscripts,'%','prcnt');
     howmany=length(subscripts); 
     formats{size(formats,1)+1,1}=funstrnumbers{i}{1};    temp5=size(formats,1);
     formats{temp5       ,2}=funstr{i}(funstrwords_b{i}(1):parens(2));
     formats{temp5       ,3}=howmany;
     formats{temp5       ,4}=subscripts;
     formats{temp5       ,5}=centercomma;
     formats{temp5       ,6}=parens;
     tempStr='';
     for ii=1:formats{temp5,3}
      temp4=',';if ii==formats{temp5,3}, temp4='';end
      %temp4=',';if ii==formats{temp5,3}, temp4=' '' \n''';end
      tempStr=[tempStr,convertFormatField(formats{temp5,4}{ii}),temp4];
     end % for j=1:formats{size(formats,
     formats{temp5,7}=tempStr;
     %if strcmp(funstrnumbers{i}{1},'1001'), funstr{i},formats,kb,end
    end % if howmany>0
   end
  end
 end
end % if ~isempty(temp)
    %funstr,formats,'ffffffffffff',keyboard




%%%%find all the entry's
%%%fid=regexp(funstr,['^\s*entry\>']); 
%%%temp1=find(~cellfun('isempty',fid))';
%%%for i=temp1(:).'
%%% entrys{length(entrys)+1}=funstrwords{i}{2};
%%%end % for i=temp1(:).
%%%
%%%%funstr,entrys,'ffffffffffffaaaaaaaa',keyboard
%%%

%%%if strcmp(this_fun_name,'tprhalfjunction')
%%% 'smack,smack,meback,2',funstr,localVar,modLocalVar,usedMods,modUsedMods,kb
%%%end


%which modules is this subroutine using?
if isempty(files) % ~strcmp(this_fun_name,'allocfegeomoned')
 if isempty(modLocalVar)
  temp3=[];
 else
  temp3=find(~cellfun('isempty',{modLocalVar{:,1}}));
 end
 if isempty(modUsedMods)
  temp=[];
 else
  temp=find(strcmp(this_fun_name,{modUsedMods{:,1}}));
 end
 if ~isempty(temp)
  [dummy,temp2,usedMods]=intersect({modUsedMods{temp,2}{:}},{modLocalVar{temp3,1}});
  usedMods=temp3(usedMods);
 end
else
 temp=find(strcmp(this_fun_name,{modUsedMods{:,1}}));
 if ~isempty(temp)
  for ii=1:length({modUsedMods{temp,2}{:}})
   temp3=find(strcmp(modUsedMods{temp,2}{ii},{modLocalVar{:,1}}));
   if length(temp3)==1
    usedMods=[usedMods,temp3];
   elseif length(temp3)>1
    % use the one in the same directory if possible
    temp5=0;
    for jj=1:length(temp3)
     if strcmp(files(temp3(jj)).path,pwd)
      temp5=1;
      usedMods=[usedMods,temp3(jj)];
      break
     end % if strcmp(files(temp3(jj)).
    end % for jj=1:length(temp3)
    if ~temp5 % no path match found... go with larger (more entries)?
     [temp6,temp7]=cellfun(@size,{modLocalVar{temp3,2}});
     [temp8,temp9]=max(temp6);
     usedMods=[usedMods,temp3(temp9)];
    end % if ~temp5
   else
    warning('used module not in files???')
   end % if length(temp3)==1
  end % for ii=1:length({modUsedMods{temp,
 end % if ~isempty(temp)
end % if isempty(files)


%Now use this to add to localVar, varp, and typeDefs when required.

%%%%which modules is this subroutine using?
%%%temp=find(~cellfun('isempty',regexp(funstr,'\<use\>'))).';
%%%if ~isempty(temp)
%%% for i=temp(:).'
%%%  temp4=strcmp(funstrwords{i},'use');temp4=temp4(1);
%%%  if ~inastring_f(funstr{i},funstrwords_b{i}(temp4)) & ~incomment(funstr{i},funstrwords_b{i}(temp4))
%%%   for j=temp4+1%:length(funstrwords{i}) %can only name 1 module per use
%%%    temp2=find(strcmp(funstrwords{i}{j},{modLocalVar{:,1}}));
%%%    usedMods=unique([usedMods,temp2]);
%%%   end % for j=temp4+1:length(funstrwords{i})
%%%  end % if ~inastring_f(funstr{i},
%%% end % for i=1:length(temp)
%%%end % if ~isempty(temp)
%%%%Now use this to add to localVar, varp, and typeDefs when required.


%Remove initial numbers from numbered lines with no continue
for i=fs_good
 if ~isempty(regexp(funstr{i},'^\s*[\d]+\s+','once')) 
  if ~strcmp(funstrwords{i}{1},'continue')
   funstr{i}=regexprep(funstr{i},'^\s*[\d]+(\s+)','$1');
  else
   funstr{i}=['% ',funstr{i}];   
  end % if ~strcmp(funstrwords{i}{1},
  [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
 end % if ~isempty(regexp(funstr,
end % for i=fs_good


% remove anything after the trailing ends 
funstr=regexprep(funstr,['^\s*end\s+'],'end %');
%except ending type defs
funstr=regexprep(funstr,['^\s*end %type'],'end type');

%'[][][][][][][]',funstr,ismod,kb


%Convert other segments and save them
filestr_subfun=[];
if whichsub==1
 inout=cell(length(fun_name),1);
 if (numSegs)>1
  disp(['********** f2matlab found the following ',num2str(length(fun_name)),' program units:']);
  disp(fun_name(:))
  for i=2:(numSegs)
   disp(['converting segment number ',num2str(i),' of ',num2str((numSegs)),...
        ' (',fun_name{i},')']);
   if ~isempty(switches)
    [temp2,temp3,temp4,temp5]=f2matlab(filename,switches,fun_name{i},i,segmentStarts,fun_name);
   else
    [temp2,temp3,temp4,temp5]=f2matlab(filename,fun_name{i},i,segmentStarts,fun_name);
   end
   numErrors=numErrors+temp3;
   filestr_subfun=[filestr_subfun,temp2];
   extraFunctions=unique([extraFunctions,temp4]);
   %'wait',temp2,keyboard
  end
 end
 whichsub=1;
end



%Misc tasks
%%%%fix the semicolon
%%%temp=regexp(funstr,'[^;]$'); %if funstr{i}(end)~=';', funstr{i}=[funstr{i},';']; end
%%%temp=(~cellfun('isempty',temp));
%%%for i=fs_good
%%% %Deblank front and back
%%% funstr{i}=deblank(funstr{i});
%%% %Ensure semilcolon at end
%%% if temp(i) & ~isempty(funstr{i})
%%%  funstr{i}=[funstr{i},';'];
%%% end
%%%end
%%%



%what if "data" is used as a variable?
temp=find(~cellfun('isempty',regexp(funstr,'\<data\>'))); temp=temp(:).';
if ~isempty(temp)
 for i=fliplr(temp)
 try % loop try
  if ~isempty(funstrwords{i})
   temp2=find(strcmp(funstrwords{i},'data'));
   if ~isempty(temp2)
    %'bnbnbnbnbnbnbnbnb',funstr{i},kb
    for j=length(temp2):-1:1
     if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp2(j)))
      %if "data" is the first word or before a :: then leave, otherwise => datamlv
      temp3=strfind(funstr{i},'::');
      if ~(temp2(j)==1 || (~isempty(temp3) && funstrwords_b{i}(temp2(j))<temp3(1)))
       funstr{i}=[funstr{i}(1:funstrwords_e{i}(temp2(j))),MLapp,...
                  funstr{i}(funstrwords_e{i}(temp2(j))+1:end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      end
     end % if validSpot(funstr{i},
    end % for j=length(temp2):-1:1
   end % if ~isempty(temp2)
  end % if ~isempty(funstrwords{i})
 catch % loop catch
  numErrors=numErrors+1;
  disp('problem with catching some data statements in the following line:')
  warning(funstr{i})
 end % loop end
 end % for i=fliplr(temp)
end % if ~isempty(temp)



%need to take care of common block variable names
temp=find(~cellfun('isempty',regexp(funstr,'^[]*\<common\>'))); temp=temp(:).';
temp3=[];temp4={};
if ~isempty(temp)
 for i=fliplr(temp)
  if ~oneBYone
   try % loop try
    if ~isempty(funstrwords{i})
     temp2=find(strcmp(funstrwords{i},'common'));
     if ~isempty(temp2)
      if ~inastring_f(funstr{i},funstrwords_b{i}(temp2(1))) & ...
           ~incomment(funstr{i},funstrwords_b{i}(temp2(1)))
       temp3=[temp3,i];  temp4{end+1}=funstr{i};
       %'cccccccccc22',funstr{i},funstrwords{i},kb
       tempstr='bcom_';
       fid=1;
       temp1=find(funstr{i}=='/');
       for j=1:length(funstrwords{i})
        if ~any(strcmp(funstrwords{i}{j},var_words))
         if ~inastring_f(funstr{i},funstrwords_b{i}(j))&&~incomment(funstr{i},funstrwords_b{i}(j))
          if inwhichlast_f(i,funstrwords_b{i}(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
           if mod(length(temp1(temp1<funstrwords_b{i}(j))),2)==1
            tempstr=[funstrwords{i}{j},'_'];
            fid=1;
           else %we have a common variable?
            funstr=regexprep(funstr,['\<',funstrwords{i}{j},'\>'],[tempstr,num2str(fid)]);
            fid=fid+1;
            [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
            temp1=find(funstr{i}=='/');
           end
          end % if inwhichlast_f(i,
         end % if ~inastring_f(funstr{i},
        end
       end % for j=1:length(funstrwords{i})
           %'cccccccccc',funstr{i},kb
      end % if ~inastring_f(funstr{i},
     end % if ~isempty(temp2)
    end % if ~isempty(funstrwords{i})
   catch % loop catch
    numErrors=numErrors+1;
    disp('problem with common block variable names in the following line:')
    warning(funstr{i})
   end % loop end
  else
   funstr{i}=['%% ',funstr{i}];
  end % if ~oneBYone
 end % for i=fliplr(temp)
end % if ~isempty(temp)
for i=temp3
 funstr(i+2:end+2)=funstr(i:end); 
 funstr{i+2}=['%% ',funstr{i}];
 funstr{i+1}=['%% ',temp4{find(i==temp3)}];
end


[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);


%%%if strcmp(this_fun_name,'readhalfjunctiont')
%%% 'reeeeeeee7890',funstr,keyboard
%%%end



% comment out the namelist's for now
temp1=find(~cellfun('isempty',regexp(funstr,'^\s*\<namelist\>')));
for i=temp1(:)'
 temp2='warning'; temp2='error';
 funstr{i}=[temp2,'(''namelist problem here''); % ',funstr{i}];
 [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
end % for i=temp1(:)'





%separate out all variable declarations
for i=fliplr(fs_good)
%%% try % loop try
  if ~isempty(funstrwords{i})
   if any(strcmpi(funstrwords{i}{1},var_words))
    %find the last var_word or ::. variables after that...
    temp2=strfind(funstr{i},'::')+1;
    goon=0;
    if isempty(temp2)
     temp5=find(strcmp(funstrwords{i},'data'));
     %or how about stuff like:
     %  integer days_in_month(12) /31,28,31,30,31,30,31,31,30,31,30,31/
     %  integer tso_index, errnoerr /2/
     temp7=find(funstr{i}=='/');
     if ~isempty(temp7) && length(temp7)/2==floor(length(temp7)/2)
      %funstr{i},'jjjjjjjjjjj',kb
      if ~any(funstr{i}(temp7-1)=='(') || ~any(funstr{i}(temp7+1)==')')
       if ~any(strcmp('common',funstrwords{i})) && ~any(strcmp('data',funstrwords{i}))
        if all(validSpot(funstr{i},temp7))
         goon=1;
        end % if all(validSpot(funstr{i},
       end % if ~any(strcmp('common',
      end % if ~any(funstr{i}(temp7-1)=='(') || ~any(funstr{i}(temp7+1)==')')
     end % if ~isempty(temp7) && length(temp7)/2==floor(length(temp7)/2)
         %split up the data statement
     if ~isempty(temp5)
      %for data statementsd add a comma after even / if there is not one
      if strncmp(lower(strtrim(funstr{i})),'data',4)
       temp6=find(funstr{i}=='/'); temp8=0;
       for ii=fliplr(2:2:length(temp6)-1)
        if funstr{i}(nextNonSpace(funstr{i},temp6(ii)))~=',' && ...
             validSpot(funstr{i},temp6(ii))
         funstr{i}=[funstr{i}(1:temp6(ii)),',',funstr{i}(temp6(ii)+1:end)]; temp8=1;
        end
       end
      end
      if temp8, [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote); end
      %'/////////////2',temp4,funstr{i},kb
      j=temp5(1);
      goon=1;
      [temp6,temp4]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(j),'/');
      funstr{i}=fixDataGroups(temp6);
      %funstr,'gggggggggggg'
      [temp6,temp4]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(j),'/');
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      temp4=[funstrwords_e{i}(j)+1,temp4];
      tempstr='';
      %'/////////////',temp4,funstr{i},kb
     end
     fid='::';
     [temp,temp1]=ismember(var_words,funstrwords{i});
     temp1=max(temp1);
     temp2=funstrwords_e{i}(temp1);
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     if howmany==0
      %is there a *8 or sim there?
      temp3=nextNonSpace(funstr{i},funstrwords_e{i}(temp1));
      if strcmp(funstr{i}(temp3),'*')
       % take up until the next whitespace
       temp2=regexp(funstr{i},[funstrwords{i}{temp1},'\*','\d+'],'end');
%%%       temp4=find(strcmp(funstr{i}(nextNonSpace(funstr{i},funstrwords_e{i}(temp1))),'*'));
%%%       temp3=find(isspace(funstr{i}));
%%%       temp3=temp3(temp3>temp4);
%%%       temp2=temp3(1)-1;
       ;%might be something like character * (*)
       temp5=nextNonSpace(funstr{i},temp3);
       if strcmp(funstr{i}(temp5),'(')
        temp2=findNext(temp5,')',funstr{i});
       end % if strcmp(temp5,
       if isempty(temp2)
        temp2=find(isspace(funstr{i})); temp2=temp2(temp2>funstrwords_e{i}(temp1));
       end
       temp2=temp2(1);
      end % if 
     else % deal with character()
      ;% must be a kind declaration or a character length, deal with later
      if ~strcmp(funstrwords{i}{temp1},'data') && ~strcmp(funstrwords{i}{temp1},'parameter')
       temp2=parens(2);
      end
%%%      if strcmp(funstrwords{i}{temp1},'character')
%%%       temp2=parens(2);
%%%      end
      
%%%     else
%%%     elseif ~(~isempty(temp5) && any(~cellfun('isempty',strfind(subscripts,'='))) && howmany>2)% no imp do loops in a data statement to mess this up
%%%      temp2=parens(2);
     end
     temp5=find(strcmp(funstrwords{i},'parameter'));
     if ~isempty(temp5) %parameter, but no ::, so take away () if there
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp5,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany>0
       funstr{i}(parens)=' ';
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      end
     end
%%%    if any(strcmp(funstrwords{i},'days_in_month'))
%%%     'tttttttttttttttttttt1',temp2,funstr{i},keyboard
%%%    end
     temp5=find(strcmp(funstrwords{i},'common')|strcmp(funstrwords{i},'save'));
     if ~isempty(temp5) %get rid of labels
      goon=1;
      temp6=find(funstr{i}=='/');
      if ~isempty(temp6)
       for j=1:2:length(temp6)
        funstr{i}(temp6(j):temp6(j+1))=[',',repmat(' ',1,temp6(j+1)-temp6(j))];
       end % for j=1:2:length(temp6)
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      end
     end
    else
     fid='';
    end
    %now get the top level commas
    % this part is to catch multiple data declaration on a single line, and sep them
    %  E.g. data kj/9*0,1,9*0,2,10*0,3,4,5,6,7,4*0,8/, hu/'     rem','sieverts'/
    [temp3,temp4,temp5]=getTopLevelStrings(funstr{i},temp2,',',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
    [temp6]=getTopLevelStrings(funstr{i},temp2,'/',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
    if ~any(strcmp(funstrwords{i},'parameter'))
     %this last catches things like: PARAMETER (PIOV2=PI/2, DPIOV2=DPI/2)
     for ii=length(temp3):-1:1
      if temp3(ii)<temp2 || (goon && mod(length(find(temp6<temp3(ii))),2)==1)
       temp3=[temp3(1:ii-1),temp3(ii+1:end)];
      end
     end
    end % if ~any(strcmp(funstrwords{i},
    temp3=temp3(temp3>temp2);
    %separate them
    temp3=[temp2,temp3,length(funstr{i})+1];
    tempstr=cell(length(temp3)-1,1);
    for ii=1:length(temp3)-1
     tempstr{ii}=[funstr{i}(1:temp2),' ',fid,funstr{i}(temp3(ii)+1:temp3(ii+1)-1),';'];
    end % for ii=1:length(temp3)-1
%%%    if any(strcmp(funstrwords{i},'data'))
%%%     'tttttttttttttttttttt',temp2,funstr{i},tempstr,keyboard
%%%    end
    [funstr{i+length(tempstr):end+length(tempstr)-1}]=deal(funstr{i+1:end});
    [funstr{i:i+length(tempstr)-1}]=deal(tempstr{:});
   end
  end % if ~isempty(funstrwords{i})
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with separating out all variable declarations in the following line:')
%%%  warning(funstr{i})
%%% end % loop end
end
[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);



%'iiiiiiiiiiiii33',showall(funstr),keyboard


%sometimes data statements don't have the "data" part, just slashes
% detect this and add "data" by 0. has slashes, 1. no "common, 2. no "data",
%  3. no ( or ) before slashes
for i=fliplr(fs_good)
 if ~isempty(funstrwords{i})
  temp=any(strcmpi(funstrwords{i}{1},{var_words{:},type_words{:}}));
  if temp
   temp1=find(funstr{i}=='/');
   if ~isempty(temp1) && length(temp1)/2==floor(length(temp1)/2)
    %funstr{i},'jjjjjjjjjjj',kb
    if ~any(funstr{i}(temp1-1)=='(') || ~any(funstr{i}(temp1+1)==')')
     if ~any(strcmp('common',funstrwords{i})) && ~any(strcmp('data',funstrwords{i}))
      if any(~incomment(funstr{i},temp1)) || any(~inastring_f(funstr{i},temp))
       %funstr{i},'jjjjjjjjjjj',kb
       funstr{i}=['data ',funstr{i}];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      end % if any(~incomment(funstr{i},
     end % if ~any(strcmp('common',
    end % if ~any(funstr{i}(temp1-1)=='(') || ~any(funstr{i}(temp1-1)==')')
   end % if ~isempty(temp1)
  end % if temp
 end % if ~isempty(funstrwords{i})
end % for i=fliplr(fs_good)

%'iiiiiiiiiiiiicvs11',funstr,keyboard

%separate out all variable declarations (again), some of the original 
% data statements still need taking care of, like:
% integer nsb_report_variables(max_sector_breakdowns) /max_sector_breakdowns*0/
for i=fliplr(fs_good)
 if ~isempty(funstrwords{i})
  if any(strcmpi(funstrwords{i}{1},var_words))
   %find the last var_word or ::. variables after that...
   temp5=find(strcmp(funstrwords{i},'data'));
   if ~isempty(temp5) && ~any(strcmpi(funstrwords{i},'character'))
    j=temp5(1);
    [temp6,temp4]=getTopGroupsAfterLoc(funstr{i},funstrwords_e{i}(j),'/');
    %'aaaaaaaaaaaaaa',funstr{i},kb
    funstr{i}=fixDataGroups(temp6);
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    %'/////////////',temp4,funstr{i},kb
   end
  end
 end % if ~isempty(funstrwords{i})
end

%%%if strcmp(this_fun_name,'test01')
%%% 'iiiiiiiiiiiiicvs',showall(funstr),kb
%%%end















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%So, now we start the macros to changeover.
funargs=[]; fundecline=[]; funProps=zeros(1,10);
temp3=fs_good(1);
for i=fs_good
%%% try % loop try
  temp=find(strcmpi(this_fun_name,funstrwords{i}));
  if ~isempty(temp)
   if ~inastring_f(funstr{i},funstrwords_b{i}(temp(1)))
    if any(strcmpi('end',funstrwords{i}))
%%%     funstr{i}='end';
    else
     if (sum(length(find(strcmpi(type_words{1},funstrwords{i}))))+sum(length(find(strcmpi(type_words{2},funstrwords{i}))))+sum(length(find(strcmpi(type_words{3},funstrwords{i})))))>0
      temp3=i;
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      temp9='';
      
      % This is preempted by the assignin functionality added
      if howmany>0
       temp9=[',',funstr{i}(parens(1)+1:parens(2)-1)];
      end
      
      funProps(1)=any(strcmpi(funstrwords{i},'recursive'));
      if any(strcmpi('function',funstrwords{i}))
       %This is a FUNCTION declaration
       suborfun(whichsub)=2;
       if any(strcmpi('result',funstrwords{i}))
        %Has a result specifier
        temp1=find(strcmpi('result',funstrwords{i}));
        funstr{i}=['function [',funstrwords{i}{temp1+1},temp9,']=',funstr{i}(funstrwords_b{i}(temp):funstrwords_b{i}(temp1)-1)];      
        %funstr{i}=['function [',funstrwords{i}{temp1+1},']=',funstr{i}(funstrwords_e{i}(temp1)+1:end)];      
        resultVar=funstrwords{i}{temp1+1};
       else
        %No result specifier for function
        funstr{i}=['function [',funstrwords{i}{temp},temp9,']=',funstr{i}(funstrwords_b{i}(temp):end)];
       end
      else
       %PROGRAM or SUBROUTINE declaration
       suborfun(whichsub)=1;
       if length(funstrwords{i})>temp(1)
        funstr{i}=['function [',funstr{i}(funstrwords_b{i}(temp(1)+1):funstrwords_e{i}(end)),']=',this_fun_name,funstr{i}(funstrwords_e{i}(temp(1))+1:end)];
       else
        funstr{i}=['function ',funstr{i}(funstrwords_b{i}(temp(1)):funstrwords_e{i}(temp(1)))];
       end
      end
      %'wwwwwwwwwww11',funstr{i},keyboard
      temp6=find(funstr{i}==')');
      temp7=',';
      %if this function has no args, then don't need a comma
      if ~isempty(temp6)
       temp8=find(~isspace(funstr{i}));
       temp8=temp8(temp8<temp6(end));
       if funstr{i}(temp8(end))=='('
        %if strcmp(funstr{i}(temp6(end)-1),'(')
        temp7='';
       end
       temp9=''; if want_vai, temp9='varargin'; else, temp7=''; end
       funstr{i}=[funstr{i}(1:temp6(end)-1),temp7,temp9,funstr{i}(temp6(end):end)];
      else
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       funstr{i}=[funstr{i}(1:funstrwords_e{i}(end)),'(varargin)',...
                  funstr{i}(funstrwords_e{i}(end)+1:end)];
      end % if ~isempty(temp6)
      %'wrrrrrrrrrrrr',funstr{i},kb
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      temp2=findstr(funstr{i},']');
      if ~isempty(temp2)
       temp=find(funstrwords_b{i}>temp2(end));
       if ~isempty(temp)
        temp=funstrwords_b{i}(temp(1));
        temp1=find(funstrwords_b{i}>temp(1));
       else
        temp1=[];
       end
      else
       temp=[];temp1=[];
      end
      funargs=temp1;
      fundecline=i;
     end
    end
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   end
  end
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with some preliminary analysis')
%%%  warning(funstr{i})
%%% end % loop end
end

%if strcmp(this_fun_name,'mtu12'),'reeeeeeee444444442',funstr,keyboard,end
%'wwwwwwwwwww',showall(funstr),keyboard



% equivalence issues
equiv={};
temp1=find(~(cellfun('isempty',regexp(funstr,'\<equivalence\>'))));
for i=fliplr(temp1(:).')
 equiv{length(equiv)+1}={};
 temp2=find(strcmp(funstrwords{i},'equivalence'));
 if ~isempty(temp2) && length(temp2)==1 && temp2==1
  if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(1))
   [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
   % change all future refs to vars 1 to last-1 to the last one
   temp5=strtrim(subscripts{howmany});
   equiv{length(equiv)}={temp5};
   for ii=1:howmany-1
    temp4=strtrim(subscripts{ii});
    %'dddddddd',funstr{i},howmany,subscripts,centercomma,parens,temp4,temp5,kb
    %can't deal with subscripted equivalents now
    if isempty(find(temp4=='(')) && isempty(find(temp5=='(')) 
     equiv{length(equiv)}={equiv{length(equiv)}{:},temp4};
     for j=s:-1:i+1
      temp3=find(strcmp(funstrwords{j},temp4));
      if ~isempty(temp3)
       for jj=length(temp3):-1:1
        if validSpot(funstr{j},funstrwords_b{j}(temp3(jj)))
         funstr{j}=[funstr{j}(1:funstrwords_b{j}(temp3(jj))-1),temp5,...
                    funstr{j}(funstrwords_e{j}(temp3(jj))+1:end)];
         [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,j,fs_goodHasAnyQuote);
        end % if validSpot(funstr{i},
       end % for jj=length(temp3):-1:1
      end % if ~isempty(temp3)
     end % for j=s:-1:i+1
    end % if isempty(find(subscripts{ii}=='('))
   end % for ii=1:howmany-1
  end % if validSpot(funstr{i},
 end % if ~isempty(temp2) && length(temp2)==1 && temp2==1
end % for i=fliplr(temp1(:).

%'dqqqqqqqqqqq',funstr,equiv,kb


% deal with implicit statements
temp1=find(~(cellfun('isempty',regexp(funstr,'\<implicit\>'))));
for i=fliplr(temp1(:).')
 temp2=find(strcmp(funstrwords{i},'implicit'));
 if ~isempty(temp2) && length(temp2)==1 && temp2==1
  if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(1))
   implicit=implicitParse(implicit,i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,var_words);
   funstr{i}=['%%% ',noKeep,' ',funstr{i}];
   [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   %'frrrrrrrrrr',funstr{i},funstr,kb
  end % if validSpot(funstr{i},
 end % if ~isempty(temp2) && length(temp2)==1 && temp2==1
end % for i=fliplr(temp1(:).
    %'frrrrrrrrrr11',funstr{i},funstr,implicit,kb



%take care of loc and val and assign to localVar
for i={'val','loc'}
 temp1=regexp(funstr,[i{1},vallocRep]);
 temp2=find(~cellfun('isempty',temp1));
 if ~isempty(temp2)
  for j=1:length(temp2)
   for ii=length(temp1{temp2(j)}):-1:1
    temp3=find(funstrwords_b{temp2(j)}==temp1{temp2(j)}(ii));
    [howmany,subscripts,centercomma,parens]=hassubscript_f(temp2(j),temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);

    goon=0; %only go forward if the next word is the name of any function
    if howmany>0
     temp6=find(funstrwords_b{temp2(j)}>parens(1) & funstrwords_b{temp2(j)}<parens(2));
     if ~isempty(temp6)
      temp6=temp6(1);
      if any(strcmp(funstrwords{temp2(j)}{temp6},{sublist_all{:,1}}))
       goon=1;
      end % if any(strcmp(funstrwords{temp2(j)}{temp6},
     end
    end
    if goon
     %TODO - if the var on the left is a type, then the field needs to be assigned as a handle, not the entire var
     if strcmp(i{1},'loc') % var before equals sign is a handle
      temp5=lastNonSpace(funstr{temp2(j)},funstrwords_b{temp2(j)}(temp3(1)));
      if funstr{temp2(j)}(temp5)=='='
       localVar=insertLocalVar(localVar,funstrwords{temp2(j)}{1},'handle',1);     
      end
     else %var in parens is a handle
      localVar=insertLocalVar(localVar,funstrwords{temp2(j)}{temp3(1)+1},'handle',1);     
     end
    end
    if goon && strcmp(i{1},'loc'),     temp4='@';  else, temp4='';  end
    funstr{temp2(j)}=[funstr{temp2(j)}(1:funstrwords_b{temp2(j)}(temp3(1))-1),...
                      '',temp4,funstr{temp2(j)}(parens(1)+1:parens(2)-1),...
                      funstr{temp2(j)}(parens(2)+1:end)];
%%%    funstr{temp2(j)}=[funstr{temp2(j)}(1:funstrwords_b{temp2(j)}(temp3(1))-1),...
%%%                      '(',temp4,funstr{temp2(j)}(parens(1)+1:end)];
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,temp2(j),fs_goodHasAnyQuote);
    %'derrrrrgg',funstr{temp2(j)},kb
   end % for ii=1:length(temp1{temp2(j)})
  end % for j=1:length(temp2)
 end
end

%%%if strcmpi(this_fun_name,'accepttransmits')
%%% 'niffffffff',localVar,funstr,kb
%%%end



%fill up localVar with variable info
temp5=cell(0); %list of vars that will be taken from var list at the end unless protected
goon=[]; %list of lines to take out
goon2=0; %comment this line if goon2 is 1
temp14=0; %whether we are inside a type def or not
goonimag=1; %last line of var decs
for i=fliplr(fs_good)
 %localVar,i,funstr{i}
%%% try % loop try
% just pass through the var decs finding out all we can
 if ~isempty(funstrwords{i})
  temp9=length(funstrwords{i})>1 && (strcmpi(funstrwords{i}{2},'type') && strcmpi(funstrwords{i}{1},'end'));
  if (any(strcmpi(funstrwords{i}{1},var_words))||temp9)&&isempty(regexp(funstr{i},'^[ ]*function'))
   goonimag=max(goonimag,i);
   if temp9,  temp1=funstrwords_e{i}(2); else, temp1=strfind(funstr{i},'::'); end
   fixEndType
   temp2=find(funstrwords_b{i}>temp1);
   
%%%   if any(strcmpi(this_fun_name,'refine')) & any(strcmpi(funstrwords{i},'f0'))
%%%    'niffffffff3',localVar,funstr,kb
%%%   end
   
% has to be the first word in the line
   %if temp9, funstr{i},'bbbbbbbbbb',kb,end
   if ~isempty(temp2)
    temp2=temp2(1); %variable location
                    % go through all the words before this and add info as appropriate
%%%    goon=1; %add this to localVar after the loop, 0=>don't
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp2,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    for j=temp2-1:-1:1
     switch funstrwords{i}{j}
       case {'real','complex','integer','logical'}
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'type',funstrwords{i}{j});
         % don't let them decalre nargs
         if strcmp('nargs',funstrwords{i}{end})
          funstr{i}=['% ',funstr{i}];
         end
       case 'character'
%%%         'sssssssssssssss',localVar,funstr{i},kb
         [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
         [localVar,temp7]=insertLocalVar(localVar,funstrwords{i}{temp2},'type',funstrwords{i}{j});
         %'ccccccccccccccc',funstr{i},kb
         if howmany2>0
          temp8=strrep(regexprep(subscripts2{1},'.+=',''),' ',''); %take away the :"len="
          localVar{temp7,2}=temp8;
%%%          if ~strcmp('*',temp8) %could be (len=*)
%%%           localVar{temp7,2}=temp8;
%%%          else
%%%           % then it must be an input or something
%%%           %localVar{temp7,13}=1;
%%%          end
          %if isempty(localVar{temp7,5}), localVar{temp7,5}={'1'}; end
         elseif howmany2==0
          localVar{temp7,2}='1'; 
          %if isempty(localVar{temp7,5}), localVar{temp7,5}={'1'}; end
         end
         %may have a *len there on the character
         fid=regexp(funstr{i},'character\s*\*(\w+)','tokens');
         if ~isempty(fid)
          localVar{temp7,2}=fid{1}{1};
         end
         %may have a *(len) there on the character (note added parentheses)
         fid=regexp(funstr{i},'character\s*\*\s*\(([\w\*]+)\s*\)','tokens');
         if ~isempty(fid)
          localVar{temp7,2}=fid{1}{1};
         end
         %may have a *len there on the variable itself
         fid=regexp(funstr{i},[funstrwords{i}{temp2},'\s*\*(\w+)'],'tokens');
         if ~isempty(fid)
          localVar{temp7,2}=fid{1}{1};
         end
         %may have a *(len) there on the variable itself (note added parentheses)
         fid=regexp(funstr{i},[funstrwords{i}{temp2},'\s*\*\s*\(([\w\*]+)\s*\)'],'tokens');
         if ~isempty(fid)
          localVar{temp7,2}=fid{1}{1};
         end
       case 'implicit'
         goon=[goon,i]; break
       case 'intrinsic'
         goon=[goon,i]; 
         temp5={temp5{:},funstrwords{i}{temp2}};
         break
       case 'dimension'
         [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
         if howmany2>0
          localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'extents',subscripts2);
         end
       case 'common'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'common',1);
       case {'double','precision','doubleprecision'}
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'type','real');
       case 'intent'
         [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
         temp4=subscripts2{1}(~isspace(subscripts2{1}));
         if ~isempty(findstr(temp4,'in'))
          if ~isempty(findstr(temp4,'out'))
           localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'intent',3);
          else
           localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'intent',1);
          end
         else
          localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'intent',2);
         end
       case 'allocatable'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'alloc',1);
       case 'pointer'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'alloc',1);
       case 'target'
       case 'equivalence' %can anything be done for these?
%%%       funstr{i},'lllllll',kb
%%%        goon=[goon,i]; 
%%%        break
       case 'external'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'external',1);
         temp5={temp5{:},funstrwords{i}{temp2}};
         goon=[goon,i]; break
       case 'parameter'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'param',1);
       case 'save'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'save',1);
       case 'automatic'
       case 'private'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'private',1);
       case 'public'
       case 'static'
       case 'optional'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'optional',1);
       case 'volatile'
       case 'data'
         localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'data',1);
         if ~ismod, needData=1; end
       case 'type'
         %'ddddddddddddddddddddddd',funstr{i},localVar,kb
         takeCareOfTypes
       case 'namelist'
     end
     % Mark this variable as common if this is in a module
     if ismod && ~temp9
      localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'common',1);
     end % if ismod      
     %if this is inside a type (temp14==1) then see if there is an initial value
     if temp14
      temp11=find(funstr{i}=='=');
      if any(temp11)
       temp11=temp11(end);
       localVar=insertLocalVar(localVar,funstrwords{i}{temp2},'default',...
                               strrep(funstr{i}(temp11+1:end),';',''));
       %'freeeeeeeeee',funstr{i},funstrwords{i}{temp2},localVar,kb
      end % if any(temp11)
     end % if temp14
    end % for j=1:temp2-1
        %can't allow this function to be a var
    if strcmp(funstrwords{i}{temp2},this_fun_name), goon=[goon,i]; end
    if ~any(goon==i)
     if howmany>0 %|| ~isempty(localVar{fid,2}) || ~isempty(localVar{fid,5})
                  %if isempty(localVar{fid,2}) && isempty(localVar{fid,5})
      [localVar,temp7]=insertLocalVar(localVar,funstrwords{i}{temp2},'extents',subscripts);
     end
    else
    end
%%%    if any(strcmp(funstrwords{i},'imach'))
%%%     '[[[[[[[[[44444444444',funstr{i},funstrwords{i}{temp2},localVar,temp5,kb
%%%    end   
    if goon2,
     funstr{i}=['%%% ',funstr{i}];
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    end
   else
    if temp9
     funstr{i},error('you must help the type name in this line, not just ''end type'' only');
    end
   end % if ~isempty(temp2)
  else
   %break % break out of loop because we are done with variable declarations
  end % if (any(strcmpi(funstrwords{i}{1},
 end % if ~isempty(funstrwords{i})
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with assigning size of local variables')
%%%  warning(funstr{i})%,kb
%%% end % loop end
end

%%%if strcmpi(this_fun_name,'sub1')
%%% 'finnnn_a1a',localVar,temp5,showall(funstr),kb
%%%end



%put in a placeholder at the end of the variable declarations, last var dec, first executable
if needData
 goonimag=goonimag+1;
 if goonimag>length(funstr), funstr{goonimag}=''; end
 funstr{goonimag}=[funstr{goonimag},' 55555',needDataStr,';'];
 [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,goonimag,fs_goodHasAnyQuote);
end


% if want_pst is set, make all the local vars default to save attribute
%localVar
for i=1:size(localVar,1)
 if all(cellfun('isempty',{localVar{i,[4,6,7,9:13]}}))
  localVar=insertLocalVar(localVar,localVar{i,1},'save',1);
 end
end

%%%% check for undeclared scalar vars (left side of equals) and insert into localVar
%%%for i=fs_good
%%% temp=find(funstr{i}=='=');
%%% if ~isempty(temp)
%%%  temp=temp(1);
%%%  temp1=find(funstrwords_b{i}<temp);
%%%  if ~isempty(temp1)
%%%   temp2=find(strcmp(funstrwords{i}{1},localVar(:,1)));
%%%   if isempty(temp2)
%%%    if inwhichlast_f(i,funstrwords_b{i}(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
%%%     if ~any(strcmpi(funstrwords{i}{1},{keywordsbegin{:},funwords{:},var_words{:},...
%%%                          'function',this_fun_name}))
%%%      %check if this var is in any of the used mods
%%%      goon=1;
%%%      for jj=1:length(usedMods)
%%%       if any(strcmpi(funstrwords{i}{1},{modLocalVar{usedMods(jj),2}{:,1}})) |...
%%%            any(strcmpi([funstrwords{i}{1},MLapp],{modLocalVar{usedMods(jj),2}{:,1}}))
%%%        goon=0;
%%%       end % if any(strcmpi(funstrwords{i}{1},
%%%      end % for jj=1:length(usedMods)
%%%       
%%%%%%      if strcmpi(funstrwords{i}{1},'eps') | strcmpi(funstrwords{i}{1},'eps_ml')
%%%%%%       %if strcmpi(this_fun_name,'phasesort') & strcmpi(funstrwords{i}{1},'phase')
%%%%%%       'niffffffff00',localVar,funstr,goon,kb
%%%%%%      end
%%%
%%%      if goon
%%%       %OK test first word for subscripts when declaration says it should have none
%%%       [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%       if howmany==0 %this is a scalar assignment with no entry in localVar, put it in
%%%        localVar=insertLocalVar(localVar,funstrwords{i}{1});
%%%       end % if howmany>0
%%%      end % if goon
%%%     end % if ~any(strcmp(funstrwords{i}{1},
%%%    end % if inwhichlast_f(i,
%%%   end % if isempty(temp2)   
%%%  end % if ~isempty(temp1)
%%% end % if ~isempty(temp)
%%%end % for i=fs_good



%for vars not declared with a type, they must be implicit. put in their types
for i=1:size(localVar,1)
 if isempty(localVar{i,3})
  localVar=insertLocalVar(localVar,localVar{i,1},'type',...
                          implicit{double(localVar{i,1}(1))-96,2});
 end
end % for i=1:size(localVar,


% Change all the local vars that have the same var name as a var in any module to have MPstr if want_MP is set.
% This is in possible prep to have all the other functions be nested.
% this version only changes everything in the main program
if want_MP && ~subfun && ~ismod
 if ~ismod
  temp2={};
  for i=1:size(modLocalVar,1)
   temp2={temp2{:},modLocalVar{i,2}{:,1}};
  end
  temp1=1;
  if ~subfun
   for i=2:size(localVar,1)
    if length(localVar{i,1})>1 %any(strcmp(localVar{i,1},temp2)) & isempty(localVar{i,13})
     funstr=regexprep(funstr,['\<',localVar{i,1},'\>'],[localVar{i,1},MPstr{temp1}]);
     localVar{i,1}=[localVar{i,1},MPstr{temp1}];
    end
   end
  end
 end
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
end

%%%if strcmpi(this_fun_name,'refine')
%%% 'finnnn',localVar,temp5,showall(funstr),kb
%%%end


%sometimes module names get listed as a variable
 
foo1=find(strcmpi(this_fun_name,modUsedMods(:,1)),1,'first');
if ~isempty(foo1)
 foo2=find(ismember(localVar(:,1),modUsedMods{foo1,2}));
 temp5={temp5{:},localVar{foo2,1}};
end


commonvars=localVar(find(~cellfun('isempty',localVar(:,4))),1).';
% insert the order of the function arguments
if ~ismod
 temp1=1;
 for i=1:length(funstrwords{fundecline}(funargs))
  if ~strcmp(funstrwords{fundecline}(funargs(i)),'varargin')
   fid=find(strcmp(funstrwords{fundecline}(funargs(i)),localVar(:,1)));
   if ~isempty(fid)
    %'finnnn11',localVar,temp5,kb
    localVar=insertLocalVar(localVar,funstrwords{fundecline}{funargs(i)},'input',temp1);
   else %so, there is an incoming argument that has not been classified as a localVar
   end % if ~isempty(fid)
   temp1=temp1+1;
  end
 end
end
%the "external" declared words are
extwords=localVar(find(~cellfun('isempty',localVar(:,12))),1).';
% but keep the externals that are local variables (e.g. function handles from an input)
temp8=find(~cellfun('isempty',localVar(:,12))&~cellfun('isempty',localVar(:,13)));
temp5=setdiff(temp5,localVar(temp8,1));

%remove the flagged words
for i=1:length(temp5)
 localVar=remLocalVar(localVar,temp5{i});
end


%%% if strcmp(this_fun_name,'phasesort')% & strcmp(localVar{i,1},'bvalu')
%%%  funstr{j},this_fun_name,localVar{i,:},'ssssssssss',kb
%%% end

%'vvvvvvvvvvvvvvvv',funstr,localVar,kb



%don't allow other functions to be local variables unless they have no extents
%or are used with no args outside a subroutine or function call (main level)
temp1={fun_name{:},funwords{:}};
for i=size(localVar,1):-1:1
 goon=1;
 % if we found any dimension in the var decs, then this can't be a function
%%%  if any(strcmpi(localVar{i,1},'fname'))
%%%   '[[[[[[[[[444444444441',funstr{j},localVar(i,:),j,kb
%%%  end 
 goon2=1;
 if length(localVar{i,5})>0 || strcmp(localVar{i,3},'character')
  goon2=0; % no need to check further, just keep this var in localvar
 end
 %but if it is a character array it can have a dimension (??) like:
 % character ( len = 10 ) fname

 %if isempty(localVar{i,5}) && isempty(localVar{i,6}) && isempty(localVar{i,8})
%%% if strcmp(this_fun_name,'bsgq8') & strcmp(localVar{i,1},'bvalu')
%%%  funstr{j},this_fun_name,localVar{i,:},'ssssssssss',kb
%%% end
 fid=zeros(1,2);
 if goon2
  if any(strcmp(localVar{i,1},temp1)) || ( isempty(localVar{i,5}) && isempty(localVar{i,6}) && isempty(localVar{i,8}) )
%%%  if any(strcmp(localVar{i,1},temp1)) || ...
%%%       ( (isempty(localVar{i,5}) && ~strcmp(localVar{i,3},'character')) && ...
%%%         isempty(localVar{i,6}) && isempty(localVar{i,8}) )
   %if this is intent in or an input var, then it should stay a localVar
   if isempty(localVar{i,10}) && isempty(localVar{i,13})
    for j=fliplr(fs_good)
%%%     if strcmp(this_fun_name,'bsgq8') & strcmp(localVar{i,1},'bvalu')
%%%      j,funstr{j},kb
%%%     end
%%%scan the file, if on lhs of eq, then is a var, if has subs (>1 for chars), is not a var
     if length(funstrwords{j})>0
      foo=find(strcmp(funstrwords{j},localVar{i,1}));
      % apparently data statements can appear anywhere?
      if ~any(strcmp(funstrwords{j}{1},var_words)) || strcmp(funstrwords{j}{1},'data')
       for ii=1:length(foo)
%%% if strcmp(this_fun_name,'checkstopcodefile') & strcmp(localVar{i,1},'open')
%%%  funstr{j},this_fun_name,localVar{i,:},'ssssssssss22',kb
%%% end                
        [howmany,subscripts,centercomma,parens]=hassubscript_f(j,foo(ii),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
        if strcmp(localVar{i,3},'character')
         if howmany>1
          goon=0; break;
         end
         if howmany==1 && any(strcmp(localVar{i,1},temp1))
          fid(1)=1;
          if ~any(strcmp(keywordsbegin,funstrwords{j}{1}))
           temp8=find(funstr{j}=='=',1,'first');
           if ~isempty(temp8) && temp8>funstrwords_b{j}(foo(ii)) && ...
                inwhichlast_f(j,funstrwords_b{j}(foo(ii)),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
            fid(2)=1; %then it is a var indeed, keep
           end
          end
         end
        else
%%%         if any(strcmpi(localVar{i,1},'bvalu'))
%%%          '[[[[[[[[[444444444441232',funstr{j},localVar(i,:),j,kb
%%%         end
         if howmany>0 %then with no declared dimensions, this has subscripts, is a function
          goon=0; break;
         end
         if ~isempty(parens) && isempty(localVar{i,5}) 
          %may be part of a struct
          if funstrwords_b{j}(foo(ii))>1 && funstr{j}(funstrwords_b{j}(foo(ii))-1)~='.' 
           goon=0; break; 
          end
         end %function because no declared subscript
        end
%%%      [outflag2,howmany2,subscripts2,centercomma2,parens2]=inwhichlast_f(j,funstrwords_b{j}(foo(ii)),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
%%%      if outflag2==1
%%%       temp6=find(~isspace(funstr{j}));
%%%       temp7=find(temp6(find(temp6<parens2(1),1,'last'))==funstrwords_e{j});
%%%       if ~isempty(temp7)
%%%        if any(strcmp(funstrwords{j}{temp7},fun_name))
%%%         goon=0;
%%%         break
%%%        end
%%%       end
%%%      end
       end
       if ~goon, break, end
      else
       if ~any(strcmp(funstrwords{j},'remg'))
        break
       end
      end
     end % if length(funstrwords{i})>0
    end % for j=fliplr(fs_good)
   end % if isempty(localVar{i,
  end
 end
 if ~goon %remove this one
  localVar=remLocalVar(localVar,localVar{i,1});
 end
 if fid(1) && ~fid(2) %remove this one
  localVar=remLocalVar(localVar,localVar{i,1});
 end
end
% change all empties to 0's, not sure I want to do this
% [localVar{cellfun('isempty',localVar)}]=deal(0);


%%%   if strcmpi(this_fun_name,'test01')
%%%    'sooooooooooooor110',localVar,kb
%%%   end

%'varrrrrrrrrrr00',showall(funstr),localVar,kb

%replace funwordsML that have been deemed to be localVar's to add MLapp on the end
for i=1:size(localVar,1)
 if any(strcmpi(localVar{i,1},funwordsML))
  % then switch
  funstr=regexprep(funstr,['\<',localVar{i,1},'\>'],[localVar{i,1},MLapp]);
  localVar{i,1}=[localVar{i,1},MLapp];
 end % if any(strcmp(localVar{i,
end % for i=1:size(localVar,

%'ssssssss',kb
% also do this for vars in used mods
for ii=1:length(usedMods)
 for j=1:size(modLocalVar{usedMods(ii),2},1)
  if length(modLocalVar{usedMods(ii),2}{j,1})>2
   if strcmp(modLocalVar{usedMods(ii),2}{j,1}(end-length(MLapp)+1:end),MLapp)
    %then replace
    funstr=regexprep(funstr,['\<',modLocalVar{usedMods(ii),2}{j,1}(1:end-length(MLapp)),...
                     '\>'],modLocalVar{usedMods(ii),2}{j,1});
   end % if strcmp(modLocalVar{usedMods(ii),
  end % if length(modLocalVar{usedMods(ii),
 end % for j=1:size(modLocalVar{usedMods(ii),
end % for ii=1:length(usedMods)


%%%%add module variables to the localVar
%%%if strcmp(this_fun_name,'besc1') & ~informationRun
%%% 'smack,smack,meback,1',funstr,localVar,modLocalVar,usedMods,modUsedMods,kb
%%%end
% make all the variables so far declaredin this_fun_name
localVar(:,19)={this_fun_name};

%%%   if strcmpi(this_fun_name,'besc1_edisc')% & ~informationRun
%%%    'sooooooooooooor11',localVar,,kb
%%%   end

[localVar,origLocalVar]=addVars(localVar,modLocalVar,usedMods,modUsedMods);
%'smack,smack,meback',funstr,localVar,origLocalVar,kb


% combine rows
keep=ones(size(localVar,1),1);
for ii=1:size(localVar,1)-1
 temp1=find(strcmp(localVar{ii,1},localVar(ii+1:end,1)));
 if ~isempty(temp1) & keep(ii)
  
  
  if isempty(strfind(localVar{ii,1},'_fv'))
%%%   for jj==temp3
%%%    keep(jj)=0;
%%%   end % for jj==temp3

   
   % old method before spag declared every variable
   temp2=ii; %keep the ii'th one if no localVar{:,19} match is found
   temp3=[ii,ii+temp1(:)'];
   temp4=0;
   for jj=temp3
    if strcmpi(localVar{jj,19},this_fun_name)&0
     temp2=jj;
     temp4=1; % found a this_fun_name match
    else 
     keep(jj)=0;
    end
    %but if this other one was declared in a module, we want to keep some information
    if any(strcmpi(modLocalVar(usedMods,1),localVar(jj,19))) & temp4
     kk=[2,3,4,5,7,8,9,11,18,19];
     localVar(temp2,kk)=localVar(jj,kk);
    end % if any(strcmpi(modLocalVar(usedMods,
   end % for jj=temp3
   keep(temp2)=1;
   
  else
   keep(ii)=0;
  end % if isempty(strfind(localVar{ii,

 end % if ~isempty(temp1)
end % for ii=1:size(localVar,



localVar=localVar(find(keep),:);

%'varrrrrrrrrrr',showall(funstr),localVar,kb



%find all the entry's
if isempty(find(strcmp('entry',localVar(:,1)))) %might be "entry" in localVar 
 fid=regexp(funstr,['^\s*entry\>']); 
 temp1=find(~cellfun('isempty',fid))';
 for i=temp1(:).'
  entrys{length(entrys)+1}=funstrwords{i}{2};
 end % for i=temp1(:).
end % if isempty()


%funstr,entrys,'ffffffffffffaaaaaaaa',keyboard





%%%if strcmp(this_fun_name,'test1_declarations')
%%% 'treeeeeeeeeeee',showall(funstr),kb
%%%end


%%%  %put in struct definitions for derived types
temp=size(typeDefs,1);
tempstr=cell(1,1);
for i=1:temp
 [temp6,typeDefs]=buildTypeDefLine(typeDefs,i,var_words,want_row,funwords,fortranVarOrRes,MLapp);
 tempstr{1}=['global ',typeDefs{i,1},'; ',typeDefs{i,1},'=',temp6,';'];
 % where does this go? the word type with no subscript and this typename
 %tempstr,'ooooooooo',kb
 goonimag=1;
 temp1=regexp(funstr,['\<type\>']);
 temp2=find(~cellfun('isempty',temp1));
 temp3=regexp(funstr,['\<',typeDefs{i,1},'\>']);
 temp4=find(~cellfun('isempty',temp3));
 temp5=intersect(temp2,temp4);
 if isempty(temp5)
  error('where is the type defined?')
 else
  goonimag=min(temp5);
 end
 funstr(goonimag+1+1:end+1)=funstr(goonimag+1:end);
 funstr(goonimag+1)=tempstr; 
end



%add modTypeDefs to typeDefs
if ~isempty(usedMods)
 for i=1:length(usedMods)
  for j=1:size(modTypeDefs{usedMods(i),2},1)
   typeDefs{size(typeDefs,1)+1,1}=modTypeDefs{usedMods(i),2}{j,1};
   typeDefs{size(typeDefs,1)  ,2}=modTypeDefs{usedMods(i),2}{j,2};
  end % for j=1:size(modTypeDefs{usedMods(i),
 end % for i=1:length(usedMods)
end % if ~isempty(usedMods)

%we want to add any new type defs to allTypeDefs
for i=1:size(typeDefs,1)
 temp1=find(strcmp(typeDefs{i,1},{allTypeDefs{:,1}}));
 %if isempty(temp1)
  allTypeDefs{size(allTypeDefs,1)+1,1}=typeDefs{i,1};
  allTypeDefs{size(allTypeDefs,1)  ,2}=typeDefs{i,2};  
  %end
end

% this was already done above!
%%%%go through type defs
%%%%Let's take care of the % => . for the type=>structs
%%%if size(typeDefs,1)>0
%%% temp2=typeDefs(:,2);
%%% temp3=cellfun('prodofsize',temp2);
%%% tempstr=cell(sum(temp3)/size(typeDefs{1,2},2),2); temp1=1;
%%% for i=1:size(typeDefs,1)
%%%  for j=1:size(typeDefs{i,2})
%%%   tempstr{temp1,1}=['[\)\w ]%\s*',typeDefs{i,2}{j,1},'\>'];
%%%   tempstr{temp1,2}=['\.',typeDefs{i,2}{j,1}];
%%%   temp1=temp1+1;
%%%   %funstr=regexprep(funstr,['[\)\w ]%\s*',typeDefs{i,2}{j,1},'\>'],['\.',typeDefs{i,2}{j,1}]);
%%%  end % for j=1:size(typeDefs{i,
%%% end % for i=1:size(typeDefs,
%%% '...............2',typeDefs,kb
%%% funstr=regexprep(funstr,tempstr(:,1),tempstr(:,2));
%%%end

if needData
 [temp1,temp3]=regexp(funstr,['\<55555',needDataStr,'\>'],'match','start');
 temp2=find(~cellfun('isempty',temp1));
 i=temp2(1);
 funstr(i+1:end+1)=funstr(i:end);
 temp4=lastNonSpace(funstr{i},temp3{i}(1));
 funstr{i+1}=funstr{i}(1:temp4);
 funstr{i}=[needDataStr,'=0;'];
end
%'kkkkkkkkkkkk',typeDefs,allTypeDefs,showall(funstr),kb
 

[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
fundecline=find(~cellfun('isempty',regexp(funstr,['^\<function.+',this_fun_name])));

%%%if strcmpi(this_fun_name,'set_sos_constraints')
%%% '81234444444444',ismod,localVar,kb
%%%end

%now take care of the type data statements like pipe(4.5,44.8,1200,"turbulent") 
%  unless they are part of the definition of that struct!
for i=1:size(typeDefs,1)
 temp=regexp(funstr,['\<',typeDefs{i,1},'\>']);
 temp1=find(~cellfun('isempty',temp));
 for j=1:length(temp1)
  for k=length(temp{temp1(j)}):-1:1
   if ~fs_goodHasAnyQuote(temp1(j)) || validSpot(funstr{temp1(j)},temp{temp1(j)}(k))
    temp2=find((funstrwords_b{temp1(j)}==temp{temp1(j)}(k)));
    %funstr{temp1(j)}(1:funstrwords_b{temp1(j)}(temp2))
    %'ffffffff',kb
    [howmany,subscripts,centercomma,parens]=hassubscript_f(temp1(j),temp2,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%    if any(strcmpi(funstrwords{temp1(j)},'element')) && any(strcmpi(funstrwords{temp1(j)},'reshape'))
%%%     'ddddddddddd',funstr{temp1(j)-5:temp1(j)},kb
%%%    end
    if howmany==(size(typeDefs{i,2},1)-1)
     [outflag,whichword,temp5]=insubscript_f(temp1(j),funstrwords_b{temp1(j)}(temp2),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     %[outflag,whichword,temp5,howmany,subscripts,centercomma,parens]=insubscript_f(temp1(j),funstrwords_b{temp1(j)}(temp2),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     %'dfdfdfdfd',funstr{temp1(j)},kb
     goonimag=1;
     if ~isempty(whichword) && strcmpi('struct',funstrwords{temp1(j)}{whichword})
      goonimag=0;
     end
     if goonimag
      tempstr='';
      for goon=1:howmany
       if goon==howmany, temp3='';,else, temp3=','; end
       tempstr=[tempstr,'''',typeDefs{i,2}{howmany+1+1-goon,1},''',',subscripts{goon},temp3];
      end % for goon=1:howmany
      funstr{temp1(j)}=[funstr{temp1(j)}(1:funstrwords_b{temp1(j)}(temp2)-1),'struct(',tempstr,funstr{temp1(j)}(parens(2):end)];
%%%  funstr{temp1(j)}=[funstr{temp1(j)}(1:parens(1)),tempstr,funstr{temp1(j)}(parens(2):end)];
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,temp1(j),fs_goodHasAnyQuote);
      %if ~ismod && strcmp('pipe2',typeDefs{i,1}),'000000000000',funstr{temp1(j)},kb,end
     end % if goonimag
    end % if howmany==size(typeDefs{i,
   end % if ~inastring_f(funstr{temp1(j)},
  end % for k=1:length(temp(temp1(j))
 end % for j=1:length(temp1)
end % for i=1:size(typeDefs, 


%'preeeeeeeeeeeeep',funstr,kb

%remove word= from intrinsic calls and dealing with optional args
tempstr={funwords{:},fun_name{:},sublist_all{:,1}};
for i=fs_good
%%% try % loop try
 if length(funstrwords{i})>0
  if ~any(strcmp(funstrwords{i}{1},{'allocate'}))
   for j=length(funstrwords{i}):-1:1
    fid=[]; %[optional args that this fun_name has, where is it called]
    temp1=find(strcmp(funstrwords{i}{j},tempstr));
%%%  if any(strcmpi(funstrwords{i},'exit'))
%%%   'ppppppppppp',funstr{i},kb
%%%  end
    temp4=lastNonSpace(funstr{i},funstrwords_b{i}(j));
    %if ~isempty(temp1)
    if ~isempty(temp1) || (j==2 && strcmp(funstrwords{i}{1},'call')) || (temp4&&funstr{i}(temp4)=='=')
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
     if howmany>0
      centercomma=[parens(1),centercomma,parens(2)];
      for ii=length(centercomma)-1:-1:1
       temp2=find(subscripts{ii}=='=');
       %temp2=find(funstr{i}(centercomma(ii):centercomma(ii+1))=='=');
       if ~isempty(temp2)
        if validSpot(funstr{i},centercomma(ii)+temp2(1))
         if funstr{i}(centercomma(ii)+temp2(1)+1)~='=' && ... %don't count logical ops equals
              funstr{i}(centercomma(ii)+temp2(1)-1)~='=' && ...
              funstr{i}(centercomma(ii)+temp2(1)-1)~='<' && ...
              funstr{i}(centercomma(ii)+temp2(1)-1)~='>' && ...
              funstr{i}(centercomma(ii)+temp2(1)-1)~='/' && ...
              funstr{i}(centercomma(ii)+temp2(1)-1)~='~'
          if ~any(ismember(funwordsNoRemoveEq,funstrwords{i}))
           [outflag,howmany2,subscripts2,centercomma2,parens2]=inwhichlast_f(i,centercomma(ii)+temp2(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
           if parens2(1)==parens(1)
            if ~any(strcmp(fun_name,funstrwords{i}{j}))
             funstr{i}=[funstr{i}(1:centercomma(ii)),funstr{i}(centercomma(ii)+temp2(end)+1:end)];
             [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
            else % this is a fun_name, and has optional args
             temp7=find(funstrwords_b{i}<centercomma(ii)+temp2(1),1,'last');
             temp8=find(strcmp(funstrwords{i}{j},{sublist_all{:,1}}));
             if ~isempty(temp7) && ~isempty(temp8)
              temp8=temp8(1);
              temp9=find(strcmpi({sublist_all{temp8,8}{:}},funstrwords{i}{temp7})); %which subscript is this optional arg?
              if ~isempty(temp9)
               fid=[fid;temp9,ii];
               subscripts{ii}=subscripts{ii}(temp2(1)+1:end);
              else %This may be a problem with the fortran, just remove the "var="
                   %'wwwwwwwwwww',kb
               funstr{i}=[funstr{i}(1:centercomma(ii)),...
                          funstr{i}(centercomma(ii)+temp2(1)+1:end)];
               [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
              end
             end
            end % if ~any(strcmp(fun_name,
           end % if parens2(1)==parens(1)end
          end % if ~any(ismember(funwordsNoRemoveEq,
         end % if funstr{i}(centercomma(ii)+temp2(1)-1)~='=' && .
        end % if ~inastring_f(funstr{i},
       end % if ~isempty(temp2)s
      end % for ii=length(centercomma)-1:-1:1
%%%if strcmpi(this_fun_name,'gettargetdata') & any(strcmp(funstrwords{i},'compute_portwgts_from_taxlots'))
%%% '81234444444444',ismod,localVar,kb
%%%end
      if ~isempty(fid)
       %rebuild the function/subroutine call
       temp0='';
       for k=min(fid(:,2)):max(fid(:,1))
        if any(fid(:,1)==k)
         temp6=find(fid(:,1)==k);
         temp0=[temp0,',',subscripts{fid(temp6,2)}];
        else
         temp0=[temp0,',[]'];
        end
       end
       funstr{i}=[funstr{i}(1:centercomma(min(fid(:,2)))-1),temp0,funstr{i}(parens(2):end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       %'sssssssssssss',funstr{i},funstrwords{i}{j},fid,subscripts,temp0,kb
      end % if ~isempty(fid)
     end % if howmany>0
    end % if ~isempty(temp1)
   end % for j=length(funstrwords{i}):-1:1
  end % if ~any(strcmp(funstrwords{i}{1},
 end % if length(funstrwords{i})>0
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with removing <word>= in the following line')
%%%  warning(funstr{i})%,kb
%%% end % loop end
end % for i=fs_good

%showall(funstr),'ccccccccccccccc434343',kb


% we have to catch statement functions now
for i=fs_good
%%% try % loop try
  temp=find(funstr{i}=='=');
  if ~isempty(temp)
   temp=temp(1);
   temp1=find(funstrwords_b{i}<temp);
   if ~isempty(temp1)
    if inwhichlast_f(i,temp,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
     if ~any(strcmp(funstrwords{i}{1},{keywordsbegin{:},funwords{:},var_words{:}}))
      %OK test first word for subscripts when declaration says it should have none
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany>0
%%%     if strcmp(funstrwords{i}{1},'g8')
%%%      'dddddd=-0',funstr{i},keyboard
%%%     end
       temp2=find(strcmp(funstrwords{i}{1},localVar(:,1)));
       goon=0;
       if ~isempty(temp2) %found this var in localVar
        if ~ischar(localVar{temp2,2}) && length(localVar{temp2,5})==0 && ~strcmp(localVar{temp2,3},'character')%&& ~strcmp(localVar{temp2,3},'string')
         goon=1;
        end % if localVar{temp2,
       else
        goon=1;
       end % if ~isempty(temp2)
       ;%if ~(the last statement was a statementFunction or had a var_word or ), then don't
       if ~(any(fs_good(find(i==fs_good)-1)==statementFunctionLines) | ...
            any(ismember(funstrwords{fs_good(find(i==fs_good)-1)},{var_words{:},'data'})) |...
            strcmp(funstrwords{fs_good(find(i==fs_good)-1)}{1},'function') | ...
            strcmp(funstrwords{fs_good(find(i==fs_good)-1)}{1},needDataStr))
        goon=0;
        %'ggggggggggg',funstr{i},keyboard
       end
       % or was a "data"
       if strcmpi(funstrwords{i}{1},'data')
        goon=0;
       end
       %not if its an input variable
       if ~isempty(funargs)
        if ~(~any(strcmpi(funstrwords{i}{1},{funstrwords{fundecline}{funargs}})))
         goon=0;
        end
       end
       if goon
        % we have a statement function (??)
        statementFunction{length(statementFunction)+1}=funstrwords{i}{1};
        statementFunctionLines=[statementFunctionLines,i];
        funstr{i}=[funstrwords{i}{1},'= @',funstr{i}(parens(1):parens(2)),' ',...
                   funstr{i}(temp+1:end)];
%%%        funstr{i}=['function ',funstrwords{i}{1},'=',...
%%%                   funstr{i}(funstrwords_b{i}(1):parens(2)),', ',...
%%%                   funstrwords{i}{1},'=',funstr{i}(temp+1:end),' end'];
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       end
       
      end % if howmany>0
     end % if ~any(strcmp(funstrwords{i}{1},
    end % if inwhichlast_f(i,
   end % if ~isempty(temp1)
  end % if ~isempty(temp)
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with converting statement functions in the following line')
%%%  warning(funstr{i})%,kb
%%% end % loop end
end % for i=fs_good

%statement functions have to be moved so that they appear after any data data statements
if ~isempty(statementFunctionLines)
 %'ttttttttttt',funstr,kb
 %see if there is a firstCall=0; if not, then do not need to move anyway...
 temp4=regexp(funstr,[needDataStr,'=0;']);
 temp5=find(~cellfun('isempty',temp4));
 if ~isempty(temp5) && temp5(end)>min(statementFunctionLines)
  funstr=funstr(:).';
  tempstr=funstr(min(statementFunctionLines):max(statementFunctionLines));
  funstr=[funstr(1:min(statementFunctionLines)-1),...
          funstr(max(statementFunctionLines)+1:temp5(end)),...
          tempstr,funstr(temp5(end)+1:end)].';
  % update these lines
  for i=min(statementFunctionLines):temp5(end)
   [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
  end
  statementFunctionLines=statementFunctionLines+(temp5(end)-(max(statementFunctionLines)+1)+1);
 end % if ~isempty(temp5)
end

%also on statement functions, they must be updated before each call
for ii=1:length(statementFunction)
 temp2=regexp(funstr,['\<',statementFunction{ii},'\>']);
 temp1=find(~cellfun('isempty',temp2));
 for jj=1:length(temp1)
  goon=0;
  for i=1:length(temp2{temp1(jj)})
   if ~any(temp1(jj)==statementFunctionLines) && ...
        validSpot(funstr{temp1(jj)},temp2{temp1(jj)}(i))
    goon=1; break;
   end % if validSpot(funstr{temp1(jj)},
  end % for i=1:length(temp2{temp1(jj)})
  if goon %SF needs to be updated on this line
   funstr{temp1(jj)}=[funstr{statementFunctionLines(ii)},funstr{temp1(jj)}];
  end % if goon %SF needs to be updated on this line
  %if jj>1 && (temp1(jj)-temp1(jj-1))==1, continue; end %if line before also has this SF,skip
 end % for jj=temp1
end % for ii=1:length(statementFunction)
 
 
 

%%%if strcmp(this_fun_name,'read_global_holdings_record')
%%% 'ffffffff121212',funstr,statementFunctionLines,kb
%%%end


%%%%%%%%%%% let's see if there are any <1 indices
% varp{n,1:3}, varp{n,1} => var name, varp{n,2} => which subscripts
%              varp{n,3} => increment for each sub
%Try to find zero and - indexed variables
%%%try % loop try
 varp=cell(0);
 for i=1:size(localVar,1)
  if iscell(localVar{i,5})
   for j=1:length(localVar{i,5})
    temp4=strfind(localVar{i,5}{j},':');
    if ~isempty(temp4)
     temp1=str2double(localVar{i,5}{j}(1:temp4(1)-1));
     if ~isnan(temp1) && temp1==0 % found a 0
      if size(varp,1)==0 || ~any(strcmpi(localVar{i,1},{varp{:,1}}))
       varp{end+1,1}=localVar{i,1};
       varp{end,2}=j;
       varp{end,3}=1;
      else
       temp5=find(strcmpi(localVar{i,1},{varp{:,1}}));
       varp{temp5,2}=unique([varp{temp5,2},j]);
       varp{temp5,3}=[varp{temp5,3},1];
      end
     end
     if ~isempty(temp1) && temp1<0 % found a -#
      if size(varp,1)==0 || ~any(strcmpi(localVar{i,1},{varp{:,1}}))
       varp{end+1,1}=localVar{i,1};
       varp{end,2}=j;
       varp{end,3}=abs(temp1)+1;
      else
       temp5=find(strcmpi(localVar{i,1},{varp{:,1}}));
       varp{temp5,2}=unique([varp{temp5,2},j]);
       varp{temp5,3}=[varp{temp5,3},abs(temp1)+1];
      end
     end
    end % if ~isempty(temp4)
%%%   if (strcmp('adif',localVar{i,1}))
%%%    localVar{i,:},varp,'diffffffff',kb
%%%   end     
   end % for j=1:length(localVar{i,
  end % if iscell(localVar{i,
 end % for i=1:size(localVar,
%%%catch % loop catch
%%% numErrors=numErrors+1;
%%% disp('problem with finding <1 starting indices')
%%% warning(funstr{i})%,kb
%%%end % loop end


%Add on modVarp as needed
if ~ismod
 if ~isempty(usedMods)
  for i=usedMods(:).'
   varp=[varp;modVarp{i,2}];
   if ~isempty(varp)
    [temp1,temp2]=unique({varp{:,1}});
    varp=varp(temp2,:); %sometimes there is a duplicate?
   end
  end % for usedMods(:).
 end % if ~isempty(usedMods)
end % if ~ismod
 
%%%if strcmp(this_fun_name,'checkstopcodefile')
%%% '7777777777777777',showall(funstr),varp,keyboard
%%%end


%Get any parameter declarations and remove var declaration and dimensioning
temp=ones(s,1); %whether to keep this line at all
filestr=zeros(1,s);%lines to add varPrefix to (so later routines know this is a var dec line)
tempstr=zeros(size(localVar,1),1); %whether this var has been dealt with or not.
for i=(fs_good)
%%% try % loop try
  if ~isempty(funstrwords{i})
   if (any(strcmpi(funstrwords{i}{1},var_words)))&&isempty(regexp(funstr{i},'^[ ]*function'))
%%%    if i==48,funstr{i},kb,end
%%%    if (any(strcmpi('xfeed_m',this_fun_name)))
%%%     funstr{i}, kb
%%%    end
%if (any(strcmpi(funstrwords{i}{1},var_words)))&&(~any(strcmpi('function',funstrwords{i})))
    temp1=strfind(funstr{i},'::');
    temp2=find(funstrwords_b{i}>temp1); % variable name    
    if ~isempty(temp2)


     temp2=temp2(1); %variable location
     fid=find(strcmp(funstrwords{i}{temp2},localVar(:,1)));
     if isempty(fid)||...  %then bag it, not a local var         
          tempstr(fid)||... %then bag it, this has been dealt with already,
          ~isempty(localVar{fid,13})||... %if it is an input var, then don't try to do anything
          any(strcmp(funstrwords{i}{temp2},statementFunction)) || ...
          (~isempty(localVar{fid,6})) ||... % if this is a data statement, bag it take care of it later with the slash out line (
          ~strcmpi(this_fun_name,localVar{fid,19})
      temp(i)=0;
     end
%%%     if ~isempty(fid) & strcmpi('tt',localVar{fid,1})
%%%      '----------------ssss',funstr{i},kb
%%%     end

     %but data statements with slashes get to go through
     temp10=0;
     if ~isempty(fid) && ~isempty(localVar{fid,6}) && ...
          ~isempty(find(funstr{i}(funstrwords_e{i}(temp2)+1:end)=='/'))
      temp(i)=1;     temp10=1;
     end
     %but if an input var is a char then it needs a strAssign
     temp14=0;
     if ~isempty(fid) && ~isempty(localVar{fid,13}) && strcmp(localVar{fid,3},'character')
      temp14=1;
      %'tttttttttt',funstr{i},localVar{fid,:},kb
      %but not if this will be a cell array of strings
      if ~isempty(localVar{fid,5}) | strcmp(localVar{fid,2},'*')
       temp14=0;
      end
%%%      %but not if there is an asterisk in the dimensions
%%%      if ~isempty(localVar{fid,5}) && any(strcmp(strtrim(localVar{fid,5}),'*'))
%%%       temp14=0;
%%%      end
     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%deal with the * in some inputs
     temp9=1;
     [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp2,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);

%%%     if strcmp(funstrwords{i}{temp2},'iflag')
%%%      funstr{i},'mmmmmmmmmm22',temp9,fid,temp(i),i,kb
%%%     end
%%%     
%%%     if strcmp(funstrwords{i}{temp2},'fjac')
%%%      funstr{i},'mmmmmmmmmm33',temp9,fid,temp(i),i,kb
%%%     end
     
     if ~isempty(fid) && ~isempty(localVar{fid,13}) && ~isempty(localVar{fid,5})
      if (howmany>0 && any(strcmp(strtrim(localVar{fid,5}),'*'))) ||...
           any(strcmp(strtrim(localVar{fid,5}),':'))
%%%     any(~cellfun('isempty',strfind(localVar{fid,5},'*')))
       temp(i)=1;     temp9=0;
       temp11={};     temp11{1}='';      temp11{2}='';
       temp12={};     temp12{1}='';      temp12{2}='';
       if ~isempty(localVar{fid,14}) %this is an optional argument
        temp11{1}=[' if (exist(''',funstrwords{i}{temp2},''',''var''));'];
        temp11{2}='';
       end
       if want_point
        temp12{1}=['if isa(',funstrwords{i}{temp2},',''mlPointer'');',...
                   funstrwords{i}{temp2},'.dims=[',num2str(subscripts{1}),...
                   ',0]; else; ',];
        temp12{2}=['end; '];
       end
       if length(localVar{fid,5})==1
        if want_row,        temp8='1,[]';       else,        temp8='[],1';       end
        if want_smm
         if want_ALLpoint
          funstr{i}=[temp11{1},funstrwords{i}{temp2},'.dims=length(',funstrwords{i}{temp2},');',temp11{2}];
         else
          funstr{i}=[temp11{1},funstrwords{i}{temp2},shapeVar,'=size',protVar,'(',...
                     funstrwords{i}{temp2},');',funstrwords{i}{temp2},'=reshape(',...
                     funstrwords{i}{temp2},',',temp8,');',temp11{2}];
         end % if want_ALLpoint
         needRS={needRS{:},funstrwords{i}{temp2}};
        else
         funstr{i}=[temp11{1},funstrwords{i}{temp2},'=reshape(',...
                    funstrwords{i}{temp2},',',temp8,');',temp11{2}];
        end
       else
        if want_smm
         if (howmany>0 && any(strcmp(strtrim(localVar{fid,5}),'*')))
          %temp6=funstr{i}(parens(1)+1:centercomma(end)-1);
          %put abs around each arg here in case they are negative
          temp6='';
          for ii=1:howmany-1
           temp6=[temp6,'abs(',subscripts{ii},')'];
           if ii~=howmany-1, temp6=[temp6,',']; end
          end % for ii=1:howmany-1
          % took away the abs(prod([ for >2 dim vars
          %'2222222222222222',funstr{i},kb
          if want_ALLpoint
           funstr{i}=[temp11{1},funstrwords{i}{temp2},'.dims=[',num2str(subscripts{1}),',0];',temp11{2}];
          else
           funstr{i}=[temp12{1},temp11{1},funstrwords{i}{temp2},shapeVar,'=size',protVar,...
                      '(',funstrwords{i}{temp2},');',...
                      funstrwords{i}{temp2},'=reshape([',funstrwords{i}{temp2},...
                      '(:).'',zeros(1,ceil(numel(',funstrwords{i}{temp2},')./prod([',temp6,...
                      '])).*prod([',temp6,'])-numel(',funstrwords{i}{temp2},'))],',...
                      temp6,',[]);',temp11{2},temp12{2}];
          end % if want_ALLpoint
%%%          funstr{i}=[temp11{1},funstrwords{i}{temp2},shapeVar,'=size',protVar,...
%%%                     '(',funstrwords{i}{temp2},');',...
%%%                     funstrwords{i}{temp2},'=reshape([',funstrwords{i}{temp2},...
%%%                     '(:).'',zeros(1,ceil(numel(',funstrwords{i}{temp2},')./prod([',temp6,...
%%%                     '])).*prod([',temp6,'])-numel(',funstrwords{i}{temp2},'))],abs(prod([',...
%%%                     temp6,'])),[]);',temp11{2}];
%%%         funstr{i}=[temp11{1},funstrwords{i}{temp2},shapeVar,'=size',protVar,'(',funstrwords{i}{temp2},');',...
%%%                    funstrwords{i}{temp2},'=reshape(',funstrwords{i}{temp2},...
%%%                    '(1:floor(numel(',funstrwords{i}{temp2},')/prod([',temp6,']))',...
%%%                    '*prod([',temp6,'])),prod([',temp6,']),[]);',temp11{2}];
         else
          funstr{i}=[temp11{1},funstrwords{i}{temp2},shapeVar,'=size',protVar,'(',funstrwords{i}{temp2},');',temp11{2}];         
         end
         needRS={needRS{:},funstrwords{i}{temp2}};
        else
         funstr{i}=[temp11{1},funstrwords{i}{temp2},'=reshape(',funstrwords{i}{temp2},',',funstr{i}(parens(1)+1:centercomma(end)),'[]);',temp11{2}];
        end
       end
       tempstr(fid)=1; %taken care of this var
      elseif howmany>1 && all(cellfun('isempty',strfind(localVar{fid,5},':')))%for an array coming in, it may need to be reshaped...       
       if want_arr %FIXME change this to another parameter
        temp(i)=1;     temp9=0;
        temp11{1}='';      temp11{2}='';
        if ~isempty(localVar{fid,14}) %this is an optional argument
         temp11{1}=[' if (exist(''',funstrwords{i}{temp2},''',''var''));'];
         temp11{2}='';
        end
        temp6=funstr{i}(parens(1)+1:parens(2)-1);
        if want_ALLpoint
         funstr{i}=[temp11{1},funstrwords{i}{temp2},'.dims=[',num2str(subscripts{1}),',0];',temp11{2}];
        else
         funstr{i}=[temp11{1},funstrwords{i}{temp2},origVar,'=',funstrwords{i}{temp2},';',...
                    funstrwords{i}{temp2},shapeVar,'=[',temp6,'];',...
                    funstrwords{i}{temp2},'=reshape([',funstrwords{i}{temp2},origVar,...
                    '(1:min(prod(',funstrwords{i}{temp2},shapeVar,'),numel(',funstrwords{i}{temp2},origVar,'))),zeros(1,max(0,prod(',funstrwords{i}{temp2},shapeVar,')-numel(',...
                    funstrwords{i}{temp2},origVar,')))],',...
                    funstrwords{i}{temp2},shapeVar,');',temp11{2}];
        end % if want_ALLpoint
%%%        funstr{i}=[temp11{1},funstrwords{i}{temp2},origVar,'=',funstrwords{i}{temp2},';',...
%%%                   funstrwords{i}{temp2},shapeVar,'=[',temp6,'];',...
%%%                   funstrwords{i}{temp2},'=reshape(',funstrwords{i}{temp2},origVar,...
%%%                   '(1:prod(',funstrwords{i}{temp2},shapeVar,')),',...
%%%                   funstrwords{i}{temp2},shapeVar,');',temp11{2}];
        needRS={needRS{:},funstrwords{i}{temp2}};
        tempstr(fid)=1; %taken care of this var
       end

      end
     end
     if temp14
      temp(i)=1;     temp9=0;
      funstr{i}=[funstrwords{i}{temp2},'=strAssign(repmat(''A'',1,',localVar{fid,2},'),[],[],',funstrwords{i}{temp2},');'];
%%%      funstr{i},      localVar{fid,:},      'ttttttttt',kb
     end % if temp14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    if strcmp(funstrwords{i}{temp2},'oooddd')
%%%     funstr{i},'mmmmmmmmmm',temp9,fid,temp(i),i,kb
%%%    end
     if temp9 %not taken care of as an assumed shape var above
      if temp(i) %if not, comment out this line
       filestr(i)=1;
       [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp2,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
       %remember, there should be only 1 var per line, and it is the first word after the ::
       goon1={''};goon1{2}='';goon1{3}='';goon1{4}='';goon1{5}='';
%%%%%%%%%%%%%%%%%%%%% data: let's take care of the data statements
       if ~isempty(localVar{fid,6})
        %'pppppppp_abc',kb
        persistentVars=unique({persistentVars{:},funstrwords{i}{temp2}});
        [temp3,temp4]=getTopGroupsAfterLoc(funstr{i},temp1+1,'/');
        temp4=[temp1+1,temp4];
        temp5='';
        temp14=0;
%%%        if strcmp(funstrwords{i}{temp2},'hj')
%%%         funstr{i},'nnnnnnnnn',temp(i),i,goon1,kb
%%%        end
        %if any(strcmpi('sdot',funstrwords{i})),'ggggg',funstr{i},kb,end
        if temp10 %actual assigning of values with a slash list
         for ii=1:length(temp3)
          temp6=find(temp3{ii}=='/');
          if ~isempty(temp6)
           %funstr{i},goon1,temp3,'/////////////111',kb
           temp7=temp6(end);     temp6=temp6(1);
           temp8=find(~isspace(temp3{ii}) | inastring_f(temp3{ii},[1:length(temp3{ii})]));
           temp8=temp8((temp8>temp6)&(temp8<temp7));

           temp12=temp4(ii)+temp6; %where this slash is in funstr{i}
           temp13=temp12;
           if howmany>0 && strcmp(localVar{fid,3},'character'), temp12=parens(1); end
           if length(find(((funstrwords_b{i}>temp4(ii))&(funstrwords_b{i}<temp12))))==1
%%%           if length(find(((funstrwords_b{i}>temp4(ii))&(funstrwords_b{i}<temp4(ii)+temp6))))==1
            if strcmp(localVar{fid,3},'character') && ~isempty(localVar{fid,5})
             if howmany==0 || any(funstr{i}(parens(1):parens(2))==':')
              temp5=[temp5,temp3{ii}(1:temp6-1),'={',temp3{ii}(temp8),'}; '];
             elseif any(funstr{i}(temp4(ii):temp13)=='=')
              %deal with an implied do loop like:
              % DATA (x(i,1),i=1,N)/'AC' , 'AZ' , 'AD' , 'AA' , 'AB' , 'ZZ' ,     &
              %   &      'ZA' , 'ZX' , 'ZY'/  
              temp5=[temp5,'[',temp3{ii}(1:temp6-1),']={',temp3{ii}(temp8),'}; '];
              temp14=1; %let's hope these data are not reassigned in the body of the function
             else
              %eliminate the subscript in situations like:
              % character*3 month_abbrev(12) / 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' /
              %but you don't want to remove the subscript for eg: DATA l(38)/'ICAMAX'/ 
              goon2=cell(1,5);
              goon2{1}=temp4(ii)+find(temp3{ii}=='/');
              [goon2{2},goon2{3}]=getTopGroupsAfterLoc(funstr{i}(goon2{1}(1)+1:goon2{1}(2)-1),1);
              if length(goon2{2})>1
               temp5=[temp5,temp3{ii}(1:find(temp3{ii}=='(',1,'first')-1),...
                      temp3{ii}(find(temp3{ii}==')',1,'first')+1:temp6-1),...
                      '={',temp3{ii}(temp8),'}; '];
              else
               goon2{4}=[find(temp3{ii}=='(',1,'first'),find(temp3{ii}==')',1,'last')];
               temp5=[temp5,temp3{ii}(1:goon2{4}(1)-1),'{',...
                      temp3{ii}(goon2{4}(1)+1:goon2{4}(2)-1),'}',...
                      temp3{ii}(goon2{4}(2)+1:temp6-1),'=',temp3{ii}(temp8),'; '];
              end
             end
            else
             temp5=[temp5,temp3{ii}(1:temp6-1),'=[',temp3{ii}(temp8),']; '];
            end
           else
            % if there is an equals in here, then it is probably an implied do loop
            if any(temp3{ii}(1:temp6-1)=='=') && ~strcmp(localVar{fid,3},'character') && ...
                 ~isempty(localVar{fid,5})
%%%             if strcmp(localVar{fid,1},'iv')
%%%              'swag',funstr{i},kb
%%%             end
             foo2=varInUsedMods(localVar{fid,1},modLocalVar,usedMods);
             if isempty(foo2)% & isletter(localVar{fid,5}{1}(1)) %why was this last part here?
              foo3={localVar{fid,:}};
             else
              foo3=foo2;
             end
             % this might need a reshape due to its being a double implied do loop
             foo1={'',''};
             if length(foo3{1,5})==2
              foo1{1}='reshape(';
              foo1{2}=[',',foo3{1,5}{1},',',foo3{1,5}{2},')'];
             end % if ~length(localVar{fid,
             temp5=[temp5,'[',temp3{ii}(1:temp6-1),']=',foo1{1},'[',temp3{ii}(temp8),']',foo1{2},';'];
             temp14=1; %let's hope these data are not reassigned in the body of the function
            elseif howmany==1 & ~isempty(funstr{i}=='*') 
             %data lists with * in them (variable defines length) like data a(5) /b*3/ , b is 5
             temp5=[temp5,',',funstrwords{i}{temp2},'=',temp3{ii}(temp6+1:temp7-1),';'];
            else
             temp5=[temp5,',',funstrwords{i}{temp2},'={};[',temp3{ii}(1:temp6-1),']=deal(',temp3{ii}(temp8),');'];
            end
           end
          end % if ~isempty(temp)
         end % for ii=1:length(temp3)
             %is this a vector or scalar?
%%%         if strcmp(funstrwords{i}{temp2},'var1')
%%%          'vvvvvv',kb
%%%         end
         if ismod || ~isempty(localVar{fid,4})
          if oneBYone && strcmp(files(whichsub).type,'blockdata')
           goon1{1}=['if ',needDataStr,', '];
          else
           goon1{1}=['if isempty(',funstrwords{i}{temp2},'), '];
          end % if oneBYone && strcmp(files(whichsub).
          % remove from persistent list because it will be global due to being common
          persistentVars=setdiff({persistentVars{:}},funstrwords{i}{temp2});
         else
          goon1{1}=['if ',needDataStr,', '];
         end
         goon1{2}=[' end;'];
         goon1{4}=temp5;
         %funstr{i}=temp5;
        else
         %set up the isempty var if not a scalar
         %temp(i)=0; %don't need it! scalar data dec
         %tempstr(fid)=1; %taken care of this var -- may be many lines of same var data dec
         %temp(i)=0; %type dec of data, don't need
        end
        %continue %no need to go further with this line... (??)
        %funstr{i},goon1,'/////////////',kb
        %if any(strcmp('nsb_report_variables',funstrwords{i})),'ggggggggg1',funstr{i},kb,end
       end % if ~isempty(localVar{fid,
%%%%%%%%%%%%%%%%%%%%% parameter: easy, just keep all after ::
       if ~isempty(localVar{fid,9})
        %if isempty(find(funstr{i}(funstrwords_e{i}(temp2)+1:end)=='='))
        if ~isempty(find(funstr{i}(funstrwords_e{i}(temp2)+1:end)=='='))
         goon1{4}=funstr{i}(funstrwords_b{i}(temp2):end);
         %tempstr(fid)=1; %taken care of this var
        else
         temp(i)=0;
         continue %this is the type dec of a param, don't need
        end
       end % if localVar{i,
%%%%%%%%%%%%%%%%%%%%% replace fortran reserved words.
       if any(strcmp(funstrwords{i}{temp2},fortranVarOrRes))
        funstr{i}=strrep(funstr{i},funstrwords{i}{temp2},[funstrwords{i}{temp2},MLapp]);
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       end
%%%%%%%%%%%%%%%%%%%%% does this need to be persistent?
       if isempty(localVar{fid,6}) || ~temp10 %not a data statement
        goon2=0;
        % if it is save, data, or common then needs it
        if ~isempty(localVar{fid,7})||~isempty(localVar{fid,6})||~isempty(localVar{fid,4})
         goon2=1;
        end
        [temp6,temp7,temp8]=getTopLevelStrings(funstr{i},funstrwords_b{i}(temp2),'=',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
        if ~isempty(temp6) & ~isempty(temp8)
         goon2=1;
        end
        if ismod         goon2=1;        end % if ismod
        if goon2
         temp15=''; if funProps(1)&&isempty(localVar{fid,4}), temp15='isRecursive||'; end
         if isempty(localVar{fid,4})
          persistentVars=unique({persistentVars{:},funstrwords{i}{temp2}});
         end
         goon1{1}=['if ',temp15,'isempty(',funstrwords{i}{temp2},'), '];
         goon1{2}=' end;';
        end % if goon2
%%%       else
%%%        temp(i)=0; %this is the type dec of a later data statement, so we won't need it zeroed
%%%        continue; %
       end % if isempty(localVar{fid,
%%%%%%%%%%%%%%%%%%%%% Do we need this to be global?  yes if common or ismod
       if ~isempty(localVar{fid,4}) || ismod
        %'dataaaaaaaaaaaaa',funstr{i},temp5,kb
        %goon1{3}=['if ~exist(''',funstrwords{i}{temp2},''',''var''); global ',funstrwords{i}{temp2},'; ']; 
        %goon1{3}=['v_=whos(''',funstrwords{i}{temp2},'''); if (isempty(v_) || ~v_.persistent); global ',funstrwords{i}{temp2},'; '];         goon1{5}=' end;';
        goon1{3}=['v_=whos(''',funstrwords{i}{temp2},'''); if isempty(v_); global ',funstrwords{i}{temp2},'; '];
        goon1{5}=[' else; if ~v_.persistent; ',funstrwords{i}{temp2},'_orig=',funstrwords{i}{temp2},'; clear ',funstrwords{i}{temp2},'; global ',funstrwords{i}{temp2},'; ',funstrwords{i}{temp2},'=',funstrwords{i}{temp2},'_orig; clear ',funstrwords{i}{temp2},'_orig; end; end;'];

%%%v_=whos('ph'); if isempty(v_);
%%% global ph; if isempty(ph), ph=0; end;
%%%else; if ~v_.persistent; ph_orig=ph; clear ph; global ph; ph=ph_orig; clear ph_orig; end; end;
       
       
       end
%%%%%%%%%%%%%%%%%%%%%zeroing
       if want_ze && (isempty(localVar{fid,6}) || ~temp10) &&...
            ~(any(strcmp(funstrwords{i}{temp2},statementFunction)) || ...
              tempstr(fid))
%%%       if want_ze && isempty(localVar{fid,6}) &&...
%%%            ~(any(strcmp(funstrwords{i}{temp2},statementFunction)) || ...
%%%              tempstr(fid))
%%%       if want_ze && isempty(localVar{fid,6}) &&...
%%%            ~(~isempty(localVar{fid,4}) || ...
%%%              any(strcmp(funstrwords{i}{temp2},statementFunction)) || ...
%%%              tempstr(fid))
%%%      if want_ze && ~(~isempty(localVar{fid,4}) || ~isempty(localVar{fid,6}) || ...
%%%                      any(strcmp(funstrwords{i}{temp2},statementFunction)) || ...
%%%                      tempstr(fid))
        goon1{4}=zeroVarDec(funstr,i,temp2,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,localVar,fid,varp,funwords,want_row,var_words);
%%%        if strcmp(funstrwords{i}{temp2},'x')
%%%         funstr{i},goon1,'++++++++++++++',kb
%%%        end
       end % if want_ze
%%%%%%%%%%%%%%%%%%%%% Put these last together
       if strcmp(localVar{fid,3},'character') %|| strcmp(localVar{fid,3},'string')
        goon1{4}=strrep(strrep(goon1{4},'(/','{'),'/)','}');
       end
       funstr{i}=[goon1{3},goon1{1},goon1{4},goon1{2},goon1{5}];
       tempstr(fid)=1; %taken care of this var
%%%       if any(strcmp('month_abbrev',funstrwords{i}))
%%%        funstr{i}
%%%        'aaaaa',funstr{i},kb
%%%       end
      else
       funstr{i}=['% ',funstr{i}];
      end % if goon1
     end % if temp9 %not taken care of as an assumed shape var above
    else
     funstr{i}=['% ',funstr{i}];
     %'what, no var here?',funstr{i},kb
    end % if ~isempty(temp2)
   end % if (any(strcmpi(funstrwords{i}{1},
  end % if ~isempty(funstrwords{i})
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with parameter declarations and remove var declaration and dimensioning')
%%%  warning(funstr{i})
%%% end % loop end
end
for i=find(filestr), funstr{i}=[varPrefix,' ',funstr{i}]; end

%%%if strcmp(this_fun_name,'test01')
%%% 'saaaaaaaaa11',showall(funstr),kb
%%%end



%%%%add in all the reshapes
%%%temp6='';
%%%for i=1:size(localVar,1)
%%% if ~isempty(localVar{i,6}) && localVar{i,6} && ~isempty(length(localVar{i,5})) && length(localVar{i,5})>1
%%%  temp1='';
%%%  for j=1:length(localVar{i,5})
%%%   temp1=[temp1,localVar{i,5}{j},','];
%%%  end % for j=1:length(localVar{i,3
%%%  temp6=[temp6,localVar{i,1},'=reshape(',localVar{i,1},',[',temp1(1:end-1),']);'];
%%% end % if localVar{i,
%%%end % for i=1:size(localVar,
%%%    %now add this in to funstr
%%%goonimag=find(filestr,1,'last');if isempty(goonimag), goonimag=1; end
%%%funstr{goonimag}=[funstr{goonimag},temp6];
%%%
%%%[s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,goonimag,fs_goodHasAnyQuote);

almil=~cellfun('isempty',regexp(funstr,'(Alan Miller)|(Date: 200)|( by SPAG)|( by SPAG)|(!bb\*)|(77to90)|(%\.\.\.Switches\:)|(M o d u l e s)|(D u m m y   A r g u m e n t s)|(L o c a l   V a r i a b l e s)|(E x t e r n a l   F u n c t i o n s)|(G l o b a l   P a r a m e t e r s)|(C o m m o n   B l o c k s)|(f77kinds)'));
%if ~isempty(find(almil)), 'eeeeeeee',kb, end

temp1=find(almil);
for ii=temp1(:)'
 if ii>1
  if ~isempty(strfind(funstr{ii-1},'-----------------------------------------------'))
   almil(ii-1)=1;
  end % if ~isempty(strfind(funstr{ii-1},
 end % if ii>1
 if ii<s
  if ~isempty(strfind(funstr{ii+1},'-----------------------------------------------'))
   almil(ii+1)=1;
  end % if ~isempty(strfind(funstr{ii-1},
 end % if ii>1
end % for ii=temp1

temp(find(almil))=0;   

almil=~cellfun('isempty',regexpi(funstr,'(% Dummy arguments)|(% Local variables)|(% PARAMETER definitions)|(End of declarations rewritten by SPAG)|(% Derived Type definitions)'));
temp(find(almil))=0; %gets rid of that line
temp(find(almil)-1)=0;% and the line before
temp(find(almil)+1)=0;% and the line after

almil=~cellfun('isempty',regexpi(funstr,'(Start of declarations rewritten by SPAG)'));
temp(find(almil))=0; %gets rid of that line
temp(find(almil)-1)=0;% and the line before

temp=find(temp);
temp1=cell(1,1);
[temp1{1:length(temp)}]=deal(funstr{temp});
funstr=temp1;
%%%% Fix the logical operators
%%%for j=1:length(logicalops)
%%% funstr=strrep(funstr,logicalops{j,1},logicalops{j,2});
%%%end



[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
fundecline=find(~cellfun('isempty',regexp(funstr,['^\<function.+',this_fun_name])));

%'saaaaaaaaa',funstr.',kb


%if strcmp(this_fun_name,'splpmn'),'///////////////',kb,end
%'reeeeeeee3333334',funstr,keyboard

%Try to find vars to be initialized in subroutine calls
temp5=whichsub;
%temp5=find(strcmpi(fun_name,this_fun_name));
temp3=fundecline;
for i=fs_good
%%% try % loop try
  temp1=strcmp('call',funstrwords{i});
  if any(temp1)
   temp1=find(temp1);
   temp1=temp1(1);
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(temp1))
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp1+1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    if howmany>0
     fid=find(((funstrwords_b{i}>parens(1))&(funstrwords_b{i}<parens(2))));
     %Initialize undeclared vars
     %fid holds the word indeces for all subscript
     if ~isempty(fid)
      for j=1:length(fid)
       % don't initialize function calls
%%%    if strcmp(this_fun_name,'refine') && strcmp(funstrwords{i}{temp1+1},'cvf') && any(strcmpi(funstrwords{i},'f0'))
%%%     'sttttttttt22',funstr{i},j,kb
%%%    end
       if ~any(strcmpi(funstrwords{i}{fid(j)},commonvars)) & ~any(strcmpi(funstrwords{i}{fid(j)},fortranfunwords)) & validSpot(funstr{i},funstrwords_b{i}(fid(j))) & funstr{i}(lastNonSpace(funstr{i},funstrwords_b{i}(fid(j))))~='.'
        goon=0;
        if any(strcmp(funstrwords{i}{fid(j)},funstrwords{temp3})) %this word appears in the function definition
         temp4=find(funstr{temp3}=='=');
         if ~isempty(temp4)
          temp2=find(strcmp(funstrwords{i}{fid(j)},funstrwords{temp3}));
          if funstrwords_b{temp3}(temp2(end))>temp4(end)
           %do nothing, this var is an incoming argument or a common variable
          else
           %put in inout for initialization. Is an output argument
           goon=1;
          end
         end
        else
         [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,fid(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
         if howmany2==0 %no subscript => must be a variable, initialize
          goon=1;
         else %test to see if function call
%%%          if ~(any(strcmp(funstrwords{i}{fid(j)},funwords))|...
%%%               any(strcmp(funstrwords{i}{fid(j)},fun_name)))
          if ~(any(strcmp(funstrwords{i}{fid(j)},funwords))|...
               any(strcmp(funstrwords{i}{fid(j)},fun_name))|...
               any(funstr{i}(parens2(1):parens2(2))=='''')|...
               any(funstr{i}(parens2(1):parens2(2))=='"')...
               )
           goon=1;
          end
         end
         % but if this is the only word before an = sign, then it is a specifier only.
         % if the subroutine is part of funwordsNoRemoveEq, then don't add
         if any(strcmp(funstrwords{i}{temp1+1},funwordsNoRemoveEq))
          goon=0;
         end
         %if want_ze==1 and this is a local var (or module's local var), then don't initialize
         temp7=varInUsedMods(funstrwords{i}{fid(j)},modLocalVar,usedMods);
         if want_ze && (any(strcmp(localVar(:,1),funstrwords{i}{fid(j)})) || ~isempty(temp7))
          goon=0;
         end % if want_ze && (any(strcmp({localVar{:,
        end
        %if this is a struct, then it (probably) doesn't need initialization up top
        temp8=find(strcmp(localVar(:,1),funstrwords{i}{fid(j)}));
        if ~isempty(temp8)
         if ~any(strcmp(localVar{temp8,3},var_words))
          goon=0;
         end
        end
        if goon & ~informationRun
         if ~any(strcmp(funstrwords{i}{fid(j)},inout{temp5})) && ...
              ~any(strcmp(funstrwords{i}{fid(j)},fun_name)) && ...
              ~any(strcmp(funstrwords{i}{fid(j)},funwords)) && ...
              ~any(strcmp(funstrwords{i}{fid(j)},statementFunction)) && ...
              ~any(strcmp(funstrwords{i}{fid(j)},extwords)) && ...
              ~strcmp(funstrwords{i}{fid(j)},[TFops{1,2},TFops{1,3}]) && ...
              ~strcmp(funstrwords{i}{fid(j)},[TFops{2,2},TFops{2,3}])
%%%         if ~informationRun %& strcmpi(funstrwords{i},'sdot')
%%%          '-=-=-=-=-=-=-',funstr{i},inout,kb
%%%         end
          inout{temp5}{end+1}=funstrwords{i}{fid(j)};
         end
        end
       end
      end
     end
    end
   end
  end
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with finding vars to be initialized in subroutine calls')
%%%  warning(funstr{i})
%%% end % loop end
end

%%%if strcmp(this_fun_name,'check2')
%%% 'reeeeeeee3333333',funstr.',inout,keyboard
%%%end


%%%%split up the one line if statements
%%%for i=fliplr(fs_good)
%%% if ~isempty(funstrwords{i})
%%%%%%       if any(strcmpi(funstrwords{i},'HISTOGRAM'))
%%%%%%        'iiiiiiiiiiiii',funstr{i},keyboard
%%%%%%       end     
%%%  if strcmp(funstrwords{i}{1},'if')
%%%   if validSpot(funstr{i},funstrwords_b{i}(1))
%%%    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%    if any(strcmp('then',funstrwords{i}))
%%%     funstr{i}=[funstr{i}(1:parens(2))];
%%%    else
%%%     funstr(i+3:end+2)=funstr(i+1:end);
%%%     tempstr=funstr{i};
%%%     funstr{i}=[tempstr(1:parens(2))];
%%%     funstr{i+1}=[tempstr(parens(2)+1:end)];
%%%     funstr{i+2}=['end;'];
%%%    end % if ~strcmp('end',
%%%   end % if validSpot(funstr{i},
%%%  end % if strcmp(funstrwords{i}{1},
%%% end % if ~isempty(funstrwords{i})
%%%end % for i=fliplr(fs_good)
%%%[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);




%%%if strcmpi(this_fun_name,'stest')
%%% 'reeeeeeee88888888aa',showall(funstr'),globVar,keyboard
%%%end

%Change over // string concatenations, note that / is a return in a format statement
for i=fs_good
%%% try
  temp=findstr(funstr{i},'//');
  for ii=length(temp):-1:1
   goon=1;       temp1=find(strcmp(funstrwords{i},'format'));
   if any(temp1)
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp1(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    if ~isempty(parens) && temp(ii)>=parens(1) && temp(ii)<=parens(2)
     goon=0;
    end
   end
   if goon && validSpot(funstr{i},temp(ii))
    [tempflag,temp5,argDelin]=changeoperator_f(i,'//',temp(ii),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords, fortranfunwords,formats,localVar,typeDefs,var_words);
%%%    if any(strcmp(funstrwords{i},'abcd'))
%%%     funstr{i},funstr{i}(1:temp(ii)+1)
%%%     'iiiiiiiiii',argDelin,funstr{i},funstr{i}(argDelin(1):argDelin(2)),kb
%%%    end
    funstr{i}=[funstr{i}(1:argDelin(1)-1),'[',funstr{i}(argDelin(1):argDelin(2)),',',...
              funstr{i}(argDelin(3):argDelin(4)),']',funstr{i}(argDelin(4)+1:end)];
    funstr{i}=strrep(funstr{i},'''''[''','[''''''');
    funstr{i}=strrep(funstr{i},''']''''',''''''']');
%%%    funstr{i}=fix_concats(funstr{i},temp(ii),funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,fs_good,i,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    temp=findstr(funstr{i},'//');
   end % if ~inastring_f(funstr{i},   
  
  end % for ii=1:length(temp)
%%% catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with Changing over // string concatenations')
%%%  warning(funstr{i})
%%% end
end

%'lopppppppppppp',showall(funstr.'),kb


temp10={}; %which local vars to add MLapp to after this section is over
%Change calls to matlab function with no fortran equivalent (user m-files).
noChangeWords={keywordsbegin{:}}.';
%noChangeWords={keywordsbegin{:},fun_name{:}}.';
temp1={fun_name{:},keywordsbegin{:},var_words{:}};
%temp1={funwords{:},fun_name{:},keywordsbegin{:},var_words{:}};
temp3=0;
for i=fliplr(fs_good)
%%%%%% try % loop try
  for j=length(funstrwords{i}):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(j))
    %if j<=length(funstrwords{i}) && validSpot(funstr{i},funstrwords_b{i}(j))
    tempflag=0;
    temp6=0;
% if this is a var in a module, then put construct the global var statement if wanted
    if want_gl && ~ismod 
%%%     if strcmpi(this_fun_name,'edisc') && strcmpi(funstrwords{i}{j},'ph')
%%%      'sssssssssss',funstr{i},keyboard
%%%     end
     %if want_gl && subfun && ~ismod 
     if any(strcmp(funstrwords{i}{j},{localVar{:,1},localVar{:,3}})) && ...
          ~any(strcmp(funstrwords{i}{j},{origLocalVar{:,1}})) && ...
          ~any(strcmp(funstrwords{i}{j},temp1)) && ...
          ~any(strcmp(funstrwords{i}{j},globVar)) && ...
          ~any(strcmp([funstrwords{i}{j},MLapp],globVar))
      goon=1;
      if length(funstrwords{i}{j})>length(MLapp) && ...
           strcmp(funstrwords{i}{j}(end-length(MLapp)+1:end),MLapp) && ...
           any(strcmp(funstrwords{i}{j}(1:end-length(MLapp)),{origLocalVar{:,1}}))
       goon=0;
      end
      if goon
       if any(strcmp(funwords,funstrwords{i}{j})), temp0=MLapp; else temp0=''; end
       globVar={globVar{:},[funstrwords{i}{j},temp0]};
      end
     end
    end % if want_gl && ~ismod 
    if ~any(strcmp(funstrwords{i}{j},noChangeWords)) %&& ~any(strcmp(funstrwords{i}{j},localVar(:,1))) 
     goon2=1;
     temp6=1;
     tempflag=0;
     tempstr=funstr{i};
     goon=1;
     if (~isempty(fundecline) && i==fundecline),      goon=0;     end
     %If there is a period in front of this word, then it must be a field of a struct, so don't
     % for things like var1.count, but .not.var is acceptable
     temp7=lastNonSpace(funstr{i},funstrwords_b{i}(j));
     if temp7>0 && funstr{i}(temp7)=='.' && j>1 && ~strcmp(funstrwords{i}{j-1},'not')
%%%     if funstrwords_b{i}(j)>1 && funstr{i}(funstrwords_b{i}(j)-1)=='.' && ...
%%%          ~strcmp(funstrwords{i}{j},'not')
      goon=0; goon2=0;
     end
     %this may be another declared function
     temp8=find(strcmp(funstrwords{i}{j},sublist_all(:,1)));
     if ~isempty(temp8)
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany==length(sublist_all{temp8(1),8})
       goon=0; goon2=0;
      end % if howmany==length(sublist_all{temp8(1),
     end % if ~isempty(temp8)
     ;% it may even be this function
     if strcmp(funstrwords{i}{j},this_fun_name)      goon=0; goon2=0;     end
%%%     if any(strcmp(funstrwords{i},'aimag'))
%%%      '999999999999112',funstr{i},keyboard
%%%     end     

     if goon && ~any(strcmp(funstrwords{i}{j},localVar(:,1))) && ...
          ~any(strcmp([funstrwords{i}{j},MLapp],localVar(:,1)))
      %|| any(strcmpi(funstrwords{i}{j},{'trgtoptismatdomain','parsed_list_length','add_variable_to_matrix','loadconstraintvectorsparse'}))
      [funstr,fortranfunwords,tempflag,temp2,temp4,needThings]=wordconverter_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,fortranfunwords,formats,localVar,modLocalVar,MLapp,varp,want_row,var_words,this_fun_name,TFops,allTypeDefs,funwordsML,statementFunction,fun_name,dumvar,want_gl,fundecline,funargs,needThings,usedMods);
      if any(strcmp(funstrwords{i}{j},fun_name)), tempflag=1; end
      if temp2, temp3=1; end
      extraFunctions=unique([extraFunctions,temp4]);
     elseif any(strcmp(funstrwords{i}{j},{funwords{:},{fortranVarOrRes{:}}})) && goon2
      %put an MLapp on the end
      %funstr{i}=regexprep(funstr{i},['\<',funstrwords{i}{j},'\>'],[funstrwords{i}{j},MLapp]);
      %      'oooooooooooo',funstr{i},kb
      funstr{i}=[funstr{i}(1:funstrwords_e{i}(j)),MLapp,funstr{i}(funstrwords_e{i}(j)+1:end)];
      %change the persistentVar list if appropriate
      fid=find(strcmp(funstrwords{i}{j},persistentVars));
      if ~isempty(fid)
       persistentVars{fid}=[persistentVars{fid},MLapp];
      end % if ~isempty(fid)
      ;%change localVar to reflect what has happened
      temp9=find(strcmp(funstrwords{i}{j},localVar(:,1)));
      if ~isempty(temp9)
       temp10=unique({temp10{:},funstrwords{i}{j}});
       %localVar{temp9(1),1}=[localVar{temp9,1},MLapp];
      end
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end
    end
%%%\
%%% -   funstr{i},funstrwords{i},funstrwords{i}{j},j,'pppppppppp',tempflag,kb
%%%/
    if tempflag==0
     if temp6%~any(strcmp(funstrwords{i}{j},noChangeWords)) 
      noChangeWords{length(noChangeWords)+1}=funstrwords{i}{j};
     end
     if size(varp,1)>0 
      temp=find(strcmpi(funstrwords{i}{j},{varp{:,1}}));
      if ~isempty(temp)
%%%     temp=find(strcmpi(funstrwords{i}{j},{varp{:,1}}));
%%%     if ~isempty(temp)
       [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
       if howmany>0
        temp7=find(strcmp(localVar(:,1),funstrwords{i}{j})); %if this is data, might have to add the varp
        if isempty(strfind(funstr{i},varPrefix)) || (~isempty(temp7) && ~isempty(localVar{temp7,6}))
         temp11=[parens(1) centercomma parens(2)];
         for goon=length(varp{temp,2}):-1:1
%%%         if any(strcmp(funstrwords{i},'end'))
%%%          varp,temp,goon,varp{temp,2}(goon),funstr{i},keyboard
%%%         end
          if ~strcmp(subscripts{varp{temp,2}(goon)},'[1:end]')
           %This could be a colon indexed expression
           temp12=strfind(subscripts{varp{temp,2}(goon)},':');
           if ~isempty(temp12)
            tempstr=[subscripts{varp{temp,2}(goon)}(1:temp12-1),'+',...
                     num2str(varp{temp,3}(goon)),subscripts{varp{temp,2}(goon)}(temp12:end)...
                    '+',num2str(varp{temp,3}(goon))];
            funstr{i}=[funstr{i}(1:temp11(varp{temp,2}(goon))),tempstr,funstr{i}(temp11(varp{temp,2}(goon)+1):end)];
           else
            funstr{i}=[funstr{i}(1:temp11(varp{temp,2}(goon)+1)-1),'+',num2str(varp{temp,3}(goon)),funstr{i}(temp11(varp{temp,2}(goon)+1):end)];
           end
           %funstr{i}=[funstr{i}(1:temp11(varp{temp,2}(goon)+1)-1+(goon-1)*2),'+',num2str(varp{temp,3}(goon)),funstr{i}(temp11(varp{temp,2}(goon)+1)+(goon-1)*2:end)];
          end
         end
        end
       end
       tempflag=1;
      end
     end
    end
    if tempflag~=0
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    end
   end % if ~inastring_f(funstr{i},
  end % for j=length(funstrwords{i}):-1:1
%%%%%% catch % loop catch
%%%%%%  numErrors=numErrors+1;
%%%%%%  disp('problem with performing word conversion')
%%%%%%  warning(funstr{i})
%%%%%% end % loop end
end
if want_kb,disp('finished performing word conversion'),disp(r),showall_f(funstr),disp(r),keyboard,end
if temp3
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
 %if strcmp(this_fun_name,'timestring'),'reeeeeeee444444442',funstr{i},keyboard,end
end
for ii=1:length(temp10)
 %adjust localVar
 temp9=find(strcmp(temp10{ii},localVar(:,1)));
 if ~isempty(temp9)
  localVar{temp9(1),1}=[localVar{temp9,1},MLapp];
 end
 %also adjust needRS
 if ~isempty(needRS)
  temp9=find(strcmp(temp10{ii},needRS));
  if ~isempty(temp9)
   needRS{temp9(1)}=[needRS{temp9(1)},MLapp];
  end
 end % if ~isempty(needRS)
end


%%%if strcmpi(this_fun_name,'stest')
%%% 'werttttttttttt',funstr.',kb
%%%end



% take care of string assignments with strAssign
for i=fs_good
 %try % loop try
 if ~isempty(funstrwords{i}) && isempty(find(strcmp(funstrwords{i},'strAssign')))
%%%         if any(strcmp(funstrwords{i},'rname'))
%%%          'iiiiiiiiiiii',funstr{i},keyboard
%%%         end
  temp6=find(strcmp(funstrwords{i}{1},localVar(:,1)));
  goon=0;
  if ~isempty(temp6) && strcmp(localVar{temp6,3},'character') && isempty(localVar{temp6,5}), goon=1; end
  % this may also be a var in the used module
  temp7={};
  temp7=varInUsedMods(funstrwords{i}{1},modLocalVar,usedMods);
  if ~isempty(temp7) && strcmp(temp7{3},'character') && isempty(temp7{5}), goon=1; end
  
  if goon
   [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);    
   [temp3,temp4,temp5]=getTopLevelStrings(funstr{i},funstrwords_e{i}(1),'=',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
   if ~isempty(temp3)
    temp9={}; temp9{1}='[]'; temp9{2}='[]';
    %'dddddddddd',funstr{i},kb
    if howmany==1
     temp8=findstr(subscripts{1},':');
     if isempty(temp8)
      temp9{1}=strtrim(subscripts{1});              temp9{2}=strtrim(subscripts{1});
     else
      temp9{1}=strtrim(subscripts{1}(1:temp8-1));   temp9{2}=strtrim(subscripts{1}(temp8+1:end));
      if isempty(temp9{1}), temp9{1}='[]'; end
      if isempty(temp9{2}), temp9{2}='[]'; end
     end
    end % if howmany==0
    funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),funstrwords{i}{1},'=strAssign(',...
               funstrwords{i}{1},',',temp9{1},'',',',temp9{2},',',funstr{i}(temp3(1)+1:end-1),');'];
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   end % if ~isempty(temp3)
  end % if goon
 end % if ~isempty(funstrwords{i})
end % for i=fs_good

    
%'sssssssssssss1',funstr',keyboard
    
    


%fix any : list in a subscript to have be enclosed in [] and fix order for a:b:step
%%%if ~isempty(strfind(version,'R14'))
tempflag=intersect(find(~cellfun('isempty',strfind(funstr,':'))),fs_good);
%%%else
%%% tempflag=[];
%%% for ii=1:length(funstr)
%%%  if ~isempty(strfind(funstr{ii},':'))
%%%   tempflag=[tempflag,ii];
%%%  end
%%% end
%%% tempflag=intersect(tempflag,fs_good);
%%%end
if ~isempty(tempflag)
 for i=tempflag
%%% try % loop try
  for jj=length(funstrwords{i}):-1:1
   if ~strcmpi(funstrwords{i},'not')
    j=jj;
    temp=funstr{i}=='(';
    temp1=funstr{i}==')';
    temp2=cumsum(temp)-cumsum([0 temp1(1:end-1)]);
    temp4=find(funstr{i}==':');
%%%    if any(strcmpi(funstrwords{i},'ll30'))
%%%     i,j, funstr{i}, kb
%%%    end
%%%   if length(funstrwords{i})>2 && strcmp('tdmrinitchan',this_fun_name)
%%%    i,j, funstr{i}, kb
%%%   end
    [temp11,temp12,temp13]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words,0,inf);
    if ~isempty(temp12)
     j=temp13;
     if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(j))
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany>0
       subscripts=strtrim(subscripts);
       temp3=[parens(1),centercomma,parens(2)];
       tempstr=[];
       for count=1:howmany
        temp5=temp4(temp4>temp3(count) & temp4<temp3(count+1)); %which subscript is this in?
        goon=0;
        if ~isempty(temp5)
         if all(temp2(temp5)==temp2(temp3(count)))
          goon=1;
         end
        end
        if goon
         temp6=''; temp6{1}='['; temp6{2}=']';
         if strcmp(subscripts{count}(1),'[')
          temp6{1}=''; temp6{2}='';
         end
         goonimag='';
         if subscripts{count}(end)==':'
          goonimag='end';
         end
         tempflag='';
         if subscripts{count}(1)==':'
          tempflag='1';
         end
         if length(temp5)==1
          % if this is a string, then limit the upper bound by the length of the string
          temp7=find(subscripts{count}==':');
          %is this on the left side of an assignment? then don't fo it
          temp9=1; temp10={};
          [temp10{1},temp10{2},temp10{3}]=getTopLevelStrings(funstr{i},funstrwords_b{i}(j),'=',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
          if temp10{3}(1)~=length(funstr{i}) && temp10{2}==0 && ...
               ~any(strcmp(funstrwords{i}{1},keywordsbegin))
           temp9=0;
          end
          if strcmp(temp12{1,3},'character') && isempty(temp12{1,5}) && ...
               length(temp7)==1 && ...
               ~strcmp(strtrim(subscripts{count}(temp7+1:end)),'1') && ...
               ~strcmp(subscripts{count}(1:temp7-1),subscripts{count}(temp7+1:end)) && ...
               temp9 && ~isempty(strtrim(subscripts{count}(temp7+1:end)))
           %'ssssssssssss',funstr{i},kb
           subscripts{count}=[subscripts{count}(1:temp7),'min(length(',funstrwords{i}{j},...
                              '),',subscripts{count}(temp7+1:end),')'];
          end
          fid=[temp6{1},tempflag,subscripts{count},goonimag,temp6{2}];
         else
          fid=[temp6{1},tempflag,...
               funstr{i}(temp3(count)+1:temp5(1)),...
               funstr{i}(temp5(2)+1:temp3(count+1)-1),...
               funstr{i}(temp5(1):temp5(2)-1),...
               temp6{2}];
         end
        else
         fid=subscripts{count};
        end
        if count~=howmany
         tempstr=[tempstr,fid,','];
        else
         tempstr=[tempstr,fid];
        end
       end
       funstr{i}=[funstr{i}(1:parens(1)),tempstr,funstr{i}(parens(2):end)];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      end
     end
    end % if any(strcmp(funstrwords{i}{j},
   end % for j=1:length(funstrwords{i})
  end % for jj=length(funstrwords{i}):-1:1

%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with fix any : list in a subscript to have be enclosed in []')
%%%  warning(funstr{i})
%%% end % loop end
 end
end % if ~isempty(tempflag)


%'reeeeeeee5555555555',funstr.',keyboard



%don't want [1:end] on strings
%funstr=regexprep(funstr,['(writeFmt\()(\s*\w+)\(\[1:end\]\)'],['$1$2']);
temp1=regexp(funstr,['(\[1:end\]\)']);
for i=find(~cellfun('isempty',temp1))
 for j=1:length(temp1{i})  
  [outflag,whichword,temp5,howmany,subscripts,centercomma,parens]=insubscript_f(i,temp1{i}(j)+1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
  if outflag && howmany==1
   temp4=find(strcmp(localVar(:,1),funstrwords{i}{whichword}));
   if ~isempty(temp4)
    if strcmp(localVar{temp4,3},'character')
     funstr{i}=[funstr{i}(1:funstrwords_e{i}(whichword)),funstr{i}(parens(2)+1:end)];
     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     %'ssssssssssssssstttt',funstr{i},kb
    end % if strcmp(localVar{temp4,
   end % if ~isempty(temp4)
  end % if outflag
 end % for j=1:length(temp1{i})
end % for ii=find(~cellfun('isempty',





%%%if strcmpi(this_fun_name,'stest')
%%% 'reeeeeeee88888888aaafter',showall(funstr'),globVar,keyboard
%%%end
%%%
%%%%Change over // string concatenations, note that / is a return in a format statement
%%%for i=fs_good
%%%%%% try
%%%  temp=findstr(funstr{i},'//');
%%%  for ii=length(temp):-1:1
%%%   goon=1;       temp1=find(strcmp(funstrwords{i},'format'));
%%%   if any(temp1)
%%%    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp1(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%    if ~isempty(parens) && temp(ii)>=parens(1) && temp(ii)<=parens(2)
%%%     goon=0;
%%%    end
%%%   end
%%%   if goon && validSpot(funstr{i},temp(ii))
%%%    [tempflag,temp5,argDelin]=changeoperator_f(i,'//',temp(ii),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords, fortranfunwords,formats,localVar,typeDefs,var_words);
%%%%%%    if any(strcmp(funstrwords{i},'abcd'))
%%%%%%     funstr{i},funstr{i}(1:temp(ii)+1)
%%%%%%     'iiiiiiiiii',argDelin,funstr{i},funstr{i}(argDelin(1):argDelin(2)),kb
%%%%%%    end
%%%    funstr{i}=[funstr{i}(1:argDelin(1)-1),'[',funstr{i}(argDelin(1):argDelin(2)),',',...
%%%              funstr{i}(argDelin(3):argDelin(4)),']',funstr{i}(argDelin(4)+1:end)];
%%%    funstr{i}=strrep(funstr{i},'''''[''','[''''''');
%%%    funstr{i}=strrep(funstr{i},''']''''',''''''']');
%%%%%%    funstr{i}=fix_concats(funstr{i},temp(ii),funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,fs_good,i,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
%%%    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
%%%    temp=findstr(funstr{i},'//');
%%%   end % if ~inastring_f(funstr{i},   
%%%  
%%%  end % for ii=1:length(temp)
%%%%%% catch
%%%%%%  numErrors=numErrors+1;
%%%%%%  disp('problem with Changing over // string concatenations')
%%%%%%  warning(funstr{i})
%%%%%% end
%%%end



% fix multi statement lines
if ~ismod
 funstr=fixMultiStatementLines(funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,fs_good,funwords,filename,varPrefix,shapeVar,origVar);
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
 fundecline=find(~cellfun('isempty',regexp(funstr,['^\<function.+',this_fun_name])));
end

%'reeeeeeee88888888',funstr,globVar,keyboard




%put a fix() around all integer/integer combinations (rhs), 
temp3=[];
temp2={funwords{:},funwordsML{:},fun_name{:}};
for i=fliplr(fs_good)
 temp=find(funstr{i}=='/');
 if ~isempty(temp)
  for j=length(temp):-1:1
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp(j))
    if funstr{i}(temp(j)-1)~='(' && ~strcmpi(funstrwords{i}{1},'data') && funstr{i}(temp(j)+1)~=')' && funstr{i}(temp(j)+1)~='=' && ~strcmpi(funstrwords{i}{1},'writef')
     [tempflag,funstr,temp1]=changeoperator_f(i,'/',temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
     if tempflag
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end

%%%     if strcmpi(this_fun_name,'newcomp')% & strcmpi(funstrwords{3},'ncomp')
%%%      funstr{i},temp1,'gggggggggg',kb
%%%     end
     
     if all(temp1~=0) && isInteger(i,temp1(1:2),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit,this_fun_name) && ...
          isInteger(i,temp1(3:4),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit,this_fun_name)

      %needs a fix()
      temp3=[temp3,i];break
      
%%%      funstr{i}=[funstr{i}(1:temp1(1)-1),'fix(',funstr{i}(temp1(1):temp1(4)),')',funstr{i}(temp1(4)+1:end)];
%%%      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     
     end % if all(temp1~=0) && isInteger(i,
    end % if funstr{i}(temp(j)-1)~='(' && funstr{i}(temp(j)+1)~=')'
   end % if validSpot(funstr{i},
  end % for j=length(temp):-1:1
 end % if ~isempty(temp)
end % for i=fliplr(fs_good)
%%% %now work on the temp3 lines to fix (put parens around) ** first, * and / order and fix
% take care of the exponents first
for i=temp3
 fid=1;
 while fid==1
  fid=0;
  [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
  temp=find(funstr{i}=='/' | funstr{i}=='*');
  temp1=find(funstr{i}=='*');
  for j=temp
   goon=1;
   if any(j==temp1) && (funstr{i}(j+1)=='*' || funstr{i}(j-1)=='*')    goon=0;   end
   if ~goon
    % fix the exponents, by inserting parenthesis
    if funstr{i}(j+1)=='*'
     temp5=j; temp6=j+1;
    else
     temp5=j-1; temp6=j;
    end
    [tempflag,tempstr,temp4]=changeoperator_f(i,'*',temp5,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
%%%    funstr{i},
%%%    funstr{i}(temp4(1):temp4(2))
%%%    funstr{i}(temp4(3):temp4(4))
    [tempflag,tempstr,temp7]=changeoperator_f(i,'*',temp6,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
%%%    funstr{i},
%%%    funstr{i}(temp4(1):temp4(2))
%%%    funstr{i}(temp4(3):temp4(4))
    if funstr{i}(lastNonSpace(funstr{i},temp4(1)))~='(' || ...
         funstr{i}(nextNonSpace(funstr{i},temp7(4)))~=')'
     funstr{i}=[funstr{i}(1:temp4(1)-1),'(',funstr{i}(temp4(1):temp7(4)),')',...
                funstr{i}(temp7(4)+1:end)];
     fid=1; break
    end
   end % if goon
  end % for j=temp
 end % while fid==1
end % for i=temp3
%%% now take care of * and /
for i=temp3
 fid=1;
 while fid==1
  fid=0;
  [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
  temp=find(funstr{i}=='/' | funstr{i}=='*');
  temp1=find(funstr{i}=='*');
  for j=temp
   goon=1;
   if any(j==temp1) && (funstr{i}(j+1)=='*' || funstr{i}(j-1)=='*')    goon=0;   end
   if goon
    if funstr{i}(j)=='*'
     [tempflag,tempstr,temp4]=changeoperator_f(i,'*',j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
     if all(temp4~=0) && ~(funstr{i}(lastNonSpace(funstr{i},temp4(1)))=='(' && ...
                           funstr{i}(nextNonSpace(funstr{i},temp4(4)))==')' )
      %need to change it and break to go back to the while loop
      funstr{i}=[funstr{i}(1:temp4(1)-1),'(',funstr{i}(temp4(1):temp4(4)),')',...
                funstr{i}(temp4(4)+1:end)];
      fid=1; break
     end % if all(temp4~=0) && ~(funstr{i}(lastNonSpace(funstr{i},
    elseif funstr{i}(j)=='/'
     [tempflag,tempstr,temp4]=changeoperator_f(i,'/',j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
     if all(temp4~=0)
      if isInteger(i,temp4(1:2),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit,this_fun_name) && isInteger(i,temp4(3:4),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit,this_fun_name)
       %last word "fix"?
       goonimag=1;
       temp5=find(funstrwords_b{i}<temp4(1),1,'last');
       if ~isempty(temp5)
        if strcmp(funstrwords{i}{temp5},'fix')
         goonimag=0;
        end % if strcmp(funstrwords{i}{temp5},
       end % if ~isempty(temp5)
       if goonimag
%%%        if strcmp(funstrwords{i}{1},'factor')
%%%         funstr{i},'ddddddddddddd',kb
%%%        end

        funstr{i}=[funstr{i}(1:temp4(1)-1),'fix(',funstr{i}(temp4(1):temp4(4)),')',funstr{i}(temp4(4)+1:end)];
        fid=1; break
       end % if goonimag
      elseif ~(funstr{i}(lastNonSpace(funstr{i},temp4(1)))=='(' && ...
               funstr{i}(nextNonSpace(funstr{i},temp4(4)))==')' )
       %put parens around it anyway
       funstr{i}=[funstr{i}(1:temp4(1)-1),'(',funstr{i}(temp4(1):temp4(4)),')',...
                  funstr{i}(temp4(4)+1:end)];
       fid=1; break
      end % if isInteger(i,
     end % if all(temp4~=0) 
    end
   end % if goon
  end % for j=temp
 end % while fid==1
end % for i=temp3
 


%%%%put a fix() around all integer/integer combinations (rhs), 
%%%for i=fliplr(fs_good)
%%% temp=find(funstr{i}=='/');
%%% if ~isempty(temp)
%%%  for j=length(temp):-1:1
%%%   if validSpot(funstr{i},temp(j))
%%%    if funstr{i}(temp(j)-1)~='(' && funstr{i}(temp(j)+1)~=')' && funstr{i}(temp(j)+1)~='='
%%%     [tempflag,funstr,temp1]=changeoperator_f(i,'/',temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);
%%%     if tempflag
%%%      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
%%%     end
%%%     if all(temp1~=0) && isInteger(i,temp1(1:2),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit) && ...
%%%          isInteger(i,temp1(3:4),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit)
%%%      %needs a fix()
%%%      %funstr{i},temp1,'gggggggggg',kb
%%%      funstr{i}=[funstr{i}(1:temp1(1)-1),'fix(',funstr{i}(temp1(1):temp1(4)),')',funstr{i}(temp1(4)+1:end)];
%%%      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
%%%     end % if all(temp1~=0) && isInteger(i,
%%%    end % if funstr{i}(temp(j)-1)~='(' && funstr{i}(temp(j)+1)~=')'
%%%   end % if validSpot(funstr{i},
%%%  end % for j=length(temp):-1:1
%%% end % if ~isempty(temp)
%%%end % for i=fliplr(fs_good)

%'reee87878778787',funstr,keyboard


%Various replacements
%%%try % loop try
 tempstr=strrep({funstr{fs_good}},'(/','[');[funstr{fs_good}]=deal(tempstr{:});
 tempstr=strrep({funstr{fs_good}},'/)',']');[funstr{fs_good}]=deal(tempstr{:});
 %Remove any spag processing statements
 funstr=regexprep(funstr,'^!.+processed by SPAG.+','');
 %Change things about the math (matrix mult, /, .*, +, etc.), in cell 'operators'.
 for i=fs_good
  for j=1:length(operators)
   temp=strfind(funstr{i},operators{j,1});
   temp1=0;
   for ii=length(temp):-1:1
    %if ~inastring_f(funstr{i},temp(ii))
    if j==1
     temp6='% =>';
    else
     temp6='';
    end
    if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp(ii))
     funstr{i}=[funstr{i}(1:temp(ii)-1),operators{j,2},funstr{i}(temp(ii)+length(operators{j,1}):end),temp6];
     temp1=1;
    end % if ~inastring_f(funstr{i},
   end
   if temp1
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   end
  end
 end
 %Fix the branch operator statements
 for j=1:length(branchops)
  tempstr=strrep({funstr{fs_good}},branchops{j,1},branchops{j,2});[funstr{fs_good}]=deal(tempstr{:});
 end
 %funstr,'000000000000',kb 
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
fundecline=find(~cellfun('isempty',regexp(funstr,['^\<function.+',this_fun_name])));
%%%catch % loop catch
%%% numErrors=numErrors+1;
%%% disp('problem with Various replacements')
%%% warning
%%%end % loop end

 %'reeeee999999999999999',funstr,keyboard


%logicalops still need some fixing for chars
logicalops_fix={'==','~=','.not.','>=','<=','>','<'};
for i=fliplr(fs_good)
 for j=1:length(logicalops_fix)
  temp=strfind(funstr{i},logicalops_fix{j});
  if ~isempty(temp)
   for k=length(temp):-1:1
    if ~incomment(funstr{i},temp(k)) & ~inastring_f(funstr{i},temp(k))
     if j==3
      %the .not. order of operations on mathematical structures is different for fortran and ML
      % for example in fortran:
      %   IF ( .NOT.ABS(Sd2)>=gamsq ) EXIT
      % should be
      %   if( ~(abs(sd2)>=gamsq) )
      % not
      %   if( ~abs(sd2)>=gamsq )
      % if the .not. is followed by a logical expression, then leave it alone though
      %'loooooooooo',funstr{i},kb
      [tempflag,funstr]=fixNotOperator(i,temp(k),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,logicalops,allTypeDefs,var_words);
     else
      [tempflag,funstr]=changeoperator_f(i,logicalops_fix{j},temp(k),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,allTypeDefs,var_words);   
     end % if j==3
     if tempflag
      %'sssssssssssss',funstr,keyboard
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end % if tempflag
    end % if ~incomment(funstr{i},
   end % for k=length(temp):-1:1
  end % if ~isempty(temp)
 end % for j=1:length(logicalops_fix)
end % for i=fs_good

%'podddddddddd',funstr.',keyboard




%Fix for, while, if, keywords groups
for i=fliplr(fs_good)
%%% try % loop try
 if ~isempty(funstrwords{i})
  switch funstrwords{i}{1}
    case 'call'
    case 'case'
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      goon=0; %if we need a dblank() or not
      if ~isempty(parens)
       funstr{i}(parens(1))='{';      funstr{i}(parens(2))='}';
       if funstr{i}(nextNonSpace(funstr{i},parens(1)))==''''
        goon=1;
       end % if funstr{i}(nextNonSpace(funstr{i},
      end
      for k=2:length(funstrwords{i})
       temp1=find(strcmp(localVar(:,1),funstrwords{i}{k}));
       if ~isempty(temp1)
        if strcmp(localVar{temp1(1),5},'character')
         goon=1;
        end % if strcmp(localVar{temp1(1),
       end % if ~isempty(temp1)
      end % for k=2:length(funstrwords{i})
      if goon
       funstr{i}=[funstr{i}(1:parens(1)),'deblank(',funstr{i}(parens(1)+1:parens(2)-1),')',...
                  funstr{i}(parens(2):end)];
      end % if goon
    case 'continue'
      %should we try to guess who points here?
      %funstr{i}=['% ',funstr{i}];
    case 'else'
      if length(funstrwords{i})>1
       if strcmp(funstrwords{i}{2},'if')
        funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'elseif',funstr{i}(funstrwords_e{i}(2)+1:funstrwords_b{i}(end)-1),';'];
       end
      end
    case 'elseif'
      funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'elseif',funstr{i}(funstrwords_e{i}(1)+1:funstrwords_b{i}(end)-1),';'];
    case 'do'
      %'qqqqqqqqqqqqq',funstr{i},keyboard
      if ~any(strcmpi(funstrwords{i},'while'))
       %fix this if it points to a label
       fixLabeledDoLoops
       fid=find(funstr{i}=='=');
       if ~isempty(fid)
        fid=fid(fid>funstrwords_e{i}(1));fid=fid(1);
        temp=findstr(funstr{i},',');temp1=[];
        temp=temp(temp>fid);
        for j=1:length(temp)
         if inwhichlast_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
          temp1=[temp1 temp(j)];
         end
        end
%%%       if strcmp(this_fun_name,'setsectorconstraints')
%%%        'qqqqqqqqqqqqq',funstr{i},keyboard
%%%       end
        temp2=findend_f(i,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
        goon=1;
        for ii=i+1:temp2-1
         if any(strcmp(funstrwords{ii},'break'))
          goon=0;
         end
        end
        if length(temp1)==1
         if want_for
          if goon
           funstr{temp2}=[funstr{temp2},';',funstr{i}(funstrwords_e{i}(1)+1:fid),strrep(funstr{i}(temp1(1)+1:end),';',''),'+1;'];
          else
           funstr{temp2}=[funstr{temp2},'; if ~exist(''tempBreak'',''var''),',funstr{i}(funstrwords_e{i}(1)+1:fid),strrep(funstr{i}(temp1(1)+1:end),';',''),'+1; end; clear tempBreak'];
          end % if goon
         end
         funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'for',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(fid+1:temp1(1)-1),':',funstr{i}(temp1(1)+1:end)];
        elseif length(temp1)==2
         temp3='+'; %if any(funstr{i}(temp1(2)+1:end-1)=='-'), temp3='-'; end
         if want_for
          if goon
           funstr{temp2}=[funstr{temp2},';',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(temp1(1)+1:temp1(2)-1),temp3,funstr{i}(temp1(2)+1:end)];
          else
           funstr{temp2}=[funstr{temp2},'; if ~exist(''tempBreak'',''var''),',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(temp1(1)+1:temp1(2)-1),temp3,strrep(funstr{i}(temp1(2)+1:end),';',''),'; end; clear tempBreak'];
          end % if goon
         end
         funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'for',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(fid+1:temp1(1)-1),':',funstr{i}(temp1(2)+1:end-1),':',funstr{i}(temp1(1)+1:temp1(2)-1),';'];
        end
       
%%%        goon=1;
%%%        for ii=i+1:temp2-1
%%%         if any(strcmp(funstrwords{ii},'break'))
%%%          goon=0;
%%%         end
%%%        end
%%%        if length(temp1)==1
%%%         if goon
%%%          if want_for
%%%           funstr{temp2}=[funstr{temp2},';',funstr{i}(funstrwords_e{i}(1)+1:fid),strrep(funstr{i}(temp1(1)+1:end),';',''),'+1;'];
%%%          end
%%%         end
%%%         funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'for',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(fid+1:temp1(1)-1),':',funstr{i}(temp1(1)+1:end)];
%%%        elseif length(temp1)==2
%%%         if goon
%%%          temp3='+'; %if any(funstr{i}(temp1(2)+1:end-1)=='-'), temp3='-'; end
%%%          if want_for
%%%           funstr{temp2}=[funstr{temp2},';',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(temp1(1)+1:temp1(2)-1),temp3,funstr{i}(temp1(2)+1:end)];
%%%          end
%%%         end
%%%         funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'for',funstr{i}(funstrwords_e{i}(1)+1:fid),funstr{i}(fid+1:temp1(1)-1),':',funstr{i}(temp1(2)+1:end-1),':',funstr{i}(temp1(1)+1:temp1(2)-1),';'];
%%%        end
       
       else %There is no = sign here and no while, just replace with while
        temp=find(strcmpi(funstrwords{i},'do'));
        %funstr=replaceword_f(i,j,funstr,funstrwords,funstrwords_b,funstrwords_e,'while (1)');
        funstr{i}=[funstr{i}(1:funstrwords_b{i}(temp(1))-1),'while (1)',funstr{i}(funstrwords_e{i}(temp(1))+1:end)];
       end
      else %This is a do while construct
       temp=find(strcmpi(funstrwords{i},'while'));
       funstr{i}=funstr{i}(funstrwords_b{i}(temp(1)):end);
      end
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    case 'if'
%%%       if any(strcmp(funstrwords{i},'encountered'))
%%%        'iiiiiiiiiiiii',funstr{i},funstr{temp2},keyboard
%%%       end     
%%%     if strcmpi('then',funstrwords{i}(end))
%%%      funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'if',funstr{i}(funstrwords_e{i}(1)+1:funstrwords_b{i}(end)-1),';'];
%%%     else
%%%      funstr{i}=[funstr{i}(1:funstrwords_b{i}(1)-1),'if',funstr{i}(funstrwords_e{i}(1)+1:end),' end;'];
%%%     end
%%%     [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    case 'otherwise'
      temp2=findend_f(i,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      temp3=find(~cellfun('isempty',(regexp(funstr(i:temp2),['^\s*case']))));
      if ~isempty(temp3) %have to move the otherwise to after the last case
       funstr=[funstr(1:i-1),funstr(i+temp3(1)-1:temp2-1),funstr(i:i+temp3(1)-1-1),...
              funstr(temp2:end)];
       for ii=i:temp2
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,ii,fs_goodHasAnyQuote);
       end
      end % if ~isempty(temp3)
    case 'switch'
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      goon=0; %if we need a dblank() or not
      if ~isempty(parens)
       if funstr{i}(nextNonSpace(funstr{i},parens(1)))==''''
        goon=1;
       end % if funstr{i}(nextNonSpace(funstr{i},
      end
      for k=2:length(funstrwords{i})
       temp1=find(strcmp(localVar(:,1),funstrwords{i}{k}));
       if ~isempty(temp1)
        if strcmp(localVar{temp1(1),3},'character')
         goon=1;
        end % if strcmp(localVar{temp1(1),
       end % if ~isempty(temp1)
      end % for k=2:length(funstrwords{i})
      if goon
       funstr{i}=[funstr{i}(1:parens(1)),'deblank(',funstr{i}(parens(1)+1:parens(2)-1),')',...
                  funstr{i}(parens(2):end)];
      end % if goon
    case 'endwhere' %just splits this up
      funstr{i}=['end where',funstr{i}(funstrwords_e{i}(1)+1:end)];
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
    case 'where' %does not support an elsewhere separate mask right now
      ;% is this a statement where or does it have a body?
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if any(funstrwords_b{i}>parens(2)) %statement where
       funstr(i+1+2:end+2)=funstr(i+1:end);
       funstr{i+1}=funstr{i}(parens(2)+1:end);
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i+1,fs_goodHasAnyQuote);
       funstr{i}=funstr{i}(1:parens(2));
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       funstr{i+2}=['end where'];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i+2,fs_goodHasAnyQuote);
       [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
      end
      temp=findend_f(i,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      temp2=findNextWord(i,'elsewhere',temp,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if temp2==0  %no elsewhere
       temp2=temp;
      else
       funstr{temp2}=funstr{temp2}(funstrwords_e{temp2}(1)+1:end);
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,temp2,fs_goodHasAnyQuote);
      end
      %get rid of where and end
      funstr{i}=['fmask=find(',funstr{i}(funstrwords_e{i}(1)+1:parens(2)),');NOTfmask=find(~',funstr{i}(funstrwords_e{i}(1)+1:parens(2)),');'];
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);     
      funstr{temp}=['%',funstr{temp}];
      %funstr{temp}=funstr{temp}(funstrwords_e{temp}(1)+1:end);
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,temp,fs_goodHasAnyQuote);
      temp3='';
      for ii=i+1:temp-1
       %ii
       if ii>temp2, temp3='NOT'; end
       for fid2=length(funstrwords{ii}):-1:1
        fid=fid2;
        temp4=find(strcmp(localVar(:,1),funstrwords{ii}{fid}));
        %'ddddddddd',funstr{ii},funstrwords{ii}{fid},kb
        [temp9,temp10,temp11]=varType(ii,fid,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words);
        fid=temp11;
        if ~isempty(temp10) && any(strcmp(temp10{1,3},var_words)) && ~ischar(temp10{1,2})
         if length(temp10{1,5})>0
          [howmany,subscripts,centercomma,parens]=hassubscript_f(ii,fid,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
          % 1-d var, but no subscript
          if length(temp10{1,5})==1 & howmany==0
           funstr{ii}=[funstr{ii}(1:funstrwords_e{ii}(fid)),'(',temp3,'fmask)',funstr{ii}(funstrwords_e{ii}(fid)+1:end)];
           % 1-d var and a subscript
          elseif length(temp10{1,5})==1 & howmany~=0
           % only change this if there is no : and at least one of the vars 
           % in this subscript is a vector
           goon=0;
           if any(funstr{ii}(parens(1):parens(2))==':'), goon=1; end
           temp6=find(funstrwords_b{ii}>parens(1) & funstrwords_b{ii}<parens(2));
           for j=1:length(temp6)
            temp7=find(strcmp(localVar(:,1),funstrwords{ii}{temp6(j)}));
            if ~isempty(temp7)
             if length(localVar{temp7,5})>0, goon=1; end
            end % if ~isempty(temp7)
           end % for j=1:length(temp6)
           if goon
            temp5='';
            if any(subscripts{1}==':')
             temp8=find(subscripts{1}==':',1,'first');
             [outflag,howmany2,subscripts2,centercomma2,parens2]=inbracket_f(ii,parens(1)+temp8,funstr);
             temp5=[subscripts2{1},'-1','+'];
             %'ttttttt1',funstr{ii},temp6,kb
            end
            funstr{ii}=[funstr{ii}(1:parens(1)),temp5,temp3,...
                        'fmask',funstr{ii}(parens(2):end)];
           end
           % 2-d var, no subscript
          elseif length(temp10{1,5})>1 & howmany==0
           funstr{ii}=[funstr{ii}(1:funstrwords_e{ii}(fid)),'(',temp3,'fmask)',funstr{ii}(funstrwords_e{ii}(fid)+1:end)];
           % 2-D, with subscripts
          elseif length(temp10{1,5})>1 & howmany~=0
           temp5=subscripts{1};
           if any(subscripts{1}==':')
            temp8=find(subscripts{1}==':',1,'first');
            [outflag,howmany2,subscripts2,centercomma2,parens2]=inbracket_f(ii,parens(1)+temp8,funstr);
            temp5=[subscripts2{1},'-1','+',temp3,'fmask'];
            %'ttttttt1',funstr{ii},temp6,kb
           end

           temp6=subscripts{2};
           if any(subscripts{2}==':')
            temp8=find(subscripts{2}==':',1,'first');
            [outflag,howmany2,subscripts2,centercomma2,parens2]=inbracket_f(ii,centercomma(1)+temp8,funstr);
            temp6=[subscripts2{1},'-1','+',temp3,'fmask'];
            %'ttttttt1',funstr{ii},temp6,kb
           end
           funstr{ii}=[funstr{ii}(1:parens(1)),temp5,',',temp6,funstr{ii}(parens(2):end)];
          end % if length(localVar{temp4,
         end % if length(localVar{temp4,
        end % if ~isempty(temp4)
       end % for fid=length(funstrwords{ii}):-1:1
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,ii,fs_goodHasAnyQuote);
      end % for ii
          %'whereeeeeeeeee',funstr{i},kb
    case 'while'
  end
 end
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with Fixing for, while, if, keywords groups')
%%%  warning(funstr{i})
%%% end % loop end
end
[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
if want_kb,disp('finished fixing if, for, etc keywords.'),disp(r),showall_f(funstr),disp(r),keyboard,end


%'tttrrrrrrrrrrr',funstr.',kb

%%%%split up the one line if statements
%%%for i=fliplr(fs_good)
%%% if ~isempty(funstrwords{i})
%%%  if strcmp(funstrwords{i}{1},'if')
%%%   if strcmp('end',funstrwords{i}(end))
%%%    funstr(i+3:end+2)=funstr(i+1:end);
%%%    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%    tempstr=funstr{i};
%%%%%%       if any(strcmp(funstrwords{i},'encountered'))
%%%%%%        'iiiiiiiiiiiii',funstr{i},keyboard
%%%%%%       end     
%%%    funstr{i}=[tempstr(1:parens(2))];
%%%    funstr{i+1}=[tempstr(parens(2)+1:funstrwords_b{i}(end)-1)];
%%%    funstr{i+2}=['end;'];
%%%   end % if ~strcmp('end',
%%%  end % if strcmp(funstrwords{i}{1},
%%% end % if ~isempty(funstrwords{i})
%%%end % for i=fliplr(fs_good)
%%%[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);


% fix struct array indexing, allow things like:
%%%type ttt1
%%%  integer i1
%%%end type ttt1
%%%type(ttt1) tv2(10)
%%%tv2%i1=3
%%%tv2(1:4)%i1=4
%%%tv2(1:4)%i1=4+tv2(1:4)%i1
tempstr=0;
for i=fliplr(fs_good)
 if ~isempty(funstrwords{i})
  for j=length(funstrwords{i}):-1:1
   temp1=find(strcmp(funstrwords{i}{j},localVar(:,1)));
   if ~isempty(temp1)
    temp2=find(strcmp(localVar{temp1,3},{typeDefs{:,1}})); 
    if ~isempty(temp2)
     temp3=lastNonSpace(funstr{i},funstrwords_b{i}(j));
     if temp3==0 || funstr{i}(temp3)~='.'
      %OK, get the varType
      [temp4,temp5,temp6]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words);
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp6,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if temp6>j && isempty(parens)
       temp7=find(funstr{i}=='='); 
       if ~isempty(temp7),        temp7=temp7(validSpot(funstr{i},temp7));       end
       if ~isempty(temp7), temp7=temp7(1); else, temp7=0; end
       goon=0;     % add []=deal
       goonimag=0; % add [] only
       if ~strcmp(temp5{1,5},'character')
        if temp3==0 && temp7>0 && ...
                 ( (~isempty(localVar{temp1,5}) & isempty(parens2)) | ...
                   any(funstr{i}(funstrwords_b{i}(j):funstrwords_b{i}(temp6))==':') )
         goon=1;
        end
        if temp3>0 && any(funstr{i}(funstrwords_b{i}(j):funstrwords_b{i}(temp6))==':') && ...
             isempty(parens)
         goonimag=1;
        end
        %'greeeeeeeeeeee11',funstr{i},funstrwords{i}{j},goon,goonimag,kb
        if goon
         temp8=find(funstr{i}==';');  temp8=temp8(validSpot(funstr{i},temp8)&temp8>temp7); 
         temp8=temp8(1);
         funstr(i+1:end+1)=funstr(i:end);
         funstr{i}=['cellVec=num2cell(',funstr{i}(temp7+1:temp8-1),');'];
         funstr{i+1}=['[',funstr{i+1}(1:temp7-1),']',' = deal(cellVec{:});',funstr{i+1}(temp8+1:end)];
         tempstr=1;
         break
        elseif goonimag
         funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',...
                    funstr{i}(funstrwords_b{i}(j):funstrwords_e{i}(temp6)),']',...
                    funstr{i}(funstrwords_e{i}(temp6)+1:end)];
         [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
        end
       end
       %'greeeeeeeeeeee',funstr{i},funstr{i+1},funstrwords{i}{j},goon,goonimag,kb
      end
     end % if temp3==0 || funstr{i}(temp3)~='.
    end % if ~isempty(temp2)
   end % if ~isempty(temp1)
  end % for j=length(funstrwords{i}):-1:1
 end % if ~isempty(funstrwords{i})
end % for i=fs_good
if tempstr
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
end



% short circuit logic on if's and elseif's
tempstr=0;
for i=fliplr(fs_good)
 if ~isempty(funstrwords{i})
  if any(strcmp(funstrwords{i}{1},{'if','elseif'}))
   goon=1;
   if any(funstr{i}==':') | any(funstr{i}=='['),   goon=0;   end
   if goon
    if length(funstrwords{i})>1 && strcmp(funstrwords{i}{2},'exist'), goon=0; end
    if goon
     for j=1:length(funstrwords{i})
      temp1=find(strcmp(funstrwords{i}{j},localVar(:,1)));
      if ~isempty(temp1)
       %OK, get the varType
       [temp4,temp5,temp6]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words);
       [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp6,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
       if ~isempty(temp5) && howmany~=length(temp5{1,5})
        goon=0; break
       end
      end % if ~isempty(temp1)
     end % for j=1:length(funstrwords{i})
     if goon
      funstr{i}=strrep(funstr{i},'|','||');
      funstr{i}=strrep(funstr{i},'&','&&');
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
     end
    end % if goon
   end % if goon
  end % if any(strcmp(funstrwords{i}{1},
 end % if ~isempty(funstrwords{i})
end % for i=fliplr(fs_good)


%'dfdfdfdfdfdfd',funstr,kb


%Find complex(,) statements with no complex and fix them
for i=fs_good
%%% try % loop try
  count=1;gotto=1;
  while count==1
   count=0;
   temp=findstr('(',funstr{i});
   if ~isempty(temp)
    for j=gotto:length(temp)
     if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp(j))
      [outflag,howmany,subscripts,centercomma,parens]=iscomplexf(i,j,temp,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if outflag && funstr{i}(lastNonSpace(funstr{i},temp(j)))~='@'
%%%       if strcmp(this_fun_name,'rotate2')
%%%        'cccccccccc',funstr{i},kb
%%%       end
       funstr{i}=[funstr{i}(1:temp(j)-1),'complex',funstr{i}(temp(j):(end))];
       [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       count=1;gotto=j;
      end
     end
     if count==1, break; end
    end
   end
  end
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with fixing (,) complex constructions')
%%%  warning(funstr{i})
%%% end % loop end
end
if want_kb,disp('finished inserting complex''s'),disp(r),showall_f(funstr),disp(r),keyboard,end



% Misc tasks
if ~subfun | oneBYone
 filename_ml=[strrep(filename_base,'.','_'),'.m'];
end

%'reeeeeeee000000000',funstr,keyboard

%Let's go for implied do loops
%TODO this doesn't work right with reading in things, e.g.
%%%OPEN (2,FILE='INTER_I2.DAT',STATUS='OLD') 
%%%READ (2,*) (w0(j),j=1,nw+1) 
%%%READ (2,*) ((ap(j,i),i=1,nw+1),j=1,nz+1) 
for i=fs_good
%%% try % loop try
  temp=find(funstr{i}=='=');
  while ~isempty(temp)
   %temp=temp(end);
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},temp(end))
    %if ~inastring_f(funstr{i},temp(end)) & ~incomment(funstr{i},temp(end))
    [outflag,howmany,subscripts,centercomma,parens]=inwhichlast_f(i,temp(end),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
    temp=temp(1:length(temp)-1);
    if outflag==1
     %'idlllllllllllll',funstr{i},kb
     % check to make sure this is not a function call
     foo1=find(funstrwords_b{i}<parens(1));
     if ~isempty(foo1) && ~isempty(files)
      if any(strcmpi(funstrwords{i}{foo1(end)},{files.name}))
       break
      end
     end
     temp3=funstr{i}(parens(1):parens(2)-1);
     [subscripts,temp5]=getTopGroupsAfterLoc(temp3,1);
     if length(subscripts)>2
      %which subscript is the = sign in?
      for ii=length(subscripts):-1:1
       if any(subscripts{ii}=='=')
        temp2=ii;
        temp2(2)=find(subscripts{ii}=='=',1,'first');
        break
       end
      end
      % if the equals is in the last subscript, that is not an implied do loop
      if temp2(1)==length(subscripts)
       break
      end
      [outflag2,howmany2,subscripts2,centercomma2,parens2]=inwhichlast_f(i,parens(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
      %'hhhhhhhhhhhhhh2222222222',funstr{i},keyboard
      if outflag2==2% | ~isempty(strfind(funstr{i},varPrefix)) %implied do loop in an array constructor
       ;%or data
       if ~any(strcmp({'if','elseif','while','fclose','fopen','frewind'},funstrwords{i}{1}))
        tempstr=subscripts{temp2(1)}(1:temp2(2)-1);
        tempstr=tempstr(~isspace(tempstr)); %should contain the loop var
        fid=temp5(temp2(1)-1);
        if (length(subscripts)-temp2(1))==2 %then a two colon for loop
         howmany=['[',subscripts{temp2(1)}(temp2(2)+1:end),':',...
                  subscripts{temp2(1)+2},':',subscripts{temp2(1)+1},']'];
        else
         howmany=['[',subscripts{temp2(1)}(temp2(2)+1:end),':',...
                  subscripts{temp2(1)+1},']'];
        end
        goon=regexprep(funstr{i}(parens(1):parens(1)+fid-1),...
                       ['(\W)',tempstr,'(\W)'],['$1',howmany,'$2']);
        % only need the ones().* if there is no loop var in the expression.
        % For something like (10.0,j=1,4)
        temp6=[]; temp6{1}=''; temp6{2}='';
        goonimag=funstrwords_b{i}>(parens(1)) & funstrwords_b{i}<(parens(1)+temp5(1)-1);
        if ~any(goonimag) || ~any(strcmp({funstrwords{i}{goonimag}},tempstr))
         temp6{1}=['ones(size(',howmany,')).*(']; temp6{2}=')';
        end
        % if this is a var dec, it may need a reshape TODO
        funstr{i}=[funstr{i}(1:parens(1)-1),temp6{1},goon(2:end-1),temp6{2},funstr{i}(parens(2)+1:end)];
       end % if ~strcmp({'if',
      else % by self, usually with a read or write 
       goon=1;
       %if this is file open/close, then skip
       if any(strcmp({'fclose','fopen','frewind'},funstrwords{i}{1}))
        break
       end
       if any(strcmp({'if','elseif','while'},funstrwords{i}{1}))
        goon=0;
        % if a read or write does not appear closer to the implied do than a "if" etc.
        fid=find(funstrwords_b{i}>funstrwords_b{i}(1) & funstrwords_b{i}<parens(1));
        if any(strcmp('fscanf',{funstrwords{i}{fid}})) | any(strcmp('fprintf',{funstrwords{i}{fid}})) | any(strcmp('writef',{funstrwords{i}{fid}}))
         goon=1;
        end % if any(strcmp('fscanf',
       end
       %'hhhhhhhhhhhhhh1111111111',funstr{i},keyboard
       if goon
        tempstr='';
        for ii=1:temp2(1)-1
         if ii~=temp2(1)-1,temp4=',';else temp4='';end
         tempstr=[tempstr,subscripts{ii},temp4];
        end
        if (length(subscripts)-temp2(1))==2 %then a two colon for loop
         funstr{i}=['for ',subscripts{temp2(1)}(1:temp2(2)-1),'=(',...
                    subscripts{temp2(1)}(temp2(2)+1:end),'):(',...
                    subscripts{temp2(1)+2},'):(',subscripts{temp2(1)+1},'), ',...
                    funstr{i}(1:parens(1)-1),tempstr,funstr{i}(parens(2)+1:end),' ;end;'];
        else
         % try to catch places where they are building a string like:
         % write( comment_string,777 ) (var(i),i=1,n) 
         goon2=1;
         temp7=find(funstr{i}=='=',1,'first');
         if length(find(funstrwords_b{i}<temp7))==1
          temp8=find(strcmp(funstrwords{i}{1},localVar(:,1)));
          if ~isempty(temp8) && strcmp('character',localVar{temp8,3})
           goon2=0;
           funstr{i}=[funstr{i}(1:temp7-1),'='''';',...
                      'for ',subscripts{temp2(1)}(1:temp2(2)-1),'=(',...
                      subscripts{temp2(1)}(temp2(2)+1:end),'):(',...
                      subscripts{temp2(1)+1},'), ',...
                      funstr{i}(1:temp7-1),'=[',funstr{i}(1:temp7-1),',',...
                      funstr{i}(temp7+1:parens(1)-1),tempstr,...
                      funstr{i}(parens(2)+1:end-1),']; end;'];
          end % if ~isempty(temp8) && strcmp('character',
         end % if length(find(funstrwords_b{i}<temp7))==1
             %'hhhhhhhhhhhhhh',funstr{i},keyboard
         if goon2==1
          funstr{i}=['for ',subscripts{temp2(1)}(1:temp2(2)-1),'=(',...
                     subscripts{temp2(1)}(temp2(2)+1:end),'):(',...
                     subscripts{temp2(1)+1},'), ',...
                     funstr{i}(1:parens(1)-1),tempstr,funstr{i}(parens(2)+1:end),' ;end;'];
         end
        end
       end % if goon
      end
      [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
      temp=find(funstr{i}=='=');
      %funstr{i},subscripts,',,,,,,,,,,,,,,,,',keyboard
     end % if length(subscripts)>2)
    end % if outflag==1
   else
    temp=temp(1:length(temp)-1);
   end % if ~inastring_f(funstr{i},
  end % while ~isempty(temp)
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with fixing implied do loops'),%  keyboard
%%%  warning(funstr{i})
%%% end % loop end
end % for i=fs_good

%'reeeeeeee11111111',showall(funstr),keyboard


%Fix up the function definitions and calls
for i=fs_good
%%% try % loop try
  temp6=1;
  if length(funstrwords{i})>0
   if ~any(strcmp(funstrwords{i}{1},type_words))
    for ii=length(funstrwords{i}):-1:1
     temp1=find(strcmp(funstrwords{i}{ii},extwords));
     if ~isempty(temp1) && validSpot(funstr{i},funstrwords_b{i}(ii)) && ...
          any(strcmp(funstrwords{i}{ii},localVar(:,1)))
      %if ~any(strcmp(funstrwords{i}{ii},fun_name)) || any(strcmp(funstrwords{i}{ii}
      if inwhichlast_f(i,funstrwords_b{i}(ii),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
       funstr{i}=[funstr{i},funHandleNameSuffix];
%%%      if strcmpi('sfnck',this_fun_name)
%%%       funstr{i},'dfgggggggg',kb
%%%      end
      end
     end
%%%        if any(strcmpi(funstrwords{i},'gaus8')) & strcmpi('eg8ck',this_fun_name) & strcmp(funstrwords{i}{ii},'fein')
%%%         funstr{i},'cccccccccc',kb
%%%        end      
     temp1=find(strcmp(funstrwords{i}{ii},fun_name));
     [temp10,temp11,temp12]=varType(i,ii,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words,0,inf);
     if ~isempty(temp1) & isempty(temp11) & ~strcmpi(funstrwords{i}{ii},this_fun_name)
      if ~strcmp(funstrwords{i}{1},'end')&&validSpot(funstr{i},funstrwords_b{i}(ii))&&...
           ~any(strcmp(funstrwords{i}{ii},localVar(:,1)))
%%%     if strcmpi('catan2',this_fun_name)
%%%      'exxxxxxxxxx',localVar,kb
%%%     end

       funstr{i}=[funstr{i},funNameSuffix];
       %funstr{i},'dfgggggggg11',kb
      end
      if ~inastring_f(funstr{i},funstrwords_b{i}(ii)) && ~any(strcmp(funstrwords{i}{ii},localVar(:,1))) && ~incomment(funstr{i},funstrwords_b{i}(ii))
       [howmany,subscripts,centercomma,parens]=hassubscript_f(i,ii,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
       if howmany>0
        tempstr=find(funstrwords_b{i}>parens(1) & funstrwords_b{i}<parens(2));
        fid=0;
        for j=length(tempstr):-1:1
         if (any(strcmp(funstrwords{i}{tempstr(j)},fun_name)) || ...
             any(strcmp(funstrwords{i}{tempstr(j)},funwords))) && ...
              ~strcmp(funstrwords{i}{tempstr(j)},this_fun_name)
          [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,tempstr(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
          if howmany2==0 && ~any(strcmp(funstrwords{i}{tempstr(j)},localVar(:,1))) &&...
               isempty(varInUsedMods(funstrwords{i}{tempstr(j)},modLocalVar,usedMods)) && ...
               validSpot(funstr{i},funstrwords_b{i}(tempstr(j))) &&...
               ~any(strcmp(funstrwords{i}{tempstr(j)},funstrwords{fundecline}(funargs))) &&...
               funstr{i}(funstrwords_b{i}(tempstr(j))-1)~='@'
           %'tsssssssss',funstr{i},kb
           funstr{i}=[funstr{i}(1:funstrwords_b{i}(tempstr(j))-1),'@',funstr{i}(funstrwords_b{i}(tempstr(j)):end)];
           fid=1;
          end % if howmany2==0
         end % if any(strcmp(funstrwords{i}{tempstr(ii)},
        end % for ii=1:length(tempstr)
        if fid
         [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
        end

%%% This is preempted by the assignin functionality added
%when we have the format:
%   var= fun_name()
% we should change it to a call so that extra vars can be changed as well.
%  call fun_name(var,...)
        if isempty(find(funstrwords_b{i}>parens(2))) && ...
             isempty(find(funstrnumbers_b{i}>parens(2)))
         %temp2=findNext(funstrwords_b{i}(ii),'=',funstr{i},-1);
         temp2=lastNonSpace(funstr{i},funstrwords_b{i}(ii));
         %do we have our = sign just before the function call
         if (temp2>0 && funstr{i}(temp2)=='=') && ...
              (any(strcmp(funstrwords{i}{1},localVar(:,1))) ||...
               strcmp(funstrwords{i}{1},this_fun_name) )
          temp4=lastNonSpace(funstr{i},temp2);
          if suborfun(temp1)==2
           if (temp4>0 && funstr{i}(temp4)~=']') && ...
                (funstrwords_b{i}(ii)-temp2==1 || ...
                 all(funstr{i}(temp2+1:funstrwords_b{i}(ii)-1)==' ')) && ...
                ~any(strcmp(strtrim(funstr{i}(1:temp2-1)),strtrim(subscripts)))
%%%        funstr{i}=['call ',funstrwords{i}{ii},'_function_(',funstr{i}(parens(1)+1:end)];
            %'fffffffffffffff',funstr{i},kb
            funstr{i}=['call ',funstrwords{i}{ii},'(',funstr{i}(1:temp2-1),',',...
                       funstr{i}(parens(1)+1:end)];
            temp6=0; %marks this line as special for below
            [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
           end % if funstrwords_b{i}(ii)-temp2==1 || all(funstr{i}(tem
          end % if suborfun(temp1)==2
         end % if temp~=-1 %we've got our = sign just before the function call,
        end % if isempty(find(funstrwords_b{i}>parens(2))) && .
        
       end % if howmany>0      
      end % if ~inastring_f(funstr{i},
     end % if ~isempty(temp1)
    end % for ii=length(funstrwords{i}):-1:1
   end % if ~any(strcmp(funstrwords{i}{1},
  end % if length(funstrwords{i}>0)

  %Adjust subroutine calls and piece multi-segmented files together
  temp=strcmp('call',funstrwords{i});
  if any(temp)

%%%   if strcmp(this_fun_name,'readcontancompartsdt')
%%%   ';;;;;;;;;;',funstr{i},kb
%%%  end

   %Need to fix the segment calls
   temp=find(temp); temp=temp(1);
   if ~inastring_f(funstr{i},funstrwords_b{i}(temp))
    temp=temp+1;
    %temp=find(strcmpi(fun_name{temp1},funstrwords{i}));
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    temp2=[funstr{i}(1:funstrwords_b{i}(temp-1)-1),'['];
    temp3=[]; fid=[];
    for ii=1:howmany
     %see if this subscript is in the form to be an output
     temp3(ii)=output_acceptable(i,temp,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,ii,howmany,subscripts,centercomma,parens,fun_name,statementFunction,localVar,fortranfunwords,var_words,this_fun_name,funwordsML,TFops,allTypeDefs);
     %Add that input to output list or put in dummyvar
    end

    goon=1;
    if any(temp3) %>0 outputs from the inputs
     for ii=1:howmany
      temp4=''; temp5='';
      if temp3(ii) %put in the copy of the input arg
       temp4=subscripts{ii};
      else %just put in a placeholder dummy output arg
       if any(temp3(ii:end))
        temp4=[dumvar,num2str(ii)];
       else
        goon=0;
       end
      end
      if ii<howmany
       if ~any(temp3(ii+1:end))
        goon=0;
       end
      end
      if ii~=howmany & goon~=0 %add a comma if not the last output arg
       temp4=[temp4,','];
      end
      temp2=[temp2,temp4];
     end
     temp2=[temp2,']='];
    else %none of the inputs are going to be outputs
     temp2=temp2(temp2~='[');
    end
    if temp6
     funstr{i}=[temp2,funstrwords{i}{temp},funstr{i}(funstrwords_e{i}(temp)+1:end)];
    else % we have to remove the first var in the call (from above)
     temp7=[parens(1),centercomma,parens(2)];
     funstr{i}=[temp2,funstrwords{i}{temp},'(',funstr{i}(temp7(2)+1:end)];
    end
    [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);   
   end
  end

%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem with Fixing up the function definitions and calls')
%%%  warning(funstr{i})
%%% end % loop end
end


%'qweeeeeeeeeeeee',funstr,kb



% fix matrix=scalar assignments
for i=fs_good
%%% try % loop try
  if ~isempty(funstrwords{i})
%%%         if strcmp(funstrwords{i}{1},'bkgsum')
%%%          'iiiiiiiiiiii',funstr{i},keyboard
%%%         end
   temp6=find(strcmp(funstrwords{i}{1},localVar(:,1)));
   goon=0; goon2=0;
   if ~isempty(temp6) && length(localVar{temp6,5})>0
    goon=1;
    if strcmp(localVar{temp6,3},'character')
     goon2=1;
    end % if strcmp(localVar{temp6,
   end
   %if ~isempty(temp6) && ~strcmp(localVar{temp6,3},'character') && ~strcmp(localVar{temp6,3},'string') && localVar{temp6,2}>0, goon=1; end
   % this may also be a var in the used module
   temp7={};
   temp7=varInUsedMods(funstrwords{i}{1},modLocalVar,usedMods);
   if ~isempty(temp7) && ~isempty(temp7{5})
    goon=1;
    if strcmp(temp7{3},'character')
     goon2=1;
    end % if strcmp(localVar{temp6,
   end
   if goon
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    if howmany==0 %not subscripted, but has >0 dimensions
     [temp3,temp4,temp5]=getTopLevelStrings(funstr{i},funstrwords_e{i}(1),'=',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
     
     %only one word before the first equals
     if ~isempty(temp3) & temp4==0
      if length(find(funstrwords_b{i}<temp3(1)))==1

       % and only one number or scalar after
       goonimag=1;
       %'fdddddddd',funstr{i},j,kb
          
       temp8=find(funstr{i}=='=');
       if ~isempty(temp8)
        %if ~goonimag && ~isempty(temp8)
        j=find(funstrwords_b{i}>temp8(1),1,'first');
        if ~isempty(j)
         while j<=length(funstrwords{i})
          if any(strcmp(funstrwords{i}{j},{'zeros','ones'})), goonimag=0; break; end
          [temp7,temp9,temp0]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words);
          if validSpot(funstr{i},funstrwords_b{i}(j))           
           if ~isempty(temp9)
            %if ~strcmp(temp9{3},'character') 
            if isempty(temp9{5})
             goonimag=1;
            else
             [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp0,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
             if isempty(parens2)
              goonimag=0; break;
             end
            end
            %end
           end % if validSpot(funstr{i},
          end
          j=temp0+1;
         end % while j<=length(funstrwords{i})
        end % if ~isempty(j)
       end % if ~goonimag && ~isempty(temp8)
       
       temp9=find(funstr{i}==':');
       if ~isempty(temp8) && ~isempty(temp9)
        temp9=temp9(temp9>temp8(1));
        if any(validSpot(funstr{i},temp9))
         goonimag=0;
        end % if any(validSpot(funstr{i},
       end % if ~isempty(temp8) && ~isempty(temp9)
       
       if goonimag
        if goon2
         funstr{i}=['for ',f2m_temp,'=1:numel(',funstrwords{i}{1},'), ',...
                    funstrwords{i}{1},'{',f2m_temp,'}=strAssign(',...
                    funstrwords{i}{1},'{',f2m_temp,'},[],[],',...
                    funstr{i}(temp8+1:end-1),'); end'];
        else
         funstr{i}=[funstr{i}(1:funstrwords_e{i}(1)),'(:)',funstr{i}(funstrwords_e{i}(1)+1:end)];
        
%%%        funstr{i}=['tmpEq',funstr{i}(funstrwords_e{i}(1)+1:end),funstr{i}(1:funstrwords_e{i}(1)),'(1:numel(tmpEq))=tmpEq;',];
        end
        [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
       end
      end % if length(find(funstrwords_b{i}<temp3(1)))==1 
     end % if ~isempty(temp3) & isempty(temp4)
    end % if howmany==0 %not subscripted,
        %end % if localVar{temp6,
   end % if goon
  end % if ~isempty(funstrwords{i})
%%% catch % loop catch
%%%  numErrors=numErrors+1;
%%%  disp('problem fixing matrix=scalar assignments')
%%%  warning(funstr{i})
%%% end % loop end
end % for i=fs_good





%'poiuy',funstr.',keyboard



%a fix() on the rhs of assignments
if want_fi
 temp8={localVar{find(strcmp({localVar{:,3}},'integer')),1}};
 for i=fs_good
%%%  try % loop try
   for j=length(funstrwords{i}):-1:1
    temp=find(strcmp(funstrwords{i}{j},temp8));
    if ~isempty(temp)&&isempty(regexp(funstr{i},shapeVar))&&isempty(regexp(funstr{i},origVar))
     if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(j))% ~inastring_f(funstr{i},funstrwords_b{i}(j)) & ~incomment(funstr{i},funstrwords_b{i}(j))
      fid=1; %rhs default
             %is it on the rhs or lhs?
      temp1=find(funstr{i}=='=',1,'first');
      %find the top level semicolons
      [temp3,temp4,temp5]=getTopLevelStrings(funstr{i},funstrwords_b{i}(j),';',i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
      if ~isempty(temp1)
       temp1=temp1(temp1>temp4(1));
       %temp1=temp1(1);
      else
       temp1=0;
      end
      if ~any(strcmp(funstrwords{i}{1},keywordsbegin)) 
       if temp1>funstrwords_b{i}(j)
        fid=0;
       end % if temp1>funstrwords_b{i}(j)
      else
       fid=2;
      end
      if strcmp(funstrwords{i}{1},'for')
       if temp1>funstrwords_b{i}(j)
        fid=2;
       end % if temp1>funstrwords_b{i}(j)
      end     
      if strcmp(funstrwords{i}{1},'function')
       fid=2;
      end
      if ~isempty(strfind(funstr{i},varPrefix)) % is this a var dec line?
       fid=2;
      end
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany==0, parens(1)=funstrwords_b{i}(j);parens(2)=funstrwords_e{i}(j); end
      if fid==1
      elseif fid==0
       temp2=find(~isspace(funstr{i}));  temp2=temp2(temp2>temp4(1));  temp2=temp2(1);
       if temp2==funstrwords_b{i}(j)
        goon=1;
        temp6=find(funstrnumbers_b{i}>=temp1+1 & funstrnumbers_b{i}<=temp5(1)-1);
        temp7=find(funstrwords_b{i}>=temp1+1 & funstrwords_b{i}<=temp5(1)-1);
        if length(temp6)==1 & isempty(temp7)
         if isempty(find(funstrnumbers{i}{temp6}=='.',1))
          goon=0;
         end
        end
        if goon
         temp1=nextNonSpace(funstr{i},temp1);
         %temp1,temp9,funstr{i},'//////////',kb
         funstr{i}=[funstr{i}(1:temp1-1),'fix(',funstr{i}(temp1:temp5(1)-1),');',funstr{i}(temp5(1)+1:end)];
         %funstr{i}=[funstr{i}(1:temp1),'fix(',funstr{i}(temp1+1:temp5(1)-1),');',funstr{i}(temp5(1)+1:end)];
        end
       end
      else % do nothing
      end % if fid
     end % if ~inastring_f(funstr{i},
    end % if ~isempty(temp)
   end % for j=length(funstrwords{i}):-1:1
%%%  catch % loop catch
%%%   numErrors=numErrors+1;
%%%   disp('problem with put a fix() around delcared ints (rhs), or a fix() when on rhs')
%%%   warning(funstr{i})
%%%  end % loop end
 end % for i=fs_good
end




% fix persistent var decs
%for ii=1:s, funstr{ii}=strrep(funstr{ii},'%%__%%__',''); end
funstr=strrep(funstr,'%%__%%__','');

[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
tempstr=strrep({funstr{fs_good}},'(/','[');[funstr{fs_good}]=deal(tempstr{:});
tempstr=strrep({funstr{fs_good}},'/)',']');[funstr{fs_good}]=deal(tempstr{:});

%'reeeeeeee44444444',funstr,keyboard


%put curly braces around string arrays and function handle arrays (became cells)
%this must be the last call to hassubscript if you care about not finding bracketized subscripts

for i=fs_good
 for j=1:length(funstrwords{i})
  temp=find(strcmp(funstrwords{i}{j},localVar(:,1)));
  if ~isempty(temp)
   %if ~incomment(funstr{i},funstrwords_b{i}(j))
   if ~fs_goodHasAnyQuote(i) || validSpot(funstr{i},funstrwords_b{i}(j))
    
%%%    if strcmp(this_fun_name,'accepttransmits') & strcmpi(funstrwords{i}{1},'sync')
%%%     funstr{i},     'wwwwwwwwww',kb
%%%    end
    
    [temp5,temp6,temp7]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,allTypeDefs,var_words,0,inf);
    if ~isempty(temp5)
     if (strcmp(temp5,'character') || ~isempty(temp6{16})) && length(temp6{5})>0
      %if (strcmp(temp5,'character') || ~isempty(localVar{temp,16})) && length(temp6{5})>0
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp7,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if howmany>0 & isempty(strfind(funstr{i},varPrefix))
       %if strcmp(funstrwords{i}{j},'fmt'), 'ooooooo',funstr{i},kb,end
%%%    if strcmp(funstrwords{i}{1},'data_construct_info') && ...
%%%         strcmp(funstrwords{i}{2},'data_type_supported')
%%%     'iiiiiiiiiiii',funstr{i},keyboard
%%%    end
       funstr{i}(parens(1))='{';
       funstr{i}(parens(2))='}';
       % cell_var{r1:r2} cell variables passed into a subroutine 
       %  (with a colon in their subscript) need {} around them
       if any(funstr{i}(parens(1)+1:parens(2)-1)==':')
        [outflag2,howmany2,subscripts2,centercomma2,parens2]=inwhichlast_f(i,funstrwords_b{i}(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename);
        if outflag2==1
         temp3=find(lastNonSpace(funstr{i},parens2(1))==funstrwords_e{i});
         if ~isempty(temp3)
          temp4=find(strcmpi(funstrwords{i}{temp3},fun_name));
          if ~isempty(temp4)
           %put curly braces around this
           funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),'{',...
                      funstr{i}(funstrwords_b{i}(j):parens(2)),'}',funstr{i}(parens(2)+1:end)];
           [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
           %'ddddddddddd',funstr{i},kb
          end % if ~isempty(temp4)
         end % if ~isempty(temp3)
        end % if outflag2==1
        
        % cell arrays = string need some help too
        temp9=nextNonSpace(funstr{i},parens(2));
        %'pppppppp',funstr{i},keyboard
        if ~isempty(temp9)
         if funstr{i}(temp9)=='='
          temp8=nextNonSpace(funstr{i},temp9);
          temp10={'{','}'};
          goon=0;
          for ii=find(funstrwords_b{i}>temp9)
           temp2=find(strcmp(funstrwords{i}{ii},localVar(:,1)));
           if ~isempty(temp2)
            if ~isempty(localVar{temp2,5})
             goon=1; break
            end % if ~isempty(localVar{temp2,
           end % if any(strcmp(funstrwords{i}{j},
          end % for ii=find(funstrwords_b{i}>temp9)
          if any(funstr{i}(temp8:end-1)==':') | goon
           temp10={'',''};
          end % if any(funstr{i}(temp8:end-1)==':')
           
           funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),...
                      funstr{i}(funstrwords_b{i}(j):parens(1)-1),brack2paren{1},...
                      funstr{i}(parens(1)+1:parens(2)-1),brack2paren{2},...
                      '=',temp10{1},funstr{i}(temp8:end-1),temp10{2},';'];
%%%        funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),...
%%%                   'for tempi=1:numel(',funstr{i}(funstrwords_b{i}(j):parens(2)),...
%%%                   '); ',funstrwords{i}{j},'{tempi}=',funstr{i}(temp8:end-1),'; end'];
%%%        funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),...
%%%                   '[',funstr{i}(funstrwords_b{i}(j):parens(2)),...
%%%                   '] = deal(',funstr{i}(temp8:end-1),');'];
%funstr{i},'ggggggggg',kb
           [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
         end % if funstr{i}(nextNonSpace(funstr{i},
        end % if funstr{i}(temp9)=='='
        
       end % if any(funstr{i}(parens(1)+1:parens(2)-1)==':')
      end % if howmany>0
     end % if strcmp(localVar{temp(1),
    end % if ~isempty(temp5)
   end % if ~inastring_f(funstr{i},
  end % if ~isempty(temp)
 end % for j=1:length(funstrwords{i})
end % for i=fs_good




%remove any trailing end? (could this be a legit end?)
if ~isempty(fs_good)
 if length(funstrwords{fs_good(end)})>0
  if strcmp(funstrwords{fs_good(end)}{1},'end') %& ~subfun
   funstr{fs_good(end)}=strrep(funstr{fs_good(end)},';','');
   [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,fs_good(end),fs_goodHasAnyQuote);
  end
 end % if length(funstrwords{fs_good(end)})>0
end

%'hhhhhhhhhhhhhh',funstr.',kb

% recursive functions may get in trouble with var vs function calls if there is no result()
temp8='result';
if ~ismod && suborfun(whichsub)==2
 if ~any(strcmp(funstrwords{1},'result'))
  for i=fs_good
   %if any(strcmp(funstrnumbers{i},'100')), 'nnnnnnnn',kb,end
   while 1
    temp9=funstr{i};
    funstr{i}=regexprep(funstr{i},['^(',this_fun_name,')([^\w])'],['$1',temp8,'$2']);
    funstr{i}=regexprep(funstr{i},['([^\w])(',this_fun_name,')([^\w])'],['$1$2',temp8,'$3']);
%%%    funstr{i}=regexprep(funstr{i},['([^\w]|^)(',this_fun_name,')([^\w])'],['$1--$2--',temp8,'--$3']);
    if strcmp(funstr{i},temp9), break, end
   end
   %funstr{i}=regexprep(funstr{i},['(',this_fun_name,')([^\w])'],['$1',temp8,'$2']);
   % now fix any inline functions
   funstr{i}=regexprep(funstr{i},['@',this_fun_name,temp8,'([^\w])'],['@',this_fun_name,'$1']);
   [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,i,fs_goodHasAnyQuote);
   %is this a recursive call? if so, remove the result
   temp=find(strcmp(funstrwords{i},[this_fun_name,temp8]));
   if ~isempty(temp)
    %'eeeeeeeeeeeeeeee',funstr{i},kb
    for j=temp(:)'
     temp1=lastNonSpace(funstr{i},funstrwords_b{i}(j));
     if temp1~=0 && funstr{i}(temp1)=='='
      [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
      if (howmany>0 & howmany==length(funargs)) || ...
                 (~isempty(find(~cellfun('isempty',regexp(funstr,'\<exist\>'))))&&howmany>0)
       funstr{i}=[funstr{i}(1:funstrwords_b{i}(j)-1),this_fun_name,funstr{i}(parens(1):end)];
       %funstr{i}=regexprep(funstr{i},[this_fun_name,temp8,'\s*\('],[this_fun_name,'(']);
      end
     end
    end
   end
  end
  % now fix the function def
  %'dddddddddd',funstr{i},kb
  funstr{1}=regexprep(funstr{1},[this_fun_name,temp8,'\s*\('],[this_fun_name,'(']);
  %funstr{1}=strrep(funstr{1},[this_fun_name,temp8,'('],[this_fun_name,'(']);
 end % if ~any(strcmp(funstrwords{1},
end % if suborfun==2

%'fffffffff123',funstr.',keyboard




% put in equivalence reassignments
if ~ismod
 temp5=s;
 temp=regexp(funstr,'\<end\>');
 temp=find(~cellfun('isempty',temp));
 temp1=regexp(funstr,'\<return\>');
 temp1=find(~cellfun('isempty',temp1));
 if ~isempty(temp)
  for i=length(temp):-1:1
   if ~isempty(funstrwords{temp(i)})
    temp3=find(strcmp(funstrwords{temp(i)},'end'));    temp3=temp3(1);
    if validSpot(funstr{temp(i)},funstrwords_b{temp(i)}(temp3))
     temp5=temp(i);
     break
    end % if validSpot(funstr{i},
   end % if ~isempty(funstrwords{i})
  end % for i=length(temp):-1:1
 end
 temp1(temp1>temp5)=[];
 if ~isempty(temp1)
  goon=1;
  for i=temp5-1:-1:temp1(end)+1
   if ~isempty(funstrwords{i})
    goon=0;
   end % if ~isempty(funstrwords{i})
  end  
  if goon, temp5=temp1(end); end
 end
 %'deeeeeeeffffffffff11',funstr.',kb
 tempstr={};
 % put in equivalence reassignments
 for j=1:length(equiv)
  if ~isempty(equiv{j})
   temp1='';
   for i=2:length(equiv{j})
    temp1=[temp1,equiv{j}{i},'=',equiv{j}{1},';'];
   end % for i=1:length(equiv)-1
   tempstr{length(tempstr)+1}=temp1;
  end % if ~isempty(equiv)
 end
 if ~isempty(tempstr)
  temp6=length(tempstr);
  funstr(temp5+temp6:end+temp6)=funstr(temp5:end);
  funstr(temp5:temp5+temp6-1)=tempstr;
  fs_good=sort(unique([fs_good,temp5:temp5+temp6-1]));
  s=s+temp6; 
  % now we also have to put this in front of every return
  %'gfgfgfgfgfgfgfgfg',kb
  temp7=find(~cellfun('isempty',regexp(funstr,'\<return\>')));
   if ~isempty(temp7)
   for i=length(temp7):-1:1
    if temp7(i)<temp5
     temp8=strfind(funstr{temp7(i)},'return');
     if ~inastring_f(funstr{temp7(i)},temp8(1)) && ~inaDQstring_f(funstr{temp7(i)},temp8(1)) && ...
          ~incomment(funstr{temp7(i)},temp8(1)) && length(funstrwords{temp7(i)})==1
      funstr(temp7(i)+temp6:end+temp6)=funstr(temp7(i):end);
      funstr(temp7(i):temp7(i)+temp6-1)=tempstr;
      %'fgfgfgfgfgf',funstr,kb
     end % if ~inastring_f(funstr{temp7(i)},
    end % if temp7(i)<temp5)
   end % for i=1:length(temp7)
  end % if ~isempty(temp)  
 end % if ~isempty(tempstr) 
end % if subfun && ~ismod && suborfun(whichsub)

%remove some lines
temp1=find((cellfun('isempty',regexp(funstr,['\<',noKeep,'\>']))));
funstr=funstr(temp1);
[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);


%'uyttttttt',showall(funstr),kb

% put the resizing of assumed sized arrays before all return statements and at the end.
% also add the caller assignments for functions
% assign fortran function variables in the caller's workspace
if subfun && ~ismod
 temp5=s;
 temp=regexp(funstr,'\<end\>');
 temp=find(~cellfun('isempty',temp));
%%% if ~isempty(sublist_all{whichsub,5}) %has a "contains"
%%%  temp5=sublist_all{whichsub,5};
%%% end % if ~isempty(sublist_all{whichsub,
 temp1=regexp(funstr,'\<return\>');
 temp1=find(~cellfun('isempty',temp1));
 if ~isempty(temp)
  for i=length(temp):-1:1
   if ~isempty(funstrwords{temp(i)})
    temp3=find(strcmp(funstrwords{temp(i)},'end'));    temp3=temp3(1);
    if validSpot(funstr{temp(i)},funstrwords_b{temp(i)}(temp3))
     temp5=temp(i);
     break
    end % if validSpot(funstr{i},
   end % if ~isempty(funstrwords{i})
  end % for i=length(temp):-1:1
 end
 temp1(temp1>temp5)=[];
 if ~isempty(temp1)
  goon=1;
  for i=temp5-1:-1:temp1(end)+1
   if ~isempty(funstrwords{i})
    goon=0;
   end % if ~isempty(funstrwords{i})
  end  
  if goon, temp5=temp1(end); end
 end
 tempstr={};
 if want_smm && ~isempty(needRS)
  for i=1:length(needRS)
   temp7='zeros';
   temp8=find(strcmpi(needRS{i},localVar(:,1)));
   if ~isempty(temp8) && strcmp(localVar{temp8,3},'character') && ~isempty(localVar{temp8,5})
    temp7='cell';
   end
   if any(strcmp(needRS{i},{funwords{:},fortranVarOrRes{:},funwordsML{:}}))
    temp4=MLapp;
   else
    temp4='';
   end
   %'derrrrrrrrrr',kb
   temp11=cell(1,4);   temp11{1}='';   temp11{2}='';    temp11{3}='';    temp11{4}='';
   if ~isempty(localVar{temp8,14}) %this is an optional argument
    temp11{1}=[' if exist(''',localVar{temp8,1},''',''var'');'];
    temp11{2}=' end;';
   end
   if ~isempty(localVar{temp8,11}) %this is allocatable or a pointer, so can be nulled
    temp11{3}=[' if (~isempty(',needRS{i},temp4,')); '];
    %temp11{3}=[' if (~isempty(',needRS{i},temp4,')&&prod(',needRS{i},shapeVar,')); '];
    temp11{4}=' end;';
   end
   temp12=cell(1,2);   temp12{1}='';   temp12{2}='';
   if want_point
    %'nnnnnnnnnn',needRS,i,kb
    temp12{1}=['if ~isa(',needRS{i},',''mlPointer'');'];
    temp12{2}=['end; '];
   end % if want_point
   
   %'whyyyyyyyyy',needRS,i,this_fun_name,localVar{temp8,:},kb
   
   if want_ALLpoint==0
    if any(strcmp(strtrim(localVar{temp8,5}),'*'))||any(strcmp(strtrim(localVar{temp8,5}),':'))
     tempstr{length(tempstr)+1}=[temp12{1},temp11{1},temp11{3},needRS{i},shapeVar,'=',temp7,'(',needRS{i},shapeVar,');',needRS{i},shapeVar,'(:)=',needRS{i},temp4,'(1:numel(',needRS{i},shapeVar,'));',needRS{i},temp4,'=',needRS{i},shapeVar,';',temp11{4},temp11{2},temp12{2}];
    elseif length(localVar{temp8,5})>1 && want_arr
     tempstr{length(tempstr)+1}=[temp12{1},temp11{1},temp11{3},needRS{i},origVar,'(1:min(prod(',needRS{i},shapeVar,'),numel(',needRS{i},origVar,')))=',needRS{i},'(1:min(prod(',needRS{i},shapeVar,'),numel(',needRS{i},origVar,')));',needRS{i},'=',needRS{i},origVar,';',temp11{4},temp11{2},temp12{2}];
%%%    tempstr{length(tempstr)+1}=[temp11{1},temp11{3},needRS{i},origVar,'(1:prod(',needRS{i},shapeVar,'))=',needRS{i},';',needRS{i},'=',needRS{i},origVar,';',temp11{4},temp11{2}];
   end
   end % if want_ALLpoint==0
%%%   tempstr{length(tempstr)+1}=[temp11{1},temp11{3},needRS{i},shapeVar,'=',temp7,'(',needRS{i},shapeVar,');',...
%%%                       needRS{i},shapeVar,'(1:numel(',needRS{i},temp4,'))=',...
%%%                       needRS{i},temp4,';',needRS{i},temp4,'=',needRS{i},shapeVar,';',temp11{4},temp11{2}];
  end % for i=1:length(needRS)
 end
 %tempstr={r,'%%%%% fortran allows functions to modify input arguments in the','%%%%% caller''s workspace, so we need to let matlab do so as well'};
 %'funnnnnnn',funstr',kb
 if suborfun(whichsub)==2 && want_fun
  temp13=0;
  for i=size(localVar,1):-1:1
   if ~isempty(localVar{i,13}) && localVar{i,13}>0 && ...
        ( isempty(localVar{i,10}) || (~isempty(localVar{i,10}) && localVar{i,10}>1))
    
    if any(strcmp(localVar{i,1},{funwords{:},fortranVarOrRes{:},funwordsML{:}}))
     temp4=MLapp;
    else
     temp4='';
    end
    temp6=''; if ~isempty(localVar{i,14}), temp6=['nargin>=',num2str(localVar{i,13}),'&&']; end
    % csil => call stack not inline function, means we are not called from an inline
    if temp13==0
     tempstr{length(tempstr)+1}=['csnil=dbstack(1); csnil=csnil(1).name(1)~=''@'';'];temp13=1;
    end
    tempstr{length(tempstr)+1}=['if csnil&&',temp6,'~isempty(inputname(',num2str(localVar{i,13}),')),',...
                        ' assignin(''caller'',''FUntemp'',', localVar{i,1},temp4,'); ',...
                        'evalin(''caller'',[inputname(',num2str(localVar{i,13}),...
                        '),''=FUntemp;'']); end'];
%%%    tempstr{length(tempstr)+1}=['if ~isempty(inputname(',num2str(localVar{i,13}),')),',...
%%%                        ' assignin(''caller'',''FUntemp'',', localVar{i,1},temp4,'); ',...
%%%                        'evalin(''caller'',[inputname(',num2str(localVar{i,13}),...
%%%                        '),''=FUntemp;'']); end'];
%%%   tempstr{length(tempstr)+1}=['if ~isempty(inputname(',num2str(localVar{i,13}),')) && ',...
%%%                       '~any(inputname(',num2str(localVar{i,13}),')==''.'')',',',...
%%%                       ' assignin(''caller'',inputname(',num2str(localVar{i,13}),...
%%%                       '),', localVar{i,1},'); end'];
   end % if localVar{i,
  end % for i=1:size(localVar,
 end % if suborfun(whichsub)==2
 %tempstr{length(tempstr)+1}='';
 goonimag=0;
 if ~isempty(tempstr)
  temp6=length(tempstr);
  funstr(temp5+temp6:end+temp6)=funstr(temp5:end);
  funstr(temp5:temp5+temp6-1)=tempstr;
  fs_good=sort(unique([fs_good,temp5:temp5+temp6-1]));
  s=s+temp6; 
  % now we also have to put this in front of every return
  %'gfgfgfgfgfgfgfgfg',kb
  temp7=find(~cellfun('isempty',regexp(funstr,'\<return\>')));
   if ~isempty(temp7)
   for i=length(temp7):-1:1
    if temp7(i)<temp5
     temp8=strfind(funstr{temp7(i)},'return');
     if ~inastring_f(funstr{temp7(i)},temp8(1)) && ~inaDQstring_f(funstr{temp7(i)},temp8(1)) && ...
          ~incomment(funstr{temp7(i)},temp8(1)) && length(funstrwords{temp7(i)})==1
      funstr(temp7(i)+temp6:end+temp6)=funstr(temp7(i):end);
      funstr(temp7(i):temp7(i)+temp6-1)=tempstr;
      %'fgfgfgfgfgf',funstr,kb
     end % if ~inastring_f(funstr{temp7(i)},
    end % if temp7(i)<temp5)
   end % for i=1:length(temp7)
  end % if ~isempty(temp)  
  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);
 end % if ~isempty(tempstr) 
end % if subfun && ~ismod && suborfun(whichsub)

%%%if strcmp(this_fun_name,'tselec')
%%% 'ttttttttttrrrrrrrrrreeeeeeeee',temp1,funstr,kb
%%%end


%fix the entry situation for this subroutine
% first we need to know where to break up the function

if ~isempty(entrys)
 temp1=[];
 for ii=1:length(entrys)
  temp1=[temp1,find(~cellfun('isempty',(regexp(funstr,['^\s*entry\s+',entrys{ii}]))))];
 end % for ii=1:length(entrys)
 ;%now add the line before the last end 
 temp2=find(~cellfun('isempty',(regexp(funstr,['^\s*end\s+']))),1,'last');
 if isempty(temp2), error('no final end (for the entrys)?'); end
 % finding the first executable line might be harder
 %  let's try first nonempty line after var decs (varPrefix)
 temp3=find(~cellfun('isempty',(regexp(funstr,['^\s*\$_#_\$_#_\s+']))),1,'last');
 temp1=[temp3+1,temp1,temp2-1];
 temp5={};
 %now start the changeover
 temp4=findNext(0,'=',funstr{fundecline});
 temp4=find(funstrwords_b{fundecline}>temp4,1,'first');

 [howmany,temp5{1},centercomma,parens]=hassubscript_f(fundecline,temp4,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
 for ii=(1:length(entrys))+1
  [howmany,temp5{length(temp5)+1},centercomma,parens]=hassubscript_f(temp1(ii),2,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
 end % for ii=1:length(entrys)
 

 temp7=['function ['];
 for ii=1:max(cellfun('length',temp5))
  temp7=[temp7,'outEntry',num2str(ii)];
  if ii==max(cellfun('length',temp5))
   temp7=[temp7,']='];
  else
   temp7=[temp7,','];
  end
 end % for ii=1:max(cellfun('length',
 
 
 temp7=[temp7,funstr{fundecline}(funstrwords_b{fundecline}(temp4):funstrwords_e{fundecline}(temp4)),'(whichEntry,'];
 for ii=1:max(cellfun('length',temp5))
  temp7=[temp7,'inEntry',num2str(ii)];
  if ii==max(cellfun('length',temp5))
   temp7=[temp7,');'];
  else
   temp7=[temp7,','];
  end
 end % for ii=1:max(cellfun('length',
 funstr{fundecline}=temp7;
 %change the function declaration
 [s,fs_good,fs_goodHasAnyQuote]=updatefunstr_1line_f(funstr,fs_good,fundecline,fs_goodHasAnyQuote);
 %now comment out the entry calls
 for ii=2:length(temp1)-1
  funstr{temp1(ii)}=['% ',funstr{temp1(ii)}];
 end % for ii=2:length(temp1-1)
 
 %add if logic and variable assignments
 temp11={};
 for ii=1:length(temp1)
  if ii==1
   temp11{ii}={'if whichEntry==1'};
  elseif ii==length(temp1)
   temp11{ii}={'end %entry choice'};
  else
   temp11{ii}={['elseif whichEntry==',num2str(ii)]};
  end
  
 end % for ii=1:length(temp1)
  
 for jj=1:length(temp5)
  for ii=1:length(temp5{jj})
   temp11{jj}{length(temp11{jj})+1}=[temp5{jj}{ii},'=','inEntry',num2str(ii),';'];
  end % for ii=1:length(temp5{1})
 end % for jj=1:length(temp5)

 for jj=1:length(temp5)
  for ii=1:length(temp5{jj})
   temp11{jj+1}={['outEntry',num2str(ii),'=',temp5{jj}{ii},';'],temp11{jj+1}{:}};
  end % for ii=1:length(temp5{1})
 end % for jj=1:length(temp5)


%%% for ii=1:length(temp11)
%%%  temp11{ii}
%%% end
%%% for ii=1:length(temp5)
%%%  temp5{ii}
%%% end % for ii=1:length(temp5)

 %comment out "return"s just before the entry if's
 for ii=2:length(temp1)
  for jj=temp1(ii)-1:-1:temp1(ii-1)+1
   if ~isempty(funstr{jj})
    if ~isempty(regexp(funstr{jj},['^\s*return\W+']))
     funstr{jj}=[funstr{jj}(1:funstrwords_b{jj}(1)-1),...
                 '%',funstr{jj}(funstrwords_b{jj}(1):end)];
    end % if ~isempty(regexp(funstr{jj},
   end % if ~isempty(funstr{jj})
  end % for jj=temp1(ii)-1:temp1(ii-1)+1
 end % for ii=2:length(temp1)
  
 %'iiiiiiiiiiiiii22aa',funstr',temp7,kb 
 
 %put them in
 temp1(2:end-1)=temp1(2:end-1)-1;
 for ii=length(temp11):-1:1
  temp9=length(temp11{ii});
  funstr(temp1(ii)+temp9+1:(end+temp9))=funstr(temp1(ii)+1:end);
  funstr(temp1(ii)+1:temp1(ii)+temp9)=temp11{ii}(:);
 end % for ii=1:length(temp11)
 
 
 %'iiiiiiiiiiiiii22',funstr',temp7,kb 


 % entry TODO: 
 %   - if there is an early "return" this does not assign output vars!
 %   - input var order (can change in entry's I think, this does not account for that
 
end % if ~isempty(entrys)

%%%%fix multistatement matlab lines
%%%temp2=find(~cellfun('isempty',(regexp(funstr,[';.+;']))));
%%%for i=temp2
%%% if isempty(regexp(funstr{i},'\<global\>')) && isempty(regexp(funstr{i},'\<if\>'))
%%%  temp3=findstr(funstr{i},';');
%%%  for j=length(temp3)-1:-1:1
%%%   if validSpot(funstr{i},temp3(j)) && inwhichlast_f(i,temp3(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
%%%    funstr{i}=[funstr{i}(1:temp3(j)),r,funstr{i}(temp3(j)+1:end)];
%%%    %'iiiiiiiii',funstr{i},kb
%%%   end % if validSpot(funstr{i},
%%%  end % for j=length(temp3):-1:1
%%% end % if isempty(regexp(funstr{i},
%%%end % for i=temp2






























funstr=regexprep(funstr,['^(\s*)break'],['$1 tempBreak=1;break']);
[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr);

%'eeeeeeeeeee',funstr.',kb

%Now put in required variable initializations
%%%temp2=fs_good(min(2,length(fs_good)));temp1=0;fid=1;
%%%temp3=regexp(funstr,'\<(function)'); %This ignores whitespace at the beginning of the line
%%%temp3=find(~cellfun('isempty',temp3));
%%%for i=temp3(:).'
%%% if any(i==fs_good)
%%%  if length(intersect({'function',fun_name{:}},funstrwords{i}))==2
%%%   temp=intersect(fun_name,funstrwords{i});
%%%   temp1=find(strcmpi(temp,fun_name));
%%%  end
%%% end
%%%end
insertExtra=0;
if length(fs_good)>0
 insertExtra=fs_good(min(2,length(fs_good)));
end
fid=0;
if ~isempty(fundecline)
 fid=whichsub;
 %fid=find(strcmpi(this_fun_name,fun_name));
end


%Construct filestr adding in initializations including persistent var declarations
filestr='';
temp3={'','','','','',''}; 
% 1 - initialize result
% 2 - persistent vars
% 3 - initialize vars first called in subroutine calls (adds needDataStr and formats to end)
% 4 - clear globals and such
% 5 - format declarations
temp4=''; 
%add in needDataStr if needData is set
if needData
 persistentVars={persistentVars{:},needDataStr};
end
if oneBYone
 blockDataList={};
 if strcmp(files(whichsub).type,'program')
  temp1=find(strcmp({files.type},'blockdata'));
  blockDataList={files(temp1).name};
 end % if strcmp(files(temp2).
end % if oneBYone


%fid=temp1;
for i=1:s
 if exist('inout','var') && ~ismod
  %put in the persistence vars at the beginning
  if i==insertExtra
   %'aaaaaaaaaaaaaaa',filestr,kb
   if suborfun(whichsub)==2     %initialize function result if need be
    if isempty(resultVar)
     temp3{1}=[this_fun_name,'result=[];'];
    else
     temp3{1}=[resultVar,'=[];'];
    end
   end
   if ~isempty(persistentVars)
    persistentVars=setdiff(persistentVars,resultVar);
    temp3{2}=['persistent ']; temp4='; ';
    for ii=1:length(persistentVars)
     temp3{2}=[temp3{2},persistentVars{ii},' '];
     temp8=find(strcmpi(persistentVars{ii},localVar(:,1)));
     if ~isempty(temp8) && strcmp(localVar{temp8,3},'character') && ~isempty(localVar{temp8,5})
      temp4=[temp4,'if isempty(',persistentVars{ii},'),',persistentVars{ii},'={};end; '];
      %'pvvvvvvvvvv',localVar,persistentVars,temp4,kb
     end
    end % for ii=1:length(persistentVars)
    if needData
     temp4=[temp4,'if isempty(',needDataStr,'),',needDataStr,'=1;end; '];
    end
   end
   temp3{2}=[temp3{2},temp4];
%%%   %let's piggyback the optional arg clearing on the back of the persistent decs
%%%   if any(~cellfun('isempty',{origLocalVar{:,14}}))
%%%    temp3{2}=[temp3{2},r];
%%%   end
%%%   for j=size(origLocalVar,1):-1:2
%%%    if ~isempty(origLocalVar{j,14})
%%%     temp3{2}=[temp3{2},'if exist(''',origLocalVar{j,1},''',''var'') && isempty(',origLocalVar{j,1},'), clear ',origLocalVar{j,1},', end;',r];
%%%    end
%%%   end
  end
  if i==insertExtra & ~isempty(inout) & fid~=0
   for j=1:length(inout{fid})
    % if this has been initialized in a module, then don't
    temp7={};
    temp7=varInUsedMods(inout{fid}{j},modLocalVar,usedMods);
%%%    if strcmp(inout{fid}{j},'dim_xc')
%%%     'reeeeeeee3333333',funstr,keyboard
%%%    end
    if isempty(temp7)
     temp3{3}=[temp3{3},inout{fid}{j},'=[];'];
    end
   end % for j=1:length(inout{fid})
  end % if i==insertExtra & ~isempty(inout) & fid~=0
 end % if exist('inout',
end % for i=1:s

%%%if strcmp(this_fun_name,'check2')
%%% 'tttttt',kb
%%%end
for i=1:s
 if i==insertExtra
  %whichsub,suborfun,subfun,ismod,sublist,sublist_all,'gggggggggggggggg',kb
  if ~subfun && ~ismod 
   %if strcmpi(sublist_all{whichsub,4},'program') %want_clg
   if strcmpi(sublist{whichsub,4},'program') %want_clg
    temp3{4}=['clear all; %clear functions;',r];
   end
   if ~isempty(blockDataList)
    temp3{4}=[temp3{4},r,'%%% blockdata initializations',r];
    for ii=1:length(blockDataList)
     temp3{4}=[temp3{4},blockDataList{ii},r];
    end % for ii=1:length(blockDataList)
   end % if ~isempty(blockDataList)
   if want_cla
    temp3{4}=[temp3{4},'global GlobInArgs nargs',r,...
              'GlobInArgs={mfilename,varargin{:}}; nargs=nargin+1;'];
   end
   if want_gl
    for j=1:size(modLocalVar,1)
     temp3{4}=[temp3{4},r,modLocalVar{j,1}];
    end
   end
   filestr=[filestr,temp3{4},r];
  elseif want_cla
   if any(~cellfun('isempty',regexpi(funstr,'(\<nargs\>)|(\<getarg\>)')))
    temp3{4}=['global GlobInArgs nargs'];  
    filestr=[filestr,temp3{4},r];
   end % if ~isempty(regexpi(filestr,
  end % if ~subfun && ~ismod && want_cla
  if want_gl && subfun
   %add in global statement
   if ~isempty(globVar)
    temp4='global';
    globVar=sort(globVar);
    for j=1:length(globVar)
     temp4=[temp4,' ',globVar{j}];
    end
    temp4=[temp4,r];
    filestr=[filestr,temp4];
    %'dddddddddddd',globVar,filestr,kb
   end % if ~isempty(globVar)
  end
  %add in unit2fid if a file was opened in this segment
  temp10='';  if ~subfun, temp10=';  if ~isempty(unit2fid), unit2fid=[]; end'; end
  if needThings(1)
   filestr=[filestr,'global unit2fid',temp10,r];
  end
 end
 if exist('inout','var') && ~ismod
  %put in the persistence vars at the beginning
  if i==insertExtra
   if suborfun(whichsub)==2     %initialize function result if need be
    filestr=[filestr,temp3{1},r];
   end
   if ~isempty(persistentVars)
    if funProps(1) %then this is recursive
     filestr=[filestr,'[currentFun]=dbstack; isRecursive=nnz(strcmp({currentFun.name},currentFun(1).name))>1;',r,...
             'if ~isRecursive',r];
    end
    filestr=[filestr,temp3{2},r];
    if funProps(1) %then this is recursive
     filestr=[filestr,'end',r];
    end
   end
   % add format statements in
   [temp8,temp9]=sort(formats(:,1));
   formats=formats(temp9,:);
   if size(formats,1)>0
    for ii=1:size(formats,1)
     temp3{5}=[temp3{5},'format_',num2str(formats{ii,1}),'=[',formats{ii,7},'];',r];
    end % for ii=1:size(formats,
    filestr=[filestr,r,temp3{5}];
   end % if size(formats,
  end
  if i==insertExtra & ~isempty(inout) & fid~=0
   filestr=[filestr,temp3{3},r];
   filestr=[filestr,funstr{i},r];
  else
   filestr=[filestr,funstr{i},r];
  end
 else
  filestr=[filestr,funstr{i},r];
 end
end

%'aaaaaaaaaaaaaaa',filestr,kb

if want_lc
 if ~isempty(changeCase)
  %protectSomeStrings
  if want_MP
   for i=1:length(tempcc)
    filestr=regexprep(filestr,...
                      ['\<',changeCase{i},'(\>|',MPstr{1},'\>|',MPstr{2},'\>)'],...
                      [changeCase{i},'$1'],'ignorecase');
   end
  else
   filestr=regexprep(filestr,tempcc,changeCase,'ignorecase');
  end
 end % if ~isempty(changeCase)
end


%'pppppppppp',persistentVars,filestr,insertExtra,keyboard

if numErrors>0
 disp(['*** There were ',num2str(numErrors),' problems f2matlab encountered during conversion.'])
else
 disp(['    f2matlab finished ',this_fun_name,' normally'])
end

%Write converted file out
filestr=filestr(filestr~=char(9)); %Remove tabs from the file
;%also get rid of some things plusfort may have put there
filestr=strrep(filestr,['use f77kinds;',r],'');
filestr=strrep(filestr,['%*** Start of declarations rewritten by SPAG',r],'');
filestr=strrep(filestr,['%',r,...
                    '% COMMON variables',r,...
                    '%',r],'');
filestr=strrep(filestr,['%',r,...
                    '% Dummy arguments',r,...
                    '%',r],'');
filestr=strrep(filestr,['%',r,...
                    '% Local variables',r,...
                    '%',r],'');
filestr=strrep(filestr,['%',r,...
                    '%*** End of declarations rewritten by SPAG',r,...
                    '%',r],'');
filestr=strrep(filestr,',)',')');
if want_fi
%%% filestr=strrep(filestr,'fix(0)','0');
%%% filestr=strrep(filestr,'fix( 0)','0');
%%% filestr=strrep(filestr,'fix(0.0)','0');
%%% filestr=strrep(filestr,'fix( 0.0)','0');
%%% filestr=strrep(filestr,'fix(1)','1');
%%% filestr=strrep(filestr,'fix( 1)','1');
%%% filestr=strrep(filestr,'fix(1.0)','1');
%%% filestr=strrep(filestr,'fix( 1.0)','1');
 filestr=strrep(filestr,'fix(zeros(','(zeros(');
end
filestr=strrep(filestr,')(',',');
filestr=strrep(filestr,'$$$$$_$$$$$','.''');
filestr=strrep(filestr,'#####_#####','*');
filestr=strrep(filestr,varPrefix,'');
filestr=strrep(filestr,[';',r,';',r,'end;',r],['; end',r]);
filestr=strrep(filestr,[TFops{1,2},TFops{1,3}],TFops{1,2});
filestr=strrep(filestr,[TFops{2,2},TFops{2,3}],TFops{2,2});
filestr=regexprep(filestr,['\<type',MLapp,'\>'],'type','ignorecase');

filestr=strrep(filestr,DQ{1},'''''');
%filestr,kb
filestr=strrep(filestr,DQ{2},'"');
filestr=strrep(filestr,DQ{3},'''');
filestr=strrep(filestr,DQ{4},'');
%filestr=strrep(filestr,'([1:end])','');
filestr=strrep(filestr,'[1:end]',':');
filestr=strrep(filestr,brack2paren{1},'(');
filestr=strrep(filestr,brack2paren{2},')');
filestr=strrep(filestr,['size',protVar],'size');
filestr=strrep(filestr,'%!REMG!!','');
%fix hex constants
filestr=regexprep(filestr,['z[''"]([0-9abcdef]+)[''"]'],['hex2dec(''$1'')'],'ignorecase');

%Get rid of subprogram spag declarations
rets=findstr(r,filestr);
temp=regexp(filestr,'%\*--');
if ~isempty(temp)
 temp1=find(rets<temp(1)); temp1=temp1(end);
 temp2=find(rets>temp(1)); temp2=temp2(1);
 filestr=filestr([1:rets(temp1),rets(temp2)+1:end]);
end
% take care of duplicate module variable names in this function
%%%if strcmpi(this_fun_name,'test1')
%%% 'opopop222222222222222',funstr,kb
%%%end

if ~ismod
 for ii=1:length(usedMods)
  if ~isempty(modLocalVar{usedMods(ii),3})
   for jj=1:length(modLocalVar{usedMods(ii),3})
    %'smuuuuuuuuu',kb
    % replace the variables in this file
    filestr=regexprep(filestr,['\<',modLocalVar{usedMods(ii),3}{jj},'\>'],...
                      [modLocalVar{usedMods(ii),3}{jj},'_',modLocalVar{usedMods(ii),1}]);
    % and replace them in the module file
    fid=fopen([modLocalVar{usedMods(ii),1},'.m']); tempstr=fscanf(fid,'%c'); fclose(fid);
    tempstr=regexprep(tempstr,['\<',modLocalVar{usedMods(ii),3}{jj},'\>'],...
                      [modLocalVar{usedMods(ii),3}{jj},'_',modLocalVar{usedMods(ii),1}]);
    fid=fopen([modLocalVar{usedMods(ii),1},'.m'],'w'); fprintf(fid,'%c',tempstr); fclose(fid);
   end % for jj=1:length(modLocalVar{usedMods(ii),
  end % if ~isempty(modUsedMods{usedMods(ii),
 end % for ii=1:length(usedMods)
end % if ~ismod


% some small housekeeping tasks
filestr=strrep(filestr,';;',';');
filestr=strrep(filestr,';,',';');
%%%if want_lc
%%% temp=changeCase;
%%% for i=1:length(changeCase)
%%%  temp{i}=['\<',changeCase{i},'\>'];
%%% end
%%% %'hmmmmmmmmmmmm',changeCase,kb
%%% tic;filestr=regexprep(filestr,temp,changeCase,'ignorecase');'gggggggggggggggggggggggg',toc
%%%end

%%%if strcmpi(this_fun_name,'universal_const_1_0')
%%% 'fiiiiiiiiiiiiii',filestr,kb
%%%end

%%%% let's implement some last minute changes
if want_lmc
 if exist([filename_base,'_lmc'])==2, eval([filename_base,'_lmc']); end
end




% indent the file
if wantIndent==1 && system('which emacs >& /dev/null')~=0,  wantIndent=0; end
if wantIndent && ~informationRun
 temp7='f2matlab_tempfilename001001.m';
 %fprintf(1,'   Indenting file with emacs:  '); fprintf(1,filename_ml); fprintf(1,[' ... ',r])
 fid=fopen(temp7,'w');  fprintf(fid,'%c',filestr);   fclose(fid);
 
 imlPath=fileparts(which('f2matlab'));
%%% if isempty(imlPath)
%%%  imlPath=ffpath('indentML');
%%% end
 %execStr=['emacs --batch ',temp7,' -l ',temp1,filesep,'indentML >& '];
 execStr=['emacs --batch ',temp7,' -l ',imlPath,filesep,'indentML >& f2matlab_logfile '];
 %disp(execStr)
 stat=system(strtrim(execStr));
 fid=fopen(temp7); filestr=fscanf(fid,'%c'); fclose(fid);
 if stat~=0
  warning('indenting problem! see f2matlab_logfile (here it is)');
  system('cat f2matlab_logfile')
 end
 delete(temp7)
 delete([temp7,'~'])
end % if wantIndent 


%add an extra end if this is the last contain'ed function
if ~ismod
 if sublist_all{whichsub,6}>0
  goon=0;
  if whichsub==size(sublist_all,1) %last segment, so add
   goon=1;
  else
   if isempty(sublist_all{whichsub+1,6})
    goon=1;
   else
    if sublist_all{whichsub+1,6}<sublist_all{whichsub,6}
     goon=1;
    end % if isempty(sublist_all{whichsub+1,
   end % if whichsub==size(sublist_all,
  end % if whichsub==size(sublist_all,
  if goon==1
   temp1=find(strcmpi(sublist_all{whichsub,7},sublist_all(:,1)));
   if isempty(temp1)
    error
   else
    filestr=[filestr,r,'end %',sublist_all{temp1,4},' ',sublist_all{temp1,1},r,r];
   end % if isempty(temp1)
  end % if goon==1
 end % if whichsub==size(sublist_all,
end % if ~ismod




%%%if oneBYone% & strcmpi(this_fun_name,'sfnck')
%%% 'opopop',funstr,kb
%%%end
if ~subfun | oneBYone
 if ~oneBYone
  allLocalVar{1}=localVar;  allExtWords{1}=extwords; allEntrys{1}=entrys;
 end
 %attach subroutines and the final trailing end
 filestr=[filestr,filestr_subfun,r];
 %add extraFunctions as needed
 if ~isempty(extraFunctions)
  temp=getExtraFunctions(extraFunctions);
  %temp,keyboard
  if want_exf==1 && isempty(files)
   filestr=[filestr,r,r,r,...
            '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',r,...
            '%%%%%%%%%%% extra functions as needed by the translation %%%%%%%%%%%',r,r];
  end
  filestr=[filestr,temp];
 end % if ~isempty(extraFunctions) 
 disp(['  time before post processing: ',datestr(now-tt1,13),' (HH:MM:SS)'])
 disp(['*************** f2matlab first pass finished **************'])
 %'yyyyyyyyyyy'
 %filestr,kb
 if ~ismod
  % back into funstr for a minute for some cleanup
  rets=findstr(r,filestr);
  rets=[0 rets];
  funstr=textscan(filestr,'%s','delimiter',r,'whitespace','');
  funstr=funstr{1};
  %funstr=strread(filestr,'%s','delimiter',r);


  %'dewwwwwwwwww',funstr,kb
  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr); 
  [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f([],sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,'%',fs_goodHasAnyQuote);
  sublist_all=sublist;
  fun_name=sublist(:,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fixScalarCalls
  takeCareOfIncludeFiles2
  fixEntryCalls
  %'wwwwwwwwwwweerrrrrr',funstr,kb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%fix multistatement matlab lines
%%%  temp2=find(~cellfun('isempty',(regexp(funstr,[';.+;']))));
%%%  for i=temp2(:)'
%%%   if isempty(regexp(funstr{i},'\<global\>')) && isempty(regexp(funstr{i},'\<if\>'))
%%%    temp3=findstr(funstr{i},';');
%%%    temp4=char(regexp(funstr{i},'^[ ]*','match'));
%%%    for j=length(temp3)-1:-1:1
%%%     if validSpot(funstr{i},temp3(j)) && inwhichlast_f(i,temp3(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,filename)==0
%%%      temp8=nextNonSpace(funstr{i},temp3(j));
%%%      funstr{i}=[funstr{i}(1:temp3(j)),r,temp4,funstr{i}(temp8:end)];
%%%      %'iiiiiiiii',funstr{i},kb
%%%     end % if validSpot(funstr{i},
%%%    end % for j=length(temp3):-1:1
%%%   end % if isempty(regexp(funstr{i},
%%%  end % for i=temp2
  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good,fs_goodHasAnyQuote]=updatefunstr_f(funstr); 
  funstr=regexprep(funstr,['writef(1,\[''.*''\],(.*)\);'],['$1']);
  
  %now assign funstr to filestr
  temp4=cell(s*2,1);
  temp4(1:2:s*2-1)=funstr;
  temp4(2:2:end)={r};
  temp6=10000;
  temp5=[[0:temp6:2*s],2*s];
  filestr='';
  for ii=1:length(temp5)-1
   filestr=[filestr,temp4{temp5(ii)+1:temp5(ii+1)}];
  end 
  if want_exf==1 | want_exf==0
   temp7=filestr;
   addExtraFiles
   if want_exf==1 && ~strcmp(filestr,temp7) && isempty(files)
    filestr=[filestr,r,r,r,...
             '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',r,...
             '%%%%%%%%%%% extra functions as needed by the translation %%%%%%%%%%%',r,r];
   end
  end
 end
 filestr=strrep(filestr,'(''offset'',1)','');
 
 
 fprintf(1,'    Writing file:  ');   fprintf(1,filename_ml);   fprintf(1,[' ... ',r])
 if informationRun
  %'teeeeeee',kb
  %temp1=find(strcmpi(this_fun_name,{files(:).name}));
 else
  fid=fopen(filename_ml,'w');  fprintf(fid,'%c',filestr);   fclose(fid);
 end % if informationRun
elseif ~ismod
 allLocalVar{length(allLocalVar)+1}=localVar;
 allExtWords{length(allExtWords)+1}=extwords;
 allEntrys{length(allEntrys)+1}=entrys;
end

if want_kb
 disp([' ']);
 if ~subfun
  disp(['Finished writing ',filename_ml,':'])
 end
 if length(funstr)<20
  showall_f(funstr,1);
 else
  showall_f(funstr(1:20),1);
  disp(['   . . .'])
 end
end
if ~subfun
 fprintf(1,'completed \n')
end
if ~subfun && ~ismod
 disp(['  Total time: ',(datestr(now-tt1,13)),' (HH:MM:SS)'])
 fprintf(1,'-----------------------------------------------------------\n')
 fprintf(1,'|      f2matlab -- Ben Barrowes, Barrowes Consulting      |\n')
 fprintf(1,'-----------------------------------------------------------\n')
end
if want_kb,'At the end.',keyboard; end
%showall_f(funstr),keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End f2matlab.

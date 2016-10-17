function [out,outLine,j]=varType(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words,nestLevel,targetNestLevel)

% set targetNestLevel to >100 (inf works) to get the varType of the current level
%  otherwise the end type will be returned

if nargin<14
 nestLevel=0;
else
 nestLevel=nestLevel+1;
end
if nargin<15
 targetNestLevel=0; 
end
% If both are zero, just behave like before

out='';outLine={};
if targetNestLevel>100  %then find the target nest level
                        % 100 is the maxmimum level of nestingthat may would probably occur
 targetNestLevel=0;
 whichword=j;
 while 1
  [hasParent,whichword]=findParent(i,whichword,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words);
  if ~hasParent, break, end
  targetNestLevel=targetNestLevel+1;
 end
 j=whichword; nestLevel=0;
end





temp1=find(strcmp(funstrwords{i}{j},localVar(:,1)));
if isempty(temp1)
 global MLapp
 temp1=find(strcmp([funstrwords{i}{j},MLapp],{localVar{:,1}}));
end % if isempty(temp1)

%'ccccccccc',kb
if ~isempty(temp1)
 if any(strcmp(localVar{temp1,3},var_words))
  out=localVar{temp1,3};
  outLine={localVar{temp1,:}};
 else
  [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
  temp5=funstrwords_e{i}(j);
  if howmany>0,   temp5=parens(2);  end
  temp2=nextNonSpace(funstr{i},temp5);
  %'vttttttttt',kb
  if (funstr{i}(temp2)=='.' && funstr{i}(temp2+1)~='*' && funstr{i}(temp2+1)~='/' && funstr{i}(temp2+1)~='^') && ~(nestLevel==targetNestLevel && targetNestLevel~=0)
   temp3=find(nextNonSpace(funstr{i},temp2)==funstrwords_b{i});
   if ~isempty(temp3)
%%%    if strcmp(funstrwords{i}{1},'tv1')
%%%     'tttttttt11',localVar,kb
%%%    end
    temp5=find(strcmp(localVar{temp1,3},{typeDefs{:,1}}));
    if ~isempty(temp5)
     for ii=1:length(temp5)
      temp4=temp5(ii); %sometimes duplicates get put in by different modules
      [out,outLine,j]=varType(i,temp3,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,typeDefs{temp4,2},typeDefs,var_words,nestLevel,targetNestLevel);
      if ~isempty(out)
       break
      end
     end % for ii=1:length(temp5)
    end % if ~isempty(temp4)
   end
  else
   %derived type, but no '.' after, so out should be the type
   out=localVar{temp1,3};
   outLine={localVar{temp1,:}};
  end
 end % if any(strcmp(localVar{temp1,
end % if ~isempty(temp1)


function [hasParent,whichword]=findParent(i,j,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words)

hasParent=0; whichword=j;
foo1=lastNonSpace(funstr{i},funstrwords_b{i}(j));
if foo1>0
 if funstr{i}(foo1)=='.' && ~(foo1>4 && strcmpi(funstr{i}(foo1-3:foo1-1),'not'))
  foo2=lastNonSpace(funstr{i},foo1);
  if funstr{i}(foo2)=='(' || funstr{i}(foo2)==')' || any(funstrwords_e{i}==foo2)
   hasParent=1;
   if any(funstrwords_e{i}==foo2)
    whichword=find(funstrwords_e{i}==foo2);
   else
    if funstr{i}(foo2)==')'
     foo3=findlefts_f(foo2,funstr{i});
     whichword=find(funstrwords_b{i}<foo3,1,'last');
    end % if funstr{i}(foo2)==')'
   end % if any(funstrwords_e{i}==foo2)
  end
 end
end
  
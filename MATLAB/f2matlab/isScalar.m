function [out]=isScalar(locStart,locEnd,i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words,modLocalVar,usedMods)

%try to determine if the expression within funstr{i}{locStart:locEnd} is a scalar or not
 
 out=1;
 
 if any(funstr{i}(locStart:locEnd)==':')
  out=0;
  return
 end
 

 %'oooooooo',kb   
 temp1=find(funstrwords_b{i}>=locStart & funstrwords_e{i}<=locEnd); 
 for ii=temp1
  temp9=find(strcmp(funstrwords{i}{ii},{localVar{:,1}}));
  if ~isempty(temp9)
   if ~isempty(localVar{temp9,5})
    out=0;
    allScalarSubs=0;
    [howmany,subscripts,centercomma,parens]=hassubscript_f(i,ii,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
    if howmany>0
     allScalarSubs=1;
     temp3=[parens(1),centercomma,parens(2)];
     for jj=1:howmany
      allScalarSubs=allScalarSubs&isScalar(temp3(jj),temp3(jj+1),i,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,localVar,typeDefs,var_words,modLocalVar,usedMods);
     end % for jj=1:howmany
    end % if howmany>0

    if allScalarSubs
     out=1;
    else
     return
    end
   end % if ~isempty(localVar{temp9}{5})
  end % if any(strcmp(funstrwords{i}{ii},
 end % for ii=temp1

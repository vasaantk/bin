function [sublist,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good]=findendSub_f(linenum,sublist,s,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,fs_good,funwords,var_words,commentMarker,fs_goodHasAnyQuote)
%if linenum is empty, then find sublist for the entire funstr
% otherwise, return sublist entry that the linenum is in

global modUsedMods

if nargin<14, commentMarker='%'; end


fs_goodLogical=zeros(1,s);
fs_goodLogical(fs_good)=1;

%try
type_words={'program';'function';'subroutine';'module';'blockdata';'end';'contains';'interface';'use'};
type_wordsRE='program|function|subroutine|module|blockdata|end|contains|interface|use';
type_wordsRE='\<program\>|\<function\>|\<subroutine\>|\<module\>|\<blockdata\>|\<end\>|\<contains\>|\<interface\>|\<use\>';
poss=find(~cellfun('isempty',regexp(funstr,type_wordsRE,'ignorecase')))';
if strcmp(commentMarker,'!')
 noAnds=find(cellfun('isempty',regexp(funstr,['^\s*[!&]'])))';
 poss=intersect(poss,noAnds);
end
poss=intersect(poss,fs_good);

%%%if ~isempty(poss)
%%% dispback(['   finding subunits of the file = ',funstr{poss(1)},'                               '])
%%%end


stoppage=0;
goon=1; inInterface=0;
if isempty(linenum)
 sublist=cell(0,11);
 if isempty(modUsedMods),  modUsedMods=cell(0,2); end
 left=0; right=0;

 for i=poss(:)'
%%%  if i>480
%%%   '----------------------------',i,funstr(i-4:i),kb
%%%  end

  for j=1:length(funstrwords{i})
   temp=find(strcmpi(funstrwords{i}{j},type_words));
%%%   if any(strcmpi(funstrwords{i},'contains'))
%%%    's2s2s2s2s2s',funstr{i},temp,j,kb
%%%   end
   if ~isempty(temp)
    if ~fs_goodHasAnyQuote(i) || (validSpot(funstr{i},funstrwords_b{i}(j),commentMarker) & validFSpot(funstr{i},funstrwords_b{i}(j),'!'))
     switch lower(type_words{temp(1)})
       case {'program';'function';'subroutine';'module';'blockdata';'interface'}

%%%         if any(strcmpi(funstrwords{i},'fun1_4'))
%%%          stoppage=1;
%%%          funstr{i},sublist,'gggggggggggg',kb
%%%         end
         
         goon=1; %we do in fact have a subprg beginning
         if j>1
          if strcmpi(funstrwords{i}{j-1},'end')
           goon=0;
          end
         end % if j>1
         if strcmpi(funstrwords{i}{1},'module') && length(funstrwords{i})>1 && ...
              strcmpi(funstrwords{i}{2},'procedure')
          goon=0;
         end % if j>1
%%%       if j<length(funstrwords{i})
%%%        if strcmpi(funstrwords{i}{j+1},'procedure')
%%%         goon=0;
%%%        end
%%%       end
         if ~isempty(regexp(funstr{i},'^\s*\<function\>\s*='))
          goon=0; %may have used "function" as a variable
         end
         if goon && ~inInterface
          left=left+1;
          slLen=size(sublist,1);
          if length(funstrwords{i})>j
           temp6=find(funstr{i}=='=');
           if ~isempty(temp6) && temp6(1)>funstrwords_b{i}(j) %probably a matlab function def
            temp5=find(funstrwords_b{i}>temp6(1),1,'first');
            if ~isempty(temp5)
             sublist{slLen+1,1}=funstrwords{i}{temp5(1)}; %subprg name
            else
             sublist{slLen+1,1}='';
            end
           else
            sublist{slLen+1,1}=funstrwords{i}{j+1}; %subprg name
           end
          else
           sublist{slLen+1,1}='';
          end % if length(funstrwords{i})>temp(1)
              % subscripts 
          if any(strcmpi(funstrwords{i}{j},{'function','subroutine'}))
           [howmany,subscripts,centercomma,parens]=hassubscript_f(i,j+1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
           if howmany>0
            sublist{slLen+1,8}=strtrim(subscripts);
           end
           %'smaaaaaaaa',funstr{i},kb
          end
          ii=i; %Start this after the last line of the last subprg
          for ii=i-1:-1:1
           if length(funstrwords{ii})>0
            temp4=find(funstr{ii}==commentMarker,1,'first');
            if isempty(temp4)
             %i=ii; 
             break
            else
             if any(funstrwords_b{ii}<temp4)
              %i=ii;
              break
             end
            end
           end % if length(funstrwords{ii})>0
           if ii==1,ii=0; break; end
          end
          if isempty(ii),ii=0; end          
          

          %find the end for this subprg
          leftEnd=1;rightEnd=0;
          hasArithmeticIF=[];
          hasAssign=[];
          jj=i+1;
          while ((leftEnd~=rightEnd)&(jj<=s))

%%%           if stoppage
%%%            '----------------------------392',jj,funstr(jj:jj),leftEnd, rightEnd,kb
%%%           end

           if fs_goodLogical(jj) 
            if ~isempty(funstrwords{jj})
             if ~fs_goodHasAnyQuote(jj) || ...
                 (validSpot(funstr{jj},funstrwords_b{jj}(1),commentMarker) & ...
                  validFSpot(funstr{jj},funstrwords_b{jj}(1),commentMarker))
              if any(strcmpi(funstrwords{jj}(1),{'for';'do';'while';'if';'switch';'where';'switch';'select';'function';'subroutine';'module';'type';'interface'})) || ...
                   (length(funstrwords{jj})>1 && ...
                    any(strcmpi(funstrwords{jj}(2),{'function','subroutine'})) && ...
                    ~strcmpi(funstrwords{jj}(1),'end') && ...
                    validFSpot(funstr{jj},funstrwords_b{jj}(2),commentMarker)) || ...
                   (length(funstrwords{jj})>2 && ...
                    any(strcmpi(funstrwords{jj}(3),{'function','subroutine'})) && ...
                    ~strcmpi(funstrwords{jj}(1),'end') && ...
                    validFSpot(funstr{jj},funstrwords_b{jj}(3),commentMarker)) || ...
                   (length(funstrwords{jj})>3 && ...
                    any(strcmpi(funstrwords{jj}(4),{'function','subroutine'})) && ...
                    ~strcmpi(funstrwords{jj}(1),'end') && ...
                    validFSpot(funstr{jj},funstrwords_b{jj}(4),commentMarker)) || ...
                   (length(funstrwords{jj})>4 && ...
                    any(strcmpi(funstrwords{jj}(5),{'function','subroutine'})) && ...
                    ~strcmpi(funstrwords{jj}(1),'end') && ...
                    validFSpot(funstr{jj},funstrwords_b{jj}(5),commentMarker)) || ...
                   (length(funstrwords{jj})>1 && ...
                    any(strcmpi(funstrwords{jj}(2),{'select','do','where'})) && ...
                    length(strtrim(funstr{jj}(funstrwords_e{jj}(1)+1:funstrwords_b{jj}(2)-1)))==1 && ...
                    strtrim(funstr{jj}(funstrwords_e{jj}(1)+1:funstrwords_b{jj}(2)-1))==':')
               
               if ~(strcmpi(funstrwords{jj}{1},'module') && length(funstrwords{jj})>1 && ...
                    strcmpi(funstrwords{jj}{2},'procedure'))
%%%                if jj<1983
%%%                 'left-----------',funstr{jj}
%%%                end
                leftEnd=leftEnd+1;
                if strcmpi(funstrwords{jj}(1),'type')
                 [howmany,subscripts,centercomma,parens]=hassubscript_f(jj,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                 if howmany>0
                  leftEnd=leftEnd-1;
                 end % if ~isempty(find(funstrwords_b{jj}>parens(2)))                
                end % if strcmpi(funstrwords{jj}(1),
                if strcmpi(funstrwords{jj}(1),'where')
                 [howmany,subscripts,centercomma,parens]=hassubscript_f(jj,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                 if ~isempty(find(funstrwords_b{jj}>parens(2)))
                  leftEnd=leftEnd-1;
                 end % if ~isempty(find(funstrwords_b{jj}>parens(2)))                
                end % if strcmpi(funstrwords{jj}(1),
                
%%%           if jj>377
%%%            '----------------------------',jj,funstr(jj-4:jj),leftEnd, rightEnd,kb
%%%           end

                %'1111111 --------------',jj,funstr(jj-4:jj),leftEnd, rightEnd,kb
                if strcmpi(funstrwords{jj}(1),'if') % single line if case in matlab
                 if strcmpi(funstrwords{jj}(end),'end') && ...
                      (validSpot(funstr{jj},funstrwords_b{jj}(end),commentMarker) & ...
                       validFSpot(funstr{jj},funstrwords_b{jj}(end),commentMarker))
                  rightEnd=rightEnd+1;
                  %'22222222',jj,funstr{jj},kb
                 end
                end
                % arithmetic if in fortran
                if strcmpi(funstrwords{jj}(1),'if') && strcmp(commentMarker,'!')
                 [howmany,subscripts,centercomma,parens]=hassubscript_f(jj,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                 if howmany==1
                  if isnumber(funstr{jj}(nextNonSpace(funstr{jj},parens(2))))
                   rightEnd=rightEnd+1;
                   if isempty(hasArithmeticIF), hasArithmeticIF=jj; end
                  end % if isnumber(funstr{jj}(nextNonSpace(funstr{jj},
                 end % if howmany==1
                end % if strcmpi(funstrwords{jj}(1),
                %single line if case in fortran
                if strcmpi(funstrwords{jj}(1),'if') && strcmp(commentMarker,'!')
                 [howmany,subscripts,centercomma,parens]=hassubscript_f(jj,1,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                 if howmany>0 % could be if used as a variable
                  temp1=find(funstrwords_b{jj}>parens(2),1,'first');
                  if ~isempty(temp1)
                   if ~strcmpi(funstrwords{jj}{temp1(1)},'then')
                    rightEnd=rightEnd+1;
                   end % if ~strcmpi(funstrwords{jj}{temp1(1)},
                  end % if ~isempty(temp1)
                 end % if howmany>1
                end % if strcmpi(funstrwords{jj}(1),
               end % if ~(strcmpi(funstrwords{jj}{1},
              end % if any(strcmpi(funstrwords{jj}(1),
              if any(strcmpi(funstrwords{jj}(1),{'end','enddo','endif','endselect','endwhere'}))
%%%               if jj<1983
%%%  'rightend', funstr{jj}
%%%               end
               rightEnd=rightEnd+1;

%%%              if jj>290
%%%               '----------------------------',jj,funstr(jj-4:jj),leftEnd, rightEnd,kb
%%%              end

               %'333333333',jj,funstr(jj-4:jj),leftEnd, rightEnd,kb
              end % if any(strcmpi(funstrwords{jj}(1),
              if strcmpi(funstrwords{jj}(1),'assign')
               if isempty(hasAssign), hasAssign=jj; end
              end % if strcmpi(funstrwords{jj}(1),
              
             end % if (~fs_goodHasAnyQuote(jj) || .
            end % if ~isempty(funstrwords{jj})
           end
           jj=jj+1;
%%%  if jj>650
%%%   '----------------------------',jj,funstr(jj-4:jj),kb
%%%  end

           %jj,leftEnd,rightEnd,funstr{jj-1},'uuuuuuuuuuuuuuuuuuu'
          end % while ((leftEnd~=rightEnd)&(jj<=s))
              %'ouuuuuuuuuuuuu',kb
          out=jj-1;


          sublist{slLen+1,2}=ii+1;                    %beginning line (incl. leading comments)
          sublist{slLen+1,3}=[out];                   %ending line
          sublist{slLen+1,4}=type_words{temp(1)};     %subprg type
          sublist{slLen+1,5}=[];                      %if it has a contains, then line no
          sublist{slLen+1,6}=left-right-1;            %nest level (main level is nest level 0)
          sublist{slLen+1,7}='';                      %parent name
          sublist{slLen+1,9}=i;                       %actual subprg declaration
          sublist{slLen+1,10}=hasArithmeticIF;        %has first arithmetic if on that line #
          sublist{slLen+1,11}=hasAssign;              %has first assign on that line #
          
          if sublist{slLen+1,6}~=0
           temp6=find([sublist{1:slLen+1,6}]==sublist{slLen+1,6}-1,1,'last');
           sublist{slLen+1,7}=sublist{temp6,1};
%%%         for k=slLen+1:-1:1
%%%          if sublist{k,6}==sublist{slLen+1,6}-1
%%%           sublist{slLen+1,7}=sublist{k,1};           break
%%%          end % if sublist{k,
%%%         end % for k=slLen+1:-1:1
          end % if sublist{slLen+1,
         end % if goon

         
         if strcmpi(funstrwords{i}{j},'interface'), inInterface=1;end
         if length(funstrwords{i})>1 && strcmpi(funstrwords{i}(1),'end') && ...
              strcmpi(funstrwords{i}(2),'interface')
          inInterface=0;
         end % if length(funstrwords{jj}>1 && strcmpi(funstrwords{jj}(2),

         %if strcmp('d_pi',sublist{end,1})
%%%         if i>1000
%%%         'sssssssssssss',sublist(max(end-5,1):end,:),funstr{i},kb
%%%         end % if i>1000
         %end       
         
         break
       case 'contains'
         for jj=size(sublist,1):-1:1
          if sublist{jj,3}>i
           sublist{jj,5}=i;
           break
          end % if sublist{jj,
         end % for jj=i:-1:1

         %sublist{size(sublist,1),5}=i;                  %if it has a contains
         break



       case 'end'         
         if j==1
          if any(i==[sublist{:,3}])
           right=right+1;
          end % if any(i==sublist(:,
         end % if j==1

         
         
%%%         % make sure this is not an end select or something
%%%         goonimag=1;
%%%         if length(funstrwords{i})>j
%%%          if ~any(strcmpi(funstrwords{i}{j+1},type_words))
%%%           goonimag=0;
%%%          end
%%%          if strcmpi(funstrwords{i}{j+1},'interface'), inInterface=0;goon=1;end
%%%         else
%%%          goonimag=0;
%%%         end
%%%%%%       if any(strcmpi(funstrwords{i},'interface'))
%%%%%%       sublist,goonimag,temp,funstr{i},i,j,'55555555',kb
%%%%%%       end
%%%% wait! is this a variable end?        
%%%          if (any(funstr{i}=='=') && ...
%%%              any(validSpot(funstr{i},find(funstr{i}=='='),commentMarker)) && ...
%%%              funstr{i}(funstrwords_e{i}(j)+1)~=';') || ...
%%%               any(strcmp(funstrwords{i},'call'))
%%%           goonimag=0;
%%%           funstr{i}(funstrwords_b{i}(j):funstrwords_e{i}(j))='eml';
%%%           [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%           %'rerererererer',funstr(i),kb
%%%          end
%%%          if goonimag && goon && ~inInterface
%%%           right=right+1;
%%%%%%        %right,left,{funstr{i-10:i+2}},i
%%%%%%        %if right>20, 'jjjjjjjjjjjjj',right,left,kb, end
%%%%close the last open subprg
%%%           for k=size(sublist,1):-1:1
%%%            if isempty(sublist{k,3})
%%%             sublist{k,3}=i;         break
%%%            end % if isempty(sublist(size(sublist,
%%%           end % for k=size(sublist,
%%%           break
%%%          end
       
       
       
       case 'use'
         if ~inInterface
          % found a module, so add it to the list if its not already there
          %  what module, function or program are we in
          for ii=size(sublist,1):-1:1
           if any(strcmp(sublist{ii,4},{'program';'function';'subroutine';'module'}))
            break
           end
          end
          temp1=find(strcmpi(modUsedMods(:,1),sublist{ii,1}));
          if isempty(temp1)
           modUsedMods{size(modUsedMods,1)+1,1}=lower(sublist{ii,1});
           temp1=size(modUsedMods,1);
          end
          if isempty(modUsedMods{temp1,2}), modUsedMods{temp1,2}=cell(0,1); end
          % and what is the name of the used module? Put it into modUsedMods{temp1,2}{here}
          modUsedMods{temp1,2}=unique(lower({modUsedMods{temp1,2}{:},funstrwords{i}{j+1}}));
%%%          if any(strcmp(funstrwords{i},'C_COM1'))
%%%           's2s2s2s2s2s--------',funstr{i},temp,j,kb
%%%          end
         end % if ~inInterface
     end % switch type_words{j}
         %'pppppppp1',sublist,funstr{i},kb
    end % if ~inastring_f(funstr{i},
   else
%%%     if any(strcmpi(funstrwords{i},'parse_formula'))
%%%      's2s2s2s2s2s--------',funstr{i},temp,j,kb
%%%     end     
    if ~any(strcmpi(var_words,funstrwords{i}{j})) &&...
         ~strcmpi('kind',funstrwords{i}{j}) && ...
         ~(j>1 && strcmpi(funstrwords{i}{j-1},'type')) && ...
         ~insubscript_f(i,funstrwords_b{i}(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords)
     break
    end
   end % if ~isempty(temp)
  end % for j=1:length(funstrwords{i})
 end % for i=1:s
end % if isempty(linenum)


%fix the nesting level  and fix the parent function
for ii=1:size(sublist,1)
 sublist{ii,6}=length(find([sublist{:,2}]<sublist{ii,2} & ...
                           [sublist{:,3}]>sublist{ii,3}));
 if sublist{ii,6}>0
  sublist{ii,7}=sublist{find([sublist{:,2}]<sublist{ii,2} & ...
                             [sublist{:,3}]>sublist{ii,3},1,'last'),1};
 else
  sublist{ii,7}='';
 end % if sublist{ii,
end % for ii=1:size(sublist,

% no arithmetic if if it occurs after the contains
for ii=1:size(sublist,1)
 if ~isempty(sublist{ii,10})
  if ~isempty(sublist{ii,5})
   if sublist{ii,10}>sublist{ii,5}
    sublist{ii,10}=[];
   end % if sublist{ii,
  end % if ~isempty(sublist{ii,
 end % if ~isempty(sublist{ii,
end % for ii=1:size(sublist,
% no assign if it occurs after the contains
for ii=1:size(sublist,1)
 if ~isempty(sublist{ii,11})
  if ~isempty(sublist{ii,5})
   if sublist{ii,11}>sublist{ii,5}
    sublist{ii,11}=[];
   end % if sublist{ii,
  end % if ~isempty(sublist{ii,
 end % if ~isempty(sublist{ii,
end % for ii=1:size(sublist,

%'whwgh',sublist,kb

%%%'yyyyyyyyyyyyyy',%funstr
%%%sublist
%%%modUsedMods
%%%kb

%%%catch
%%% disp('error finding program and subprogram delineations. ');
%%% error('Often this is caused by no program statement in the fortran file.');
%%%end
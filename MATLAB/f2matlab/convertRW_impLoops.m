function strOut=convertRW_impLoops(groupsIn,noQuotes)
% returns the string ready for readFmt and writeFmt
%
% recursive
 
 global DQ
 if nargin<2, noQuotes=0; end
 strOut='';

%%% groupsIn,'wwwwwwwwww_start',kb
 
 if length(groupsIn)>0
  if ~isempty(groupsIn{1})
   for ii=1:length(groupsIn)
%%%    if ~isempty(strfind(groupsIn{ii},'exe'))
%%%     groupsIn{ii},'cccccccc12',kb
%%%    end
    %if this is a string literal, need an extra set of quotes
    if strcmp(groupsIn{ii}(1),'''')
     temp8=['''''',groupsIn{ii},''''''];
     %but do we have an implied do loop?
    elseif groupsIn{ii}(1)=='(' && groupsIn{ii}(end)==')'
     temp9=strtrim(getTopGroupsAfterLoc(groupsIn{ii}(2:end-1),0));
     %'sumaaaaaaaaaaaaaaku',kb
     %if there is no equals sign in the list, then we just pass them along
     if length(temp9)>2 && (any(temp9{end-1}=='=') || any(temp9{end-2}=='='))
      ;%where is the = sign?
      eqSign=0;
      for jj=length(temp9):-1:1
       if any(temp9{jj}=='='), eqSign=jj; break; end
      end
      
      temp10=find(temp9{eqSign}=='=',1,'first');
      %this DQ{3} is here so that parens get changed to curly braces later
      temp8=['{',convertRW_impLoops(temp9(1:eqSign-1),noQuotes),',''',...
             strtrim(temp9{eqSign}(1:temp10-1)),''',''',...
             strtrim(temp9{eqSign}(temp10+1:end)),''','''];
%%%      temp8=['{',DQ{3},convertRW_impLoops(temp9(1:eqSign-1),1),DQ{3},',''',...
%%%             strtrim(temp9{eqSign}(1:temp10-1)),''',''',...
%%%             strtrim(temp9{eqSign}(temp10+1:end)),''','''];
      if length(temp9)==eqSign+2
       temp8=[temp8,temp9{eqSign+2},''','''];
      else
       temp8=[temp8,'1'','''];
      end
      temp8=[temp8,temp9{eqSign+1},'''}'];
     else
      temp8='';
      for jj=1:length(temp9)
       if temp9{jj}(1)==''''
        temp8=[temp8,DQ{3},DQ{3},temp9{jj},DQ{3},DQ{3}];
       else
        temp8=[temp8,DQ{3},temp9{jj},DQ{3}];
       end % if temp9{jj}(1)==''''
       if jj~=length(temp9)
        temp8=[temp8,','];
       end % if jj~=length(temp9)
      end % for jj=1:length(temp9)
     end % if length(temp9)>2 && any(temp9{2}=='=') % we have an IDLoop
    else
     %'9999999999',temp8,kb
     temp8=[DQ{3},strrep(groupsIn{ii},'''',DQ{1}),DQ{3}];
     %temp8=[DQ{3},groupsIn{ii},DQ{3}];
    end % if strcmp(groupsIn{ii}(1),
    strOut=[strOut,temp8];
    if ii<length(groupsIn)
     strOut=[strOut,','];
    end % for ii=1:length(groupsIn)
   end % if ~isempty(groupsIn{1})
  end
 end % if length(groupsIn)>0

 %strOut,'wwwwwwwwww',kb
 
 
 
 
%%%  if length(groupsIn)>0
%%%  if ~isempty(groupsIn{1})
%%%   for ii=1:length(groupsIn)
%%%    %if ~isempty(strfind('tables',groupsIn{1}))
%%%    %groupsIn,'cccccccc12',kb
%%%    %end
%%%    %if this is a string literal, need an extra set of quotes
%%%    if strcmp(groupsIn{ii}(1),'''')
%%%     temp8=['''''',groupsIn{ii},''''''];
%%%     %but do we have an implied do loop?
%%%    elseif groupsIn{ii}(1)=='(' && groupsIn{ii}(end)==')'
%%%     temp9=strtrim(getTopGroupsAfterLoc(groupsIn{ii}(2:end-1),0));
%%%     'sumaaaaaaaaaaaaaaku',kb
%%%     %if there is no equals sign in the list, then we just pass them along
%%%     if length(temp9)>2
%%%      if any(temp9{end-1}=='=') || any(temp9{end-2}=='=') % we have an IDLoop
%%%       ;%where is the = sign?
%%%       eqSign=0;
%%%       for jj=length(temp9):-1:1
%%%        if any(temp9{jj}=='='), eqSign=jj; break; end
%%%       end
%%%       
%%%       temp10=find(temp9{eqSign}=='=',1,'first');
%%%       %this DQ{3} is here so that parens get changed to curly braces later
%%%       temp8=['{',convertRW_impLoops(temp9(1:eqSign-1),noQuotes),',''',...
%%%              strtrim(temp9{eqSign}(1:temp10-1)),''',''',...
%%%              strtrim(temp9{eqSign}(temp10+1:end)),''','''];
%%%%%%      temp8=['{',DQ{3},convertRW_impLoops(temp9(1:eqSign-1),1),DQ{3},',''',...
%%%%%%             strtrim(temp9{eqSign}(1:temp10-1)),''',''',...
%%%%%%             strtrim(temp9{eqSign}(temp10+1:end)),''','''];
%%%       if length(temp9)==eqSign+2
%%%        temp8=[temp8,temp9{eqSign+2},''','''];
%%%       else
%%%        temp8=[temp8,'1'','''];
%%%       end
%%%       temp8=[temp8,temp9{eqSign+1},'''}'];
%%%      end % if any(temp9{end-1}=='=') || any(temp9{end-2}=='=') % we have an IDLoop
%%%     elseif length(temp9)==1 %a false alarm on the IDL, so pass along
%%%      temp8=[DQ{3},groupsIn{ii},DQ{3}];
%%%     else %two groups? go to keyboard...
%%%      disp(groupsIn{ii})
%%%      error('problem with this group');
%%%     end % if length(temp9)>2 && any(temp9{2}=='=') % we have an IDLoop
%%%
%%%     %'9999999999',temp8,kb
%%%    else
%%%     temp8=[DQ{3},groupsIn{ii},DQ{3}];
%%%    end % if strcmp(groupsIn{ii}(1),
%%%    strOut=[strOut,temp8];
%%%    if ii<length(groupsIn)
%%%     strOut=[strOut,','];
%%%    end % for ii=1:length(groupsIn)
%%%   end % if ~isempty(groupsIn{1})
%%%  end
%%% end % if length(groupsIn)>0

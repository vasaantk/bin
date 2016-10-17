endFlag=''; if strcmp(temp11,'read'), endFlag=',readEndFlag'; end

tempstr=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',temp11,'ErrFlag',endFlag,']=',temp11,'Fmt(',thisfid,',',groupsStr];
%tempstr=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',temp11,'ErrFlag',endFlag,']=',temp11,'Fmt(',subscripts{1},',',groupsStr];
%%tempstr=[funstr{i}(1:funstrwords_b{i}(j)-1),'[',temp11,'ErrFlag',endFlag,']=',temp11,'Fmt(',thisfid,',',groupsStr];
 temp6=strtrim(getTopGroupsAfterLoc(funstr{i},parens(2)));

 
 %funstr{i},temp6,formatStr,'smmmmmmmmmmm',kb
 
 
 temp7=convertRW_impLoops(temp6);
 
%%% temp7='';
%%% if ~isempty(temp6{1})
%%%  for ii=1:length(temp6)
%%%   %temp6,'cccccccc',kb
%%%   %if this is a string literal, need an extra set of quotes
%%%   if strcmp(temp6{ii}(1),'''')
%%%    temp8=['''''',temp6{ii},''''''];
%%%   else
%%%    temp8=['''',temp6{ii},''''];
%%%   end
%%%   %but do we have an implied do loop?
%%%   if temp6{ii}(1)=='(' && temp6{ii}(end)==')'
%%%    temp9=strtrim(getTopGroupsAfterLoc(temp6{ii}(2:end-1),0));
%%%    if length(temp9)>2 && any(temp9{2}=='=') % we have an IDLoop
%%%     temp10=find(temp9{2}=='=',1,'first');
%%%     temp8=['{',DQ{3},temp9{1},DQ{3},',''',temp9{2}(1:temp10-1),''',''',temp9{2}(temp10+1:end),...
%%%            ''','''];
%%%     if length(temp9)==4
%%%      temp8=[temp8,temp9{4},''','''];
%%%     end
%%%     temp8=[temp8,temp9{3},'''}'];
%%%    end % if length(temp9)>2 && any(temp9{2}=='=') % we have an IDLoop
%%%   end % if temp6{ii}(1)=='('
%%%   temp7=[temp7,temp8];
%%%   if ii<length(temp6)
%%%    temp7=[temp7,','];
%%%   end % for ii=1:length(temp6)
%%%  end % if ~isempty(temp6{1})
%%% end
 
 
 
 
 if ~isempty(temp7)
  tempstr=[tempstr,','];
 end
 tempstr=[tempstr,temp7,');'];
%%% funstr{i},temp7,tempstr,'ffffffffffffffffffffffffffff',kb
 funstr{i}=tempstr;

 


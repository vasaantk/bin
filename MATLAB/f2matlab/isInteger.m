function out = isInteger(i,range,funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords,fortranfunwords,formats,localVar,implicit,this_fun_name)

str=funstr{i};
tl=str=='(';
tl(find(tl))=~inastring_f(str,find(tl));
tl(find(tl))=~inastring2_f(str,find(tl));
tr=str==')';
tr(find(tr))=~inastring_f(str,find(tr));
tr(find(tr))=~inastring2_f(str,find(tr));
tb=tl-tr;   tlevel=[0,cumsum(tb)];

if str(range(1))=='('
 loc=range(1)+1;
else
 loc=range(1);
end

%what words and numbers are on the same level as loc?
possW=find(funstrwords_b{i}>=range(1) & funstrwords_b{i}<=range(2) & ...
      tlevel(funstrwords_b{i})>=tlevel(loc));
possN=find(funstrnumbers_b{i}>=range(1) & funstrnumbers_b{i}<=range(2) & ...
      tlevel(funstrnumbers_b{i})>=tlevel(loc));

outW=false(1,length(possW));;
outN=false(1,length(possN));;


%%%if strcmpi(funstrwords{i}{1},'factor')
%%% 'inttttttttttt',funstr{i},funstr{i}(range(1):range(2)),kb
%%%end


localVar{size(localVar,1)+1,1}='fix';localVar{size(localVar,1),3}='integer';
for ii=1:length(possW)
 if ~strcmpi(funstrwords{i}{possW(ii)},this_fun_name)
  temp=find(strcmp(funstrwords{i}{possW(ii)},{localVar{:,1}}));
  if ~isempty(temp)
   if strcmp(localVar{temp,3},'integer')
    outW(ii)=true;
   elseif strcmp(localVar{temp,3},'real')
    outW(ii)=false;
    break
   end % if strcmp(localVar{temp,
   ; %try to catch implicitly defined variables
  elseif isempty(find(strcmp(funstrwords{i}{possW(ii)},funwords)))
   %not a function, so it must be an implicitly defined variable
   %'eeeeeeeeee',funstr{i},kb
   temp2=find(strcmp(funstrwords{i}{possW(ii)}(1),{implicit{:,1}}));
   if ~isempty(temp2)
    if strcmp(implicit{temp2(1),2},'integer')
     outW(ii)=true;
    end % if strcmp(implicit{temp2(1),
   end % if isempty(temp2)
  end % if ~isempty(temp)
 end % if ~strcmpi(funstrwords{i}{possW(ii)},
end

for ii=1:length(possN)
 if isempty(regexpi(funstrnumbers{i}{possN(ii)},'[\.edq]'))
  outN(ii)=true;
 else
  outN(ii)=false;
  break
 end % if ~isempty(temp)
end

if all(outW) && all(outN)
 out=1;
else
 out=0;
end


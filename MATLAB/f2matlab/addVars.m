function [localVar,originalLocaVar]=addVars(localVar,modLocalVar,usedMods,modUsedMods)

global files

originalLocaVar=localVar;
for i=1:length(usedMods)
 %'aaaaaaaaaaaaaaaa',whos,kb
 localVar(size(localVar,1)+1:size(localVar,1)+size(modLocalVar{usedMods(i),2},1),:)=...
     modLocalVar{usedMods(i),2}(:,:);
%%% [localVar{size(localVar,1)+1:size(localVar,1)+size(modLocalVar{usedMods(i),2},1),:}]=deal(modLocalVar{usedMods(i),2}{:,:});
 if ~isempty(files)
  % then we are done, the vars of the module already contain the vars of the used modules
  % because we are going in the correct module order already
 else
  %does this module use others?
  temp=find(strcmp({modUsedMods{:,1}},modLocalVar{usedMods(i),1}));
  if ~isempty(temp)
   %'deeeeeeeeeee',temp,localVar,usedMods,kb
   for j=1:length(modUsedMods{temp,2})
    % where is this used mod in modLocalVar
    temp2=find(strcmp(modUsedMods{temp,2}{j},{modLocalVar{:,1}}));
    if ~isempty(temp2)
     localVar=addVars(localVar,modLocalVar,temp2,modUsedMods);
    end
   end
  end
 end % if oneBYone
end


% moved this back into f2matlab

%%%% combine rows
%%%keep=ones(size(localVar,1),1);
%%%for ii=1:size(localVar,1)-1
%%% temp1=find(strcmp(localVar{ii,1},localVar(ii+1:end,1)));
%%% if ~isempty(temp1)
%%%  temp1=temp1(1);
%%%  keep(ii+temp1)=0;
%%%  localVar{ii,3}=localVar{ii+temp1,3}; % type in the second is usually more accurate (from the module,
%%%                                       % for example)
%%%  for jj=4:size(localVar,2)
%%%   if isempty(localVar{ii,jj}) && ~isempty(localVar{ii+temp1,jj})
%%%    localVar{ii,jj}=localVar{ii+temp1,jj};
%%%   end % if isempty(localVar{ii,
%%%  end % for jj=4:size(localVar,
%%% end % if ~isempty(temp1)
%%%end % for ii=1:size(localVar,
%%%
%%%
%%%localVar=localVar(find(keep),:);

%%%[a,b]=unique({localVar{:,1}},'last');
%%%localVar=localVar(b,:);

%%%localVar
%%%'feeeeeee',kb

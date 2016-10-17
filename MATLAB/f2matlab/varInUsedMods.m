function out=varInUsedMods(word,modLocalVar,usedMods,MLapp);

if nargin<4, MLapp='_ml'; end
out={};

for i=length(usedMods):-1:1
 temp1=find(strcmp(word,modLocalVar{usedMods(i),2}(:,1)));
%%% if isempty(temp1)
%%%  temp1=find(strcmp([word,MLapp],{modLocalVar{usedMods(i),2}{:,1}}));
%%% end
 if ~isempty(temp1)
  out={modLocalVar{usedMods(i),2}{temp1,:}};
  break
 end % if ~isempty(temp1)
end % for i=1:length(usedMods)
 
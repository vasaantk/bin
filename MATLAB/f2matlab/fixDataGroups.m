function [strOut,groups]=fixDataGroups(groups);

%'00000000000',showall(groups),kb
%find the '/'s and commas 
subGroup=cell(1,length(groups));
for ii=1:length(groups)
 if any(groups{ii}=='/')
  % should be only an opening and closing / in this group, but careful of the strings!
  temp1=groups{ii}=='/';
  temp1(find(temp1))=~inastring_f(groups{ii},find(temp1));
  temp1(find(temp1))=~inastring2_f(groups{ii},find(temp1));
  temp1(find(temp1))=~inaDQstring_f(groups{ii},find(temp1));
  sla(ii,1:2)=find(temp1);
    
  [subGroup{ii}]=getTopGroupsAfterLoc(groups{ii}(sla(ii,1)+1:sla(ii,2)-1),0);
  %fix subgroups like these:
  % 5HD7R  , 5HD6R  , 5HD2R  to bo 'D7R  ', 'D6R  ', 'D2R  '
  for jj=length(subGroup{ii}):-1:1
   [bb1,bb2]=regexp(subGroup{ii}{jj},'^\s*\d+h');
   if ~isempty(bb1)
    len=str2num(subGroup{ii}{jj}(bb1:bb2-1));
    subGroup{ii}{jj}=['''',subGroup{ii}{jj}(bb2+1:bb2+len),''''];
    %'0000000000011',showall(subGroup),kb  
   end % if ~isempty(bb1)
  end % for jj=length(subGroup{ii}):-1:1
  
  for jj=length(subGroup{ii}):-1:1
   if any(subGroup{ii}{jj}=='*')
    astLoc=find(subGroup{ii}{jj}=='*');
    goon=1;
    %are we in a string?
    qloc=find(subGroup{ii}{jj}=='''');
    if ~isempty(qloc)
     if mod(length(qloc(qloc<astLoc(1))),2)==1
      goon=0;
     end
    end
    %we might have already fixed this... with a ones() at the beginning of the slash group
    if strncmpi(subGroup{ii}{jj},'ones',4)
     goon=0;
    end
    if goon
%%%     num=str2num(subGroup{ii}{jj}(1:astLoc-1));
%%%     if ~isempty(num)
%%%     for kk=0:num-1
%%%      subGroup{ii}{jj+kk}=subGroup{ii}{jj}(astLoc+1:end);
%%%     end
%%%%%%     subGroup{ii}{jj}=repmat([subGroup{ii}{jj}(astLoc+1:end),','],1,str2num(subGroup{ii}{jj}(1:astLoc-1)));
%%%%%%     subGroup{ii}{jj}=subGroup{ii}{jj}(1:end-1);
%%%%%%          subGroup{ii}{jj}=['repmat(',subGroup{ii}{jj}(astLoc+1:end),',1,',subGroup{ii}{jj}(1:astLoc-1),')'];
%%%     'fffffffff',subGroup,subGroup{ii}{jj},kb
%%%    end
     
     
     num=str2num(subGroup{ii}{jj}(1:astLoc-1));
     %if ~isempty(num)
     if length(subGroup)>1
      oldL=length(subGroup{ii});
      for kk=1:num-1
       subGroup{ii}{oldL+kk}='';
      end
      if ~isempty(jj+num:length(subGroup{ii}))
       [subGroup{ii}{jj+num:length(subGroup{ii})}]=deal(subGroup{ii}{jj+1:oldL});
      end
      [subGroup{ii}{jj:jj+num-1}]=deal(subGroup{ii}{jj}(astLoc+1:end));
     else
      % can only be one of these! very limited... otherwise what to do with 
      %   something like DATA my0,my1/2*12/,my2,my3/2*8/ ?
      subGroup{ii}{jj}=['ones(1,',subGroup{ii}{jj}(1:astLoc-1),')*',subGroup{ii}{jj}(astLoc+1:end),''];
     end % if ~isempty(num)
     %'000000000001212',num,subGroup{ii},subGroup,kb
     
    end
%%%    'fffffffff',subGroup,subGroup{ii}{jj},kb
    
   end % if any(subGroup{ii}{jj}=='*')
  end % for jj=length(subGroup{ii}):-1:1
 end % for jj=1:length(temp1) end % if any(groups{ii}=='/')
end % for ii=1:length(groups)

%']]]]]]]]]',groups,subGroup,kb

% now put them back together
for ii=1:length(groups)
 if any(groups{ii}=='/')
  groups{ii}=groups{ii}(1:sla(ii,1));
  for jj=1:length(subGroup{ii})
   groups{ii}=[groups{ii},subGroup{ii}{jj}];
   if jj~=length(subGroup{ii})
    groups{ii}=[groups{ii},','];
   else
    groups{ii}=[groups{ii},'/'];
   end
  end % for jj=1:length(subGroup{ii})
      %'ppppppppppp',groups{ii},kb
 else
  % need to grab one form the next group with /'s and reassign
  for jj=ii+1:length(groups)
   if any(groups{jj}=='/')
    groups{ii}=[groups{ii},'/',subGroup{jj}{1},'/'];
    subGroup{jj}={subGroup{jj}{2:end}};
    %'ooooooooooo',groups,subGroup,kb
    break
   end % if ~any(groups{ii}=='/')
  end % for jj=ii+1:length(groups)
 end % if ~any(groups{ii}=='/')
end % for ii=1:length(groups)

strOut='data ';
for ii=1:length(groups)
 strOut=[strOut,groups{ii}];
 if ii~=length(groups), strOut=[strOut,',']; end
end % for ii=1:length(groups)

%'tttttttttt',groups,strOut,kb
%fix the ridiculous numer* notation

%%%for ii=1:length(groups)
%%% if any(groups{ii}=='*')

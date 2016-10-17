% OK, scan through finding
%   include '
% then replace inline

%'eeeeeeeeeeeeeee',filestr,kb

[temp1,temp2]=regexpi(filestr,[char(10),'\s*include\s*[''"]'],'once');
if length(temp1)>0
 disp(['substituting in include files']);
end
while 1 %do this until no more includes (break condition is inside takeCareOfIncludeFiles)
 [temp1,temp2]=regexpi(filestr,[char(10),'\s*include\s*[''"]']);
 %'iiiiiiii2',temp1,kb
 temp3=find(filestr=='''' | filestr=='"');
 rets=findstr(r,filestr);  rets=[1 rets];

 if length(temp1)==0, break, end
 temp10=0;
 for i=length(temp1):-1:1
  %is this in a valid spot
  if isempty(find(filestr(rets(find(rets<=temp1(i),1,'last')):temp1(i))=='!')) && ...
       mod(length(find(filestr(rets(find(rets<=temp1(i),1,'last')):temp1(i))=='''')),2)~=1 && ...
       mod(length(find(filestr(rets(find(rets<=temp1(i),1,'last')):temp1(i))=='"')),2)~=1
   temp10=1;
   temp4=filestr(temp2(i)+1:temp3(find(temp3>temp2(i),1,'first'))-1);
%%%   if strcmpi('ephem.inc',temp4), 'gggggggg',kb,end
   [temp5,temp6,temp7]=fileparts(temp4);
   %if ~isempty(temp5), temp4=[temp6,temp7]; end %why did I have this originally???
   disp(['   found include file ',temp4,' ... inserting']);
   if isempty(temp7) %add .for if file doesn't exist without ext
    if exist(temp4)~=2
     temp4=[temp4,'.for'];
     [temp9{1},temp9{2},temp9{3}]=fileparts(which(temp4));
     temp9{4}=fullfile(temp9{1},[temp9{2},temp9{3}]);
    else     
     temp9{1}='.'; %assum in present directory
     temp9{4}=temp4;
    end
   else
    [temp9{1},temp9{2},temp9{3}]=fileparts(which(temp4));
    temp9{4}=fullfile(temp9{1},[temp9{2},temp9{3}]);
   end
   %'ddddddddddd',temp4,temp9,kb
   if ~isempty(temp9{1})
    fid=fopen(temp9{4}); temp8=fscanf(fid,'%c'); fclose(fid);
   else
    warning(['had a problem finding include file ',temp4,r,'Is that directory on the Matlab path?']);
    temp8=['! could not find include file ',temp4,r];
   end
   %regexprep all in the file at once
   tempstr=[r,...
            'f2matlab_begin_include_file',r,r,...
            temp8,...
            '!!! f2matlab finish include file ',temp9{4},r,...
           ];   
   %[ss,temp12]=regexp(filestr,[r,'\s*?include\s*?''',temp4,'''.+?',r],'start','match');
   % now replace all those includes of that file in this file
   bar1=regexpi(filestr,[r,'\s*?include\s*?["'']',temp4,'[''"][ ]*']);
%%%   if strcmpi('xxtnow',temp4) | strcmpi('ephem.inc',temp4)
%%%    temp1,'fffffffffff',kb
%%%   end
   if ~isempty(bar1)
    for jj=length(bar1):-1:1
     bar2=find(rets>bar1(jj),1,'first');
     filestr=[filestr(1:bar1(jj)-1),tempstr,filestr(rets(bar2)+1:end)];
    end % for jj=length(bar1):-1:1
   end
   %filestr=regexprep(filestr,[r,'\s*?include\s*?''',temp4,'''.+?',r],tempstr,'ignorecase');
   %'iiiiiiiiiiiii',kb
   break
%%%   %splice this include in with delimiting lines so we can replace it later
%%%   filestr=[filestr(1:rets(find(rets<temp1(i),1,'last'))),...
%%%            'f2matlab_begin_include_file',r,r,...
%%%            temp8,...
%%%            '!!! f2matlab finish include file ',temp9{4},...
%%%            filestr(rets(find(rets>temp1(i),1,'first')):end),...
%%%           ];
   %filestr(rets(find(rets<temp1(i),1,'last'))-50:rets(find(rets<temp1(i),1,'last'))+800)
  end
 end
 if temp10==0
  disp('finished inserting include files')
  break
 end %all remaining includes are in comments
end

%'iiiiiiiiii',temp1,kb
% OK, so write out the converted code, and replace inline if the same text, 
%  if not, make a new include file. This solves things like different common block names

%'iiiiiiiiiiii',kb

temp9={}; %inc files found and whether this is the first occurrence
while 1
 incBeg=regexpi(funstr,'f2matlab_begin_include_file');
 incBegF=find(~cellfun('isempty',incBeg));
 infEndStatement='f2matlab finish include file';
 incEnd=regexpi(funstr,infEndStatement);
 incEndF=find(~cellfun('isempty',incEnd));
 i=length(incBegF);
 if i==0, break, end
 j=find(incEndF>incBegF(end),1,'first');
 filestr=[];
 for ii=1:incEndF(j)-incBegF(i)-1, filestr=[filestr,funstr{incBegF(i)+ii},r]; end
 temp1={};
 incName=strtrim(funstr{incEndF(j)}(length(infEndStatement)+6:end));
%%% if strcmpi('xxpnt',incName)
%%%  'fffffffffff23',kb
%%% end
 disp(['found include file ',incName])
 if any(strcmp({temp9{:}},incName))
  temp8=0;
 else
  temp8=1;
  temp9{length(temp9)+1}=incName;  
 end
 [temp1{1},temp1{2},temp1{3}]=fileparts(incName);
 % if there is no path and extension, it must be a file in the same dir
 if isempty(temp1{1}) && isempty(temp1{3})
  temp1{1}='.';
 end
 temp4=[temp1{1},filesep,temp1{2},'_ml.m'];
 temp6=[temp1{1},filesep,temp1{2},'_*.m'];
 %check to see if there are any existing include files of this sort and compare.
 % if the same, use that include file, if not, make a new include file (with extension if nec)
 temp7=0;
 temp5=[dir(temp4);dir(temp6)];
 temp3=temp1;
 %'ttttttttttttt',kb
 for ii=1:length(temp5)
  fid=fopen(temp5(ii).name); tempstr=fscanf(fid,'%c'); fclose(fid);
  if strcmp(filestr,tempstr) %found a match
   [temp3{1},temp3{2}]=fileparts(temp5(ii).name);
   temp4=[temp1{1},filesep,temp5(ii).name];
   temp7=ii;
  end % if strcmp(filestr,
 end % for ii=1:length(temp5)
 if ~temp7
  if temp8 %no match, but first time found this include file, so (re)write main include file
   temp3{2}=temp1{2};
   fid=fopen(temp4,'w'); fprintf(fid,'%c',filestr);  fclose(fid);
   %'gggggggggg',kb
  else %not first time for this inc file and no match found, so (re)write incName_subname.m
   funBeg=regexpi(funstr,'^function\>');
   funBegF=find(~cellfun('isempty',funBeg));
   temp10=fun_name{find(funBegF<incBegF(end),1,'last')};
   temp3{2}=[temp1{2},'_',temp10];
   temp4=[temp1{1},filesep,temp3{2},'.m'];   
   fid=fopen(temp4,'w'); fprintf(fid,'%c',filestr);  fclose(fid);
  end % if temp8 %no match,
 end % if ~temp7

 goon=1; %take the include part out of main file
         %'dddddddddddd',kb
 if want_ifi
  funBeg=regexpi(funstr,'^function\>');
  funBegF=find(~cellfun('isempty',funBeg));
  if ~isempty(funBegF)
   %then there are function in this file, so leave this one
   goon=0;
  end
 end % if want_ifi
  
 
 if goon
  funstr={funstr{1:incBegF(i)-1},temp3{2},funstr{incEndF(j)+1:end}};
 else
  funstr{incBegF(i)}=['%%%  begin include file -- ',incName];
 end
 
 
%%% fid=fopen(temp4,'w'); fprintf(fid,'%c',filestr);  fclose(fid);
%%% %funstr{incBegF(i)-1:incEndF(j)+1}
%%% funstr={funstr{1:incBegF(i)-1},temp1{2},funstr{incEndF(j)+1:end}};
%%% %funstr{incBegF(i)-1:incEndF(j)+1}
end % while 1
[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good]=updatefunstr_f(funstr);













%%%while 1
%%% incBeg=regexpi(funstr,'f2matlab_begin_include_file');
%%% incBegF=find(~cellfun('isempty',incBeg));
%%% infEndStatement='f2matlab finish include file';
%%% incEnd=regexpi(funstr,infEndStatement);
%%% incEndF=find(~cellfun('isempty',incEnd));
%%% i=length(incBegF);
%%% if i==0, break, end
%%% j=find(incEndF>incBegF(end),1,'first');
%%% filestr=[];
%%% for ii=1:incEndF(j)-incBegF(i)-1, filestr=[filestr,funstr{incBegF(i)+ii},r]; end
%%% temp1={};
%%% incName=funstr{incEndF(j)}(length(infEndStatement)+6:end);
%%% disp(['found include file ',incName])
%%% [temp1{1},temp1{2},temp1{3}]=fileparts(incName);
%%% % if there is no path and extension, it must be a file in the same dir
%%% if isempty(temp1{1}) && isempty(temp1{3})
%%%  temp1{1}='.';
%%% end
%%% fid=fopen([temp1{1},filesep,temp1{2},'.m'],'w'); fprintf(fid,'%c',filestr);  fclose(fid);
%%% %funstr{incBegF(i)-1:incEndF(j)+1}
%%% funstr={funstr{1:incBegF(i)-1},temp1{2},funstr{incEndF(j)+1:end}};
%%% %funstr{incBegF(i)-1:incEndF(j)+1}
%%%end % while 1
%%%[funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good]=updatefunstr_f(funstr);

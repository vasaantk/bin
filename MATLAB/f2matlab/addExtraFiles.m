if want_exf==1 && isempty(files)
 filestr=[filestr,r,r,r,...
          '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',r,...
          '%%%%%%%%%%% extra functions as needed by the translation %%%%%%%%%%%',r,r];
end

tempStr={'minval_ml','maxval_ml','minloc_ml','maxloc_ml','strrel','writeFmt','readFmt',...
         'readWriteIOlist','readf','writef','strAssign','empt0','mlPointer'};
for ii=1:length(tempStr)
 if ~isempty(regexp(filestr,['\<',tempStr{ii},'\>']))
  if want_exf==1
   fid=fopen(fullfile(fileparts(which('f2matlab')),[tempStr{ii},'.m']));
   temp1=fscanf(fid,'%c'); fclose(fid);
   filestr=[filestr,r,r,r,temp1];
  elseif want_exf==0
   fid=fopen([pwd,filesep,[tempStr{ii},'.m']]);
   if fid==-1
    temp1=copyfile(fullfile(fileparts(which('f2matlab')),[tempStr{ii},'.m']),'.');
    if ~temp1
     warning(['error copying file ''',tempStr{ii},''' to the current directory'])
    end
   else
    fclose(fid);
   end % if fid==-1
  end % if want_exf==1
 end % if ~isempty(regexp(filestr,
end % for ii=1:length(tempStr)



%%%
%%%
%%%%minval_ml
%%%if ~isempty(regexp(filestr,'\<minval_ml\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'minval_ml.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'minval_ml.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'minval_ml.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',minval_ml.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%maxval_ml
%%%if ~isempty(regexp(filestr,'\<maxval_ml\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'maxval_ml.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'maxval_ml.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'maxval_ml.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',maxval_ml.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%strrel
%%%if ~isempty(regexp(filestr,'\<strrel\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'strrel.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'strrel.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'strrel.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',strrel.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%addwriteFmt
%%%if ~isempty(regexp(filestr,'\<writeFmt\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'writeFmt.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'writeFmt.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'writeFmt.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',writeFmt.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%addreadFmt
%%%if ~isempty(regexp(filestr,'\<readFmt\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'readFmt.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'readFmt.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'readFmt.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',readFmt.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%if ~isempty(regexp(filestr,'\<readWriteIOlist\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'readWriteIOlist.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  temp1=copyfile(fullfile(fileparts(which('f2matlab')),'readWriteIOlist.m'),'.');
%%%  if ~temp1
%%%   warning(['error copying file ''',readWriteIOlist.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%addreadf
%%%if ~isempty(regexp(filestr,'\<readf\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'readf.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  temp1=copyfile(fullfile(fileparts(which('f2matlab')),'readf.m'),'.');
%%%  if ~temp1
%%%   warning(['error copying file ''',readf.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%addwritef
%%%if ~isempty(regexp(filestr,'\<writef\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'writef.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'writef.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'writef.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',writef.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%add strAssign
%%%if ~isempty(regexp(filestr,'\<strAssign\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'strAssign.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  fid=fopen([pwd,filesep,'writeFmt.m']);
%%%  if fid~=-1
%%%   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'strAssign.m'),'.');
%%%   fclose(fid);
%%%  end
%%%  if ~temp1
%%%   warning(['error copying file ''',writef.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,
%%%
%%%%add empt0
%%%if ~isempty(regexp(filestr,'\<empt0\>'))
%%% if want_exf==1
%%%  fid=fopen(fullfile(fileparts(which('f2matlab')),'empt0.m'));
%%%  temp1=fscanf(fid,'%c'); fclose(fid);
%%%  filestr=[filestr,r,r,r,temp1];
%%% elseif want_exf==0
%%%  temp1=copyfile(fullfile(fileparts(which('f2matlab')),'empt0.m'),'.');
%%%  if ~temp1
%%%   warning(['error copying file ''',writef.m,''' to the current directory'])
%%%  end
%%% end % if want_exf==1
%%%end % if ~isempty(regexp(filestr,

%%%%add pntr if needed, has to be copied because
%%%if ~isempty(regexp(filestr,'\<mlPointer\>'))
%%% temp1=copyfile(fullfile(fileparts(which('f2matlab')),'pntr.m'),'.');
%%% if ~temp1
%%%  warning(['error copying file pntr.m to the current directory'])
%%% end
%%%end % if ~isempty(regexp(filestr,

%mlPointer
if ~isempty(regexp(filestr,'\<mlPointer\>'))
 if want_exf==1
  fid=fopen(fullfile(fileparts(which('f2matlab')),'pntr.m'));
  temp1=fscanf(fid,'%c'); fclose(fid);
  filestr=[filestr,r,r,r,temp1];
 elseif want_exf==0
  fid=fopen([pwd,filesep,'pntr.m']);
  if fid==-1
   temp1=copyfile(fullfile(fileparts(which('f2matlab')),'pntr.m'),'.');
   if ~temp1
    warning(['error copying file pntr.m to the current directory'])
   end
  else
   fclose(fid);
  end
 end % if want_exf==1
end % if ~isempty(regexp(filestr,



%%%
%%%%add mlPointer if needed
%%%if ~isempty(regexp(filestr,'\<mlPointer\>'))
%%% temp1=copyfile(fullfile(fileparts(which('f2matlab')),'mlPointer.m'),'.');
%%% if ~temp1
%%%  warning(['error copying file ''',writef.m,''' to the current directory'])
%%% end
%%%end % if ~isempty(regexp(filestr,

%%%
%%%%addGetArg
%%%if want_cla
%%% fid=fopen(fullfile(fileparts(which('f2matlab')),'getarg.m'));
%%% temp1=fscanf(fid,'%c'); fclose(fid);
%%% filestr=[filestr,r,r,r,temp1];
%%%end % if ~isempty(regexp(filestr,if ~isempty(regexp(filestr,'\<strrel\>'))


%getarg
if want_cla
 if ~isempty(regexp(filestr,'\<getarg\>'))
  if want_exf==1
   fid=fopen(fullfile(fileparts(which('f2matlab')),'getarg.m'));
   temp1=fscanf(fid,'%c'); fclose(fid);
   filestr=[filestr,r,r,r,temp1];
  elseif want_exf==0
   fid=fopen([pwd,filesep,'getarg.m']);
   if fid==-1
    temp1=copyfile(fullfile(fileparts(which('f2matlab')),'getarg.m'),'.');
    if ~temp1
     warning(['error copying file getarg.m to the current directory'])
    end
   else
    fclose(fid);
   end
  end % if want_exf==1
 end % if ~isempty(regexp(filestr,
end % if want_cla

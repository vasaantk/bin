function [readErrFlag,readEndFlag]=readFmt(unitIn,formatIn,varargin)
% attempts to be able to reproduce fortran's formatted read statements
 global unit2fid
 %translate unitIn to fidIn
 if isnumeric(unitIn)
  fidRow=find(unit2fid(:,1)==unitIn,1,'last');
  if isempty(fidRow), error(['unknown fid in readFmt',]); end
  fidIn=unit2fid(fidRow,2);
 else %internal read, pass the string through
  fidIn=unitIn;
 end
 for i=1:length(varargin),  varargin{i}=strtrim(varargin{i}); end
 %extract format fields from formatIn
 percents=find(formatIn=='%'| formatIn=='\');
 formatFields=cell(1,length(percents));
 for ii=1:length(percents)
  if ii==length(percents)
   formatFields{ii}=strtrim(formatIn(percents(ii):end));
  else
   formatFields{ii}=strtrim(formatIn(percents(ii):percents(ii+1)-1));
  end
 end % for ii=1:length(percents)
 ;%We should treat everything like a %#c not a %#s
 formatFields=strrep(formatFields,'s','c');
 %Now form the IO list for assigning the calling workspace
 for ii=1:length(varargin)
  if iscell(varargin{ii}) %an implied do loop, make a list
   ;%build in functionality for a nested loop
   for kk=1:length(varargin{ii})-4
    if iscell(varargin{ii}{kk})
     IDL(1)=evalin('caller',varargin{ii}{kk}{end-2});
     IDL(2)=evalin('caller',varargin{ii}{kk}{end-1});
     IDL(3)=evalin('caller',varargin{ii}{kk}{end  });
     vt={}; clk=length(varargin{ii}{kk});
     for jj=IDL(1):IDL(2):IDL(3)
      for mm=1:clk-4
        vt={vt{:},regexprep(varargin{ii}{kk}{mm},...
                            ['\<',varargin{ii}{kk}{clk-3},'\>'],sprintf('%d',jj))};
      end % for mm=1:length(varargin{ii}{kk})-1
     end
     varargin{ii}={varargin{ii}{1:kk-1},vt{:},varargin{ii}{kk+1:end}};
    end % for kk=1:length(varargin{ii})-4
   end % if any(cellfun('isclass',
  end % if iscell(varargin{ii}) %an implied do loop,
 end % for ii=1:length(varargin)
 IOlist={};
 for ii=1:length(varargin)
  if iscell(varargin{ii}) %an implied do loop, make a list
   IDL(1)=evalin('caller',varargin{ii}{end-2});
   IDL(2)=evalin('caller',varargin{ii}{end-1});
   IDL(3)=evalin('caller',varargin{ii}{end  });
   cl=length(varargin{ii});
   for jj=IDL(1):IDL(2):IDL(3)
    for kk=1:cl-4
      IOlist={IOlist{:},regexprep(varargin{ii}{kk},...
                                  ['\<',varargin{ii}{cl-3},'\>'],sprintf('%d',jj))};
    end % for kk=1:cl-4
   end
  elseif ischar(varargin{ii}) %regular string input, so one IOlist item per element of array
                              %assume no vector indexing on non scalars with subscripts
   if ~isempty(regexp(varargin{ii},'[\(\{\*\/\-\+\^]|^[0-9\.]')) || ...
        evalin('caller',['ischar(',varargin{ii},')'])
    IOlist={IOlist{:},varargin{ii}};
   else
    %assume this is a single variable, with at least size of 1
    varSize=evalin('caller',['prod(size(',varargin{ii},'))']);
    if varSize>0
     cellArray=evalin('caller',['iscell(',varargin{ii},')']);
     for jj=1:varSize
      if cellArray
       IOlist={IOlist{:},[varargin{ii},'{',sprintf('%d',jj),'}']};
      else
       IOlist={IOlist{:},[varargin{ii},'(',sprintf('%d',jj),')']};
      end
     end % for jj=1:evalin('caller',
    else
     IOlist={IOlist{:},varargin{ii}};
    end
   end % if any(varargin{ii}=='(')
  else
   warning('readFmt didn''t understand what it was given');
   varargin{ii}
   return
  end
 end % for ii=1:length(varargin)
 
 %now start assigning
 readErrFlag=false; readEndFlag=false; goon=1; whereFF=1; nFF=length(formatFields);
 %we want to execute at least one fgetl
 if isnumeric(fidIn) %fidIn is a file ID
  dataLine=fgetl(fidIn); if dataLine==-1, readEndFlag=true; return; end
  dataLine=regexprep(dataLine,['\<([-+]?[0-9]*[\.]?[0-9]+\.?)([dDqQ])([-+]?[0-9]+)'],'$1e$3');
 elseif ischar(fidIn) %they are trying to read a string
  dataLine=fidIn;
 end % if isnumeric(fidIn)
 dataLineOrig=dataLine;
 dataLine=strrep(dataLine,',',' ');
 for ii=1:max(length(IOlist),length(formatFields)) % because there may be trailing newlines
  while true
   if whereFF<=length(formatFields) && strcmp(formatFields{whereFF}(end),'n')
    dataLine=fgetl(fidIn); if dataLine==-1, readEndFlag=true; return; end
    %dataLine=regexprep(dataLine,'([0-9])-([0-9])','$1 -$2');
    whereFF=whereFF+1;
   else
    break
   end % if strcmp(formatFields{whereFF}(end),
  end
  if ii>length(IOlist), break, end
  %determine whether we count the next ff (don't if it is a tab or x field)
  while true
   if strcmp(formatFields{whereFF}(end),'t')
    dataLine=dataLineOrig(str2num(formatFields{whereFF}(2:end-1)):end);
    whereFF=whereFF+1;
   elseif strcmp(formatFields{whereFF}(end),'x')
    dataLine=dataLine(str2num(formatFields{whereFF}(2:end-1))+1:end);
    whereFF=whereFF+1;
   else
    break
   end % if strcmp(formatFields{whereFF}(end),
  end
  if any(~isspace(dataLine))
   %assume there is at least one format field...
   %get the next value in dataLine with the next formatField
   isLog=0;
   if strcmpi(formatFields{whereFF}(end),'l'), formatFields{whereFF}(end)='c'; isLog=1; end
   switch formatFields{whereFF}(end)
     case {'c'}
       clen=sscanf(formatFields{whereFF}(2:end-1),'%d');
       if isempty(clen) % %c clen should be set to length of IOlist{ii}
        clen=evalin('caller',['length(',IOlist{ii},')']);
        if clen==0, clen=1; end
       end
       tempstr=dataLine(1:min(clen,length(dataLine))); 
       dataLine=dataLine(clen+1:end);
     otherwise
       tempstr=strrep(formatFields{whereFF},'*','');
       ni=fix(sscanf(tempstr(2:end-1),'%d'));
       if isempty(ni)
        [val,foo,readErrFlag,ni]=sscanf(dataLine,tempstr,1);
        ni=ni-1;
       end
       tempstr=dataLine(1:min(ni,length(dataLine)));
       dataLine=dataLine(ni+1:end);        
       %[tempstr,dataLine]=strtok(dataLine);
       tempstr=regexprep(tempstr,'d','e','ignorecase');
   end
   %matlab seems to have some issue with the decimal digits. Get rid of width and decimal spec
   formatFields{whereFF}=regexprep(formatFields{whereFF},['\.\d*'],'');
   [val,foo,readErrFlag]=sscanf(tempstr,strrep(formatFields{whereFF},'*',''),1);
   if isempty(val) && formatFields{whereFF}(end)~='c', val=0; end
   readErrFlag=~isempty(readErrFlag);
   if isLog
    if ~isempty(regexpi(val,'f')), val=0; else, val=1; end
    formatFields{whereFF}(end)='l';
   end
   %now assign that to the corresponding IOlist value in the caller workspace
   switch formatFields{whereFF}(end)
     case {'f','g','u','i','d','e'}
       evalin('caller',[IOlist{ii},'=',sprintf('%40.20g',val),';']);
       %evalin('caller',[IOlist{ii},'=',sprintf('%f',val),';']);
       %evalin('caller',[IOlist{ii},'=',sprintf(formatFields{whereFF},val{1}),';']);
     case {'l'}
       evalin('caller',[IOlist{ii},'=',sprintf('%d',val),';']);
     case {'s'}
       evalin('caller',[IOlist{ii},'(1:',sprintf('%d',length(val)),')=''',strrep(val,'''',''''''),''';']);
       evalin('caller',[IOlist{ii},'(',sprintf('%d',length(val)),'+1:end)='' '';']);
     case {'c'}
       val=val(double(val)~=0); %for octave sscanf (pads with null)
       evalin('caller',[IOlist{ii},'(1:',sprintf('%d',length(val)),')=''',strrep(val,'''',''''''),''';']);
       evalin('caller',[IOlist{ii},'(',sprintf('%d',length(val)),'+1:end)='' '';']);
   end
   if all(formatFields{whereFF}~='*'),whereFF=whereFF+1;end
  else %we have run out of data on this dataLine, so this IOlist spot gets 
       %a zero or empty string until we run out of ff
   switch formatFields{whereFF}(end)
     case {'f','g','u','i','d'}
       evalin('caller',[IOlist{ii},'=0;']);
     case {'s','c'}
       evalin('caller',[IOlist{ii},'='''';']);
   end % switch formatFields{whereFF}(end)
   if all(formatFields{whereFF}~='*'),whereFF=whereFF+1;end%   whereFF=whereFF+1;
  end % if any(~isspace(dataLine(currentPos+1:end)))
      % if we run out of ff first, then get a new line and reset ff
      %  or, if on a * and we've run out of data
  if (whereFF>nFF || ( any(formatFields{whereFF}=='*') & all(isspace(dataLine)) )) ...
       && ii<length(IOlist)
   if isnumeric(fidIn)
    dataLine=fgetl(fidIn); if dataLine==-1, readEndFlag=true; break; end
    %dataLine=regexprep(dataLine,'([0-9])-([0-9])','$1 -$2');
    if whereFF>nFF,     whereFF=1;    end
   elseif ischar(fidIn) %they are trying to read a string
    readEndFlag=true; break;
   end % if isnumeric(fidIn)
  end % if whereFF>nFF && ii<length(IOlist)
 end % for ii=1:length(IOlist0
 ;%finished the IOlist, anything else in the line is ignored
end % function [readErrFlag,

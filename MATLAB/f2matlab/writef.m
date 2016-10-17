function out=writef(fid,varargin)
% function out=writef(fid,varargin)
%  Catches fortran stdout (6) and reroutes in to Matlab's stdout (1)
%  Catches fortran stderr (0) and reroutes in to Matlab's stderr (2)
 crlf=char(10); if ispc, crlf=[char(13),crlf]; end
 if isnumeric(fid)
  if fid==6|fid==1, out=fprintf(1,varargin{:});fprintf(1,crlf);
  elseif fid==0,    out=fprintf(2,varargin{:});fprintf(2,crlf);
  elseif isempty(fid) %% treat empty array like a string array
   out=sprintf(varargin{:});
   if nargin>2 %set the calling var to out
    if ~isempty(inputname(1)), assignin('caller',inputname(1),out); end
   end
  else
   %translate unitIn to fidIn
   global unit2fid
   fidRow=find(unit2fid(:,1)==fid,1,'last');
   if isempty(fidRow), error(['unknown fid in readFmt',]); end
   fidIn=unit2fid(fidRow,2);
   out=fprintf(fidIn,varargin{:});fprintf(fidIn,crlf);
  end
 elseif ischar(fid)
  out=sprintf(varargin{:});
  if nargin>2 %set the calling var to out
   if ~isempty(inputname(1)), assignin('caller',inputname(1),out); end
  end
 else,              out=fprintf(fid,varargin{:});
 end
end

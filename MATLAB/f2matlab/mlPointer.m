%mlPointer -- matlab class definition
%   is a class in the matlab environment that attempts to mimic
%   the behavior of a fortran array that is passed by reference.
%
%   A mlPointer object has four properties:
%      data - this is a matlab pntr class which is a handle class
%             pntr in turn has only one property:
%                data - this is a 1-D vector of data that is shared
%                       by all subsequent copies of this object.
%      offset - an offset into data. Thus, if obj.offset is 3,
%               obj(1) actually indexes the 3rd element of data
%               rather than the 3rd.
%      dims - dimensions of the data. If dims is a single number, 
%             this corresponds to the length of data. If dims is a 
%             vector of 2 numbers, then subsref's into data will be
%             according to these assumed matrix dimensions.
%      len - length of the data
%
%   The main usage here is when a fortran program calls a subroutine
%   by passing multiple references to the same 1-D array at 
%   different locations (offsets), e.g.
%          call sub1(work(10), work(20), work)
%   By using this class, when one part of work is modified in sub1, 
%   other objects are also aytomatically updated because input 
%   variables in sub1 all reference the same data.
classdef mlPointer
 properties
  data,  offset,  dims,  len
 end
 methods 
  function out=mlPointer(data,offset,dims,len)
   if nargin<1, data=[]; end
   if nargin==1 && isa(data,'mlPointer')
    out=data;    return
   end
   if nargin<2, offset=1; end
   if nargin<3
    dims=size(data);    dims=dims(find(dims~=1));
   end
   if nargin<4, len=[numel(data)]; end
   if nargin==1, data=data(:).'; end     % if using want_row=0; add .' if using want_row=1;
   out.data=pntr;   out.data.data=data;   out.offset=offset;
   out.dims=dims;   out.len=len;
  end
  function out=subsref(obj,S)
  %   'subsref',S,'in subsref',keyboard
   if strcmp(S.type,'()')
    if length(S.subs)==2
     if isa(S.subs{1},'char') && ~strcmp(S.subs{1},':')
      out=obj;
      if length(S.subs{2})==1 % must add old offset then (-1) (may already have an offset)
       out.offset=(out.offset-1)+S.subs{2};
      elseif length(S.subs{2})==2 %FIXME, will not work for dims more than 2
       out.offset=(out.offset-1)+S.subs{2}(1)+out.dims(1)*(S.subs{2}(2)-1);
      end
     else
      try
       out=subsref(reshape(obj.data.data(obj.offset:end),obj.dims(1),[]),S);
      catch
       %'ddddddddd',obj,S,dbstack,kb
       % zero pad if necessary with the new offset
       bar=ceil((obj.len-obj.offset+1)/obj.dims(1));
       bar2=obj.dims(1)*bar+obj.offset-1;
       if bar2>obj.len
        obj.data.data(bar2)=0;
       end
       foo=reshape(obj.data.data(obj.offset:obj.offset+obj.dims(1)*bar-1),obj.dims(1),bar);
       out=subsref(foo,S);      
      end
     end
    else%if length(S.subs)==1
     if ~strcmp(S.subs{1},':')
      out=obj.data.data(S.subs{1}+obj.offset-1);
     else
      out=obj.data.data(:);
     end
    end
   elseif S.type=='.'
    if strcmp(S.subs,'data')
     out=obj.data.data;
    else
     out=obj.(S.subs);
    end
   end
  end
  function obj=subsasgn(obj,S,in)
  % 'subsasgn',S,'in subsasgn',kb
   if strcmp(S.type,'()')
    if length(S.subs)==2
     if obj.dims(2)==0
      try
       %'dddddddddw',obj,S,dbstack,kb
       foo=subsasgn(reshape(obj.data.data(obj.offset:end),obj.dims(1),[]),S,in);
       obj.data.data(obj.offset:end)=foo(:);
      catch
       bar=ceil((obj.len-obj.offset+1)/obj.dims(1));
       bar2=obj.dims(1)*bar+obj.offset-1;
       if bar2>obj.len
        obj.data.data(bar2)=0;
       end
       foo=reshape(obj.data.data(obj.offset:obj.offset+obj.dims(1)*bar-1),obj.dims(1),bar);
       foo=subsasgn(foo,S,in);
       obj.data.data(obj.offset:obj.offset+obj.dims(1)*bar-1)=foo(:);
      end
     else
      foo=reshape(obj.data.data(obj.offset:obj.len),obj.dims(1),obj.dims(2));
      foo=subsasgn(foo,S,in);
      obj.data.data(obj.offset:obj.len)=foo(:);
     end
    else%if length(S.subs)==1
     obj.data.data(S.subs{1}+obj.offset-1)=in;
    end
   elseif S.type=='.'
    obj.(S.subs)=in;
   end
  end
%%%%%%%%%%%%%%%%%%% Misc functions
  function out=end(obj,k,n)
    if length(obj.dims)==1
     out=obj.len;
    else
     out=obj.dims(k);
    end
   end
   function out=ne(a,b)
    if isa(a,'mlPointer')
     if isa(b,'mlPointer')
      out=a.data.data(a.offset)~=b.data.data(b.offset);
     else
      out=a.data.data(a.offset)~=b;
     end
    else
     out=b.data.data(b.offset)~=a;
    end % if isa(a,
   end % function out=ne(a,
    function display(obj)
     if length(obj.dims)==1
      display(obj.data.data)
     else
      display(reshape(obj.data.data(1:floor(length(obj.data.data)/obj.dims(1))*obj.dims(1)),obj.dims(1),[]))
     end % if length(obj.
    end
    function out=double(obj)
     if length(obj.dims)==1
      out=obj.data.data(:).';   %use this if want_row=0; % add .' if want_row=1;
     else
      out=reshape(obj.data.data(1:floor(length(obj.data.data)/obj.dims(1))*obj.dims(1)),obj.dims(1),[]);
     end % if length(obj.
    end % function out=double 
     function out=length(obj)
      out=numel(obj.data.data);
     end % function out=       
 end
end

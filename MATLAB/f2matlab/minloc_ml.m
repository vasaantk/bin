function out=minloc_ml(array,dim,mask)
% duplicates the functionality of fortran's minloc
%
%  INPUTS:   array -> data variable    
%              dim -> dimension upon which to operate
%                     (same in Fortran and Matlab)
%             mask -> elements of x to consider
%
% OUTPUTS:     out -> same as fortran's minloc
%
% author: Ben Barrowes 3/2016, barrowes@alum.mit.edu

arraydim=length(find(size(array)~=1));
if nargin==1
 [foo,bar]=min(array(:));
 out=cell(1,arraydim);
 [out{:}]=ind2sub(size(array),bar);
 out=[out{:}];
elseif nargin==2
 if islogical(dim)
  array(~dim)=realmax;
  [foo,bar]=min(array(:));
  out=cell(1,arraydim);
  [out{:}]=ind2sub(size(array),bar);
  out=[out{:}];
 else
  [foo,out]=min(array,[],dim);
  out=squeeze(out);
 end % if ~islogical(dim)
else
 if arraydim==1
  array(~mask)=realmax;
  [foo,out]=min(array);
 else %matrix
  array(~mask)=realmax;
  [foo,out]=min(array,[],dim);
  out=squeeze(out);
 end % if length(find(prod(array)>1))==1 %(vector)
end % if nargin==1
outSize=size(out);
if length(outSize)==2 && outSize(1)>1 && outSize(2)==1 %switch to row vector
 out=out.';
end

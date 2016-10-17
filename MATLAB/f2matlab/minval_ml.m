function out=minval_ml(array,dim,mask)
% duplicates the functionality of fortran's minval
%
%  INPUTS:   array -> data variable    
%              dim -> dimension upon which to operate
%                     (same in Fortran and Matlab)
%             mask -> elements of x to consider
%
% OUTPUTS:     out -> same as fortran's minval
%
% author: Ben Barrowes 3/2016, barrowes@alum.mit.edu


if isempty(array), array=realmax; return; end

if nargin==1
 out=min(array(:));
elseif nargin==2
 if islogical(dim)
  if any(dim)
   out=min(array(dim));
  else
   out=realmax;
  end % if any(dim)
 else
  out=min(array,[],dim);
 end % if ~islogical(dim)
else
 if any(mask)
  if length(find(prod(array)>1))==1 %(vector)
   out=min(array(mask));
  else %matrix
   out1=ones(size(array))*realmax;
   out1(mask)=array(mask);
   out=min(out1,[],dim);
  end % if length(find(prod(array)>1))==1 %(vector)
 else
  out=min(array,[],dim); out(:)=realmax;
 end % if any(mask)
end % if nargin==1
outSize=size(out);
if length(outSize)==2 && outSize(1)>1 && outSize(2)==1 %switch to row vector
 out=out.';
end

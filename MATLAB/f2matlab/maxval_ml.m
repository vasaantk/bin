function out=maxval_ml(array,dim,mask)
% duplicates the functionality of fortran's maxval

if isempty(array), array=-realmax; return; end

if nargin==1
 out=max(array(:));
elseif nargin==2
 if islogical(dim)
  if any(dim)
   out=max(array(dim));
  else
   out=-realmax;
  end % if any(dim)
 else
  out=max(array,[],dim);
 end % if ~islogical(dim)
else
 if any(mask)
  if length(find(prod(array)>1))==1 %(vector)
   out=max(array(mask));
  else %matrix
   out1=ones(size(array))*(-realmax);
   out1(mask)=array(mask);
   out=max(out1,[],dim);
  end % if length(find(prod(array)>1))==1 %(vector)
 else
  out=max(array,[],dim); out(:)=-realmax;
 end % if any(mask)
end % if nargin==1
outSize=size(out);
if length(outSize)==2 && outSize(1)>1 && outSize(2)==1 %switch to row vector
 out=out.';
end
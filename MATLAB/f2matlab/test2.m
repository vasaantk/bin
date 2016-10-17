function test1(varargin)
 clear all; %clear functions;

 persistent a b c d ; 

 if isempty(a), a=0; end;
 if isempty(b), b=0; end;
 if isempty(c), c=0; end;
 if isempty(d), d=0; end;

 a=1;
 b=2;
 c=3;
 d=4;

 [a]=subr(1,a);
 [b,a]=subr(4,b,a);
 [a,b,c]=subr(2,a,b,c);
 [a,b,c,d]=subr(3,a,b,c,d);

 [d,c]=subra(d,c);

end %program test1


function [outEntry1,outEntry2,outEntry3,outEntry4]=subr(whichEntry,inEntry1,inEntry2,inEntry3,inEntry4);
 persistent bb cc dd ; 

 if isempty(bb), bb=0; end;
 if isempty(cc), cc=0; end;
 if isempty(dd), dd=0; end;

 if whichEntry==1
  aa=inEntry1;
  varargin=inEntry2;
   'subr'
   'aa=',aa
  %return;


  outEntry2=varargin;
  outEntry1=aa;
 elseif whichEntry==2
  aa=inEntry1;
  bb=inEntry2;
  cc=inEntry3;
  % entry subr3(aa,bb,cc);
   'subr3'
   'aa=',aa
   'bb=',bb
   'cc=',cc
  %return;

  outEntry3=cc;
  outEntry2=bb;
  outEntry1=aa;
 elseif whichEntry==3
  aa=inEntry1;
  bb=inEntry2;
  cc=inEntry3;
  dd=inEntry4;
  % entry subr4(aa,bb,cc,dd);
   'subr4'
   'aa=',aa
   'bb=',bb
   'cc=',cc
   'dd=',dd



  outEntry4=dd;
  outEntry3=cc;
  outEntry2=bb;
  outEntry1=aa;
 elseif whichEntry==4
  aa=inEntry1;
  bb=inEntry2;
  % entry subr2(aa,bb);
   'subr2'
   'aa=',aa
   'bb=',bb
  %return;


  outEntry2=bb;
  outEntry1=aa;
 end %entry choice
end %subroutine subr








function [aa,bb]=subra(aa,bb,varargin);


  'in subra'
  'aa=',aa
  'bb=',bb

 [aa,bb]=subr(4,aa,bb);

end %subroutine subra




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% extra functions as needed by the translation %%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% extra functions as needed by the translation %%%%%%%%%%%


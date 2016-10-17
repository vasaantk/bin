function main(varargin)

%*****************************************************************************80
%
%! MINPACK_PRB runs the MINPACK tests.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

clear all; %clear functions;


timestamp( );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''MINPACK_PRB''');
[writeErrFlag]=writeFmt(1,['%c'],'''  FORTRAN90 version''');
[writeErrFlag]=writeFmt(1,['%c'],'''  A set of tests for MINPACK.''');

test01( );
test02( );
test03( );
test04( );
test05( );
test06( );
test07( );
test08( );
test09( );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''MINPACK_PRB''');
[writeErrFlag]=writeFmt(1,['%c'],'''  Normal end of execution.''');

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
timestamp( );

%stop
end %program main
function test01(varargin)

%*****************************************************************************80
%
%! TEST01 tests CHKDER.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent err fjac fvec fvecp i ido iflag j ldfjac m mode n x xp ; 

 if isempty(n), n = 5; end;
 if isempty(m), m = n; end;
 if isempty(ldfjac), ldfjac = n; end;

 if isempty(err), err=zeros(m,1); end;
 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(fvecp), fvecp=zeros(m,1); end;
 if isempty(i), i=0; end;
 if isempty(ido), ido=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(j), j=0; end;
 if isempty(mode), mode=0; end;
 if isempty(x), x=zeros(n,1); end;
 if isempty(xp), xp=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST01''');
[writeErrFlag]=writeFmt(1,['%c'],'''  CHKDER compares a user supplied jacobian''');
[writeErrFlag]=writeFmt(1,['%c'],'''  and a finite difference approximation to it''');
[writeErrFlag]=writeFmt(1,['%c'],'''  and judges whether the jacobian is correct.''');

for ido = 1: 2;

if( ido == 1 );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''  On the first test, use a correct jacobian.''');

elseif( ido == 2 ) ;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''  Repeat the test, but use a "bad" jacobian''');
[writeErrFlag]=writeFmt(1,['%c'],'''  and see if the routine notices!''');

end;
%
%  Set the point at which the test is to be made:
%
x([1:n]) = 0.5d+00;

[ n, x]=r8vec_print ( n, x, '  Evaluation point X:' );

mode = 1;
[ m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err ]=chkder( m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err );
iflag = 1;

[ n, x, fvec, fjac, ldfjac, iflag ]=f01( n, x, fvec, fjac, ldfjac, iflag );
[ n, xp, fvecp, fjac, ldfjac, iflag ]=f01( n, xp, fvecp, fjac, ldfjac, iflag );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''  Sampled function values F(X) and F(XP)''');
[writeErrFlag]=writeFmt(1,['%c'],''' ''');
for i = 1: m;
[writeErrFlag]=writeFmt(1,['%3d',repmat('%14.6g',1,2)],'i','fvec(i)','fvecp(i)');
end; i = fix(m+1);

iflag = 2;
[ n, x, fvec, fjac, ldfjac, iflag ]=f01( n, x, fvec, fjac, ldfjac, iflag );
%
%  Here's where we put a mistake into the jacobian, on purpose.
%
if( ido == 2 );
fjac(1,1) = 1.01d+00 .* fjac(1,1);
fjac(2,3) = - fjac(2,3);
end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''  Computed jacobian''');
[writeErrFlag]=writeFmt(1,['%c'],''' ''');
for i = 1: m;
[writeErrFlag]=writeFmt(1,[repmat('%14.6g',1,5)],'fjac(i,[1:n])');
end; i = fix(m+1);

mode = 2;
[ m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err ]=chkder( m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''  CHKDER gradient component error estimates:''');
[writeErrFlag]=writeFmt(1,['%c'],'''     > 0.5, the component is probably correct.''');
[writeErrFlag]=writeFmt(1,['%c'],'''     < 0.5, the component is probably incorrect.''');
[writeErrFlag]=writeFmt(1,['%c'],''' ''');
for i = 1: m;
[writeErrFlag]=writeFmt(1,['%6d','%14.6g'],'i','err(i)');
end; i = fix(m+1);

end; ido = fix(2+1);

return;
end %subroutine test01
function [n, x, fvec, fjac, ldfjac, iflag]=f01( n, x, fvec, fjac, ldfjac, iflag );

%*****************************************************************************80
%
%! F01 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    17 May 2001
%
%  Author:
%
%    John Burkardt
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the number of variables.
%
%    Input, real ( kind = 8 ) X(N), the variable values.
%
%    Output, real ( kind = 8 ) FVEC(N), the function values at X,
%    if IFLAG = 1.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), the N by N jacobian at X,
%    if IFLAG = 2.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of FJAC,
%    which must be at least N.
%
%    Input, integer ( kind = 4 ) IFLAG:
%    1, please compute F(I) (X).
%    2, please compute FJAC(I,J) (X).
%


persistent i j prod_ml ; 

fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(prod_ml), prod_ml=0; end;
%
%  If IFLAG is 1, we are supposed to evaluate F(X).
%
if( iflag == 1 );

for i = 1: n - 1;
fvec(i) = x(i) - real( n + 1) + sum(sum( x([1:n]) ));
end; i = fix(n - 1+1);

fvec(n) = prod(x([1:n])) - 1.0d+00;
%
%  If IFLAG is 2, we are supposed to evaluate FJAC(I,J) = d F(I)/d X(J)
%
elseif( iflag == 2 ) ;

fjac([1:n-1],[1:n]) = 1.0d+00;

for i = 1: n - 1;
fjac(i,i) = 2.0d+00;
end; i = fix(n - 1+1);

prod_ml = prod(x([1:n]));

for j = 1: n;
fjac(n,j) = prod_ml ./ x(j);
end; j = fix(n+1);

end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine f01
function test02(varargin)

%*****************************************************************************80
%
%! TEST02 tests HYBRD1.
%
%  Discussion:
%
%    This is an example of what your main program would look
%    like if you wanted to use MINPACK to solve N nonlinear equations
%    in N unknowns.  In this version, we avoid computing the jacobian
%    matrix, and request that MINPACK approximate it for us.
%
%    The set of nonlinear equations is:
%
%      x1**2 - 10 * x1 + x2**2 + 8 = 0
%      x1 * x2**2 + x1 - 10 * x2 + 8 = 0
%
%    with solution x1 = x2 = 1
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fvec iflag info n tol x ; 

 if isempty(n), n = 2; end;

 if isempty(fvec), fvec=zeros(n,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST02''');
[writeErrFlag]=writeFmt(1,['%c'],'''  HYBRD1 solves a nonlinear system of equations.''');

x([1:2]) =[ 3.0d+00, 0.0d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ n, x, fvec, iflag ]=f02( n, x, fvec, iflag );
[ n, fvec]=r8vec_print ( n, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, n, x, fvec, tol, info ]=hybrd1( @f02, n, x, fvec, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ n, fvec]=r8vec_print ( n, fvec, '  F(X):' );

return;
end %subroutine test02
function [n, x, fvec, iflag]=f02( n, x, fvec, iflag );

%*****************************************************************************80
%
%! F02 is a function routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%




fvec(1) = x(1) .* x(1) - 10.0d+00 .* x(1) + x(2) .* x(2) + 8.0d+00;
fvec(2) = x(1) .* x(2) .* x(2) + x(1) - 10.0d+00 .* x(2) + 8.0d+00;

return;
end %subroutine f02
function test03(varargin)

%*****************************************************************************80
%
%! TEST03 tests HYBRJ1.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fjac fvec iflag info ldfjac n tol x ; 

 if isempty(n), n = 2; end;
 if isempty(ldfjac), ldfjac = n; end;

 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fvec), fvec=zeros(n,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST03''');
[writeErrFlag]=writeFmt(1,['%c'],'''  HYBRJ1 solves a nonlinear system of equations.''');

x([1:2]) =[ 3.0d+00, 0.0d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ n, x, fvec, iflag ]=f02( n, x, fvec, iflag );
[ n, fvec]=r8vec_print ( n, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, n, x, fvec, fjac, ldfjac, tol, info ]=hybrj1( @f03, n, x, fvec, fjac, ldfjac, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ n, fvec]=r8vec_print ( n, fvec, '  F(X):' );

return;
end %subroutine test03
function [n, x, fvec, fjac, ldfjac, iflag]=f03( n, x, fvec, fjac, ldfjac, iflag );

%*****************************************************************************80
%
%! F03 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%



fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);

if( iflag == 1 );

fvec(1) = x(1) .* x(1) - 10.0d+00 .* x(1) + x(2) .* x(2) + 8.0d+00;
fvec(2) = x(1) .* x(2) .* x(2) + x(1) - 10.0d+00 .* x(2) + 8.0d+00;

elseif( iflag == 2 ) ;

fjac(1,1) = 2.0d+00 .* x(1) - 10.0d+00;
fjac(1,2) = 2.0d+00 .* x(2);
fjac(2,1) = x(2) .* x(2) + 1.0d+00;
fjac(2,2) = 2.0d+00 .* x(1) .* x(2) - 10.0d+00;

end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine f03
function test04(varargin)

%*****************************************************************************80
%
%! TEST04 tests LMDER1.
%
%  Discussion:
%
%    LMDER1 solves M nonlinear equations in N unknowns, with M >= N.
%
%    LMDER1 seeks a solution X minimizing the euclidean norm of the residual.
%
%    In this example, the set of equations is actually linear, but
%    normally they are nonlinear.
%
%    In this problem, we have a set of pairs of data points, and we
%    seek a functional relationship between them.  We assume the
%    relationship is of the form
%
%      y = a * x + b
%
%    and we want to know the values of a and b.  Therefore, we would like
%    to find numbers a and b which satisfy a set of equations.
%
%    The data points are (2,2), (4,11), (6,28) and (8,40).
%
%    Therefore, the equations we want to satisfy are:
%
%      a * 2 + b -  2 = 0
%      a * 4 + b - 11 = 0
%      a * 6 + b - 28 = 0
%      a * 8 + b - 40 = 0
%
%    The least squares solution of this system is a=6.55, b=-12.5,
%    In other words, the line y=6.55*x-12.5 is the line which 'best'
%    models the data in the least squares sense.
%
%    Problems with more variables, or higher degree polynomials, would
%    be solved similarly.  For example, suppose we have (x,y,z) data,
%    and we wish to find a relationship of the form f(x,y,z).  We assume
%    that x and y occur linearly, and z quadratically.  Then the equation
%    we seek has the form:
%
%      a*x+b*y+c*z + d*z*z + e = 0
%
%    and, supposing that our first two points were (1,2,3), (1,3,8), our set of
%    equations would begin:
%
%      a*1+b*2+c*3 + d*9  + e = 0
%      a*1+b*3+c*8 + d*64 + e = 0
%
%    and so on.
%
%    M is the number of equations, which in this case is the number of
%    (x,y) data values.
%
%    N is the number of variables, which in this case is the number of
%    'free' coefficients in the relationship we are trying to determine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    31 October 2005
%
%  Author:
%
%    John Burkardt
%

persistent fjac fvec iflag info ldfjac m n tol x ; 

 if isempty(m), m = 4; end;
 if isempty(n), n = 2; end;
 if isempty(ldfjac), ldfjac = m; end;

 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST04''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMDER1 minimizes M functions in N variables.''');

x([1:2]) =[ 0.0d+00, 5.0d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ m, n, x, fvec, fjac, ldfjac, iflag ]=f04( m, n, x, fvec, fjac, ldfjac, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, fjac, ldfjac, tol, info ]=lmder1( @f04, m, n, x, fvec, fjac, ldfjac, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test04
function [m, n, x, fvec, fjac, ldfjac, iflag]=f04( m, n, x, fvec, fjac, ldfjac, iflag );

%*****************************************************************************80
%
%! F04 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent i xdat ydat ; 

fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(i), i=0; end;
 if isempty(xdat), xdat([1:4]) =[2.0d+00,  4.0d+00,  6.0d+00,  8.0d+00 ]; end;
 if isempty(ydat), ydat([1:4]) =[2.0d+00, 11.0d+00, 28.0d+00, 40.0d+00 ]; end;

if( iflag == 1 );

fvec([1:m]) = x(1) .* xdat([1:m]) + x(2) - ydat([1:m]);

elseif( iflag == 2 ) ;

fjac([1:m],1) = xdat([1:m]);
fjac([1:m],2) = 1.0d+00;

else;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''F04 - Fatal error!''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Called with unexpected value of IFLAG = ''','iflag');
warning(['stop encountered in original fortran code  ',char(10),';']);
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return

end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine f04
function test05(varargin)

%*****************************************************************************80
%
%! TEST05 tests LMDER1.
%
%  Discussion:
%
%    LMDER1 solves M nonlinear equations in n unknowns, where M is greater
%    than N.  The functional fit is nonlinear this time, of the form
%
%      y=a+b*x**c,
%
%    with x and y data, and a, b and c unknown.
%
%    This problem is set up so that the data is exactly fit by by
%    a=1, b=3, c=2.  Normally, the data would only be approximately
%    fit by the best possible solution.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fjac fvec iflag info ldfjac m n tol x ; 

 if isempty(m), m = 10; end;
 if isempty(n), n = 3; end;
 if isempty(ldfjac), ldfjac = m; end;

 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST05''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMDER1 minimizes M functions in N variables.''');

x([1:3]) =[ 0.0d+00, 5.0d+00, 1.3d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ m, n, x, fvec, fjac, ldfjac, iflag ]=f05( m, n, x, fvec, fjac, ldfjac, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, fjac, ldfjac, tol, info ]=lmder1( @f05, m, n, x, fvec, fjac, ldfjac, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test05
function [m, n, x, fvec, fjac, ldfjac, iflag]=f05( m, n, x, fvec, fjac, ldfjac, iflag );

%*****************************************************************************80
%
%! F05 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent xdat ydat ; 

fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(xdat), xdat([1:10]) =[1.0d+00, 2.0d+00, 3.0d+00, 4.0d+00, 5.0d+00,6.0d+00, 7.0d+00, 8.0d+00, 9.0d+00, 10.0d+00 ]; end;
 if isempty(ydat), ydat([1:10]) =[4.0d+00, 13.0d+00, 28.0d+00, 49.0d+00, 76.0d+00,109.0d+00, 148.0d+00, 193.0d+00, 244.0d+00, 301.0d+00 ]; end;

if( iflag == 1 );

fvec([1:m]) = x(1) + x(2) .* xdat([1:m]).^x(3) - ydat([1:m]);

elseif( iflag == 2 ) ;

fjac([1:m],1) = 1.0d+00;
fjac([1:m],2) = xdat([1:m]).^x(3);
fjac([1:m],3) = x(2) .* log( xdat([1:m]) ) .* xdat([1:m]).^x(3);

end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine f05
function test06(varargin)

%*****************************************************************************80
%
%! TEST06 tests LMDIF1.
%
%  Discussion:
%
%    LMDIF1 solves M nonlinear equations in N unknowns, where M is greater
%    than N.  Generally, you cannot get a solution vector x which will satisfy
%    all the equations.  That is, the vector equation f(x)=0 cannot
%    be solved exactly.  Instead, minpack seeks a solution x so that
%    the euclidean norm transpose(f(x))*f(x) is minimized.  The size
%    of the euclidean norm is a measure of how good the solution is.
%
%    In this example, the set of equations is actually linear, but
%    normally they are nonlinear.
%
%    In this problem, we have a set of pairs of data points, and we
%    seek a functional relationship between them.  We assume the
%    relationship is of the form
%
%      y=a*x+b
%
%    and we want to know the values of a and b.  Therefore, we would like
%    to find numbers a and b which satisfy a set of equations.
%
%    The data points are (2,2), (4,11), (6,28) and (8,40).
%
%    Therefore, the equations we want to satisfy are:
%
%      a * 2 + b -  2 = 0
%      a * 4 + b - 11 = 0
%      a * 6 + b - 28 = 0
%      a * 8 + b - 40 = 0
%
%    The least squares solution of this system is a=6.55, b=-12.5,
%    In other words, the line y=6.55*x-12.5 is the line which 'best'
%    models the data in the least squares sense.
%
%    Problems with more variables, or higher degree polynomials, would
%    be solved similarly.  For example, suppose we have (x,y,z) data,
%    and we wish to find a relationship of the form f(x,y,z).  We assume
%    that x and y occur linearly, and z quadratically.  Then the equation
%    we seek has the form:
%
%      a*x+b*y+c*z + d*z*z + e = 0
%
%    and, supposing that our first two points were (1,2,3), (1,3,8), our set of
%    equations would begin:
%
%      a*1+b*2+c*3 + d*9  + e = 0
%      a*1+b*3+c*8 + d*64 + e = 0
%
%    and so on.
%
%    M is the number of equations, which in this case is the number of
%    (x,y) data values.
%
%    N is the number of variables, which in this case is the number of
%    'free' coefficients in the relationship we are trying to determine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fvec iflag info m n tol x ; 

 if isempty(m), m = 4; end;
 if isempty(n), n = 2; end;

 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST06''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMDIF1 minimizes M functions in N variables.''');

x([1:2]) =[ 0.0d+00, 5.0d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ m, n, x, fvec, iflag ]=f06( m, n, x, fvec, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, tol, info ]=lmdif1( @f06, m, n, x, fvec, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test06
function [m, n, x, fvec, iflag]=f06( m, n, x, fvec, iflag );

%*****************************************************************************80
%
%! F06 is a function routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent xdat ydat ; 

 if isempty(xdat), xdat([1:4]) =[2.0d+00,  4.0d+00,  6.0d+00,  8.0d+00 ]; end;
 if isempty(ydat), ydat([1:4]) =[2.0d+00, 11.0d+00, 28.0d+00, 40.0d+00 ]; end;

fvec([1:m]) = x(1) .* xdat([1:m]) + x(2) - ydat([1:m]);

return;
end %subroutine f06
function test07(varargin)

%*****************************************************************************80
%
%! TEST07 tests LMDIF1.
%
%  Discussion:
%
%    LMDIF1 solves M nonlinear equations in N unknowns, where M is greater
%    than N.  It is similar to test02, except that the functional fit is
%    nonlinear this time, of the form
%
%      y = a + b * x**c,
%
%    with x and y data, and a, b and c unknown.
%
%    This problem is set up so that the data is exactly fit by by
%    a=1, b=3, c=2.  Normally, the data would only be approximately
%    fit by the best possible solution.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fvec iflag info m n tol x ; 

 if isempty(m), m = 10; end;
 if isempty(n), n = 3; end;

 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST07''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMDIF1 minimizes M functions in N variables.''');

x([1:3]) =[ 0.0d+00, 5.0d+00, 1.3d+00 ];
[ n, x]=r8vec_print ( n, x, '  X:' );
iflag = 1;
[ m, n, x, fvec, iflag ]=f07( m, n, x, fvec, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, tol, info ]=lmdif1( @f07, m, n, x, fvec, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test07
function [m, n, x, fvec, iflag]=f07( m, n, x, fvec, iflag );

%*****************************************************************************80
%
%! F07 is a function routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent xdat ydat ; 

 if isempty(xdat), xdat([1:10]) =[1.0d+00, 2.0d+00, 3.0d+00, 4.0d+00, 5.0d+00,6.0d+00, 7.0d+00, 8.0d+00, 9.0d+00, 10.0d+00 ]; end;
 if isempty(ydat), ydat([1:10]) =[4.0d+00, 13.0d+00, 28.0d+00, 49.0d+00, 76.0d+00,109.0d+00, 148.0d+00, 193.0d+00, 244.0d+00, 301.0d+00 ]; end;

fvec([1:m]) = x(1) + x(2) .* xdat([1:m]).^x(3) - ydat([1:m]);

return;
end %subroutine f07
function test08(varargin)

%*****************************************************************************80
%
%! TEST08 tests LMSTR1.
%
%  Discussion:
%
%    LMSTR1 solves M nonlinear equations in N unknowns, where M is greater
%    than N.  Generally, you cannot get a solution vector x which will satisfy
%    all the equations.  That is, the vector equation f(x)=0 cannot
%    be solved exactly.  Instead, minpack seeks a solution x so that
%    the euclidean norm transpose(f(x))*f(x) is minimized.  The size
%    of the euclidean norm is a measure of how good the solution is.
%
%    In this example, the set of equations is actually linear, but
%    normally they are nonlinear.
%
%    In this problem, we have a set of pairs of data points, and we
%    seek a functional relationship between them.  We assume the
%    relationship is of the form
%
%      y=a*x+b
%
%    and we want to know the values of a and b.  Therefore, we would like
%    to find numbers a and b which satisfy a set of equations.
%
%    The data points are (2,2), (4,11), (6,28) and (8,40).
%
%    Therefore, the equations we want to satisfy are:
%
%      a * 2 + b -  2 = 0
%      a * 4 + b - 11 = 0
%      a * 6 + b - 28 = 0
%      a * 8 + b - 40 = 0
%
%    The least squares solution of this system is a=6.55, b=-12.5,
%    In other words, the line y=6.55*x-12.5 is the line which 'best'
%    models the data in the least squares sense.
%
%    Problems with more variables, or higher degree polynomials, would
%    be solved similarly.  For example, suppose we have (x,y,z) data,
%    and we wish to find a relationship of the form f(x,y,z).  We assume
%    that x and y occur linearly, and z quadratically.  Then the equation
%    we seek has the form:
%
%      a*x + b*y + c*z + d*z*z + e = 0
%
%    and, supposing that our first two points were (1,2,3), (1,3,8), our set of
%    equations would begin:
%
%      a*1 + b*2 + c*3 + d*9  + e = 0
%      a*1 + b*3 + c*8 + d*64 + e = 0
%
%    and so on.
%
%    M is the number of equations, which in this case is the number of
%    (x,y) data values.
%
%    N is the number of variables, which in this case is the number of
%    'free' coefficients in the relationship we are trying to determine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fjac fjrow fvec iflag info ldfjac m n tol x ; 

 if isempty(m), m = 4; end;
 if isempty(n), n = 2; end;
 if isempty(ldfjac), ldfjac = m; end;

 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fjrow), fjrow=0; end;
 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST08''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMSTR1 minimizes M functions in N variables.''');

x([1:2]) =[ 0.0d+00, 5.0d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ m, n, x, fvec, fjrow, iflag ]=f08( m, n, x, fvec, fjrow, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, fjac, ldfjac, tol, info ]=lmstr1( @f08, m, n, x, fvec, fjac, ldfjac, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test08
function [m, n, x, fvec, fjrow, iflag]=f08( m, n, x, fvec, fjrow, iflag );

%*****************************************************************************80
%
%! F08 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent xdat ydat ; 

 if isempty(xdat), xdat([1:4]) =[2.0d+00,  4.0d+00,  6.0d+00,  8.0d+00 ]; end;
 if isempty(ydat), ydat([1:4]) =[2.0d+00, 11.0d+00, 28.0d+00, 40.0d+00 ]; end;

if( iflag == 1 );

fvec([1:m]) = x(1) .* xdat([1:m]) + x(2) - ydat([1:m]);

else;

fjrow(1) = xdat(iflag-1);
fjrow(2) = 1.0d+00;

end;

return;
end %subroutine f08
function test09(varargin)

%*****************************************************************************80
%
%! TEST09 tests LMSTR1.
%
%  Discussion:
%
%    LMSTR1 solves M nonlinear equations in N unknowns, where M is greater
%    than N.  This test is similar to test02, except that the functional fit
%    is nonlinear this time, of the form
%
%      y = a + b * x**c,
%
%    with x and y data, and a, b and c unknown.
%
%    This problem is set up so that the data is exactly fit by by
%    a=1, b=3, c=2.  Normally, the data would only be approximately
%    fit by the best possible solution.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%

persistent fjac fjrow fvec iflag info ldfjac m n tol x ; 

 if isempty(m), m = 10; end;
 if isempty(n), n = 3; end;
 if isempty(ldfjac), ldfjac = m; end;

 if isempty(fjac), fjac=zeros(ldfjac,n); end;
 if isempty(fjrow), fjrow=zeros(n,1); end;
 if isempty(fvec), fvec=zeros(m,1); end;
 if isempty(iflag), iflag=0; end;
 if isempty(info), info=0; end;
 if isempty(tol), tol=0; end;
 if isempty(x), x=zeros(n,1); end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'''TEST09''');
[writeErrFlag]=writeFmt(1,['%c'],'''  LMSTR1 minimizes M functions in N variables.''');

x([1:3]) =[ 0.0d+00, 5.0d+00, 1.3d+00 ];
[ n, x]=r8vec_print ( n, x, '  Initial X:' );
iflag = 1;
[ m, n, x, fvec, fjrow, iflag ]=f09( m, n, x, fvec, fjrow, iflag );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

tol = 0.00001d+00;

[dumvar1, m, n, x, fvec, fjac, ldfjac, tol, info ]=lmstr1( @f09, m, n, x, fvec, fjac, ldfjac, tol, info );

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c','%6d'],'''  Returned value of INFO = ''','info');
[ n, x]=r8vec_print ( n, x, '  X:' );
[ m, fvec]=r8vec_print ( m, fvec, '  F(X):' );

return;
end %subroutine test09
function [m, n, x, fvec, fjrow, iflag]=f09( m, n, x, fvec, fjrow, iflag );

%*****************************************************************************80
%
%! F09 is a function/jacobian routine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    30 December 2004
%
%  Author:
%
%    John Burkardt
%


persistent xdat ydat ; 

 if isempty(xdat), xdat([1:10]) =[1.0d+00, 2.0d+00, 3.0d+00, 4.0d+00, 5.0d+00,6.0d+00, 7.0d+00, 8.0d+00, 9.0d+00, 10.0d+00 ]; end;
 if isempty(ydat), ydat([1:10]) =[4.0d+00, 13.0d+00, 28.0d+00, 49.0d+00, 76.0d+00,109.0d+00, 148.0d+00, 193.0d+00, 244.0d+00, 301.0d+00 ]; end;

if( iflag == 1 );

fvec([1:m]) = x(1) + x(2) .* xdat([1:m]).^x(3) - ydat([1:m]);

else;

fjrow(1) = 1.0d+00;
fjrow(2) = xdat(iflag-1).^x(3);
fjrow(3) = x(2) .* log( xdat(iflag-1) ) .* xdat(iflag-1).^x(3);

end;

return;
end %subroutine f09






%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!





function [m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err]=chkder( m, n, x, fvec, fjac, ldfjac, xp, fvecp, mode, err );

%*****************************************************************************80
%
%! CHKDER checks the gradients of M functions of N variables.
%
%  Discussion:
%
%    CHKDER checks the gradients of M nonlinear functions in N variables,
%    evaluated at a point X, for consistency with the functions themselves.
%
%    The user calls CHKDER twice, first with MODE = 1 and then with MODE = 2.
%
%    MODE = 1.
%      On input,
%        X contains the point of evaluation.
%      On output,
%        XP is set to a neighboring point.
%
%    Now the user must evaluate the function and gradients at X, and the
%    function at XP.  Then the subroutine is called again:
%
%    MODE = 2.
%      On input,
%        FVEC contains the function values at X,
%        FJAC contains the function gradients at X.
%        FVECP contains the functions evaluated at XP.
%      On output,
%        ERR contains measures of correctness of the respective gradients.
%
%    The subroutine does not perform reliably if cancellation or
%    rounding errors cause a severe loss of significance in the
%    evaluation of a function.  Therefore, none of the components
%    of X should be unusually small (in particular, zero) or any
%    other value which may cause loss of significance.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) M, is the number of functions.
%
%    Input, integer ( kind = 4 ) N, is the number of variables.
%
%    Input, real ( kind = 8 ) X(N), the point at which the jacobian is to be
%    evaluated.
%
%    Input, real ( kind = 8 ) FVEC(M), is used only when MODE = 2.
%    In that case, it should contain the function values at X.
%
%    Input, real ( kind = 8 ) FJAC(LDFJAC,N), an M by N array.  When MODE = 2,
%    FJAC(I,J) should contain the value of dF(I)/dX(J).
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least M.
%
%    Output, real ( kind = 8 ) XP(N), on output with MODE = 1, is a neighboring
%    point of X, at which the function is to be evaluated.
%
%    Input, real ( kind = 8 ) FVECP(M), on input with MODE = 2, is the function
%    value at XP.
%
%    Input, integer ( kind = 4 ) MODE, should be set to 1 on the first call, and
%    2 on the second.
%
%    Output, real ( kind = 8 ) ERR(M).  On output when MODE = 2, ERR contains
%    measures of correctness of the respective gradients.  If there is no
%    severe loss of significance, then if ERR(I):
%      = 1.0D+00, the I-th gradient is correct,
%      = 0.0D+00, the I-th gradient is incorrect.
%      > 0.5D+00, the I-th gradient is probably correct.
%      < 0.5D+00, the I-th gradient is probably incorrect.
%


persistent eps_ml epsf epslog epsmch i j temp ; 

 if isempty(eps_ml), eps_ml=0; end;
 if isempty(epsf), epsf=0; end;
 if isempty(epslog), epslog=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(temp), temp=0; end;

epsmch = eps;
eps_ml = sqrt( epsmch );
%
%  MODE = 1.
%
if( mode == 1 );

for j = 1: n;
temp = eps_ml .* abs( x(j) );
if( temp == 0.0d+00 );
temp = eps_ml;
end;
xp(j) = x(j) + temp;
end; j = fix(n+1);
%
%  MODE = 2.
%
elseif( mode == 2 ) ;

epsf = 100.0d+00 .* epsmch;
epslog = log10( eps_ml );

err(:) = 0.0d+00;

for j = 1: n;
temp = abs( x(j) );
if( temp == 0.0d+00 );
temp = 1.0d+00;
end;
err([1:m]) = err([1:m]) + temp .* fjac([1:m],j);
end; j = fix(n+1);

for i = 1: m;

temp = 1.0d+00;

if( fvec(i) ~= 0.0d+00 && fvecp(i) ~= 0.0d+00 &&abs( fvecp(i)-fvec(i)) >= epsf .* abs( fvec(i) ) );
temp = eps_ml .* abs((fvecp(i)-fvec(i)) ./ eps_ml - err(i) )./( abs( fvec(i) ) + abs( fvecp(i) ) );
end;

err(i) = 1.0d+00;

if( epsmch < temp && temp < eps_ml );
err(i) =( log10( temp ) - epslog ) ./ epslog;
end;

if( eps_ml <= temp );
err(i) = 0.0d+00;
end;

end; i = fix(m+1);

end;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine chkder
function [n, r, lr, diag, qtb, delta, x]=dogleg( n, r, lr, diag, qtb, delta, x );

%*****************************************************************************80
%
%! DOGLEG finds the minimizing combination of Gauss-Newton and gradient steps.
%
%  Discussion:
%
%    Given an M by N matrix A, an N by N nonsingular diagonal
%    matrix D, an M-vector B, and a positive number DELTA, the
%    problem is to determine the convex combination X of the
%    Gauss-Newton and scaled gradient directions that minimizes
%    (A*X - B) in the least squares sense, subject to the
%    restriction that the euclidean norm of D*X be at most DELTA.
%
%    This subroutine completes the solution of the problem
%    if it is provided with the necessary information from the
%    QR factorization of A.  That is, if A = Q*R, where Q has
%    orthogonal columns and R is an upper triangular matrix,
%    then DOGLEG expects the full upper triangle of R and
%    the first N components of Q'*B.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the order of the matrix R.
%
%    Input, real ( kind = 8 ) R(LR), the upper triangular matrix R stored
%    by rows.
%
%    Input, integer ( kind = 4 ) LR, the size of the R array, which must be no less
%    than (N*(N+1))/2.
%
%    Input, real ( kind = 8 ) DIAG(N), the diagonal elements of the matrix D.
%
%    Input, real ( kind = 8 ) QTB(N), the first N elements of the vector Q'* B.
%
%    Input, real ( kind = 8 ) DELTA, is a positive upper bound on the
%    euclidean norm of D*X(1:N).
%
%    Output, real ( kind = 8 ) X(N), the desired convex combination of the
%    Gauss-Newton direction and the scaled gradient direction.
%


persistent alpha_ml bnorm epsmch gnorm i j jj k l qnorm sgnorm sum2 temp wa1 wa2 ; 

 if isempty(alpha_ml), alpha_ml=0; end;
 if isempty(bnorm), bnorm=0; end;
 if isempty(epsmch), epsmch=0; end;
 if isempty(gnorm), gnorm=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(jj), jj=0; end;
 if isempty(k), k=0; end;
 if isempty(l), l=0; end;
 if isempty(qnorm), qnorm=0; end;
 if isempty(sgnorm), sgnorm=0; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;

epsmch = eps;
%
%  Calculate the Gauss-Newton direction.
%
jj =fix(fix(( n .*( n + 1 ) ) ./ 2) + 1);

for k = 1: n;

j = fix(n - k + 1);
jj = fix(jj - k);
l = fix(jj + 1);
sum2 = 0.0d+00;

for i = j + 1: n;
sum2 = sum2 + r(l) .* x(i);
l = fix(l + 1);
end; i = fix(n+1);

temp = r(jj);

if( temp == 0.0d+00 );

l = fix(j);
for i = 1: j;
temp = max( temp, abs( r(l)) );
l = fix(l + n - i);
end; i = fix(j+1);

if( temp == 0.0d+00 );
temp = epsmch;
else;
temp = epsmch .* temp;
end;

end;

x(j) =( qtb(j) - sum2 ) ./ temp;

end; k = fix(n+1);
%
%  Test whether the Gauss-Newton direction is acceptable.
%
wa1([1:n]) = 0.0d+00;
wa2([1:n]) = diag([1:n]) .* x([1:n]);
[qnorm , n, wa2 ]=enorm( n, wa2 );

if( qnorm <= delta );
return;
end;
%
%  The Gauss-Newton direction is not acceptable.
%  Calculate the scaled gradient direction.
%
l = 1;
for j = 1: n;
temp = qtb(j);
for i = j: n;
wa1(i) = wa1(i) + r(l) .* temp;
l = fix(l + 1);
end; i = fix(n+1);
wa1(j) = wa1(j) ./ diag(j);
end; j = fix(n+1);
%
%  Calculate the norm of the scaled gradient.
%  Test for the special case in which the scaled gradient is zero.
%
[gnorm , n, wa1 ]=enorm( n, wa1 );
sgnorm = 0.0d+00;
alpha_ml = delta ./ qnorm;

if( gnorm ~= 0.0d+00 );
%
%  Calculate the point along the scaled gradient which minimizes the quadratic.
%
wa1([1:n]) =( wa1([1:n]) ./ gnorm ) ./ diag([1:n]);

l = 1;
for j = 1: n;
sum2 = 0.0d+00;
for i = j: n;
sum2 = sum2 + r(l) .* wa1(i);
l = fix(l + 1);
end; i = fix(n+1);
wa2(j) = sum2;
end; j = fix(n+1);

[temp , n, wa2 ]=enorm( n, wa2 );
sgnorm =( gnorm ./ temp ) ./ temp;
%
%  Test whether the scaled gradient direction is acceptable.
%
alpha_ml = 0.0d+00;
%
%  The scaled gradient direction is not acceptable.
%  Calculate the point along the dogleg at which the quadratic is minimized.
%
if( sgnorm < delta );

[bnorm , n, qtb ]=enorm( n, qtb );
temp =( bnorm ./ gnorm ) .*( bnorm ./ qnorm ) .*( sgnorm ./ delta );
temp = temp -( delta ./ qnorm ) .*( sgnorm ./ delta).^2+ sqrt(( temp -( delta ./ qnorm ) ).^2+( 1.0d+00 -( delta ./ qnorm ).^2 ).*( 1.0d+00 -( sgnorm ./ delta ).^2 ) );

alpha_ml =(( delta ./ qnorm ) .*( 1.0d+00 -( sgnorm ./ delta ).^2 ) ) ./ temp;

end;

end;
%
%  Form appropriate convex combination of the Gauss-Newton
%  direction and the scaled gradient direction.
%
temp =( 1.0d+00 - alpha_ml ) .* min( sgnorm, delta );

x([1:n]) = temp .* wa1([1:n]) + alpha_ml .* x([1:n]);

return;
end %subroutine dogleg
function [enormresult, n, x ]=enorm( n, x );

%*****************************************************************************80
%
%! ENORM computes the Euclidean norm of a vector.
%
%  Discussion:
%
%    This is an extremely simplified version of the original ENORM
%    routine, which has been renamed to 'ENORM2'.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, is the length of the vector.
%
%    Input, real ( kind = 8 ) X(N), the vector whose norm is desired.
%
%    Output, real ( kind = 8 ) ENORM, the Euclidean norm of the vector.
%

enormresult=[];
persistent enorm ; 

 if isempty(enormresult), enormresult=0; end;

enormresult = sqrt( sum(sum( x([1:n]).^2 )));

return;
end %function enorm
function [enorm2result, n, x ]=enorm2( n, x );

%*****************************************************************************80
%
%! ENORM2 computes the Euclidean norm of a vector.
%
%  Discussion:
%
%    This routine was named ENORM.  It has been renamed 'ENORM2',
%    and a simplified routine has been substituted.
%
%    The Euclidean norm is computed by accumulating the sum of
%    squares in three different sums.  The sums of squares for the
%    small and large components are scaled so that no overflows
%    occur.  Non-destructive underflows are permitted.  Underflows
%    and overflows do not occur in the computation of the unscaled
%    sum of squares for the intermediate components.
%
%    The definitions of small, intermediate and large components
%    depend on two constants, RDWARF and RGIANT.  The main
%    restrictions on these constants are that RDWARF**2 not
%    underflow and RGIANT**2 not overflow.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1
%    Argonne National Laboratory,
%    Argonne, Illinois.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, is the length of the vector.
%
%    Input, real ( kind = 8 ) X(N), the vector whose norm is desired.
%
%    Output, real ( kind = 8 ) ENORM2, the Euclidean norm of the vector.
%


enorm2result=[];
persistent agiant enorm2 i rdwarf rgiant s1 s2 s3 x1max x3max xabs ; 

 if isempty(agiant), agiant=0; end;
 if isempty(enorm2result), enorm2result=0; end;
 if isempty(i), i=0; end;
 if isempty(rdwarf), rdwarf=0; end;
 if isempty(rgiant), rgiant=0; end;
 if isempty(s1), s1=0; end;
 if isempty(s2), s2=0; end;
 if isempty(s3), s3=0; end;
 if isempty(xabs), xabs=0; end;
 if isempty(x1max), x1max=0; end;
 if isempty(x3max), x3max=0; end;

rdwarf = sqrt( realmin );
rgiant = sqrt( realmax );

s1 = 0.0d+00;
s2 = 0.0d+00;
s3 = 0.0d+00;
x1max = 0.0d+00;
x3max = 0.0d+00;
agiant = rgiant ./ real( n);

for i = 1: n;

xabs = abs( x(i) );

if( xabs <= rdwarf );

if( x3max < xabs );
s3 = 1.0d+00 + s3 .*( x3max ./ xabs ).^2;
x3max = xabs;
elseif( xabs ~= 0.0d+00 ) ;
s3 = s3 +( xabs ./ x3max ).^2;
end;

elseif( agiant <= xabs ) ;

if( x1max < xabs );
s1 = 1.0d+00 + s1 .*( x1max ./ xabs ).^2;
x1max = xabs;
else;
s1 = s1 +( xabs ./ x1max ).^2;
end;

else;

s2 = s2 + xabs.^2;

end;

end; i = fix(n+1);
%
%  Calculation of norm.
%
if( s1 ~= 0.0d+00 );

enorm2result = x1max .* sqrt( s1 +( s2 ./ x1max ) ./ x1max );

elseif( s2 ~= 0.0d+00 ) ;

if( x3max <= s2 );
enorm2result = sqrt( s2 .*( 1.0d+00 +( x3max ./ s2 ) .*( x3max .* s3 ) ) );
else;
enorm2result = sqrt( x3max .*(( s2 ./ x3max ) +( x3max .* s3 ) ) );
end;

else;

enorm2result = x3max .* sqrt( s3 );

end;

return;
end %function enorm2
function [fcn, n, x, fvec, fjac, ldfjac, iflag, ml, mu, epsfcn]=fdjac1( fcn, n, x, fvec, fjac, ldfjac, iflag, ml, mu, epsfcn );

%*****************************************************************************80
%
%! FDJAC1 estimates an N by N jacobian matrix using forward differences.
%
%  Discussion:
%
%    This subroutine computes a forward-difference approximation
%    to the N by N jacobian matrix associated with a specified
%    problem of N functions in N variables. If the jacobian has
%    a banded form, then function evaluations are saved by only
%    approximating the nonzero terms.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( n, x, fvec, iflag )
%
%      integer ( kind = 4 ) n
%
%      real fvec(n)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) N, the number of functions and variables.
%
%    Input, real ( kind = 8 ) X(N), the point where the jacobian is evaluated.
%
%    Input, real ( kind = 8 ) FVEC(N), the functions evaluated at X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), the N by N approximate
%    jacobian matrix.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of FJAC, which must
%    not be less than N.
%
%    Output, integer ( kind = 4 ) IFLAG, is an error flag returned by FCN.  If FCN
%    returns a nonzero value of IFLAG, then this routine returns immediately
%    to the calling program, with the value of IFLAG.
%
%    Input, integer ( kind = 4 ) ML, MU, specify the number of subdiagonals and
%    superdiagonals within the band of the jacobian matrix.  If the
%    jacobian is not banded, set ML and MU to N-1.
%
%    Input, real ( kind = 8 ) EPSFCN, is used in determining a suitable step
%    length for the forward-difference approximation.  This approximation
%    assumes that the relative errors in the functions are of the order of
%    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
%    the relative errors in the functions are of the order of the machine
%    precision.
%


persistent eps_ml epsmch h i j k msum temp wa1 wa2 ; 

 if isempty(eps_ml), eps_ml=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(h), h=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(k), k=0; end;
 if isempty(msum), msum=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;

epsmch = eps;

eps_ml = sqrt( max( epsfcn, epsmch ) );
msum = fix(ml + mu + 1);
%
%  Computation of dense approximate jacobian.
%
if( n <= msum );

for j = 1: n;

temp = x(j);
h = eps_ml .* abs( temp );
if( h == 0.0d+00 );
h = eps_ml;
end;

x(j) = temp + h;
[ n, x, wa1, iflag ]=fcn( n, x, wa1, iflag );

if( iflag < 0 );
 tempBreak=1;break;
end;

x(j) = temp;
fjac([1:n],j) =( wa1([1:n]) - fvec([1:n]) ) ./ h;

end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak

else;
%
%  Computation of banded approximate jacobian.
%
for k = 1: msum;

for j = k: msum: n;
wa2(j) = x(j);
h = eps_ml .* abs( wa2(j) );
if( h == 0.0d+00 );
h = eps_ml;
end;
x(j) = wa2(j) + h;
end; j = fix(n+ msum);

[ n, x, wa1, iflag ]=fcn( n, x, wa1, iflag );

if( iflag < 0 );
 tempBreak=1;break;
end;

for j = k: msum: n;

x(j) = wa2(j);

h = eps_ml .* abs( wa2(j) );
if( h == 0.0d+00 );
h = eps_ml;
end;

fjac([1:n],j) = 0.0d+00;

for i = 1: n;
if( j - mu <= i && i <= j + ml );
fjac(i,j) =( wa1(i) - fvec(i) ) ./ h;
end;
end; i = fix(n+1);

end; j = fix(n+ msum);

end; if ~exist('tempBreak','var'), k = msum+1; end; clear tempBreak

end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine fdjac1
function [fcn, m, n, x, fvec, fjac, ldfjac, iflag, epsfcn]=fdjac2( fcn, m, n, x, fvec, fjac, ldfjac, iflag, epsfcn );

%*****************************************************************************80
%
%! FDJAC2 estimates an M by N jacobian matrix using forward differences.
%
%  Discussion:
%
%    This subroutine computes a forward-difference approximation
%    to the M by N jacobian matrix associated with a specified
%    problem of M functions in N variables.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( m, n, x, fvec, iflag )
%      integer ( kind = 4 ) n
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) M, is the number of functions.
%
%    Input, integer ( kind = 4 ) N, is the number of variables.  N must not exceed M.
%
%    Input, real ( kind = 8 ) X(N), the point where the jacobian is evaluated.
%
%    Input, real ( kind = 8 ) FVEC(M), the functions evaluated at X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), the M by N approximate
%    jacobian matrix.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of FJAC, which must
%    not be less than M.
%
%    Output, integer ( kind = 4 ) IFLAG, is an error flag returned by FCN.  If FCN
%    returns a nonzero value of IFLAG, then this routine returns immediately
%    to the calling program, with the value of IFLAG.
%
%    Input, real ( kind = 8 ) EPSFCN, is used in determining a suitable
%    step length for the forward-difference approximation.  This approximation
%    assumes that the relative errors in the functions are of the order of
%    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
%    the relative errors in the functions are of the order of the machine
%    precision.
%


persistent eps_ml epsmch h i j temp wa ; 

 if isempty(eps_ml), eps_ml=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(h), h=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa), wa=zeros(m,1); end;

epsmch = eps;

eps_ml = sqrt( max( epsfcn, epsmch ) );

for j = 1: n;

temp = x(j);
h = eps_ml .* abs( temp );
if( h == 0.0d+00 );
h = eps_ml;
end;

x(j) = temp + h;
[ m, n, x, wa, iflag ]=fcn( m, n, x, wa, iflag );

if( iflag < 0 );
 tempBreak=1;break;
end;

x(j) = temp;
fjac([1:m],j) =( wa([1:m]) - fvec([1:m]) ) ./ h;

end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine fdjac2
function [fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode,factor, nprint, info, nfev, fjac, ldfjac, r, lr, qtf]=hybrd( fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode,factor, nprint, info, nfev, fjac, ldfjac, r, lr, qtf );

%*****************************************************************************80
%
%! HYBRD seeks a zero of N nonlinear equations in N variables.
%
%  Discussion:
%
%    HYBRD finds a zero of a system of N nonlinear functions in N variables
%    by a modification of the Powell hybrid method.  The user must provide a
%    subroutine which calculates the functions.  The jacobian is
%    then calculated by a forward-difference approximation.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( n, x, fvec, iflag )
%      integer ( kind = 4 ) n
%      real fvec(n)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) N, the number of functions and variables.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(N), the functions evaluated at the output X.
%
%    Input, real ( kind = 8 ) XTOL.  Termination occurs when the relative error
%    between two consecutive iterates is at most XTOL.  XTOL should be
%    nonnegative.
%
%    Input, integer ( kind = 4 ) MAXFEV.  Termination occurs when the number of
%    calls to FCN is at least MAXFEV by the end of an iteration.
%
%    Input, integer ( kind = 4 ) ML, MU, specify the number of subdiagonals and
%    superdiagonals within the band of the jacobian matrix.  If the jacobian
%    is not banded, set ML and MU to at least n - 1.
%
%    Input, real ( kind = 8 ) EPSFCN, is used in determining a suitable step
%    length for the forward-difference approximation.  This approximation
%    assumes that the relative errors in the functions are of the order of
%    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
%    the relative errors in the functions are of the order of the machine
%    precision.
%
%    Input/output, real ( kind = 8 ) DIAG(N).  If MODE = 1, then DIAG is set
%    internally.  If MODE = 2, then DIAG must contain positive entries that
%    serve as multiplicative scale factors for the variables.
%
%    Input, integer ( kind = 4 ) MODE, scaling option.
%    1, variables will be scaled internally.
%    2, scaling is specified by the input DIAG vector.
%
%    Input, real ( kind = 8 ) FACTOR, determines the initial step bound.  This
%    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
%    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
%    in the interval (0.1, 100) with 100 the recommended value.
%
%    Input, integer ( kind = 4 ) NPRINT, enables controlled printing of
%    iterates if it is positive.  In this case, FCN is called with IFLAG = 0 at
%    the beginning of the first iteration and every NPRINT iterations thereafter
%    and immediately prior to return, with X and FVEC available
%    for printing.  If NPRINT is not positive, no special calls
%    of FCN with IFLAG = 0 are made.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.
%    Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, relative error between two consecutive iterates is at most XTOL.
%    2, number of calls to FCN has reached or exceeded MAXFEV.
%    3, XTOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    4, iteration is not making good progress, as measured by the improvement
%       from the last five jacobian evaluations.
%    5, iteration is not making good progress, as measured by the improvement
%       from the last ten iterations.
%
%    Output, integer ( kind = 4 ) NFEV, the number of calls to FCN.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an N by N array which contains
%    the orthogonal matrix Q produced by the QR factorization of the final
%    approximate jacobian.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least N.
%
%    Output, real ( kind = 8 ) R(LR), the upper triangular matrix produced by
%    the QR factorization of the final approximate jacobian, stored rowwise.
%
%    Input, integer ( kind = 4 ) LR, the size of the R array, which must be no
%    less than (N*(N+1))/2.
%
%    Output, real ( kind = 8 ) QTF(N), contains the vector Q'*FVEC.
%


persistent actred delta epsmch fnorm fnorm1 gt i iflag iter iwa j jeval l msum ncfail ncsuc nslow1 nslow2 pnorm prered ratio sing sum2 temp wa1 wa2 wa3 wa4 xnorm ; 

 if isempty(actred), actred=0; end;
 if isempty(delta), delta=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(fnorm), fnorm=0; end;
 if isempty(fnorm1), fnorm1=0; end;
 if isempty(i), i=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(iter), iter=0; end;
 if isempty(iwa), iwa=zeros(1,1); end;
 if isempty(j), j=0; end;
 if isempty(jeval), jeval=false; end;
 if isempty(l), l=0; end;
 if isempty(msum), msum=0; end;
 if isempty(ncfail), ncfail=0; end;
 if isempty(nslow1), nslow1=0; end;
 if isempty(nslow2), nslow2=0; end;
 if isempty(ncsuc), ncsuc=0; end;
 if isempty(pnorm), pnorm=0; end;
 if isempty(prered), prered=0; end;
 if isempty(ratio), ratio=0; end;
 if isempty(sing), sing=false; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;
 if isempty(wa3), wa3=zeros(n,1); end;
 if isempty(wa4), wa4=zeros(n,1); end;
 if isempty(xnorm), xnorm=0; end;

 if isempty(gt), gt=false; end;

epsmch = eps;

info = 0;
iflag = 0;
nfev = 0;
%
%  Check the input parameters for errors.
%
if( n <= 0 );
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( xtol < 0.0d+00 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( maxfev <= 0 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( ml < 0 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( mu < 0 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( factor <= 0.0d+00 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( ldfjac < n ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( lr <fix(( n .*(n + 1) ) ./ 2) ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;





if( mode == 2 );

for j = 1: n;
if( diag(j) <= 0.0d+00 );
if( iflag < 0 );
 info = fix(iflag);
end;
iflag = 0;
if( 0 < nprint );
 [ n, x, fvec, iflag ]=fcn( n, x, fvec, iflag );
end;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;
end; j = fix(n+1);

end;
%
%  Evaluate the function at the starting point
%  and calculate its norm.
%
iflag = 1;
[ n, x, fvec, iflag ]=fcn( n, x, fvec, iflag );
nfev = 1;

if( iflag < 0 );
if( iflag < 0 );
 info = fix(iflag);
end;
iflag = 0;
if( 0 < nprint );
 [ n, x, fvec, iflag ]=fcn( n, x, fvec, iflag );
end;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;

[fnorm , n, fvec ]=enorm( n, fvec );
%
%  Determine the number of calls to FCN needed to compute the jacobian matrix.
%
msum = fix(min( ml+mu+1, n ));
%
%  Initialize iteration counter and monitors.
%
iter = 1;
ncsuc = 0;
ncfail = 0;
nslow1 = 0;
nslow2 = 0;
%
%  Beginning of the outer loop.
%
gt=false;
while (1);
if(~ gt);
jeval = true;
%
%  Calculate the jacobian matrix.
%
iflag = 2;
[ fcn, n, x, fvec, fjac, ldfjac, iflag, ml, mu, epsfcn ]=fdjac1( fcn, n, x, fvec, fjac, ldfjac, iflag, ml, mu, epsfcn );

nfev = fix(nfev + msum);
if( iflag < 0 );
  tempBreak=1;break;
end;
%
%  Compute the QR factorization of the jacobian.
%
[ n, n, fjac, ldfjac,dumvar5, iwa,dumvar7, wa1, wa2 ]=qrfac( n, n, fjac, ldfjac, false, iwa, 1, wa1, wa2 );
%
%  On the first iteration, if MODE is 1, scale according
%  to the norms of the columns of the initial jacobian.
%
if( iter == 1 );

if( mode ~= 2 );

diag([1:n]) = wa2([1:n]);
for j = 1: n;
if( wa2(j) == 0.0d+00 );
diag(j) = 1.0d+00;
end;
end; j = fix(n+1);

end;
%
%  On the first iteration, calculate the norm of the scaled X
%  and initialize the step bound DELTA.
%
wa3([1:n]) = diag([1:n]) .* x([1:n]);
[xnorm , n, wa3 ]=enorm( n, wa3 );
delta = factor .* xnorm;
if( delta == 0.0d+00 );
delta = factor;
end;

end;
%
%  Form Q' * FVEC and store in QTF.
%
qtf([1:n]) = fvec([1:n]);

for j = 1: n;

if( fjac(j,j) ~= 0.0d+00 );
temp = - dot( qtf([j:n]), fjac([j:n],j) ) ./ fjac(j,j);
qtf([j:n]) = qtf([j:n]) + fjac([j:n],j) .* temp;
end;

end; j = fix(n+1);
%
%  Copy the triangular factor of the QR factorization into R.
%
sing = false;

for j = 1: n;
l = fix(j);
for i = 1: j-1;
r(l) = fjac(i,j);
l = fix(l + n - i);
end; i = fix(j-1+1);
r(l) = wa1(j);
if( wa1(j) == 0.0d+00 );
 sing = true;
end;
end; j = fix(n+1);
%
%  Accumulate the orthogonal factor in FJAC.
%
[ n, n, fjac, ldfjac ]=qform( n, n, fjac, ldfjac );
%
%  Rescale if necessary.
%
if( mode ~= 2 );
for j = 1: n;
diag(j) = max( diag(j), wa2(j) );
end; j = fix(n+1);
end;
%
%  Beginning of the inner loop.
%
end;
gt=false;
%
%  If requested, call FCN to enable printing of iterates.
%
if( 0 < nprint );
iflag = 0;
if( rem( iter-1, nprint ) == 0);
[ n, x, fvec, iflag ]=fcn( n, x, fvec, iflag );
end;
if( iflag < 0 );
  tempBreak=1;break;
end;
end;
%
%  Determine the direction P.
%
[ n, r, lr, diag, qtf, delta, wa1 ]=dogleg( n, r, lr, diag, qtf, delta, wa1 );
%
%  Store the direction P and X + P.
%  Calculate the norm of P.
%
wa1([1:n]) = - wa1([1:n]);
wa2([1:n]) = x([1:n]) + wa1([1:n]);
wa3([1:n]) = diag([1:n]) .* wa1([1:n]);

[pnorm , n, wa3 ]=enorm( n, wa3 );
%
%  On the first iteration, adjust the initial step bound.
%
if( iter == 1 );
delta = min( delta, pnorm );
end;
%
%  Evaluate the function at X + P and calculate its norm.
%
iflag = 1;
[ n, wa2, wa4, iflag ]=fcn( n, wa2, wa4, iflag );
nfev = fix(nfev + 1);

if( iflag < 0 );
 tempBreak=1;break;
end;

[fnorm1 , n, wa4 ]=enorm( n, wa4 );
%
%  Compute the scaled actual reduction.
%
actred = -1.0d+00;
if( fnorm1 < fnorm );
actred = 1.0d+00 -( fnorm1 ./ fnorm ).^2;
end;
%
%  Compute the scaled predicted reduction.
%
l = 1;
for i = 1: n;
sum2 = 0.0d+00;
for j = i: n;
sum2 = sum2 + r(l) .* wa1(j);
l = fix(l + 1);
end; j = fix(n+1);
wa3(i) = qtf(i) + sum2;
end; i = fix(n+1);

[temp , n, wa3 ]=enorm( n, wa3 );
prered = 0.0d+00;
if( temp < fnorm );
prered = 1.0d+00 -( temp ./ fnorm ).^2;
end;
%
%  Compute the ratio of the actual to the predicted reduction.
%
ratio = 0.0d+00;
if( 0.0d+00 < prered );
ratio = actred ./ prered;
end;
%
%  Update the step bound.
%
if( ratio < 0.1d+00 );

ncsuc = 0;
ncfail = fix(ncfail + 1);
delta = 0.5d+00 .* delta;

else;

ncfail = 0;
ncsuc = fix(ncsuc + 1);

if( 0.5d+00 <= ratio || 1 < ncsuc );
delta = max( delta, pnorm ./ 0.5d+00 );
end;

if( abs( ratio - 1.0d+00 ) <= 0.1d+00 );
delta = pnorm ./ 0.5d+00;
end;

end;
%
%  Test for successful iteration.
%
%  Successful iteration.
%  Update X, FVEC, and their norms.
%
if( 0.0001d+00 <= ratio );
x([1:n]) = wa2([1:n]);
wa2([1:n]) = diag([1:n]) .* x([1:n]);
fvec([1:n]) = wa4([1:n]);
[xnorm , n, wa2 ]=enorm( n, wa2 );
fnorm = fnorm1;
iter = fix(iter + 1);
end;
%
%  Determine the progress of the iteration.
%
nslow1 = fix(nslow1 + 1);
if( 0.001d+00 <= actred );
nslow1 = 0;
end;

if( jeval );
nslow2 = fix(nslow2 + 1);
end;

if( 0.1d+00 <= actred );
nslow2 = 0;
end;
%
%  Test for convergence.
%
if( delta <= xtol .* xnorm || fnorm == 0.0d+00 );
info = 1;
end;

if( info ~= 0 );
 tempBreak=1;break;
end;
%
%  Tests for termination and stringent tolerances.
%
if( maxfev <= nfev );
info = 2;
end;

if( 0.1d+00 .* max( 0.1d+00 .* delta, pnorm ) <= epsmch .* xnorm );
info = 3;
end;

if( nslow2 == 5 );
info = 4;
end;

if( nslow1 == 10 );
 info = 5;
end;
if( info ~= 0 );
  tempBreak=1;break;
end;
%
%  Criterion for recalculating jacobian approximation
%  by forward differences.
%
if( ncfail == 2 );
 continue;
end;
%
%  Calculate the rank one modification to the jacobian
%  and update QTF if necessary.
%
for j = 1: n;
sum2 = dot( wa4([1:n]), fjac([1:n],j) );
wa2(j) =( sum2 - wa3(j) ) ./ pnorm;
wa1(j) = diag(j) .*(( diag(j) .* wa1(j) ) ./ pnorm );
if( 0.0001d+00 <= ratio );
qtf(j) = sum2;
end;
end; j = fix(n+1);
%
%  Compute the QR factorization of the updated jacobian.
%
[ n, n, r, lr, wa1, wa2, wa3, sing ]=r1updt( n, n, r, lr, wa1, wa2, wa3, sing );
[ n, n, fjac, ldfjac, wa2, wa3 ]=r1mpyq( n, n, fjac, ldfjac, wa2, wa3 );
[dumvar1, n, qtf,dumvar4, wa2, wa3 ]=r1mpyq( 1, n, qtf, 1, wa2, wa3 );
%
%  End of the inner loop.
%
jeval = false;
gt=true;
continue;
%
%  End of the outer loop.
%
end;
% 300 continue;
%
%  Termination, either normal or user imposed.
%
if( iflag < 0 );
info = fix(iflag);
end;

iflag = 0;

if( 0 < nprint );
[ n, x, fvec, iflag ]=fcn( n, x, fvec, iflag );
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine hybrd
function [fcn, n, x, fvec, tol, info]=hybrd1( fcn, n, x, fvec, tol, info );

%*****************************************************************************80
%
%! HYBRD1 seeks a zero of N nonlinear equations in N variables.
%
%  Discussion:
%
%    HYBRD1 finds a zero of a system of N nonlinear functions in N variables
%    by a modification of the Powell hybrid method.  This is done by using the
%    more general nonlinear equation solver HYBRD.  The user must provide a
%    subroutine which calculates the functions.  The jacobian is then
%    calculated by a forward-difference approximation.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( n, x, fvec, iflag )
%      integer ( kind = 4 ) n
%      real fvec(n)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) N, the number of functions and variables.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(N), the functions evaluated at the output X.
%
%    Input, real ( kind = 8 ) TOL.  Termination occurs when the algorithm
%    estimates that the relative error between X and the solution is at
%    most TOL.  TOL should be nonnegative.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the
%    description of FCN.
%    Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, algorithm estimates that the relative error between X and the
%       solution is at most TOL.
%    2, number of calls to FCN has reached or exceeded 200*(N+1).
%    3, TOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    4, the iteration is not making good progress.
%

persistent diag epsfcn factor fjac j ldfjac lr lwa maxfev ml mode mu nfev nprint qtf r xtol ; 

 if isempty(lwa), lwa=0; end;

 if isempty(diag), diag=zeros(n,1); end;
 if isempty(epsfcn), epsfcn=0; end;
 if isempty(factor), factor=0; end;
 if isempty(fjac), fjac=zeros(n,n); end;
 if isempty(j), j=0; end;
 if isempty(ldfjac), ldfjac=0; end;
 if isempty(lr), lr=0; end;
 if isempty(maxfev), maxfev=0; end;
 if isempty(ml), ml=0; end;
 if isempty(mode), mode=0; end;
 if isempty(mu), mu=0; end;
 if isempty(nfev), nfev=0; end;
 if isempty(nprint), nprint=0; end;
 if isempty(qtf), qtf=zeros(n,1); end;
 if isempty(r), r=zeros(fix((n.*(n+1))./2),1); end;
 if isempty(xtol), xtol=0; end;

info = 0;

if( n <= 0 );
return;
elseif( tol < 0.0d+00 ) ;
return;
end;

maxfev = fix(200 .*( n + 1 ));
xtol = tol;
ml = fix(n - 1);
mu = fix(n - 1);
epsfcn = 0.0d+00;
mode = 2;
diag([1:n]) = 1.0d+00;
nprint = 0;
lr =fix(fix(( n .*( n + 1 ) ) ./ 2));
factor = 100.0d+00;
ldfjac = fix(n);

[ fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode,factor, nprint, info, nfev, fjac, ldfjac, r, lr, qtf ]=hybrd( fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode,factor, nprint, info, nfev, fjac, ldfjac, r, lr, qtf );

if( info == 5 );
info = 4;
end;

return;
end %subroutine hybrd1
function [fcn, n, x, fvec, fjac, ldfjac, xtol, maxfev, diag, mode,factor, nprint, info, nfev, njev, r, lr, qtf]=hybrj( fcn, n, x, fvec, fjac, ldfjac, xtol, maxfev, diag, mode,factor, nprint, info, nfev, njev, r, lr, qtf );

%*****************************************************************************80
%
%! HYBRJ seeks a zero of N nonlinear equations in N variables.
%
%  Discussion:
%
%    HYBRJ finds a zero of a system of N nonlinear functions in N variables
%    by a modification of the Powell hybrid method.  The user must provide a
%    subroutine which calculates the functions and the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the jacobian.  FCN should have the form:
%
%      subroutine fcn ( n, x, fvec, fjac, ldfjac, iflag )
%      integer ( kind = 4 ) ldfjac
%      integer ( kind = 4 ) n
%      real fjac(ldfjac,n)
%      real fvec(n)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If IFLAG = 1 on intput, FCN should calculate the functions at X and
%    return this vector in FVEC.
%    If IFLAG = 2 on input, FCN should calculate the jacobian at X and
%    return this matrix in FJAC.
%    To terminate the algorithm, the user may set IFLAG negative.
%
%    Input, integer ( kind = 4 ) N, the number of functions and variables.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(N), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an N by N matrix, containing
%    the orthogonal matrix Q produced by the QR factorization
%    of the final approximate jacobian.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the
%    array FJAC.  LDFJAC must be at least N.
%
%    Input, real ( kind = 8 ) XTOL.  Termination occurs when the relative error
%    between two consecutive iterates is at most XTOL.  XTOL should be
%    nonnegative.
%
%    Input, integer ( kind = 4 ) MAXFEV.  Termination occurs when the number of
%    calls to FCN is at least MAXFEV by the end of an iteration.
%
%    Input/output, real ( kind = 8 ) DIAG(N).  If MODE = 1, then DIAG is set
%    internally.  If MODE = 2, then DIAG must contain positive entries that
%    serve as multiplicative scale factors for the variables.
%
%    Input, integer ( kind = 4 ) MODE, scaling option.
%    1, variables will be scaled internally.
%    2, scaling is specified by the input DIAG vector.
%
%    Input, real ( kind = 8 ) FACTOR, determines the initial step bound.  This
%    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
%    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
%    in the interval (0.1, 100) with 100 the recommended value.
%
%    Input, integer ( kind = 4 ) NPRINT, enables controlled printing of iterates if it
%    is positive.  In this case, FCN is called with IFLAG = 0 at the
%    beginning of the first iteration and every NPRINT iterations thereafter
%    and immediately prior to return, with X and FVEC available
%    for printing.  If NPRINT is not positive, no special calls
%    of FCN with IFLAG = 0 are made.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG.  See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, relative error between two consecutive iterates is at most XTOL.
%    2, number of calls to FCN with IFLAG = 1 has reached MAXFEV.
%    3, XTOL is too small.  No further improvement in
%       the approximate solution X is possible.
%    4, iteration is not making good progress, as measured by the
%       improvement from the last five jacobian evaluations.
%    5, iteration is not making good progress, as measured by the
%       improvement from the last ten iterations.
%
%    Output, integer ( kind = 4 ) NFEV, the number of calls to FCN with IFLAG = 1.
%
%    Output, integer ( kind = 4 ) NJEV, the number of calls to FCN with IFLAG = 2.
%
%    Output, real ( kind = 8 ) R(LR), the upper triangular matrix produced
%    by the QR factorization of the final approximate jacobian, stored rowwise.
%
%    Input, integer ( kind = 4 ) LR, the size of the R array, which must be no less
%    than (N*(N+1))/2.
%
%    Output, real ( kind = 8 ) QTF(N), contains the vector Q'*FVEC.
%


persistent actred delta epsmch fnorm fnorm1 gt i iflag iter iwa j jeval l ncfail ncsuc nslow1 nslow2 pnorm prered ratio sing sum2 temp wa1 wa2 wa3 wa4 xnorm ; 

 if isempty(actred), actred=0; end;
 if isempty(delta), delta=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(fnorm), fnorm=0; end;
 if isempty(fnorm1), fnorm1=0; end;
 if isempty(i), i=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(iter), iter=0; end;
 if isempty(iwa), iwa=zeros(1,1); end;
 if isempty(j), j=0; end;
 if isempty(jeval), jeval=false; end;
 if isempty(l), l=0; end;
 if isempty(ncfail), ncfail=0; end;
 if isempty(nslow1), nslow1=0; end;
 if isempty(nslow2), nslow2=0; end;
 if isempty(ncsuc), ncsuc=0; end;
 if isempty(pnorm), pnorm=0; end;
 if isempty(prered), prered=0; end;
 if isempty(ratio), ratio=0; end;
 if isempty(sing), sing=false; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;
 if isempty(wa3), wa3=zeros(n,1); end;
 if isempty(wa4), wa4=zeros(n,1); end;
 if isempty(xnorm), xnorm=0; end;

 if isempty(gt), gt=false; end;

epsmch = eps;

info = 0;
iflag = 0;
nfev = 0;
njev = 0;
%
%  Check the input parameters for errors.
%
while (1);
if( n <= 0 );
 tempBreak=1;break;
end;

if( ldfjac < n ||xtol < 0.0d+00 ||maxfev <= 0 ||factor <= 0.0d+00 ||lr <fix((n.*(n + 1))./2) );
 tempBreak=1;break;
end;

if( mode == 2 );
for j = 1: n;
if( diag(j) <= 0.0d+00 );
  tempBreak=1;break;
end;
end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak
end;

%
%  Evaluate the function at the starting point
%  and calculate its norm.
%
iflag = 1;
[ n, x, fvec, fjac, ldfjac, iflag ]=fcn( n, x, fvec, fjac, ldfjac, iflag );
nfev = 1;
if( iflag < 0 );
  tempBreak=1;break;
end;
[fnorm , n, fvec ]=enorm( n, fvec );
%
%  Initialize iteration counter and monitors.
%
iter = 1;
ncsuc = 0;
ncfail = 0;
nslow1 = 0;
nslow2 = 0;
%
%  Beginning of the outer loop.
%
gt=false;
while (1);
if(~ gt);
%30 continue

jeval = true;
%
%  Calculate the jacobian matrix.
%
iflag = 2;
[ n, x, fvec, fjac, ldfjac, iflag ]=fcn( n, x, fvec, fjac, ldfjac, iflag );
njev = fix(njev + 1);
if( iflag < 0 );
  tempBreak=1;break;
end;
%
%  Compute the QR factorization of the jacobian.
%
[ n, n, fjac, ldfjac,dumvar5, iwa,dumvar7, wa1, wa2 ]=qrfac( n, n, fjac, ldfjac, false, iwa, 1, wa1, wa2 );
%
%  On the first iteration, if MODE is 1, scale according
%  to the norms of the columns of the initial jacobian.
%
if( iter == 1 );

if( mode ~= 2 );
diag([1:n]) = wa2([1:n]);
for j = 1: n;
if( wa2(j) == 0.0d+00 );
 diag(j) = 1.0d+00;
end;
end; j = fix(n+1);
end;
%
%  On the first iteration, calculate the norm of the scaled X
%  and initialize the step bound DELTA.
%
wa3([1:n]) = diag([1:n]) .* x([1:n]);
[xnorm , n, wa3 ]=enorm( n, wa3 );
delta = factor .* xnorm;
if( delta == 0.0d+00 );
delta = factor;
end;
end;
%
%  Form Q'*FVEC and store in QTF.
%
qtf([1:n]) = fvec([1:n]);

for j = 1: n;
if( fjac(j,j) ~= 0.0d+00 );
sum2 = 0.0d+00;
for i = j: n;
sum2 = sum2 + fjac(i,j) .* qtf(i);
end; i = fix(n+1);
temp = - sum2 ./ fjac(j,j);
for i = j: n;
qtf(i) = qtf(i) + fjac(i,j) .* temp;
end; i = fix(n+1);
end;
end; j = fix(n+1);
%
%  Copy the triangular factor of the QR factorization into R.
%
sing = false;
for j = 1: n;
l = fix(j);
for i = 1: j-1;
r(l) = fjac(i,j);
l = fix(l + n - i);
end; i = fix(j-1+1);
r(l) = wa1(j);
if( wa1(j) == 0.0d+00 );
sing = true;
end;
end; j = fix(n+1);
%
%  Accumulate the orthogonal factor in FJAC.
%
[ n, n, fjac, ldfjac ]=qform( n, n, fjac, ldfjac );
%
%  Rescale if necessary.
%
if( mode ~= 2 );
for j = 1: n;
diag(j) = max( diag(j), wa2(j) );
end; j = fix(n+1);
end;
%
%  Beginning of the inner loop.
%
end;
gt=false;
%
%  If requested, call FCN to enable printing of iterates.
%
if( 0 < nprint );
iflag = 0;
if( rem( iter-1, nprint ) == 0 );
[ n, x, fvec, fjac, ldfjac, iflag ]=fcn( n, x, fvec, fjac, ldfjac, iflag );
end;
if( iflag < 0 );
 tempBreak=1;break;
end;
end;
%
%  Determine the direction P.
%
[ n, r, lr, diag, qtf, delta, wa1 ]=dogleg( n, r, lr, diag, qtf, delta, wa1 );
%
%  Store the direction P and X + P.
%  Calculate the norm of P.
%
wa1([1:n]) = - wa1([1:n]);
wa2([1:n]) = x([1:n]) + wa1([1:n]);
wa3([1:n]) = diag([1:n]) .* wa1([1:n]);
[pnorm , n, wa3 ]=enorm( n, wa3 );
%
%  On the first iteration, adjust the initial step bound.
%
if( iter == 1 );
delta = min( delta, pnorm );
end;
%
%  Evaluate the function at X + P and calculate its norm.
%
iflag = 1;
[ n, wa2, wa4, fjac, ldfjac, iflag ]=fcn( n, wa2, wa4, fjac, ldfjac, iflag );
nfev = fix(nfev + 1);
if( iflag < 0 );
  tempBreak=1;break;
end;
[fnorm1 , n, wa4 ]=enorm( n, wa4 );
%
%  Compute the scaled actual reduction.
%
actred = -1.0d+00;
if( fnorm1 < fnorm );
actred = 1.0d+00 -( fnorm1 ./ fnorm ).^2;
end;
%
%  Compute the scaled predicted reduction.
%
l = 1;
for i = 1: n;
sum2 = 0.0d+00;
for j = i: n;
sum2 = sum2 + r(l) .* wa1(j);
l = fix(l + 1);
end; j = fix(n+1);
wa3(i) = qtf(i) + sum2;
end; i = fix(n+1);

[temp , n, wa3 ]=enorm( n, wa3 );
prered = 0.0d+00;
if( temp < fnorm );
prered = 1.0d+00 -( temp ./ fnorm ).^2;
end;
%
%  Compute the ratio of the actual to the predicted reduction.
%
if( 0.0d+00 < prered );
ratio = actred ./ prered;
else;
ratio = 0.0d+00;
end;
%
%  Update the step bound.
%
if( ratio < 0.1d+00 );
ncsuc = 0;
ncfail = fix(ncfail + 1);
delta = 0.5d+00 .* delta;
else;
ncfail = 0;
ncsuc = fix(ncsuc + 1);

if( 0.5d+00 <= ratio || 1 < ncsuc );
delta = max( delta, pnorm ./ 0.5d+00 );
end;

if( abs( ratio - 1.0d+00 ) <= 0.1d+00 );
delta = pnorm ./ 0.5d+00;
end;

end;
%
%  Test for successful iteration.
%

%
%  Successful iteration.
%  Update X, FVEC, and their norms.
%
if( 0.0001d+00 <= ratio );
x([1:n]) = wa2([1:n]);
wa2([1:n]) = diag([1:n]) .* x([1:n]);
fvec([1:n]) = wa4([1:n]);
[xnorm , n, wa2 ]=enorm( n, wa2 );
fnorm = fnorm1;
iter = fix(iter + 1);
end;
%
%  Determine the progress of the iteration.
%
nslow1 = fix(nslow1 + 1);
if( 0.001d+00 <= actred );
nslow1 = 0;
end;

if( jeval );
nslow2 = fix(nslow2 + 1);
end;

if( 0.1d+00 <= actred );
nslow2 = 0;
end;
%
%  Test for convergence.
%
if( delta <= xtol .* xnorm || fnorm == 0.0d+00 );
info = 1;
end;

if( info ~= 0 );
  tempBreak=1;break;
end;
%
%  Tests for termination and stringent tolerances.
%
if( maxfev <= nfev );
info = 2;
end;

if( 0.1d+00 .*max( 0.1d+00 .* delta, pnorm ) <= epsmch .* xnorm );
info = 3;
end;

if( nslow2 == 5 );
info = 4;
end;

if( nslow1 == 10 );
info = 5;
end;

if( info ~= 0 );
 tempBreak=1;break;
end;
%
%  Criterion for recalculating jacobian.
%
if( ncfail == 2 );
continue;
end;
%
%  Calculate the rank one modification to the jacobian
%  and update QTF if necessary.
%
for j = 1: n;
sum2 = dot( wa4([1:n]), fjac([1:n],j) );
wa2(j) =( sum2 - wa3(j) ) ./ pnorm;
wa1(j) = diag(j) .*(( diag(j) .* wa1(j) ) ./ pnorm );
if( ratio >= 0.0001d+00 );
qtf(j) = sum2;
end;
end; j = fix(n+1);
%
%  Compute the QR factorization of the updated jacobian.
%
[ n, n, r, lr, wa1, wa2, wa3, sing ]=r1updt( n, n, r, lr, wa1, wa2, wa3, sing );
[ n, n, fjac, ldfjac, wa2, wa3 ]=r1mpyq( n, n, fjac, ldfjac, wa2, wa3 );
[dumvar1, n, qtf,dumvar4, wa2, wa3 ]=r1mpyq( 1, n, qtf, 1, wa2, wa3 );
%
%  End of the inner loop.
%
jeval = false;
gt=true;
continue;

%
%  End of the outer loop.
%
end;

 tempBreak=1;break;
end;
% 300 continue;
%
%  Termination, either normal or user imposed.
%
if( iflag < 0 );
info = fix(iflag);
end;

iflag = 0;

if( nprint > 0 );
[ n, x, fvec, fjac, ldfjac, iflag ]=fcn( n, x, fvec, fjac, ldfjac, iflag );
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine hybrj
function [fcn, n, x, fvec, fjac, ldfjac, tol, info]=hybrj1( fcn, n, x, fvec, fjac, ldfjac, tol, info );

%*****************************************************************************80
%
%! HYBRJ1 seeks a zero of N nonlinear equations in N variables by Powell's method.
%
%  Discussion:
%
%    HYBRJ1 finds a zero of a system of N nonlinear functions in N variables
%    by a modification of the Powell hybrid method.  This is done by using the
%    more general nonlinear equation solver HYBRJ.  The user
%    must provide a subroutine which calculates the functions
%    and the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the jacobian.  FCN should have the form:
%
%      subroutine fcn ( n, x, fvec, fjac, ldfjac, iflag )
%      integer ( kind = 4 ) ldfjac
%      integer ( kind = 4 ) n
%      real fjac(ldfjac,n)
%      real fvec(n)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If IFLAG = 1 on intput, FCN should calculate the functions at X and
%    return this vector in FVEC.
%    If IFLAG = 2 on input, FCN should calculate the jacobian at X and
%    return this matrix in FJAC.
%    To terminate the algorithm, the user may set IFLAG negative.
%
%    Input, integer ( kind = 4 ) N, the number of functions and variables.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(N), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an N by N array which contains
%    the orthogonal matrix Q produced by the QR factorization of the final
%    approximate jacobian.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least N.
%
%    Input, real ( kind = 8 ) TOL.  Termination occurs when the algorithm
%    estimates that the relative error between X and the solution is at most
%    TOL.  TOL should be nonnegative.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, algorithm estimates that the relative error between X and the
%       solution is at most TOL.
%    2, number of calls to FCN with IFLAG = 1 has reached 100*(N+1).
%    3, TOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    4, iteration is not making good progress.
%


persistent diag factor j lr maxfev mode nfev njev nprint qtf r xtol ; 

 if isempty(diag), diag=zeros(n,1); end;
 if isempty(factor), factor=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(j), j=0; end;
 if isempty(lr), lr=0; end;
 if isempty(maxfev), maxfev=0; end;
 if isempty(mode), mode=0; end;
 if isempty(nfev), nfev=0; end;
 if isempty(njev), njev=0; end;
 if isempty(nprint), nprint=0; end;
 if isempty(qtf), qtf=zeros(n,1); end;
 if isempty(r), r=zeros(fix((n.*(n+1))./2),1); end;
 if isempty(xtol), xtol=0; end;

info = 0;

if( n <= 0 );
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( ldfjac < n ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( tol < 0.0d+00 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;

maxfev = fix(100 .*( n + 1 ));
xtol = tol;
mode = 2;
diag([1:n]) = 1.0d+00;
factor = 100.0d+00;
nprint = 0;
lr =fix(fix(( n .*( n + 1 ) ) ./ 2));

[ fcn, n, x, fvec, fjac, ldfjac, xtol, maxfev, diag, mode,factor, nprint, info, nfev, njev, r, lr, qtf ]=hybrj( fcn, n, x, fvec, fjac, ldfjac, xtol, maxfev, diag, mode,factor, nprint, info, nfev, njev, r, lr, qtf );

if( info == 5 );
info = 4;
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine hybrj1
function [fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf]=lmder( fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf );

%*****************************************************************************80
%
%! LMDER minimizes M functions in N variables by the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMDER minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm.
%    The user must provide a subroutine which calculates the functions
%    and the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the jacobian.  FCN should have the form:
%
%      subroutine fcn ( m, n, x, fvec, fjac, ldfjac, iflag )
%      integer ( kind = 4 ) ldfjac
%      integer ( kind = 4 ) n
%      real fjac(ldfjac,n)
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If IFLAG = 1 on intput, FCN should calculate the functions at X and
%    return this vector in FVEC.
%    If IFLAG = 2 on input, FCN should calculate the jacobian at X and
%    return this matrix in FJAC.
%    To terminate the algorithm, the user may set IFLAG negative.
%
%    Input, integer ( kind = 4 ) M, is the number of functions.
%
%    Input, integer ( kind = 4 ) N, is the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an M by N array.  The upper
%    N by N submatrix of FJAC contains an upper triangular matrix R with
%    diagonal elements of nonincreasing magnitude such that
%      P' * ( JAC' * JAC ) * P = R' * R,
%    where P is a permutation matrix and JAC is the final calculated jacobian.
%    Column J of P is column IPVT(J) of the identity matrix.  The lower
%    trapezoidal part of FJAC contains information generated during
%    the computation of R.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least M.
%
%    Input, real ( kind = 8 ) FTOL.  Termination occurs when both the actual
%    and predicted relative reductions in the sum of squares are at most FTOL.
%    Therefore, FTOL measures the relative error desired in the sum of
%    squares.  FTOL should be nonnegative.
%
%    Input, real ( kind = 8 ) XTOL.  Termination occurs when the relative error
%    between two consecutive iterates is at most XTOL.  XTOL should be
%    nonnegative.
%
%    Input, real ( kind = 8 ) GTOL.  Termination occurs when the cosine of the
%    angle between FVEC and any column of the jacobian is at most GTOL in
%    absolute value.  Therefore, GTOL measures the orthogonality desired
%    between the function vector and the columns of the jacobian.  GTOL should
%    be nonnegative.
%
%    Input, integer ( kind = 4 ) MAXFEV.  Termination occurs when the number of calls
%    to FCN with IFLAG = 1 is at least MAXFEV by the end of an iteration.
%
%    Input/output, real ( kind = 8 ) DIAG(N).  If MODE = 1, then DIAG is set
%    internally.  If MODE = 2, then DIAG must contain positive entries that
%    serve as multiplicative scale factors for the variables.
%
%    Input, integer ( kind = 4 ) MODE, scaling option.
%    1, variables will be scaled internally.
%    2, scaling is specified by the input DIAG vector.
%
%    Input, real ( kind = 8 ) FACTOR, determines the initial step bound.  This
%    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
%    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
%    in the interval (0.1, 100) with 100 the recommended value.
%
%    Input, integer ( kind = 4 ) NPRINT, enables controlled printing of iterates if it
%    is positive.  In this case, FCN is called with IFLAG = 0 at the
%    beginning of the first iteration and every NPRINT iterations thereafter
%    and immediately prior to return, with X and FVEC available
%    for printing.  If NPRINT is not positive, no special calls
%    of FCN with IFLAG = 0 are made.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, both actual and predicted relative reductions in the sum of
%       squares are at most FTOL.
%    2, relative error between two consecutive iterates is at most XTOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, the cosine of the angle between FVEC and any column of the jacobian
%       is at most GTOL in absolute value.
%    5, number of calls to FCN with IFLAG = 1 has reached MAXFEV.
%    6, FTOL is too small.  No further reduction in the sum of squares
%       is possible.
%    7, XTOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    8, GTOL is too small.  FVEC is orthogonal to the columns of the
%       jacobian to machine precision.
%
%    Output, integer ( kind = 4 ) NFEV, the number of calls to FCN with IFLAG = 1.
%
%    Output, integer ( kind = 4 ) NJEV, the number of calls to FCN with IFLAG = 2.
%
%    Output, integer ( kind = 4 ) IPVT(N), defines a permutation matrix P such that
%    JAC*P = Q*R, where JAC is the final calculated jacobian, Q is
%    orthogonal (not stored), and R is upper triangular with diagonal
%    elements of nonincreasing magnitude.  Column J of P is column
%    IPVT(J) of the identity matrix.
%
%    Output, real ( kind = 8 ) QTF(N), contains the first N elements of Q'*FVEC.
%


persistent actred delta dirder epsmch fnorm fnorm1 gnorm gt i iflag iter j l par pnorm prered ratio sum2 temp temp1 temp2 wa1 wa2 wa3 wa4 xnorm ; 

 if isempty(actred), actred=0; end;
 if isempty(delta), delta=0; end;
 if isempty(dirder), dirder=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(fnorm), fnorm=0; end;
 if isempty(fnorm1), fnorm1=0; end;
 if isempty(gnorm), gnorm=0; end;
 if isempty(i), i=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(iter), iter=0; end;
 if isempty(j), j=0; end;
 if isempty(l), l=0; end;
 if isempty(par), par=0; end;
 if isempty(pnorm), pnorm=0; end;
 if isempty(prered), prered=0; end;
 if isempty(ratio), ratio=0; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(temp1), temp1=0; end;
 if isempty(temp2), temp2=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;
 if isempty(wa3), wa3=zeros(n,1); end;
 if isempty(wa4), wa4=zeros(m,1); end;
 if isempty(xnorm), xnorm=0; end;

 if isempty(gt), gt=false; end;

epsmch = eps;

info = 0;
iflag = 0;
nfev = 0;
njev = 0;
%
%  Check the input parameters for errors.
%
while (1);
if( n <= 0 );
 tempBreak=1;break;
end;

if( m < n );
 tempBreak=1;break;
end;

if( ldfjac < m|| ftol < 0.0d+00 || xtol < 0.0d+00 || gtol < 0.0d+00|| maxfev <= 0 || factor <= 0.0d+00 );
 tempBreak=1;break;
end;

if( mode == 2 );
for j = 1: n;
if( diag(j) <= 0.0d+00 );
  tempBreak=1;break;
end;
end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak
end;
%
%  Evaluate the function at the starting point and calculate its norm.
%
iflag = 1;
[ m, n, x, fvec, fjac, ldfjac, iflag ]=fcn( m, n, x, fvec, fjac, ldfjac, iflag );
nfev = 1;
if( iflag < 0 );
 tempBreak=1;break;
end;

[fnorm , m, fvec ]=enorm( m, fvec );
%
%  Initialize Levenberg-Marquardt parameter and iteration counter.
%
par = 0.0d+00;
iter = 1;
%
%  Beginning of the outer loop.
%
gt=false;
while (1);
if(~ gt);
%30 continue
%
%  Calculate the jacobian matrix.
%
iflag = 2;
[ m, n, x, fvec, fjac, ldfjac, iflag ]=fcn( m, n, x, fvec, fjac, ldfjac, iflag );

njev = fix(njev + 1);

if( iflag < 0 );
 tempBreak=1;break;
end;
%
%  If requested, call FCN to enable printing of iterates.
%
if( 0 < nprint );
iflag = 0;
if( rem( iter-1, nprint ) == 0 );
[ m, n, x, fvec, fjac, ldfjac, iflag ]=fcn( m, n, x, fvec, fjac, ldfjac, iflag );
end;
if( iflag < 0 );
 tempBreak=1;break;
end;
end;
%
%  Compute the QR factorization of the jacobian.
%
[ m, n, fjac, ldfjac,dumvar5, ipvt, n, wa1, wa2 ]=qrfac( m, n, fjac, ldfjac, true, ipvt, n, wa1, wa2 );
%
%  On the first iteration and if mode is 1, scale according
%  to the norms of the columns of the initial jacobian.
%
if( iter == 1 );

if( mode ~= 2 );
diag([1:n]) = wa2([1:n]);
for j = 1: n;
if( wa2(j) == 0.0d+00 );
diag(j) = 1.0d+00;
end;
end; j = fix(n+1);
end;
%
%  On the first iteration, calculate the norm of the scaled X
%  and initialize the step bound DELTA.
%
wa3([1:n]) = diag([1:n]) .* x([1:n]);

[xnorm , n, wa3 ]=enorm( n, wa3 );
delta = factor .* xnorm;
if( delta == 0.0d+00 );
delta = factor;
end;
end;
%
%  Form Q'*FVEC and store the first N components in QTF.
%
wa4([1:m]) = fvec([1:m]);

for j = 1: n;

if( fjac(j,j) ~= 0.0d+00 );
sum2 = dot( wa4([j:m]), fjac([j:m],j) );
temp = - sum2 ./ fjac(j,j);
wa4([j:m]) = wa4([j:m]) + fjac([j:m],j) .* temp;
end;

fjac(j,j) = wa1(j);
qtf(j) = wa4(j);

end; j = fix(n+1);
%
%  Compute the norm of the scaled gradient.
%
gnorm = 0.0d+00;

if( fnorm ~= 0.0d+00 );

for j = 1: n;
l = fix(ipvt(j));
if( wa2(l) ~= 0.0d+00 );
sum2 = dot( qtf([1:j]), fjac([1:j],j) ) ./ fnorm;
gnorm = max( gnorm, abs( sum2 ./ wa2(l) ) );
end;
end; j = fix(n+1);

end;
%
%  Test for convergence of the gradient norm.
%
if( gnorm <= gtol );
info = 4;
 tempBreak=1;break;
end;
%
%  Rescale if necessary.
%
if( mode ~= 2 );
for j = 1: n;
diag(j) = max( diag(j), wa2(j) );
end; j = fix(n+1);
end;
%
%  Beginning of the inner loop.
%
end;
gt=false;
%
%  Determine the Levenberg-Marquardt parameter.
%
[ n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 ]=lmpar( n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 );
%
%  Store the direction p and x + p. calculate the norm of p.
%
wa1([1:n]) = - wa1([1:n]);
wa2([1:n]) = x([1:n]) + wa1([1:n]);
wa3([1:n]) = diag([1:n]) .* wa1([1:n]);

[pnorm , n, wa3 ]=enorm( n, wa3 );
%
%  On the first iteration, adjust the initial step bound.
%
if( iter == 1 );
delta = min( delta, pnorm );
end;
%
%  Evaluate the function at x + p and calculate its norm.
%
iflag = 1;
[ m, n, wa2, wa4, fjac, ldfjac, iflag ]=fcn( m, n, wa2, wa4, fjac, ldfjac, iflag );

nfev = fix(nfev + 1);

if( iflag < 0 );
 tempBreak=1;break;
end;

[fnorm1 , m, wa4 ]=enorm( m, wa4 );
%
%  Compute the scaled actual reduction.
%
actred = -1.0d+00;
if( 0.1d+00 .* fnorm1 < fnorm );
actred = 1.0d+00 -( fnorm1 ./ fnorm ).^2;
end;
%
%  Compute the scaled predicted reduction and
%  the scaled directional derivative.
%
for j = 1: n;
wa3(j) = 0.0d+00;
l = fix(ipvt(j));
temp = wa1(l);
wa3([1:j]) = wa3([1:j]) + fjac([1:j],j) .* temp;
end; j = fix(n+1);

temp1 = enorm( n, wa3 ) ./ fnorm;
temp2 =( sqrt( par ) .* pnorm ) ./ fnorm;
prered = temp1.^2 + temp2.^2 ./ 0.5d+00;
dirder = -( temp1.^2 + temp2.^2 );
%
%  Compute the ratio of the actual to the predicted reduction.
%
if( prered ~= 0.0d+00 );
ratio = actred ./ prered;
else;
ratio = 0.0d+00;
end;
%
%  Update the step bound.
%
if( ratio <= 0.25d+00 );

if( actred >= 0.0d+00 );
temp = 0.5d+00;
end;

if( actred < 0.0d+00 );
temp = 0.5d+00 .* dirder ./( dirder + 0.5d+00 .* actred );
end;

if( 0.1d+00 .* fnorm1 >= fnorm || temp < 0.1d+00 );
temp = 0.1d+00;
end;

delta = temp .* min( delta, pnorm ./ 0.1d+00 );
par = par ./ temp;

else;

if( par == 0.0d+00 || ratio >= 0.75d+00 );
delta = 2.0d+00 .* pnorm;
par = 0.5d+00 .* par;
end;

end;
%
%  Successful iteration.
%
%  Update X, FVEC, and their norms.
%
if( ratio >= 0.0001d+00 );
x([1:n]) = wa2([1:n]);
wa2([1:n]) = diag([1:n]) .* x([1:n]);
fvec([1:m]) = wa4([1:m]);
[xnorm , n, wa2 ]=enorm( n, wa2 );
fnorm = fnorm1;
iter = fix(iter + 1);
end;
%
%  Tests for convergence.
%
if( abs( actred) <= ftol &&prered <= ftol &&0.5d+00 .* ratio <= 1.0d+00 );
info = 1;
end;

if( delta <= xtol .* xnorm );
info = 2;
end;

if( abs( actred) <= ftol && prered <= ftol&& 0.5d+00 .* ratio <= 1.0d+00 && info == 2 );
info = 3;
end;

if( info ~= 0 );
  tempBreak=1;break;
end;
%
%  Tests for termination and stringent tolerances.
%
if( nfev >= maxfev );
info = 5;
end;

if( abs( actred ) <= epsmch && prered <= epsmch&& 0.5d+00 .* ratio <= 1.0d+00 );
 info = 6;
end;
if( delta <= epsmch .* xnorm );
 info = 7;
end;
if( gnorm <= epsmch );
 info = 8;
end;
if( info ~= 0 );
  tempBreak=1;break;
end;
%
%  End of the inner loop. repeat if iteration unsuccessful.
%
if( ratio < 0.0001d+00 );
gt=true;
continue;
end;
%
%  End of the outer loop.
%
end;
 tempBreak=1;break;
end;
%
%  Termination, either normal or user imposed.
%
if( iflag < 0 );
info = fix(iflag);
end;

iflag = 0;

if( 0 < nprint );
[ m, n, x, fvec, fjac, ldfjac, iflag ]=fcn( m, n, x, fvec, fjac, ldfjac, iflag );
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine lmder
function [fcn, m, n, x, fvec, fjac, ldfjac, tol, info]=lmder1( fcn, m, n, x, fvec, fjac, ldfjac, tol, info );

%*****************************************************************************80
%
%! LMDER1 minimizes M functions in N variables by the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMDER1 minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm.
%    This is done by using the more general least-squares solver LMDER.
%    The user must provide a subroutine which calculates the functions
%    and the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the jacobian.  FCN should have the form:
%
%      subroutine fcn ( m, n, x, fvec, fjac, ldfjac, iflag )
%      integer ( kind = 4 ) ldfjac
%      integer ( kind = 4 ) n
%      real fjac(ldfjac,n)
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If IFLAG = 1 on intput, FCN should calculate the functions at X and
%    return this vector in FVEC.
%    If IFLAG = 2 on input, FCN should calculate the jacobian at X and
%    return this matrix in FJAC.
%    To terminate the algorithm, the user may set IFLAG negative.
%
%    Input, integer ( kind = 4 ) M, the number of functions.
%
%    Input, integer ( kind = 4 ) N, is the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an M by N array.  The upper
%    N by N submatrix contains an upper triangular matrix R with
%    diagonal elements of nonincreasing magnitude such that
%      P' * ( JAC' * JAC ) * P = R' * R,
%    where P is a permutation matrix and JAC is the final calculated
%    jacobian.  Column J of P is column IPVT(J) of the identity matrix.
%    The lower trapezoidal part of FJAC contains information generated during
%    the computation of R.
%
%    Input, integer ( kind = 4 ) LDFJAC, is the leading dimension of FJAC,
%    which must be no less than M.
%
%    Input, real ( kind = 8 ) TOL.  Termination occurs when the algorithm
%    estimates either that the relative error in the sum of squares is at
%    most TOL or that the relative error between X and the solution is at
%    most TOL.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, algorithm estimates that the relative error in the sum of squares
%       is at most TOL.
%    2, algorithm estimates that the relative error between X and the
%       solution is at most TOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, FVEC is orthogonal to the columns of the jacobian to machine precision.
%    5, number of calls to FCN with IFLAG = 1 has reached 100*(N+1).
%    6, TOL is too small.  No further reduction in the sum of squares is
%       possible.
%    7, TOL is too small.  No further improvement in the approximate
%       solution X is possible.
%


persistent diag factor ftol gtol ipvt maxfev mode nfev njev nprint qtf xtol ; 

 if isempty(diag), diag=zeros(n,1); end;
 if isempty(factor), factor=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(ftol), ftol=0; end;
 if isempty(gtol), gtol=0; end;
 if isempty(ipvt), ipvt=zeros(n,1); end;
 if isempty(maxfev), maxfev=0; end;
 if isempty(mode), mode=0; end;
 if isempty(nfev), nfev=0; end;
 if isempty(njev), njev=0; end;
 if isempty(nprint), nprint=0; end;
 if isempty(qtf), qtf=zeros(n,1); end;
 if isempty(xtol), xtol=0; end;

info = 0;

if( n <= 0 );
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( m < n ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( ldfjac < m ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( tol < 0.0d+00 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;

factor = 100.0d+00;
maxfev = fix(100 .*( n + 1 ));
ftol = tol;
xtol = tol;
gtol = 0.0d+00;
mode = 1;
nprint = 0;

[ fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf ]=lmder( fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf );

if( info == 8 );
info = 4;
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine lmder1
function [fcn, m, n, x, fvec, ftol, xtol, gtol, maxfev, epsfcn,diag, mode, factor, nprint, info, nfev, fjac, ldfjac, ipvt, qtf]=lmdif( fcn, m, n, x, fvec, ftol, xtol, gtol, maxfev, epsfcn,diag, mode, factor, nprint, info, nfev, fjac, ldfjac, ipvt, qtf );

%*****************************************************************************80
%
%! LMDIF minimizes M functions in N variables by the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMDIF minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm.
%    The user must provide a subroutine which calculates the functions.
%    The jacobian is then calculated by a forward-difference approximation.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( m, n, x, fvec, iflag )
%      integer ( kind = 4 ) m
%      integer ( kind = 4 ) n
%
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) M, the number of functions.
%
%    Input, integer ( kind = 4 ) N, the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Input, real ( kind = 8 ) FTOL.  Termination occurs when both the actual
%    and predicted relative reductions in the sum of squares are at most FTOL.
%    Therefore, FTOL measures the relative error desired in the sum of
%    squares.  FTOL should be nonnegative.
%
%    Input, real ( kind = 8 ) XTOL.  Termination occurs when the relative error
%    between two consecutive iterates is at most XTOL.  Therefore, XTOL
%    measures the relative error desired in the approximate solution.  XTOL
%    should be nonnegative.
%
%    Input, real ( kind = 8 ) GTOL. termination occurs when the cosine of the
%    angle between FVEC and any column of the jacobian is at most GTOL in
%    absolute value.  Therefore, GTOL measures the orthogonality desired
%    between the function vector and the columns of the jacobian.  GTOL should
%    be nonnegative.
%
%    Input, integer ( kind = 4 ) MAXFEV.  Termination occurs when the number of calls
%    to FCN is at least MAXFEV by the end of an iteration.
%
%    Input, real ( kind = 8 ) EPSFCN, is used in determining a suitable step length for
%    the forward-difference approximation.  This approximation assumes that
%    the relative errors in the functions are of the order of EPSFCN.
%    If EPSFCN is less than the machine precision, it is assumed that the
%    relative errors in the functions are of the order of the machine
%    precision.
%
%    Input/output, real ( kind = 8 ) DIAG(N).  If MODE = 1, then DIAG is set
%    internally.  If MODE = 2, then DIAG must contain positive entries that
%    serve as multiplicative scale factors for the variables.
%
%    Input, integer ( kind = 4 ) MODE, scaling option.
%    1, variables will be scaled internally.
%    2, scaling is specified by the input DIAG vector.
%
%    Input, real ( kind = 8 ) FACTOR, determines the initial step bound.  This bound is
%    set to the product of FACTOR and the euclidean norm of DIAG*X if
%    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
%    in the interval (0.1, 100) with 100 the recommended value.
%
%    Input, integer ( kind = 4 ) NPRINT, enables controlled printing of iterates if it
%    is positive.  In this case, FCN is called with IFLAG = 0 at the
%    beginning of the first iteration and every NPRINT iterations thereafter
%    and immediately prior to return, with X and FVEC available
%    for printing.  If NPRINT is not positive, no special calls
%    of FCN with IFLAG = 0 are made.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, both actual and predicted relative reductions in the sum of squares
%       are at most FTOL.
%    2, relative error between two consecutive iterates is at most XTOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, the cosine of the angle between FVEC and any column of the jacobian
%       is at most GTOL in absolute value.
%    5, number of calls to FCN has reached or exceeded MAXFEV.
%    6, FTOL is too small.  No further reduction in the sum of squares
%       is possible.
%    7, XTOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    8, GTOL is too small.  FVEC is orthogonal to the columns of the
%       jacobian to machine precision.
%
%    Output, integer ( kind = 4 ) NFEV, the number of calls to FCN.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an M by N array.  The upper
%    N by N submatrix of FJAC contains an upper triangular matrix R with
%    diagonal elements of nonincreasing magnitude such that
%
%      P' * ( JAC' * JAC ) * P = R' * R,
%
%    where P is a permutation matrix and JAC is the final calculated jacobian.
%    Column J of P is column IPVT(J) of the identity matrix.  The lower
%    trapezoidal part of FJAC contains information generated during
%    the computation of R.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least M.
%
%    Output, integer ( kind = 4 ) IPVT(N), defines a permutation matrix P such that
%    JAC * P = Q * R, where JAC is the final calculated jacobian, Q is
%    orthogonal (not stored), and R is upper triangular with diagonal
%    elements of nonincreasing magnitude.  Column J of P is column IPVT(J)
%    of the identity matrix.
%
%    Output, real ( kind = 8 ) QTF(N), the first N elements of Q'*FVEC.
%


persistent actred delta dirder epsmch fnorm fnorm1 gnorm gt i iflag iter j l par pnorm prered ratio sum2 temp temp1 temp2 wa1 wa2 wa3 wa4 xnorm ; 

 if isempty(actred), actred=0; end;
 if isempty(delta), delta=0; end;
 if isempty(dirder), dirder=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(fnorm), fnorm=0; end;
 if isempty(fnorm1), fnorm1=0; end;
 if isempty(gnorm), gnorm=0; end;
 if isempty(i), i=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(iter), iter=0; end;
 if isempty(j), j=0; end;
 if isempty(l), l=0; end;
 if isempty(par), par=0; end;
 if isempty(pnorm), pnorm=0; end;
 if isempty(prered), prered=0; end;
 if isempty(ratio), ratio=0; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(temp1), temp1=0; end;
 if isempty(temp2), temp2=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;
 if isempty(wa3), wa3=zeros(n,1); end;
 if isempty(wa4), wa4=zeros(m,1); end;
 if isempty(xnorm), xnorm=0; end;

 if isempty(gt), gt=false; end;

epsmch = eps;

info = 0;
iflag = 0;
nfev = 0;

while (1);
if( n <= 0 );
 tempBreak=1;break;
elseif( m < n ) ;
 tempBreak=1;break;
elseif( ldfjac < m ) ;
 tempBreak=1;break;
elseif( ftol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( xtol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( gtol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( maxfev <= 0 ) ;
 tempBreak=1;break;
elseif( factor <= 0.0d+00 ) ;
 tempBreak=1;break;
end;

if( mode == 2 );
for j = 1: n;
if( diag(j) <= 0.0d+00 );
 tempBreak=1;break;
end;
end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak
end;
%
%  Evaluate the function at the starting point and calculate its norm.
%
iflag = 1;
[ m, n, x, fvec, iflag ]=fcn( m, n, x, fvec, iflag );
nfev = 1;

if( iflag < 0 );
 tempBreak=1;break;
end;

[fnorm , m, fvec ]=enorm( m, fvec );
%
%  Initialize Levenberg-Marquardt parameter and iteration counter.
%
par = 0.0d+00;
iter = 1;
%
%  Beginning of the outer loop.
%
gt=false;
while (1);
if(~ gt);
%30 continue
%
%  Calculate the jacobian matrix.
%
iflag = 2;
[ fcn, m, n, x, fvec, fjac, ldfjac, iflag, epsfcn ]=fdjac2( fcn, m, n, x, fvec, fjac, ldfjac, iflag, epsfcn );
nfev = fix(nfev + n);

if( iflag < 0 );
 tempBreak=1;break;
end;
%
%  If requested, call FCN to enable printing of iterates.
%
if( 0 < nprint );
iflag = 0;
if( rem( iter-1, nprint ) == 0 );
[ m, n, x, fvec, iflag ]=fcn( m, n, x, fvec, iflag );
end;
if( iflag < 0 );
 tempBreak=1;break;
end;
end;
%
%  Compute the QR factorization of the jacobian.
%
[ m, n, fjac, ldfjac,dumvar5, ipvt, n, wa1, wa2 ]=qrfac( m, n, fjac, ldfjac, true, ipvt, n, wa1, wa2 );
%
%  On the first iteration and if MODE is 1, scale according
%  to the norms of the columns of the initial jacobian.
%
if( iter == 1 );

if( mode ~= 2 );
diag([1:n]) = wa2([1:n]);
for j = 1: n;
if( wa2(j) == 0.0d+00 );
diag(j) = 1.0d+00;
end;
end; j = fix(n+1);
end;
%
%  On the first iteration, calculate the norm of the scaled X
%  and initialize the step bound DELTA.
%
wa3([1:n]) = diag([1:n]) .* x([1:n]);
[xnorm , n, wa3 ]=enorm( n, wa3 );
delta = factor .* xnorm;
if( delta == 0.0d+00 );
delta = factor;
end;
end;
%
%  Form Q' * FVEC and store the first N components in QTF.
%
wa4([1:m]) = fvec([1:m]);

for j = 1: n;

if( fjac(j,j) ~= 0.0d+00 );
sum2 = dot( wa4([j:m]), fjac([j:m],j) );
temp = - sum2 ./ fjac(j,j);
wa4([j:m]) = wa4([j:m]) + fjac([j:m],j) .* temp;
end;

fjac(j,j) = wa1(j);
qtf(j) = wa4(j);

end; j = fix(n+1);
%
%  Compute the norm of the scaled gradient.
%
gnorm = 0.0d+00;

if( fnorm ~= 0.0d+00 );

for j = 1: n;

l = fix(ipvt(j));

if( wa2(l) ~= 0.0d+00 );
sum2 = 0.0d+00;
for i = 1: j;
sum2 = sum2 + fjac(i,j) .*( qtf(i) ./ fnorm );
end; i = fix(j+1);
gnorm = max( gnorm, abs( sum2 ./ wa2(l) ) );
end;

end; j = fix(n+1);

end;
%
%  Test for convergence of the gradient norm.
%
if( gnorm <= gtol );
info = 4;
 tempBreak=1;break;
end;
%
%  Rescale if necessary.
%
if( mode ~= 2 );
for j = 1: n;
diag(j) = max( diag(j), wa2(j) );
end; j = fix(n+1);
end;
%
%  Beginning of the inner loop.
%
end;
gt=false;
%
%  Determine the Levenberg-Marquardt parameter.
%
[ n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 ]=lmpar( n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 );
%
%  Store the direction P and X + P.
%  Calculate the norm of P.
%
wa1([1:n]) = -wa1([1:n]);
wa2([1:n]) = x([1:n]) + wa1([1:n]);
wa3([1:n]) = diag([1:n]) .* wa1([1:n]);

[pnorm , n, wa3 ]=enorm( n, wa3 );
%
%  On the first iteration, adjust the initial step bound.
%
if( iter == 1 );
delta = min( delta, pnorm );
end;
%
%  Evaluate the function at X + P and calculate its norm.
%
iflag = 1;
[ m, n, wa2, wa4, iflag ]=fcn( m, n, wa2, wa4, iflag );
nfev = fix(nfev + 1);
if( iflag < 0 );
 tempBreak=1;break;
end;
[fnorm1 , m, wa4 ]=enorm( m, wa4 );
%
%  Compute the scaled actual reduction.
%
if( 0.1d+00 .* fnorm1 < fnorm );
actred = 1.0d+00 -( fnorm1 ./ fnorm ).^2;
else;
actred = -1.0d+00;
end;
%
%  Compute the scaled predicted reduction and the scaled directional derivative.
%
for j = 1: n;
wa3(j) = 0.0d+00;
l = fix(ipvt(j));
temp = wa1(l);
wa3([1:j]) = wa3([1:j]) + fjac([1:j],j) .* temp;
end; j = fix(n+1);

temp1 = enorm( n, wa3 ) ./ fnorm;
temp2 =( sqrt( par ) .* pnorm ) ./ fnorm;
prered = temp1.^2 + temp2.^2 ./ 0.5d+00;
dirder = -( temp1.^2 + temp2.^2 );
%
%  Compute the ratio of the actual to the predicted reduction.
%
ratio = 0.0d+00;
if( prered ~= 0.0d+00 );
ratio = actred ./ prered;
end;
%
%  Update the step bound.
%
if( ratio <= 0.25d+00 );

if( actred >= 0.0d+00 );
temp = 0.5d+00;
end;

if( actred < 0.0d+00 );
temp = 0.5d+00 .* dirder ./( dirder + 0.5d+00 .* actred );
end;

if( 0.1d+00 .* fnorm1 >= fnorm || temp < 0.1d+00 );
temp = 0.1d+00;
end;

delta = temp .* min( delta, pnorm ./ 0.1d+00  );
par = par ./ temp;

else;

if( par == 0.0d+00 || ratio >= 0.75d+00 );
delta = 2.0d+00 .* pnorm;
par = 0.5d+00 .* par;
end;

end;
%
%  Test for successful iteration.
%

%
%  Successful iteration. update X, FVEC, and their norms.
%
if( 0.0001d+00 <= ratio );
x([1:n]) = wa2([1:n]);
wa2([1:n]) = diag([1:n]) .* x([1:n]);
fvec([1:m]) = wa4([1:m]);
[xnorm , n, wa2 ]=enorm( n, wa2 );
fnorm = fnorm1;
iter = fix(iter + 1);
end;
%
%  Tests for convergence.
%
if( abs( actred) <= ftol && prered <= ftol&& 0.5d+00 .* ratio <= 1.0d+00 );
info = 1;
end;

if( delta <= xtol .* xnorm );
info = 2;
end;

if( abs( actred) <= ftol && prered <= ftol&& 0.5d+00 .* ratio <= 1.0d+00 && info == 2 );
 info = 3;
end;
if( info ~= 0 );
  tempBreak=1;break;
end;
%
%  Tests for termination and stringent tolerances.
%
if( nfev >= maxfev );
info = 5;
end;

if( abs( actred) <= epsmch && prered <= epsmch&& 0.5d+00 .* ratio <= 1.0d+00 );
 info = 6;
end;
if( delta <= epsmch .* xnorm );
 info = 7;
end;
if( gnorm <= epsmch );
 info = 8;
end;

if( info ~= 0 );
 tempBreak=1;break;
end;
%
%  End of the inner loop.  Repeat if iteration unsuccessful.
%
if( ratio < 0.0001d+00 );
gt=true;
continue;
end;
%
%  End of the outer loop.
%
end;
 tempBreak=1;break;
end;

%
%  Termination, either normal or user imposed.
%
if( iflag < 0 );
info = fix(iflag);
end;

iflag = 0;

if( nprint > 0 );
[ m, n, x, fvec, iflag ]=fcn( m, n, x, fvec, iflag );
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine lmdif
function [fcn, m, n, x, fvec, tol, info]=lmdif1( fcn, m, n, x, fvec, tol, info );

%*****************************************************************************80
%
%! LMDIF1 minimizes M functions in N variables using the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMDIF1 minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm.
%    This is done by using the more general least-squares solver LMDIF.
%    The user must provide a subroutine which calculates the functions.
%    The jacobian is then calculated by a forward-difference approximation.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions.  The routine should have the form:
%
%      subroutine fcn ( m, n, x, fvec, iflag )
%      integer ( kind = 4 ) n
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    The value of IFLAG should not be changed by FCN unless
%    the user wants to terminate execution of the routine.
%    In this case set IFLAG to a negative integer.
%
%    Input, integer ( kind = 4 ) M, the number of functions.
%
%    Input, integer ( kind = 4 ) N, the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Input, real ( kind = 8 ) TOL.  Termination occurs when the algorithm
%    estimates either that the relative error in the sum of squares is at
%    most TOL or that the relative error between X and the solution is at
%    most TOL.  TOL should be nonnegative.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, algorithm estimates that the relative error in the sum of squares
%       is at most TOL.
%    2, algorithm estimates that the relative error between X and the
%       solution is at most TOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, FVEC is orthogonal to the columns of the jacobian to machine precision.
%    5, number of calls to FCN has reached or exceeded 200*(N+1).
%    6, TOL is too small.  No further reduction in the sum of squares
%       is possible.
%    7, TOL is too small.  No further improvement in the approximate
%       solution X is possible.
%


persistent diag epsfcn factor fjac ftol gtol ipvt ldfjac maxfev mode nfev nprint qtf xtol ; 

 if isempty(diag), diag=zeros(n,1); end;
 if isempty(epsfcn), epsfcn=0; end;
 if isempty(factor), factor=0; end;
 if isempty(fjac), fjac=zeros(m,n); end;
 if isempty(ftol), ftol=0; end;
 if isempty(gtol), gtol=0; end;
 if isempty(ipvt), ipvt=zeros(n,1); end;
 if isempty(ldfjac), ldfjac=0; end;
 if isempty(maxfev), maxfev=0; end;
 if isempty(mode), mode=0; end;
 if isempty(nfev), nfev=0; end;
 if isempty(nprint), nprint=0; end;
 if isempty(qtf), qtf=zeros(n,1); end;
 if isempty(xtol), xtol=0; end;

info = 0;

if( n <= 0 );
return;
elseif( m < n ) ;
return;
elseif( tol < 0.0d+00 ) ;
return;
end;

factor = 100.0d+00;
maxfev = fix(200 .*( n + 1 ));
ftol = tol;
xtol = tol;
gtol = 0.0d+00;
epsfcn = 0.0d+00;
mode = 1;
nprint = 0;
ldfjac = fix(m);

[ fcn, m, n, x, fvec, ftol, xtol, gtol, maxfev, epsfcn,diag, mode, factor, nprint, info, nfev, fjac, ldfjac, ipvt, qtf ]=lmdif( fcn, m, n, x, fvec, ftol, xtol, gtol, maxfev, epsfcn,diag, mode, factor, nprint, info, nfev, fjac, ldfjac, ipvt, qtf );

if( info == 8 );
info = 4;
end;

return;
end %subroutine lmdif1
function [n, r, ldr, ipvt, diag, qtb, delta, par, x, sdiag]=lmpar( n, r, ldr, ipvt, diag, qtb, delta, par, x, sdiag );

%*****************************************************************************80
%
%! LMPAR computes a parameter for the Levenberg-Marquardt method.
%
%  Discussion:
%
%    Given an M by N matrix A, an N by N nonsingular diagonal
%    matrix D, an M-vector B, and a positive number DELTA,
%    the problem is to determine a value for the parameter
%    PAR such that if X solves the system
%
%      A*X = B,
%      sqrt ( PAR ) * D * X = 0,
%
%    in the least squares sense, and DXNORM is the euclidean
%    norm of D*X, then either PAR is zero and
%
%      ( DXNORM - DELTA ) <= 0.1 * DELTA,
%
%    or PAR is positive and
%
%      abs ( DXNORM - DELTA) <= 0.1 * DELTA.
%
%    This subroutine completes the solution of the problem
%    if it is provided with the necessary information from the
%    QR factorization, with column pivoting, of A.  That is, if
%    A*P = Q*R, where P is a permutation matrix, Q has orthogonal
%    columns, and R is an upper triangular matrix with diagonal
%    elements of nonincreasing magnitude, then LMPAR expects
%    the full upper triangle of R, the permutation matrix P,
%    and the first N components of Q'*B.  On output
%    LMPAR also provides an upper triangular matrix S such that
%
%      P' * ( A' * A + PAR * D * D ) * P = S'* S.
%
%    S is employed within LMPAR and may be of separate interest.
%
%    Only a few iterations are generally needed for convergence
%    of the algorithm.  If, however, the limit of 10 iterations
%    is reached, then the output PAR will contain the best
%    value obtained so far.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the order of R.
%
%    Input/output, real ( kind = 8 ) R(LDR,N),the N by N matrix.  The full
%    upper triangle must contain the full upper triangle of the matrix R.
%    On output the full upper triangle is unaltered, and the strict lower
%    triangle contains the strict upper triangle (transposed) of the upper
%    triangular matrix S.
%
%    Input, integer ( kind = 4 ) LDR, the leading dimension of R.  LDR must be
%    no less than N.
%
%    Input, integer ( kind = 4 ) IPVT(N), defines the permutation matrix P such that
%    A*P = Q*R.  Column J of P is column IPVT(J) of the identity matrix.
%
%    Input, real ( kind = 8 ) DIAG(N), the diagonal elements of the matrix D.
%
%    Input, real ( kind = 8 ) QTB(N), the first N elements of the vector Q'*B.
%
%    Input, real ( kind = 8 ) DELTA, an upper bound on the euclidean norm of D*X.
%    DELTA should be positive.
%
%    Input/output, real ( kind = 8 ) PAR.  On input an initial estimate of the
%    Levenberg-Marquardt parameter.  On output the final estimate.
%    PAR should be nonnegative.
%
%    Output, real ( kind = 8 ) X(N), the least squares solution of the system
%    A*X = B, sqrt(PAR)*D*X = 0, for the output value of PAR.
%
%    Output, real ( kind = 8 ) SDIAG(N), the diagonal elements of the upper
%    triangular matrix S.
%


persistent dwarf dxnorm fp gnorm gt i iter j k l nsing parc parl paru qnorm sum2 temp wa1 wa2 ; 

 if isempty(dwarf), dwarf=0; end;
 if isempty(dxnorm), dxnorm=0; end;
 if isempty(gnorm), gnorm=0; end;
 if isempty(fp), fp=0; end;
 if isempty(i), i=0; end;
 if isempty(iter), iter=0; end;
 if isempty(j), j=0; end;
 if isempty(k), k=0; end;
 if isempty(l), l=0; end;
 if isempty(nsing), nsing=0; end;
 if isempty(parc), parc=0; end;
 if isempty(parl), parl=0; end;
 if isempty(paru), paru=0; end;
 if isempty(qnorm), qnorm=0; end;
r_orig=r;r_shape=[ldr,n];r=reshape([r_orig(1:min(prod(r_shape),numel(r_orig))),zeros(1,max(0,prod(r_shape)-numel(r_orig)))],r_shape);
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;

 if isempty(gt), gt=false; end;

%
%  DWARF is the smallest positive magnitude.
%
dwarf = realmin;
%
%  Compute and store in X the Gauss-Newton direction.
%
%  If the jacobian is rank-deficient, obtain a least squares solution.
%
nsing = fix(n);

for j = 1: n;
wa1(j) = qtb(j);
if( r(j,j) == 0.0d+00 && nsing == n );
nsing = fix(j - 1);
end;
if( nsing < n );
wa1(j) = 0.0d+00;
end;
end; j = fix(n+1);

for k = 1: nsing;
j = fix(nsing - k + 1);
wa1(j) = wa1(j) ./ r(j,j);
temp = wa1(j);
wa1([1:j-1]) = wa1([1:j-1]) - r([1:j-1],j) .* temp;
end; k = fix(nsing+1);

for j = 1: n;
l = fix(ipvt(j));
x(l) = wa1(j);
end; j = fix(n+1);
%
%  Initialize the iteration counter.
%  Evaluate the function at the origin, and test
%  for acceptance of the Gauss-Newton direction.
%
iter = 0;
wa2([1:n]) = diag([1:n]) .* x([1:n]);
[dxnorm , n, wa2 ]=enorm( n, wa2 );
fp = dxnorm - delta;

gt=false;
while (1);
if(~ gt);
if( fp <= 0.1d+00 .* delta );
 tempBreak=1;break;
end;
%
%  If the jacobian is not rank deficient, the Newton
%  step provides a lower bound, PARL, for the zero of
%  the function.
%
%  Otherwise set this bound to zero.
%
parl = 0.0d+00;

if( nsing >= n );

for j = 1: n;
l = fix(ipvt(j));
wa1(j) = diag(l) .*( wa2(l) ./ dxnorm );
end; j = fix(n+1);

for j = 1: n;
sum2 = dot( wa1([1:j-1]), r([1:j-1],j) );
wa1(j) =( wa1(j) - sum2 ) ./ r(j,j);
end; j = fix(n+1);

[temp , n, wa1 ]=enorm( n, wa1 );
parl =(( fp ./ delta ) ./ temp ) ./ temp;

end;
%
%  Calculate an upper bound, PARU, for the zero of the function.
%
for j = 1: n;
sum2 = dot( qtb([1:j]), r([1:j],j) );
l = fix(ipvt(j));
wa1(j) = sum2 ./ diag(l);
end; j = fix(n+1);

[gnorm , n, wa1 ]=enorm( n, wa1 );
paru = gnorm ./ delta;
if( paru == 0.0d+00 );
paru = dwarf ./ min( delta, 0.1d+00 );
end;
%
%  If the input PAR lies outside of the interval (PARL, PARU),
%  set PAR to the closer endpoint.
%
par = max( par, parl );
par = min( par, paru );
if( par == 0.0d+00 );
par = gnorm ./ dxnorm;
end;
%
%  Beginning of an iteration.
%
end;
gt=false;

iter = fix(iter + 1);
%
%  Evaluate the function at the current value of PAR.
%
if( par == 0.0d+00 );
par = max( dwarf, 0.001d+00 .* paru );
end;

wa1([1:n]) = sqrt( par ) .* diag([1:n]);

[ n, r, ldr, ipvt, wa1, qtb, x, sdiag ]=qrsolv( n, r, ldr, ipvt, wa1, qtb, x, sdiag );

wa2([1:n]) = diag([1:n]) .* x([1:n]);
[dxnorm , n, wa2 ]=enorm( n, wa2 );
temp = fp;
fp = dxnorm - delta;
%
%  If the function is small enough, accept the current value of PAR.
%
if( abs( fp ) <= 0.1d+00 .* delta );
 tempBreak=1;break;
end;
%
%  Test for the exceptional cases where PARL
%  is zero or the number of iterations has reached 10.
%
if( parl == 0.0d+00 && fp <= temp && temp < 0.0d+00 );
 tempBreak=1;break;
elseif( iter == 10 ) ;
 tempBreak=1;break;
end;
%
%  Compute the Newton correction.
%
for j = 1: n;
l = fix(ipvt(j));
wa1(j) = diag(l) .*( wa2(l) ./ dxnorm );
end; j = fix(n+1);

for j = 1: n;
wa1(j) = wa1(j) ./ sdiag(j);
temp = wa1(j);
wa1([j+1:n]) = wa1([j+1:n]) - r([j+1:n],j) .* temp;
end; j = fix(n+1);

[temp , n, wa1 ]=enorm( n, wa1 );
parc =(( fp ./ delta ) ./ temp ) ./ temp;
%
%  Depending on the sign of the function, update PARL or PARU.
%
if( 0.0d+00 < fp );
parl = max( parl, par );
elseif( fp < 0.0d+00 ) ;
paru = min( paru, par );
end;
%
%  Compute an improved estimate for PAR.
%
par = max( parl, par + parc );
%
%  End of an iteration.
%
gt=true;
continue;

 tempBreak=1;break;
end;

%
%  Termination.
%
if( iter == 0 );
par = 0.0d+00;
end;

r_orig(1:min(prod(r_shape),numel(r_orig)))=r(1:min(prod(r_shape),numel(r_orig)));r=r_orig;
return;
end %subroutine lmpar
function [fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf]=lmstr( fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf );

%*****************************************************************************80
%
%! LMSTR minimizes M functions in N variables using the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMSTR minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm
%    which uses minimal storage.
%
%    The user must provide a subroutine which calculates the functions and
%    the rows of the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the rows of the jacobian.
%    FCN should have the form:
%
%      subroutine fcn ( m, n, x, fvec, fjrow, iflag )
%
%      integer ( kind = 4 ) m
%      integer ( kind = 4 ) n
%
%      real fjrow(n)
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If the input value of IFLAG is 1, calculate the functions at X and
%    return this vector in FVEC.
%    If the input value of IFLAG is I > 1, calculate the (I-1)-st row of
%    the jacobian at X, and return this vector in FJROW.
%    To terminate the algorithm, set the output value of IFLAG negative.
%
%    Input, integer ( kind = 4 ) M, the number of functions.
%
%    Input, integer ( kind = 4 ) N, the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an N by N array.  The upper
%    triangle of FJAC contains an upper triangular matrix R such that
%
%      P' * ( JAC' * JAC ) * P = R' * R,
%
%    where P is a permutation matrix and JAC is the final calculated jacobian.
%    Column J of P is column IPVT(J) of the identity matrix.  The lower
%    triangular part of FJAC contains information generated during
%    the computation of R.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least N.
%
%    Input, real ( kind = 8 ) FTOL.  Termination occurs when both the actual and
%    predicted relative reductions in the sum of squares are at most FTOL.
%    Therefore, FTOL measures the relative error desired in the sum of
%    squares.  FTOL should be nonnegative.
%
%    Input, real ( kind = 8 ) XTOL.  Termination occurs when the relative error between
%    two consecutive iterates is at most XTOL.  XTOL should be nonnegative.
%
%    Input, real ( kind = 8 ) GTOL. termination occurs when the cosine of the angle
%    between FVEC and any column of the jacobian is at most GTOL in absolute
%    value.  Therefore, GTOL measures the orthogonality desired between the
%    function vector and the columns of the jacobian.  GTOL should
%    be nonnegative.
%
%    Input, integer ( kind = 4 ) MAXFEV.  Termination occurs when the number of calls
%    to FCN with IFLAG = 1 is at least MAXFEV by the end of an iteration.
%
%    Input/output, real ( kind = 8 ) DIAG(N).  If MODE = 1, then DIAG is set internally.
%    If MODE = 2, then DIAG must contain positive entries that serve as
%    multiplicative scale factors for the variables.
%
%    Input, integer ( kind = 4 ) MODE, scaling option.
%    1, variables will be scaled internally.
%    2, scaling is specified by the input DIAG vector.
%
%    Input, real ( kind = 8 ) FACTOR, determines the initial step bound.  This bound is
%    set to the product of FACTOR and the euclidean norm of DIAG*X if
%    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
%    in the interval (0.1, 100) with 100 the recommended value.
%
%    Input, integer ( kind = 4 ) NPRINT, enables controlled printing of iterates if it
%    is positive.  In this case, FCN is called with IFLAG = 0 at the
%    beginning of the first iteration and every NPRINT iterations thereafter
%    and immediately prior to return, with X and FVEC available
%    for printing.  If NPRINT is not positive, no special calls
%    of FCN with IFLAG = 0 are made.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, both actual and predicted relative reductions in the sum of squares
%       are at most FTOL.
%    2, relative error between two consecutive iterates is at most XTOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, the cosine of the angle between FVEC and any column of the jacobian
%       is at most GTOL in absolute value.
%    5, number of calls to FCN with IFLAG = 1 has reached MAXFEV.
%    6, FTOL is too small.  No further reduction in the sum of squares is
%       possible.
%    7, XTOL is too small.  No further improvement in the approximate
%       solution X is possible.
%    8, GTOL is too small.  FVEC is orthogonal to the columns of the
%       jacobian to machine precision.
%
%    Output, integer ( kind = 4 ) NFEV, the number of calls to FCN with IFLAG = 1.
%
%    Output, integer ( kind = 4 ) NJEV, the number of calls to FCN with IFLAG = 2.
%
%    Output, integer ( kind = 4 ) IPVT(N), defines a permutation matrix P such that
%    JAC * P = Q * R, where JAC is the final calculated jacobian, Q is
%    orthogonal (not stored), and R is upper triangular.
%    Column J of P is column IPVT(J) of the identity matrix.
%
%    Output, real ( kind = 8 ) QTF(N), contains the first N elements of Q'*FVEC.
%


persistent actred delta dirder epsmch fnorm fnorm1 gnorm gt i iflag iter j l par pnorm prered ratio sing sum2 temp temp1 temp2 wa1 wa2 wa3 wa4 xnorm ; 

 if isempty(actred), actred=0; end;
 if isempty(delta), delta=0; end;
 if isempty(dirder), dirder=0; end;
 if isempty(epsmch), epsmch=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(fnorm), fnorm=0; end;
 if isempty(fnorm1), fnorm1=0; end;
 if isempty(gnorm), gnorm=0; end;
 if isempty(i), i=0; end;
 if isempty(iflag), iflag=0; end;
 if isempty(iter), iter=0; end;
 if isempty(j), j=0; end;
 if isempty(l), l=0; end;
 if isempty(par), par=0; end;
 if isempty(pnorm), pnorm=0; end;
 if isempty(prered), prered=0; end;
 if isempty(ratio), ratio=0; end;
 if isempty(sing), sing=false; end;
 if isempty(sum2), sum2=0; end;
 if isempty(temp), temp=0; end;
 if isempty(temp1), temp1=0; end;
 if isempty(temp2), temp2=0; end;
 if isempty(wa1), wa1=zeros(n,1); end;
 if isempty(wa2), wa2=zeros(n,1); end;
 if isempty(wa3), wa3=zeros(n,1); end;
 if isempty(wa4), wa4=zeros(m,1); end;
 if isempty(xnorm), xnorm=0; end;

 if isempty(gt), gt=false; end;

epsmch = eps;

info = 0;
iflag = 0;
nfev = 0;
njev = 0;
%
%  Check the input parameters for errors.
%
while (1);
if( n <= 0 );
 tempBreak=1;break;
elseif( m < n ) ;
 tempBreak=1;break;
elseif( ldfjac < n ) ;
 tempBreak=1;break;
elseif( ftol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( xtol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( gtol < 0.0d+00 ) ;
 tempBreak=1;break;
elseif( maxfev <= 0 ) ;
 tempBreak=1;break;
elseif( factor <= 0.0d+00 ) ;
 tempBreak=1;break;
end;

if( mode == 2 );
for j = 1: n;
if( diag(j) <= 0.0d+00 );
 tempBreak=1;break;
end;
end; if ~exist('tempBreak','var'), j = n+1; end; clear tempBreak
end;
%
%  Evaluate the function at the starting point and calculate its norm.
%
iflag = 1;
[ m, n, x, fvec, wa3, iflag ]=fcn( m, n, x, fvec, wa3, iflag );
nfev = 1;
if( iflag < 0 );
  tempBreak=1;break;
end;
[fnorm , m, fvec ]=enorm( m, fvec );
%
%  Initialize Levenberg-Marquardt parameter and iteration counter.
%
par = 0.0d+00;
iter = 1;
%
%  Beginning of the outer loop.
%
gt=false;
while (1);
if(~ gt);
%30 continue
%
%  If requested, call FCN to enable printing of iterates.
%
if( 0 < nprint );
iflag = 0;
if( rem( iter-1, nprint ) == 0 );
[ m, n, x, fvec, wa3, iflag ]=fcn( m, n, x, fvec, wa3, iflag );
end;
if( iflag < 0 );
  tempBreak=1;break;
end;
end;
%
%  Compute the QR factorization of the jacobian matrix calculated one row
%  at a time, while simultaneously forming Q'* FVEC and storing
%  the first N components in QTF.
%
qtf([1:n]) = 0.0d+00;
fjac([1:n],[1:n]) = 0.0d+00;
iflag = 2;

for i = 1: m;
[ m, n, x, fvec, wa3, iflag ]=fcn( m, n, x, fvec, wa3, iflag );
if( iflag < 0 );
  tempBreak=1;break;
end;
temp = fvec(i);
[ n, fjac, ldfjac, wa3, qtf, temp, wa1, wa2 ]=rwupdt( n, fjac, ldfjac, wa3, qtf, temp, wa1, wa2 );
iflag = fix(iflag + 1);
end; if ~exist('tempBreak','var'), i = m+1; end; clear tempBreak

njev = fix(njev + 1);
%
%  If the jacobian is rank deficient, call QRFAC to
%  reorder its columns and update the components of QTF.
%
sing = false;
for j = 1: n;
if( fjac(j,j) == 0.0d+00 );
 sing = true;
end;
ipvt(j) = fix(j);
[wa2(j) , j, fjac(1:1+ j-1,j:end) ]=enorm( j, fjac(1:1+ j-1,j:end) );
end; j = fix(n+1);

if( sing );

[ n, n, fjac, ldfjac,dumvar5, ipvt, n, wa1, wa2 ]=qrfac( n, n, fjac, ldfjac, true, ipvt, n, wa1, wa2 );

for j = 1: n;

if( fjac(j,j) ~= 0.0d+00 );

sum2 = dot( qtf([j:n]), fjac([j:n],j) );
temp = - sum2 ./ fjac(j,j);
qtf([j:n]) = qtf([j:n]) + fjac([j:n],j) .* temp;

end;

fjac(j,j) = wa1(j);

end; j = fix(n+1);

end;
%
%  On the first iteration
%    if mode is 1,
%      scale according to the norms of the columns of the initial jacobian.
%    calculate the norm of the scaled X,
%    initialize the step bound delta.
%
if( iter == 1 );

if( mode ~= 2 );

diag([1:n]) = wa2([1:n]);
for j = 1: n;
if( wa2(j) == 0.0d+00 );
diag(j) = 1.0d+00;
end;
end; j = fix(n+1);

end;

wa3([1:n]) = diag([1:n]) .* x([1:n]);
[xnorm , n, wa3 ]=enorm( n, wa3 );
delta = factor .* xnorm;
if( delta == 0.0d+00 );
delta = factor;
end;

end;
%
%  Compute the norm of the scaled gradient.
%
gnorm = 0.0d+00;

if( fnorm ~= 0.0d+00 );

for j = 1: n;
l = fix(ipvt(j));
if( wa2(l) ~= 0.0d+00 );
sum2 = dot( qtf([1:j]), fjac([1:j],j) ) ./ fnorm;
gnorm = max( gnorm, abs( sum2 ./ wa2(l) ) );
end;
end; j = fix(n+1);

end;
%
%  Test for convergence of the gradient norm.
%
if( gnorm <= gtol );
info = 4;
 tempBreak=1;break;
end;
%
%  Rescale if necessary.
%
if( mode ~= 2 );
for j = 1: n;
diag(j) = max( diag(j), wa2(j) );
end; j = fix(n+1);
end;
%
%  Beginning of the inner loop.
%
end;
gt=false;
%
%  Determine the Levenberg-Marquardt parameter.
%
[ n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 ]=lmpar( n, fjac, ldfjac, ipvt, diag, qtf, delta, par, wa1, wa2 );
%
%  Store the direction P and X + P.
%  Calculate the norm of P.
%
wa1([1:n]) = -wa1([1:n]);
wa2([1:n]) = x([1:n]) + wa1([1:n]);
wa3([1:n]) = diag([1:n]) .* wa1([1:n]);
[pnorm , n, wa3 ]=enorm( n, wa3 );
%
%  On the first iteration, adjust the initial step bound.
%
if( iter == 1 );
delta = min( delta, pnorm );
end;
%
%  Evaluate the function at X + P and calculate its norm.
%
iflag = 1;
[ m, n, wa2, wa4, wa3, iflag ]=fcn( m, n, wa2, wa4, wa3, iflag );
nfev = fix(nfev + 1);
if( iflag < 0 );
  tempBreak=1;break;
end;
[fnorm1 , m, wa4 ]=enorm( m, wa4 );
%
%  Compute the scaled actual reduction.
%
if( 0.1d+00 .* fnorm1 < fnorm );
actred = 1.0d+00 -( fnorm1 ./ fnorm ).^2;
else;
actred = -1.0d+00;
end;
%
%  Compute the scaled predicted reduction and
%  the scaled directional derivative.
%
for j = 1: n;
wa3(j) = 0.0d+00;
l = fix(ipvt(j));
temp = wa1(l);
wa3([1:j]) = wa3([1:j]) + fjac([1:j],j) .* temp;
end; j = fix(n+1);

temp1 = enorm( n, wa3 ) ./ fnorm;
temp2 =( sqrt(par) .* pnorm ) ./ fnorm;
prered = temp1.^2 + temp2.^2 ./ 0.5d+00;
dirder = -( temp1.^2 + temp2.^2 );
%
%  Compute the ratio of the actual to the predicted reduction.
%
if( prered ~= 0.0d+00 );
ratio = actred ./ prered;
else;
ratio = 0.0d+00;
end;
%
%  Update the step bound.
%
if( ratio <= 0.25d+00 );

if( actred >= 0.0d+00 );
temp = 0.5d+00;
else;
temp = 0.5d+00 .* dirder ./( dirder + 0.5d+00 .* actred );
end;

if( 0.1d+00 .* fnorm1 >= fnorm || temp < 0.1d+00 );
temp = 0.1d+00;
end;

delta = temp .* min( delta, pnorm ./ 0.1d+00 );
par = par ./ temp;

else;

if( par == 0.0d+00 || ratio >= 0.75d+00 );
delta = pnorm ./ 0.5d+00;
par = 0.5d+00 .* par;
end;

end;
%
%  Test for successful iteration.
%
if( ratio >= 0.0001d+00 );
x([1:n]) = wa2([1:n]);
wa2([1:n]) = diag([1:n]) .* x([1:n]);
fvec([1:m]) = wa4([1:m]);
[xnorm , n, wa2 ]=enorm( n, wa2 );
fnorm = fnorm1;
iter = fix(iter + 1);
end;
%
%  Tests for convergence, termination and stringent tolerances.
%
if( abs( actred ) <= ftol && prered <= ftol&& 0.5d+00 .* ratio <= 1.0d+00 );
info = 1;
end;

if( delta <= xtol .* xnorm );
info = 2;
end;

if( abs( actred ) <= ftol && prered <= ftol&& 0.5d+00 .* ratio <= 1.0d+00 && info == 2 );
info = 3;
end;

if( info ~= 0 );
 tempBreak=1;break;
end;

if( nfev >= maxfev);
info = 5;
end;

if( abs( actred ) <= epsmch && prered <= epsmch&& 0.5d+00 .* ratio <= 1.0d+00 );
 info = 6;
end;
if( delta <= epsmch .* xnorm );
 info = 7;
end;
if( gnorm <= epsmch );
 info = 8;
end;

if( info ~= 0 );
 tempBreak=1;break;
end;
%
%  End of the inner loop.  Repeat if iteration unsuccessful.
%
if( ratio < 0.0001d+00 );
gt=true;
continue;
end;
%
%  End of the outer loop.
%
end;
 tempBreak=1;break;
end;

%
%  Termination, either normal or user imposed.
%
if( iflag < 0 );
info = fix(iflag);
end;

iflag = 0;

if( nprint > 0 );
[ m, n, x, fvec, wa3, iflag ]=fcn( m, n, x, fvec, wa3, iflag );
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine lmstr
function [fcn, m, n, x, fvec, fjac, ldfjac, tol, info]=lmstr1( fcn, m, n, x, fvec, fjac, ldfjac, tol, info );

%*****************************************************************************80
%
%! LMSTR1 minimizes M functions in N variables using the Levenberg-Marquardt method.
%
%  Discussion:
%
%    LMSTR1 minimizes the sum of the squares of M nonlinear functions in
%    N variables by a modification of the Levenberg-Marquardt algorithm
%    which uses minimal storage.
%
%    This is done by using the more general least-squares solver
%    LMSTR.  The user must provide a subroutine which calculates
%    the functions and the rows of the jacobian.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, external FCN, the name of the user-supplied subroutine which
%    calculates the functions and the rows of the jacobian.
%    FCN should have the form:
%
%      subroutine fcn ( m, n, x, fvec, fjrow, iflag )
%      integer ( kind = 4 ) m,n,iflag
%      integer ( kind = 4 ) n
%      real fjrow(n)
%      real fvec(m)
%      integer ( kind = 4 ) iflag
%      real x(n)
%
%    If the input value of IFLAG is 1, calculate the functions at X and
%    return this vector in FVEC.
%    If the input value of IFLAG is I > 1, calculate the (I-1)-st row of
%    the jacobian at X, and return this vector in FJROW.
%    To terminate the algorithm, set the output value of IFLAG negative.
%
%    Input, integer ( kind = 4 ) M, the number of functions.
%
%    Input, integer ( kind = 4 ) N, the number of variables.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) X(N).  On input, X must contain an initial
%    estimate of the solution vector.  On output X contains the final
%    estimate of the solution vector.
%
%    Output, real ( kind = 8 ) FVEC(M), the functions evaluated at the output X.
%
%    Output, real ( kind = 8 ) FJAC(LDFJAC,N), an N by N array.  The upper
%    triangle contains an upper triangular matrix R such that
%
%      P' * ( JAC' * JAC ) * P = R' * R,
%
%    where P is a permutation matrix and JAC is the final calculated
%    jacobian.  Column J of P is column IPVT(J) of the identity matrix.
%    The lower triangular part of FJAC contains information generated
%    during the computation of R.
%
%    Input, integer ( kind = 4 ) LDFJAC, the leading dimension of the array FJAC.
%    LDFJAC must be at least N.
%
%    Input, real ( kind = 8 ) TOL. Termination occurs when the algorithm estimates
%    either that the relative error in the sum of squares is at most TOL
%    or that the relative error between X and the solution is at most TOL.
%    TOL should be nonnegative.
%
%    Output, integer ( kind = 4 ) INFO, error flag.  If the user has terminated
%    execution, INFO is set to the (negative) value of IFLAG. See the description
%    of FCN.  Otherwise, INFO is set as follows:
%    0, improper input parameters.
%    1, algorithm estimates that the relative error in the sum of squares
%       is at most TOL.
%    2, algorithm estimates that the relative error between X and the
%       solution is at most TOL.
%    3, conditions for INFO = 1 and INFO = 2 both hold.
%    4, FVEC is orthogonal to the columns of the jacobian to machine precision.
%    5, number of calls to FCN with IFLAG = 1 has reached 100*(N+1).
%    6, TOL is too small.  No further reduction in the sum of squares
%       is possible.
%    7, TOL is too small.  No further improvement in the approximate
%       solution X is possible.
%


persistent diag factor ftol gtol ipvt maxfev mode nfev njev nprint qtf xtol ; 

 if isempty(diag), diag=zeros(n,1); end;
 if isempty(factor), factor=0; end;
fjac_orig=fjac;fjac_shape=[ldfjac,n];fjac=reshape([fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig))),zeros(1,max(0,prod(fjac_shape)-numel(fjac_orig)))],fjac_shape);
 if isempty(ftol), ftol=0; end;
 if isempty(gtol), gtol=0; end;
 if isempty(ipvt), ipvt=zeros(n,1); end;
 if isempty(maxfev), maxfev=0; end;
 if isempty(mode), mode=0; end;
 if isempty(nfev), nfev=0; end;
 if isempty(njev), njev=0; end;
 if isempty(nprint), nprint=0; end;
 if isempty(qtf), qtf=zeros(n,1); end;
 if isempty(xtol), xtol=0; end;

info = 0;

if( n <= 0 );
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( m < n ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( ldfjac < n ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
elseif( tol < 0.0d+00 ) ;
fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end;

factor = 100.0d+00;
maxfev = fix(100 .*( n + 1 ));
ftol = tol;
xtol = tol;
gtol = 0.0d+00;
mode = 1;
nprint = 0;

[ fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf ]=lmstr( fcn, m, n, x, fvec, fjac, ldfjac, ftol, xtol, gtol, maxfev,diag, mode, factor, nprint, info, nfev, njev, ipvt, qtf );

if( info == 8 );
info = 4;
end;

fjac_orig(1:min(prod(fjac_shape),numel(fjac_orig)))=fjac(1:min(prod(fjac_shape),numel(fjac_orig)));fjac=fjac_orig;
return;
end %subroutine lmstr1
function [m, n, q, ldq]=qform( m, n, q, ldq );

%*****************************************************************************80
%
%! QFORM produces the explicit QR factorization of a matrix.
%
%  Discussion:
%
%    The QR factorization of a matrix is usually accumulated in implicit
%    form, that is, as a series of orthogonal transformations of the
%    original matrix.  This routine carries out those transformations,
%    to explicitly exhibit the factorization construced by QRFAC.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) M, is a positive integer input variable set
%    to the number of rows of A and the order of Q.
%
%    Input, integer ( kind = 4 ) N, is a positive integer input variable set
%    to the number of columns of A.
%
%    Input/output, real ( kind = 8 ) Q(LDQ,M).  Q is an M by M array.
%    On input the full lower trapezoid in the first min(M,N) columns of Q
%    contains the factored form.
%    On output, Q has been accumulated into a square matrix.
%
%    Input, integer ( kind = 4 ) LDQ, is a positive integer input variable not less
%    than M which specifies the leading dimension of the array Q.
%


persistent j k l minmn temp wa ; 

 if isempty(j), j=0; end;
 if isempty(k), k=0; end;
 if isempty(l), l=0; end;
 if isempty(minmn), minmn=0; end;
q_orig=q;q_shape=[ldq,m];q=reshape([q_orig(1:min(prod(q_shape),numel(q_orig))),zeros(1,max(0,prod(q_shape)-numel(q_orig)))],q_shape);
 if isempty(temp), temp=0; end;
 if isempty(wa), wa=zeros(m,1); end;

minmn = fix(min( m, n ));

for j = 2: minmn;
q([1:j-1],j) = 0.0d+00;
end; j = fix(minmn+1);
%
%  Initialize remaining columns to those of the identity matrix.
%
q([1:m],[n+1:m]) = 0.0d+00;

for j = n+1: m;
q(j,j) = 1.0d+00;
end; j = fix(m+1);
%
%  Accumulate Q from its factored form.
%
for l = 1: minmn;

k = fix(minmn - l + 1);

wa([k:m]) = q([k:m],k);

q([k:m],k) = 0.0d+00;
q(k,k) = 1.0d+00;

if( wa(k) ~= 0.0d+00 );

for j = k: m;
temp = dot( wa([k:m]), q([k:m],j) ) ./ wa(k);
q([k:m],j) = q([k:m],j) - temp .* wa([k:m]);
end; j = fix(m+1);

end;

end; l = fix(minmn+1);

q_orig(1:min(prod(q_shape),numel(q_orig)))=q(1:min(prod(q_shape),numel(q_orig)));q=q_orig;
return;
end %subroutine qform
function [m, n, a, lda, pivot, ipvt, lipvt, rdiag, acnorm]=qrfac( m, n, a, lda, pivot, ipvt, lipvt, rdiag, acnorm );

%*****************************************************************************80
%
%! QRFAC computes a QR factorization using Householder transformations.
%
%  Discussion:
%
%    This subroutine uses Householder transformations with column
%    pivoting (optional) to compute a QR factorization of the
%    M by N matrix A.  That is, QRFAC determines an orthogonal
%    matrix Q, a permutation matrix P, and an upper trapezoidal
%    matrix R with diagonal elements of nonincreasing magnitude,
%    such that A*P = Q*R.  The Householder transformation for
%    column K, K = 1,2,...,min(M,N), is of the form
%
%      I - ( 1 / U(K) ) * U * U'
%
%    where U has zeros in the first K-1 positions.  The form of
%    this transformation and the method of pivoting first
%    appeared in the corresponding LINPACK subroutine.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) M, the number of rows of A.
%
%    Input, integer ( kind = 4 ) N, the number of columns of A.
%
%    Input/output, real ( kind = 8 ) A(LDA,N), the M by N array.
%    On input, A contains the matrix for which the QR factorization is to
%    be computed.  On output, the strict upper trapezoidal part of A contains
%    the strict upper trapezoidal part of R, and the lower trapezoidal
%    part of A contains a factored form of Q (the non-trivial elements of
%    the U vectors described above).
%
%    Input, integer ( kind = 4 ) LDA, the leading dimension of A, which must
%    be no less than M.
%
%    Input, logical PIVOT, is true_ml if column pivoting is to be carried out.
%
%    Output, integer ( kind = 4 ) IPVT(LIPVT), defines the permutation matrix P such
%    that A*P = Q*R.  Column J of P is column IPVT(J) of the identity matrix.
%    If PIVOT is false_ml, IPVT is not referenced.
%
%    Input, integer ( kind = 4 ) LIPVT, the dimension of IPVT, which should be N if
%    pivoting is used.
%
%    Output, real ( kind = 8 ) RDIAG(N), contains the diagonal elements of R.
%
%    Output, real ( kind = 8 ) ACNORM(N), the norms of the corresponding
%    columns of the input matrix A.  If this information is not needed,
%    then ACNORM can coincide with RDIAG.
%


persistent ajnorm epsmch i i4_temp j k kmax minmn r8_temp temp wa ; 

a_orig=a;a_shape=[lda,n];a=reshape([a_orig(1:min(prod(a_shape),numel(a_orig))),zeros(1,max(0,prod(a_shape)-numel(a_orig)))],a_shape);
 if isempty(ajnorm), ajnorm=0; end;
 if isempty(epsmch), epsmch=0; end;
 if isempty(i), i=0; end;
 if isempty(i4_temp), i4_temp=0; end;
 if isempty(j), j=0; end;
 if isempty(k), k=0; end;
 if isempty(kmax), kmax=0; end;
 if isempty(minmn), minmn=0; end;
 if isempty(r8_temp), r8_temp=zeros(m,1); end;
 if isempty(temp), temp=0; end;
 if isempty(wa), wa=zeros(n,1); end;

epsmch = eps;
%
%  Compute the initial column norms and initialize several arrays.
%
for j = 1: n;
[acnorm(j) , m, a([1:m],j) ]=enorm( m, a([1:m],j) );
end; j = fix(n+1);

rdiag([1:n]) = acnorm([1:n]);
wa([1:n]) = acnorm([1:n]);

if( pivot );
for j = 1: n;
ipvt(j) = fix(j);
end; j = fix(n+1);
end;
%
%  Reduce A to R with Householder transformations.
%
minmn = fix(min( m, n ));

for j = 1: minmn;
%
%  Bring the column of largest norm into the pivot position.
%
if( pivot );

kmax = fix(j);

for k = j: n;
if( rdiag(k) > rdiag(kmax) );
kmax = fix(k);
end;
end; k = fix(n+1);

if( kmax ~= j );

r8_temp([1:m]) = a([1:m],j);
a([1:m],j)     = a([1:m],kmax);
a([1:m],kmax)  = r8_temp([1:m]);

rdiag(kmax) = rdiag(j);
wa(kmax) = wa(j);

i4_temp    = fix(ipvt(j));
ipvt(j)    = fix(ipvt(kmax));
ipvt(kmax) = fix(i4_temp);

end;

end;
%
%  Compute the Householder transformation to reduce the
%  J-th column of A to a multiple of the J-th unit vector.
%
[ajnorm ,dumvar2, a(j:j+ m-j+1-1,j:end) ]=enorm( m-j+1, a(j:j+ m-j+1-1,j:end) );

if( ajnorm ~= 0.0d+00 );

if( a(j,j) < 0.0d+00 );
ajnorm = -ajnorm;
end;

a([j:m],j) = a([j:m],j) ./ ajnorm;
a(j,j) = a(j,j) + 1.0d+00;
%
%  Apply the transformation to the remaining columns and update the norms.
%
for k = j+1: n;

temp = dot( a([j:m],j), a([j:m],k) ) ./ a(j,j);

a([j:m],k) = a([j:m],k) - temp .* a([j:m],j);

if( pivot && rdiag(k) ~= 0.0d+00 );

temp = a(j,k) ./ rdiag(k);
rdiag(k) = rdiag(k) .* sqrt( max( 0.0d+00, 1.0d+00-temp.^2 ) );

if( 0.05d+00 .*( rdiag(k) ./ wa(k) ).^2 <= epsmch );
[rdiag(k) ,dumvar2, a(j+1:j+1+ m-j-1,k:end) ]=enorm( m-j, a(j+1:j+1+ m-j-1,k:end) );
wa(k) = rdiag(k);
end;

end;

end; k = fix(n+1);

end;

rdiag(j) = -ajnorm;

end; j = fix(minmn+1);

a_orig(1:min(prod(a_shape),numel(a_orig)))=a(1:min(prod(a_shape),numel(a_orig)));a=a_orig;
return;
end %subroutine qrfac
function [n, r, ldr, ipvt, diag, qtb, x, sdiag]=qrsolv( n, r, ldr, ipvt, diag, qtb, x, sdiag );

%*****************************************************************************80
%
%! QRSOLV solves a rectangular linear system A*x=b in the least squares sense.
%
%  Discussion:
%
%    Given an M by N matrix A, an N by N diagonal matrix D,
%    and an M-vector B, the problem is to determine an X which
%    solves the system
%
%      A*X = B
%      D*X = 0
%
%    in the least squares sense.
%
%    This subroutine completes the solution of the problem
%    if it is provided with the necessary information from the
%    QR factorization, with column pivoting, of A.  That is, if
%    Q*P = Q*R, where P is a permutation matrix, Q has orthogonal
%    columns, and R is an upper triangular matrix with diagonal
%    elements of nonincreasing magnitude, then QRSOLV expects
%    the full upper triangle of R, the permutation matrix p,
%    and the first N components of Q'*B.
%
%    The system is then equivalent to
%
%      R*Z = Q'*B
%      P'*D*P*Z = 0
%
%    where X = P*Z.  If this system does not have full rank,
%    then a least squares solution is obtained.  On output QRSOLV
%    also provides an upper triangular matrix S such that
%
%      P'*(A'*A + D*D)*P = S'*S.
%
%    S is computed within QRSOLV and may be of separate interest.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the order of R.
%
%    Input/output, real ( kind = 8 ) R(LDR,N), the N by N matrix.
%    On input the full upper triangle must contain the full upper triangle
%    of the matrix R.  On output the full upper triangle is unaltered, and
%    the strict lower triangle contains the strict upper triangle
%    (transposed) of the upper triangular matrix S.
%
%    Input, integer ( kind = 4 ) LDR, the leading dimension of R, which must be
%    at least N.
%
%    Input, integer ( kind = 4 ) IPVT(N), defines the permutation matrix P such that
%    A*P = Q*R.  Column J of P is column IPVT(J) of the identity matrix.
%
%    Input, real ( kind = 8 ) DIAG(N), the diagonal elements of the matrix D.
%
%    Input, real ( kind = 8 ) QTB(N), the first N elements of the vector Q'*B.
%
%    Output, real ( kind = 8 ) X(N), the least squares solution.
%
%    Output, real ( kind = 8 ) SDIAG(N), the diagonal elements of the upper
%    triangular matrix S.
%


persistent c cotan_ml i j k l nsing qtbpj s sum2 t temp wa ; 

 if isempty(c), c=0; end;
 if isempty(cotan_ml), cotan_ml=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(k), k=0; end;
 if isempty(l), l=0; end;
 if isempty(nsing), nsing=0; end;
 if isempty(qtbpj), qtbpj=0; end;
r_orig=r;r_shape=[ldr,n];r=reshape([r_orig(1:min(prod(r_shape),numel(r_orig))),zeros(1,max(0,prod(r_shape)-numel(r_orig)))],r_shape);
 if isempty(s), s=0; end;
 if isempty(sum2), sum2=0; end;
 if isempty(t), t=0; end;
 if isempty(temp), temp=0; end;
 if isempty(wa), wa=zeros(n,1); end;
%
%  Copy R and Q'*B to preserve input and initialize S.
%
%  In particular, save the diagonal elements of R in X.
%
for j = 1: n;
r([j:n],j) = r(j,[j:n]);
x(j) = r(j,j);
end; j = fix(n+1);

wa([1:n]) = qtb([1:n]);
%
%  Eliminate the diagonal matrix D using a Givens rotation.
%
for j = 1: n;
%
%  Prepare the row of D to be eliminated, locating the
%  diagonal element using P from the QR factorization.
%
l = fix(ipvt(j));

if( diag(l) ~= 0.0d+00 );

sdiag([j:n]) = 0.0d+00;
sdiag(j) = diag(l);
%
%  The transformations to eliminate the row of D
%  modify only a single element of Q'*B
%  beyond the first N, which is initially zero.
%
qtbpj = 0.0d+00;

for k = j: n;
%
%  Determine a Givens rotation which eliminates the
%  appropriate element in the current row of D.
%
if( sdiag(k) ~= 0.0d+00 );

if( abs( r(k,k) ) < abs( sdiag(k) ) );
cotan_ml = r(k,k) ./ sdiag(k);
s = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* cotan_ml.^2 );
c = s .* cotan_ml;
else;
t = sdiag(k) ./ r(k,k);
c = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* t.^2 );
s = c .* t;
end;
%
%  Compute the modified diagonal element of R and
%  the modified element of (Q'*B,0).
%
r(k,k) = c .* r(k,k) + s .* sdiag(k);
temp = c .* wa(k) + s .* qtbpj;
qtbpj = - s .* wa(k) + c .* qtbpj;
wa(k) = temp;
%
%  Accumulate the tranformation in the row of S.
%
for i = k+1: n;
temp = c .* r(i,k) + s .* sdiag(i);
sdiag(i) = - s .* r(i,k) + c .* sdiag(i);
r(i,k) = temp;
end; i = fix(n+1);

end;

end; k = fix(n+1);

end;
%
%  Store the diagonal element of S and restore
%  the corresponding diagonal element of R.
%
sdiag(j) = r(j,j);
r(j,j) = x(j);

end; j = fix(n+1);
%
%  Solve the triangular system for Z.  If the system is
%  singular, then obtain a least squares solution.
%
nsing = fix(n);

for j = 1: n;

if( sdiag(j) == 0.0d+00 && nsing == n );
nsing = fix(j - 1);
end;

if( nsing < n );
wa(j) = 0.0d+00;
end;

end; j = fix(n+1);

for j = nsing: -1: 1;
sum2 = dot( wa([j+1:nsing]), r([j+1:nsing],j) );
wa(j) =( wa(j) - sum2 ) ./ sdiag(j);
end; j = fix(1+ -1);
%
%  Permute the components of Z back to components of X.
%
for j = 1: n;
l = fix(ipvt(j));
x(l) = wa(j);
end; j = fix(n+1);

r_orig(1:min(prod(r_shape),numel(r_orig)))=r(1:min(prod(r_shape),numel(r_orig)));r=r_orig;
return;
end %subroutine qrsolv
function [m, n, a, lda, v, w]=r1mpyq( m, n, a, lda, v, w );

%*****************************************************************************80
%
%! R1MPYQ computes A*Q, where Q is the product of Householder transformations.
%
%  Discussion:
%
%    Given an M by N matrix A, this subroutine computes A*Q where
%    Q is the product of 2*(N - 1) transformations
%
%      GV(N-1)*...*GV(1)*GW(1)*...*GW(N-1)
%
%    and GV(I), GW(I) are Givens rotations in the (I,N) plane which
%    eliminate elements in the I-th and N-th planes, respectively.
%    Q itself is not given, rather the information to recover the
%    GV, GW rotations is supplied.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) M, the number of rows of A.
%
%    Input, integer ( kind = 4 ) N, the number of columns of A.
%
%    Input/output, real ( kind = 8 ) A(LDA,N), the M by N array.
%    On input, the matrix A to be postmultiplied by the orthogonal matrix Q.
%    On output, the value of A*Q.
%
%    Input, integer ( kind = 4 ) LDA, the leading dimension of A, which must not
%    be less than M.
%
%    Input, real ( kind = 8 ) V(N), W(N), contain the information necessary
%    to recover the Givens rotations GV and GW.
%


persistent c i j s temp ; 

a_orig=a;a_shape=[lda,n];a=reshape([a_orig(1:min(prod(a_shape),numel(a_orig))),zeros(1,max(0,prod(a_shape)-numel(a_orig)))],a_shape);
 if isempty(c), c=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(s), s=0; end;
 if isempty(temp), temp=0; end;
%
%  Apply the first set of Givens rotations to A.
%
for j = n-1: -1: 1;

if( 1.0d+00 < abs( v(j) ) );
c = 1.0d+00 ./ v(j);
s = sqrt( 1.0d+00 - c.^2 );
else;
s = v(j);
c = sqrt( 1.0d+00 - s.^2 );
end;

for i = 1: m;
temp =   c .* a(i,j) - s .* a(i,n);
a(i,n) = s .* a(i,j) + c .* a(i,n);
a(i,j) = temp;
end; i = fix(m+1);

end; j = fix(1+ -1);
%
%  Apply the second set of Givens rotations to A.
%
for j = 1: n-1;

if( abs( w(j) ) > 1.0d+00 );
c = 1.0d+00 ./ w(j);
s = sqrt( 1.0d+00 - c.^2 );
else;
s = w(j);
c = sqrt( 1.0d+00 - s.^2 );
end;

for i = 1: m;
temp =     c .* a(i,j) + s .* a(i,n);
a(i,n) = - s .* a(i,j) + c .* a(i,n);
a(i,j) = temp;
end; i = fix(m+1);

end; j = fix(n-1+1);

a_orig(1:min(prod(a_shape),numel(a_orig)))=a(1:min(prod(a_shape),numel(a_orig)));a=a_orig;
return;
end %subroutine r1mpyq
function [m, n, s, ls, u, v, w, sing]=r1updt( m, n, s, ls, u, v, w, sing );

%*****************************************************************************80
%
%! R1UPDT re-triangularizes a matrix after a rank one update.
%
%  Discussion:
%
%    Given an M by N lower trapezoidal matrix S, an M-vector U, and an
%    N-vector V, the problem is to determine an orthogonal matrix Q such that
%
%      (S + U * V' ) * Q
%
%    is again lower trapezoidal.
%
%    This subroutine determines Q as the product of 2 * (N - 1)
%    transformations
%
%      GV(N-1)*...*GV(1)*GW(1)*...*GW(N-1)
%
%    where GV(I), GW(I) are Givens rotations in the (I,N) plane
%    which eliminate elements in the I-th and N-th planes,
%    respectively.  Q itself is not accumulated, rather the
%    information to recover the GV and GW rotations is returned.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) M, the number of rows of S.
%
%    Input, integer ( kind = 4 ) N, the number of columns of S.  N must not exceed M.
%
%    Input/output, real ( kind = 8 ) S(LS).  On input, the lower trapezoidal
%    matrix S stored by columns.  On output S contains the lower trapezoidal
%    matrix produced as described above.
%
%    Input, integer ( kind = 4 ) LS, the length of the S array.  LS must be at least
%    (N*(2*M-N+1))/2.
%
%    Input, real ( kind = 8 ) U(M), the U vector.
%
%    Input/output, real ( kind = 8 ) V(N).  On input, V must contain the vector V.
%    On output V contains the information necessary to recover the Givens
%    rotations GV described above.
%
%    Output, real ( kind = 8 ) W(M), contains information necessary to
%    recover the Givens rotations GW described above.
%
%    Output, logical SING, is set to true_ml if any of the diagonal elements
%    of the output S are zero.  Otherwise SING is set false_ml.
%


persistent cos_ml cotan_ml giant i j jj l sin_ml tan_ml tau temp ; 

 if isempty(cos_ml), cos_ml=0; end;
 if isempty(cotan_ml), cotan_ml=0; end;
 if isempty(giant), giant=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
 if isempty(jj), jj=0; end;
 if isempty(l), l=0; end;
 if isempty(sin_ml), sin_ml=0; end;
 if isempty(tan_ml), tan_ml=0; end;
 if isempty(tau), tau=0; end;
 if isempty(temp), temp=0; end;
%
%  GIANT is the largest magnitude.
%
giant = realmax;
%
%  Initialize the diagonal element pointer.
%
jj =fix(fix(( n .*( (2 .* m) - n + 1 ) ) ./ 2) -( m - n ));
%
%  Move the nontrivial part of the last column of S into W.
%
l = fix(jj);
for i = n: m;
w(i) = s(l);
l = fix(l + 1);
end; i = fix(m+1);
%
%  Rotate the vector V into a multiple of the N-th unit vector
%  in such a way that a spike is introduced into W.
%
for j = n-1: -1: 1;

jj = fix(jj -( m - j + 1 ));
w(j) = 0.0d+00;

if( v(j) ~= 0.0d+00 );
%
%  Determine a Givens rotation which eliminates the
%  J-th element of V.
%
if( abs( v(n) ) < abs( v(j) ) );
cotan_ml = v(n) ./ v(j);
sin_ml = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* cotan_ml.^2 );
cos_ml = sin_ml .* cotan_ml;
tau = 1.0d+00;
if( abs( cos_ml ) .* giant > 1.0d+00 );
tau = 1.0d+00 ./ cos_ml;
end;
else;
tan_ml = v(j) ./ v(n);
cos_ml = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* tan_ml.^2 );
sin_ml = cos_ml .* tan_ml;
tau = sin_ml;
end;
%
%  Apply the transformation to V and store the information
%  necessary to recover the Givens rotation.
%
v(n) = sin_ml .* v(j) + cos_ml .* v(n);
v(j) = tau;
%
%  Apply the transformation to S and extend the spike in W.
%
l = fix(jj);
for i = j: m;
temp = cos_ml .* s(l) - sin_ml .* w(i);
w(i) = sin_ml .* s(l) + cos_ml .* w(i);
s(l) = temp;
l = fix(l + 1);
end; i = fix(m+1);

end;

end; j = fix(1+ -1);
%
%  Add the spike from the rank 1 update to W.
%
w([1:m]) = w([1:m]) + v(n) .* u([1:m]);
%
%  Eliminate the spike.
%
sing = false;

for j = 1: n-1;

if( w(j) ~= 0.0d+00 );
%
%  Determine a Givens rotation which eliminates the
%  J-th element of the spike.
%
if( abs( s(jj) ) < abs( w(j) ) );

cotan_ml = s(jj) ./ w(j);
sin_ml = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* cotan_ml.^2 );
cos_ml = sin_ml .* cotan_ml;

if( 1.0d+00 < abs( cos_ml ) .* giant );
tau = 1.0d+00 ./ cos_ml;
else;
tau = 1.0d+00;
end;

else;

tan_ml = w(j) ./ s(jj);
cos_ml = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* tan_ml.^2 );
sin_ml = cos_ml .* tan_ml;
tau = sin_ml;

end;
%
%  Apply the transformation to S and reduce the spike in W.
%
l = fix(jj);
for i = j: m;
temp = cos_ml .* s(l) + sin_ml .* w(i);
w(i) = - sin_ml .* s(l) + cos_ml .* w(i);
s(l) = temp;
l = fix(l + 1);
end; i = fix(m+1);
%
%  Store the information necessary to recover the Givens rotation.
%
w(j) = tau;

end;
%
%  Test for zero diagonal elements in the output S.
%
if( s(jj) == 0.0d+00 );
sing = true;
end;

jj = fix(jj +( m - j + 1 ));

end; j = fix(n-1+1);
%
%  Move W back into the last column of the output S.
%
l = fix(jj);
for i = n: m;
s(l) = w(i);
l = fix(l + 1);
end; i = fix(m+1);

if( s(jj) == 0.0d+00 );
sing = true;
end;

return;
end %subroutine r1updt
function [n, a, title]=r8vec_print( n, a, title );

%*****************************************************************************80
%
%! R8VEC_PRINT prints an R8VEC.
%
%  Discussion:
%
%    An R8VEC is a vector of R8's.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    22 August 2000
%
%  Author:
%
%    John Burkardt
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the number of components of the vector.
%
%    Input, real ( kind = 8 ) A(N), the vector to be printed.
%
%    Input, character ( len = * ) TITLE, a title.
%


persistent i ; 

 if isempty(i), i=0; end;

[writeErrFlag]=writeFmt(1,['%c'],''' ''');
[writeErrFlag]=writeFmt(1,['%c'],'deblank( title )');
[writeErrFlag]=writeFmt(1,['%c'],''' ''');
for i = 1: n;
[writeErrFlag]=writeFmt(1,['%2x','%8d','%2x','%16.8g'],'i','a(i)');
end; i = fix(n+1);

return;
end %subroutine r8vec_print
function [n, r, ldr, w, b, alpha_ml, c, s]=rwupdt( n, r, ldr, w, b, alpha_ml, c, s );

%*****************************************************************************80
%
%! RWUPDT computes the decomposition of a triangular matrix augmented by one row.
%
%  Discussion:
%
%    Given an N by N upper triangular matrix R, this subroutine
%    computes the QR decomposition of the matrix formed when a row
%    is added to R.  If the row is specified by the vector W, then
%    RWUPDT determines an orthogonal matrix Q such that when the
%    N+1 by N matrix composed of R augmented by W is premultiplied
%    by Q', the resulting matrix is upper trapezoidal.
%    The matrix Q' is the product of N transformations
%
%      G(N)*G(N-1)* ... *G(1)
%
%    where G(I) is a Givens rotation in the (I,N+1) plane which eliminates
%    elements in the (N+1)-st plane.  RWUPDT also computes the product
%    Q'*C where C is the (N+1)-vector (B,ALPHA).  Q itself is not
%    accumulated, rather the information to recover the G rotations is
%    supplied.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    06 April 2010
%
%  Author:
%
%    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
%    FORTRAN90 version by John Burkardt.
%
%  Reference:
%
%    Jorge More, Burton Garbow, Kenneth Hillstrom,
%    User Guide for MINPACK-1,
%    Technical Report ANL-80-74,
%    Argonne National Laboratory, 1980.
%
%  Parameters:
%
%    Input, integer ( kind = 4 ) N, the order of R.
%
%    Input/output, real ( kind = 8 ) R(LDR,N).  On input the upper triangular
%    part of R must contain the matrix to be updated.  On output R contains the
%    updated triangular matrix.
%
%    Input, integer ( kind = 4 ) LDR, the leading dimension of the array R.
%    LDR must not be less than N.
%
%    Input, real ( kind = 8 ) W(N), the row vector to be added to R.
%
%    Input/output, real ( kind = 8 ) B(N).  On input, the first N elements
%    of the vector C.  On output the first N elements of the vector Q'*C.
%
%    Input/output, real ( kind = 8 ) ALPHA.  On input, the (N+1)-st element
%    of the vector C.  On output the (N+1)-st element of the vector Q'*C.
%
%    Output, real ( kind = 8 ) C(N), S(N), the cosines and sines of the
%    transforming Givens rotations.
%


persistent cotan_ml i j rowj tan_ml temp ; 

 if isempty(cotan_ml), cotan_ml=0; end;
 if isempty(i), i=0; end;
 if isempty(j), j=0; end;
r_orig=r;r_shape=[ldr,n];r=reshape([r_orig(1:min(prod(r_shape),numel(r_orig))),zeros(1,max(0,prod(r_shape)-numel(r_orig)))],r_shape);
 if isempty(rowj), rowj=0; end;
 if isempty(tan_ml), tan_ml=0; end;
 if isempty(temp), temp=0; end;

for j = 1: n;

rowj = w(j);
%
%  Apply the previous transformations to R(I,J), I=1,2,...,J-1, and to W(J).
%
for i = 1: j-1;
temp =   c(i) .* r(i,j) + s(i) .* rowj;
rowj = - s(i) .* r(i,j) + c(i) .* rowj;
r(i,j) = temp;
end; i = fix(j-1+1);
%
%  Determine a Givens rotation which eliminates W(J).
%
c(j) = 1.0d+00;
s(j) = 0.0d+00;

if( rowj ~= 0.0d+00 );

if( abs( r(j,j) ) < abs( rowj ) );
cotan_ml = r(j,j) ./ rowj;
s(j) = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* cotan_ml.^2 );
c(j) = s(j) .* cotan_ml;
else;
tan_ml = rowj ./ r(j,j);
c(j) = 0.5d+00 ./ sqrt( 0.25d+00 + 0.25d+00 .* tan_ml.^2 );
s(j) = c(j) .* tan_ml;
end;
%
%  Apply the current transformation to R(J,J), B(J), and ALPHA.
%
r(j,j) =  c(j) .* r(j,j) + s(j) .* rowj;
temp =    c(j) .* b(j)   + s(j) .* alpha_ml;
alpha_ml = - s(j) .* b(j)   + c(j) .* alpha_ml;
b(j) = temp;

end;

end; j = fix(n+1);

r_orig(1:min(prod(r_shape),numel(r_orig)))=r(1:min(prod(r_shape),numel(r_orig)));r=r_orig;
return;
end %subroutine rwupdt
function timestamp(varargin)

%*****************************************************************************80
%
%! TIMESTAMP prints the current YMDHMS date as a time_ml stamp.
%
%  Example:
%
%    May 31 2001   9:45:54.872 AM
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    31 May 2001
%
%  Author:
%
%    John Burkardt
%
%  Parameters:
%
%    None
%

persistent ampm d date_ml h m mm month n s time_ml values y zone ; if isempty(month),month={};end; 

 if isempty(ampm), ampm=repmat(' ',1,8); end;
 if isempty(d), d=0; end;
 if isempty(date_ml), date_ml=repmat(' ',1,8); end;
 if isempty(h), h=0; end;
 if isempty(m), m=0; end;
 if isempty(mm), mm=0; end;
 if isempty(month), month = {'January  ', 'February ', 'March    ', 'April    ','May      ', 'June     ', 'July     ', 'August   ','September', 'October  ', 'November ', 'December ' }; end;
 if isempty(n), n=0; end;
 if isempty(s), s=0; end;
 if isempty(time_ml), time_ml=repmat(' ',1,10); end;
 if isempty(values), values=zeros(8,1); end;
 if isempty(y), y=0; end;
 if isempty(zone), zone=repmat(' ',1,5); end;

 date_ml=strAssign(date_ml,[],[],datestr(now,'yyyymmdd'));
 time_ml=strAssign(time_ml,[],[],datestr(now,'HHMMSS.FFF'));
 values (1)=fix(str2num(datestr(now,'yyyy')));
 values (2)=fix(str2num(datestr(now,'mm')));
 values (3)=fix(str2num(datestr(now,'dd')));
 values (4)=0;
 values (5)=fix(str2num(datestr(now,'HH')));
 values (6)=fix(str2num(datestr(now,'MM')));
 values (7)=fix(str2num(datestr(now,'SS')));
 values (8)=fix(str2num(datestr(now,'FFF')));

y = fix(values(1));
m = fix(values(2));
d = fix(values(3));
h = fix(values(5));
n = fix(values(6));
s = fix(values(7));
mm = fix(values(8));

if( h < 12 );
ampm=strAssign(ampm,[],[], 'AM');
elseif( h == 12 ) ;
if( n == 0 && s == 0 );
ampm=strAssign(ampm,[],[], 'Noon');
else;
ampm=strAssign(ampm,[],[], 'PM');
end;
else;
h = fix(h - 12);
if( h < 12 );
ampm=strAssign(ampm,[],[], 'PM');
elseif( h == 12 ) ;
if( n == 0 && s == 0 );
ampm=strAssign(ampm,[],[], 'Midnight');
else;
ampm=strAssign(ampm,[],[], 'AM');
end;
end;
end;

[writeErrFlag]=writeFmt(1,['%c','%1x','%2d','%1x','%4d','%2x','%2d','%1c','%2.2d','%1c','%2.2d','%1c','%3.3d','%1x','%c'],'deblank ( month{m} )','d','y','h',''':''','n',''':''','s','''.''','mm','deblank ( ampm )');

return;
end %subroutine timestamp


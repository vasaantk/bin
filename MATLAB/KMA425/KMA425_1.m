% Explicit Heat Equation
% 20th March 2014

% 'clear' all previously saved values
clear
figNo = 1 ;

% Initial time
t0 = 0 ;
% Final time
tf = pi/2 ;
% Number of steps and step size
N = 140 ;
dt = (tf - t0)/N ;

% start:step:stop
t = t0:dt:tf ;

% The vector 't' can also be produced via:
% t = linspace(t0,tf,N); but this has an extra
% 'fencepost'.


x0 = 0 ;
xf = pi ;
M = 20 ;
dx = (xf - x0)/M ;
x = x0:dx:xf ;

r = dt/dx^2 ;

% This is to output the 'r' Courant number,
% to see if it is less than or equal to 1/2.

% The '%' comes from the value that you want printed out.
fprintf('Courant number: r = %.2f, \t', r) ;
fprintf('%.2f <= %.2f\n', M^2/N, (xf - x0)^2/2/tf) ;


% Create a matrix 
[XX,TT] = meshgrid(x,t) ;


%% Fourier Series Solution = UFS
% The '.' does element-by-element multiplication
UFS = 2*sin(3*XX).*exp(-9*TT) ;


figure(figNo)
figNo = figNo + 1 ;

clf ;

% 2 rows 2 columns with figure into position 1
subplot(221)

% Create surface of 2D of XX, 2D of TT and 2D of UFS.
% All must be of the same size for 'surf' to work.

title('Fourier Series')
xlabel('x')
ylabel('t')
surf(XX, TT, UFS)


%% Explicit Numerical Solution = UEN

% Better to create an empty matrix and populate it
% as it is computationaly more efficient
UEN(N+1, M+1) = 0 ;

% Make sure to do the computation on every element in
% that row of the matrix

% MATLABs uses a 1 first-element index notation

% Initial condition = f(x)
UEN(1,:) = 2 * sin(3 * x) ;

% Boundary condition
UEN(:,1) = 0 * t ;
UEN(:,M+1) = 0 * t;

% [Michael Brideson's handy-dandy advice: Use matrixes
% different sizes, so if MATLAB does what you ask it to
% instead of what you meant, it would likely stuff up 
% and crash]

for k = 2 : N + 1
    temp1 = (1 - 2*r ) * UEN(k-1, 2:M) ;
    temp2 = r * (UEN(k-1, 1:M-1) + UEN(k-1, 3:M+1)) ;
    
    UEN(k, 2:M) = temp1 + temp2;
end

err_UEN = UFS - UEN ;

% 2 rows 2 columns figure into position 2
subplot(222)
surf(XX, TT, UEN)

subplot(223)
surf(XX, TT, err_UEN)

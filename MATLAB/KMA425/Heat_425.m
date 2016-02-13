% Crank-Nicolson @ Heat Equation
% 11th April 2014

% 'clear' all previously saved values
clear
figNo = 1 ;

timeRes = 30 ;
spaceRes = 30 ;

t0 = 0 ;
tf = 1 ;
dt = (tf - t0)/timeRes ;
t = linspace(t0,tf,timeRes);

x0 = 0 ;
xf = 1 ;
dx = (xf - x0)/spaceRes ;
x = linspace(x0,xf,spaceRes+1);

% Courant number is not impt for C-N method (because of stability)
r = dt/dx^2

%% Create a tridiagonal matrix with MATLAB's "spadiags" which is a 50 X 50 matrix
A = [-r*0.5*ones(spaceRes,1), (1+r)*ones(spaceRes,1), -r*0.5*ones(spaceRes,1)];
tdA = spdiags(A,[-1,0,1], spaceRes,spaceRes);

tdA(1,2) = 2*tdA(1,2);

%% Explicit Numerical Solution = UEN
UEN = zeros(timeRes,spaceRes+1);
B = zeros(spaceRes,1);

% Initial condition = f(x)
UEN(1,:) = 2*x.^2;

% Fixed boundary condition
UEN(:,end) = 2;

% Solution algorithm
for k = 1:timeRes-1
    % Derivative boundary condition
    B(1) = (1-r)*UEN(k,1) + r*UEN(k,2);
    % Start by looping through all space (except at the boundaries) and also the time equals 'k' solution
    B(2:spaceRes) = r*0.5*UEN(k,1:spaceRes-1) + (1-r)*UEN(k,2:spaceRes) + r*0.5*UEN(k,3:spaceRes+1);
    B(end) = B(end) + r*0.5*UEN(k+1,end);
    % Now determine and assign the solution at all spaces and at t=k only as the new solutions at t=k+1
    UEN(k+1,1:spaceRes) = tdA\B;
end

%% Fourier Series Solution = UFS
n=(0:70)'; % Number of Fourier terms

C  = (-1).^n./(pi*(2*n+1)).^3; % Coefficients
fx =        cos(  (2*n+1)*pi    *x/2) ; % f(x) = cos(nx)
gt =        exp(-((2*n+1)*pi).^2*t/4)'; % g(t) = exp(nt)

Cx = repmat(C,1,length(x)); % Repeat C by len(x)
Cfx = Cx.*fx; % Now multiply in the coefficients to f(x)

UFS = 2 - 64 * gt * Cfx;

uErr = UFS - UEN;

%% Plots

[XX,TT] = meshgrid(x,t) ;
figure(figNo)
figNo = figNo+1 ;
clf ;

subplot(221)
surf(XX,TT,UFS)
axis([0 1 0 1 0 2])
xlabel('x')
ylabel('t')
zlabel('UFS')

subplot(222)
surf(XX,TT,UEN)
xlabel('x')
ylabel('t')
zlabel('UFN')

subplot(223)
surf(XX,TT,uErr)
title(UFS - UEN)
xlabel('x')
ylabel('t')
zlabel('UFS - UEN')

subplot(224)
plot(x,UFS(end,:) - UEN(end,:))
title('t=1')
xlabel('x')
ylabel('UFS - UEN')

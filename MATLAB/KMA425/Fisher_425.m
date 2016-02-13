% Explicit Method @ Fisher Equation
% 20th March 2014

% 'clear' all previously saved values
clear
figNo = 1 ;

% Temporal variables
t0 = 0 ;
% Final time
tf = 80 ;
% Number of steps and step size
timeRes = 100 ;
dt = (tf - t0)/timeRes ;
% start:step:stop
t = linspace(t0,tf,timeRes);

% Spatial variables
% -150 < x < 150 gives a gradient of ~2.3 for UEN(x,t)=0.5
x0 = -150;
xf = 150;
spaceRes = 100 ;
dx = (xf - x0)/spaceRes ;
x = linspace(x0,xf,spaceRes);

% This is to output the 'r' Courant number,
% to see if it is less than or equal to 1/2.
% The '%' comes from the value that you want printed out.
r = dt/dx^2 ;
fprintf('Courant number: r = %.2f, \t', r) ;
fprintf('%.2f <= %.2f\n', spaceRes^2/timeRes, (xf - x0)^2/2/tf) ;

% Create a matrix
[XX,TT] = meshgrid(x,t) ;
figure(figNo)
figNo = figNo+1 ;
clf ;

%% Explicit Numerical Solution = UEN
UEN = zeros(timeRes,spaceRes);

% Boundary condition is defined within the solution algorithm
% Initial condition = f(x)
for n = 1:spaceRes
    if (x(n) <= -2)
        UEN(1,n) = 1;
    elseif (x(n) >= -2 && x(n) <= 0)
        UEN(1,n) = -x(n)/2;
    else
        UEN(1,n) = 0;
    end        
end

% Solution algorithm
for timeStart = 1:timeRes-1
    UEN(timeStart+1,1) = 1;
    UEN(timeStart+1,end) = 0;
    UEN(timeStart+1,2:end-1) = UEN(timeStart,2:end-1).*(1-2*r + r*dt*(1-UEN(timeStart,2:end-1))) + r*(UEN(timeStart,3:end) + UEN(timeStart,1:end-2));
end

% Plot the solution
surf(XX,TT,UEN)
title('Fisher Equation')
xlabel('x')
ylabel('t')
zlabel('UEN')
colormap('Gray')


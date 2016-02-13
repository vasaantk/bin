% Peaceman-Rachford Alternating Direction Iteration @ Laplace's Equation
% 5th June 2014

%%=====================================================================
%
%
%    Clear all previously saved parameters
%
%

clear
figNo = 1;




%%=====================================================================
%
%
%    Dimensions for x, y, t and r
%
%

res = 30;

spaceResY = res;
spaceResX = res;
timeRes   = res;

y0 = 0;
yf = 1;
dy = (yf - y0)/spaceResY;
y  = y0 : dy : yf;
y  = y';

x0 = 0;
xf = 1;
dx = (xf - x0)/spaceResX;
x  = x0 : dx : xf;
x  = x';

r  = dy/dx^2;





%%=====================================================================
%
%
%    Create a tridiagonal (td) matrix with MATLAB's "spadiags"
%
%

Cx   = [r*0.5*ones(spaceResX,1), -r*ones(spaceResX,1), r*0.5*ones(spaceResX,1)];
Cy   = [r*0.5*ones(spaceResY,1), -r*ones(spaceResY,1), r*0.5*ones(spaceResY,1)];
tdCx = spdiags(Cx,[-1,0,1], spaceResX-1, spaceResX-1);
tdCy = spdiags(Cy,[-1,0,1], spaceResY-1, spaceResY-1);




%%=====================================================================
%
%
%     Boundary information for numerical solution
%
%

b0(1:spaceResY+1) = 0;                   % Lower x initial boundary condition for all y. Horizontal
b1(1:spaceResY+1) = 0;                   % Upper x initial boundary condition for all y. Horizontal
b2(1:spaceResX+1) = 0';                  %   LHS y initial boundary condition for all x. Vertical
b3                = 1 * (x.* (1-x))';    %   RHS y initial boundary condition for all x. Vertical

% Now setup the square border to encompass the UEN
border          = zeros(spaceResY+1, spaceResX+1);

% Populate the square border with initial conditions
border(:,1)     = b0;    % Lower x (1st column for all 'x')
border(:,end)   = b1;    % Upper x (end column for all 'x')
border(1,:)     = b2;    % LHS y   (1st row for all 'y')
border(end,:)   = b3;    % RHS y   (end row for all 'y')





%%=====================================================================
%
%
%     Explicit Numerical Solution Algorithm of UEN
%
%

u0  = (sin(res*x)./(res*x)) * (sin(res*y)./(res*y))';  % Initial guess of solution
UEN = u0(2:end-1,2:end-1);    % UEN takes on the entire "Initial guess of solution", but excludes the border perimeter

for n = 1:timeRes

    %%========================
    %
    %    LHS y boundary vector is B0l
    %
    bn(1,:) =      b0(1:end-2);   % nth level of LHS boundary stops 2 steps short of original lower x boundary
    bn(2,:) = -2 * b0(2:end-1);
    bn(3,:) =      b0(3:end  );
    bnp1    = bn;                 % (n+1)th level of LHS boundary is the same as nth level
    B0l     = 0.5 * (bn(2,:) + bnp1(2,:)) + r * 0.25 * (sum(bn) + sum(bnp1));    % LHS boundary vector
                                                                                 % sum() adds up along vertical axis. Count of columns preserverd

    %%========================
    %
    %    RHS y boundary vector is BMl
    %
    clear bn
    bn(1,:) =      b1(1:end-2);   % nth level of RHS boundary stops 2 steps short of original upper x boundary
    bn(2,:) = -2 * b1(2:end-1);
    bn(3,:) =      b1(3:end-0);
    bnp1    = bn;                 % (n+1)th level of RHS boundary is the same as nth level
    BMl     = 0.5 * (bn(2,:) + bnp1(2,:)) + r * 0.25 * (sum(bn) + sum(bnp1));    % RHS boundary vector
                                                                                 % sum() adds up along vertical axis. Count of columns preserverd



    %%========================
    %
    %    nth level solution computation
    %

    % UEN boundary's LHS and RHS
    B       = zeros(spaceResY-1,spaceResX-1);
    B(:,1)  = B0l';    % LHS boundary
    B(:,end)= BMl';    % RHS boundary

    B_inter = B;       % Intermediate boudary is to be saved in current state to be used in (n+1)th level computation

    for l = 1:spaceResY-1
        UEN_ml = UEN(l,:);    % Select the entire lth row as we iterate
        b_ml   = B(l,:);      % Select the enture lth row as we iterate

        % Set populating conditions for LHS/RHS columns as well as for the entire guts
        if l == 1,           UEN_mlm1 = b2(2:spaceResX); else UEN_mlm1 = UEN(l-1,:); end
        if l == spaceResY-1, UEN_mlp1 = b3(2:spaceResX); else UEN_mlp1 = UEN(l+1,:); end

        UEN_rhs           = UEN_ml + 0.5*r * (UEN_mlm1 - 2*UEN_ml + UEN_mlp1 + b_ml);
        UEN_inter_ml(l,:) = (eye(spaceResX-1) - tdCx)\UEN_rhs';    % Solution for intermediate level is computed
    end



    UEN = UEN_inter_ml;    % UEN becomes intermediate level solution. Consists of guts only



    %%========================
    %
    %    (n+1)th level solution computation
    %

    clear bn bnp1 %... and setup for top/bottom boundaries
    B0l     = b2(2:end-1);
    BMl     = b3(2:end-1);

    % UEN boundary's top and bottom
    B       = zeros(spaceResY-1,spaceResX-1);
    B(1,:)  = B0l;    % Top boundary
    B(end,:)= BMl;    % Bottom boundary

    for m = 1:spaceResX-1
        UEN_ml = UEN(:,m)';    % Select the entire mth column as we iterate. Transpose it into a row
        b_ml   = B(:,m)';      % Select the entire mth column as we iterate. Transpose it into a row

        % Set populating conditions for top/bottom rows as well as for the entire guts
        if m == 1,           UEN_mm1l = B_inter(:,m)'; else UEN_mm1l = UEN(:,m-1)'; end
        if m == spaceResX-1, UEN_mp1l = B_inter(:,m)'; else UEN_mp1l = UEN(:,m+1)'; end

        UEN_rhs      = UEN_ml + 0.5*r * (UEN_mm1l - 2*UEN_ml + UEN_mp1l + b_ml);
        UEN_np1(:,m) = (eye(spaceResY-1) - tdCy)\UEN_rhs';    % Solution for (n+1)th level is computed
    end

    UEN = UEN_np1;    % UEN becomes (n+1)th level solution. Consists of guts only
end

u = border;                                                       % Import the border and integrate with the guts in the next line
u(2:spaceResY,2:spaceResX) = u(2:spaceResY,2:spaceResX) + UEN;    % Replace the original guts with the latest (n+1)th guts
UEN = u;                                                          % Change name of solution to make plotting nomenclature sensible




%%=====================================================================
%
%
%    Fourier Series Solution
%
%

k = (0:100)';    % Number of Fourier terms
C1  = 8./    (pi*(2*k+1)).^3;
C2  = 1./sinh(pi*(2*k+1) * yf/xf);
fx  =  sin(pi*(2*k+1) * x'/xf).*repmat(C1,1,length(x));    % f(x) =  sin(kx)
gy  = sinh(pi*(2*k+1) * y'/xf).*repmat(C2,1,length(y));    % g(y) = sinh(ky)
UFS = gy' * fx;
err = UFS - UEN;



%%=====================================================================
%
%
%    Plots
%
%

[XX,YY] = meshgrid(x,y);

subplot(221)
surf(XX,YY,u0)
xlabel('x')
ylabel('y')
zlabel('Initial guess')

subplot(223)
surf(XX,YY,UFS)
xlabel('x')
ylabel('y')
zlabel('UFS')

subplot(222)
surf(XX,YY,UEN)
xlabel('x')
ylabel('y')
zlabel('UEN')

subplot(224)
surf(XX,YY,err)
xlabel('x')
ylabel('y')
zlabel('UFS - UEN')
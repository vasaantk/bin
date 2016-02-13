clf

% Variables
SIGMA = 1;
NU_0  = 10;         % Centre freq in Hz
NU = -20:0.01:20;   % Freq range around centre in Hz



%%====================================
%
%    Function definition for a Gaussian
%

CONST = 1/(2*SIGMA*sqrt(2*pi));  % Constant term
DENOM = -1/(2*SIGMA*SIGMA);      % Denominators in exp() argument

NUMER_1 = (NU - NU_0).^2;        % 1st term numerator
NUMER_2 = (NU + NU_0).^2;        % 2nd term numerator

ARG_1 = NUMER_1 * DENOM;         % Combine numerator and denominator
ARG_2 = NUMER_2 * DENOM;         % Combine numerator and denominator

AMP = CONST * (exp(ARG_1) + exp(ARG_2));    % Power spectrum is defined as a Gaussian

figure(1)
clf
plot(NU,AMP)

%%======================







%%====================================
%
%    Take the I.F.T of AMP
%

DELAY = fft(AMP);
s = fftshift(real(DELAY));
plot(NU,s)

%%======================







%%====================================
%
%    This is the result of an analytic
%    F.T function
%

A = exp(-2*(pi*NU*SIGMA).^2);
B = cos( 2* pi*NU_0*NU);
R = A.*B;     % I.F.T of AMP is the DELAY

%%======================












Fs = 1000;                    % Sampling frequency
T = 1/Fs;                     % Sample time
L = 1000;                     % Length of signal
t = (0:L-1)*T;                % Time vector
% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid

x = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);
y = x + 2*randn(size(t));     % Sinusoids plus noise
plot(Fs*t(1:50),y(1:50))

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(f,2*abs(Y(1:NFFT/2+1)))
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
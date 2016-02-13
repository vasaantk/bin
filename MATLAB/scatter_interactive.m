function [selVel, selAmp]=scatter_interactive(X,Y,Amp,Vel);
% Usage: [selVel, selAmp]=scatter_interactive(X,Y,Amp,Vel);
% Interactive plotter for 4d data. Designed for spectral line VLBI.
% Opens two figures - figure 1 shows the X,Y plot. When any key at the 
% command line is pressed, the current axis in figure 1 is selected and
% the corresponding Vel, Amp spectra is plotted in figure 2. Text listings
% are also printed out, column-wise for copy-paste afterwards. Pressing any
% key will then cause the program to loop to the start for more plotting fun.
% This will keep on going until figure (2) is killed. Enjoy!



% Create the plots
X=X(:);
Y=Y(:);
Amp=Amp(:);
Vel=Vel(:);
figure(2)
hold off
figure(1)
hold off
scatter(X,Y,12,Vel,'filled')
colorbar
while ~isempty(get(2))
    figure(1)
    pause
    % Now the spectra plots
    figure(1)
    A=axis;
    B=find(X>A(1)&X<A(2)&Y>A(3)&Y<A(4));
    figure(2)
    selVel=Vel(B);
    selAmp=Amp(B);
    plot(selVel,selAmp, 'k.')
    selAmp
    selVel
    pause
end
    

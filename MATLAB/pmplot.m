%%==================================================================
%
%      Script to plot propoer motion signature of masers to compare
%      between trends when tropospheric corrections are included,
%      excluded and the cobination used for paperfit.
%
%      16 September 2014
%

date = [2012.183, 2013.210, 2013.460, 2013.621, 2013.887];

% Troposphere xOff
trop = [4.330, 2.667, 1.426, 1.031, 0.932];
% No Troposphere xOff
noTrop = [4.177, 1.484, 1.644, 1.495, 0.727];

noTrop = [4.177,  1.717,  1.644,  1.495,  0.727];
% Paperfit xOff
paper = [4.177, 2.667, 1.654, 1.031, 0.727];

hold on
plot(date,trop,'kx')
plot(date,noTrop,'ro')
plot(date,paper,'ms')

legend('trop','notrop','paperfit')

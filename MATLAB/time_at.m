%% "Time_ATMOS is a  script to extrapolate observatory clocks linearly
% from existing values in ATMOS.FITS

% 24th July 2014

% hr,min,sec are the usr desired end-pt for extrapolation; script
% automatically takes care of the day
function time_at(hr, min, sec, reqAnt, print)

clf

if nargin < 5
    print = 0;
else
    print = 1;
end

ANTENNA = reqAnt;
tend = 24 * datenum([0 0 0 hr min sec]);    % Usr specified end time

%% Initialize variables.
filename = '/Users/satellite/PhD/v255r/lateGeoBlk/ATMOS.FITS';
startRow = 2;

formatSpec = '%3f%4f%3f%3f%5f%9f%11f%12f%f%[^\n\r]';
%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);

%% Allocate imported array to column variable names
VarName1 = dataArray{:, 1};
VarName2 = dataArray{:, 2};
VarName3 = dataArray{:, 3};
VarName4 = dataArray{:, 4};
VarName5 = dataArray{:, 5};
VarName6 = dataArray{:, 6};
VarName7 = dataArray{:, 7};
VarName8 = dataArray{:, 8};
VarName9 = dataArray{:, 9};

ant = VarName1;
nxt = VarName2;    % Next day
hr  = VarName3;
min = VarName4;
sec = VarName5;
clk = VarName7;

% Make year, month and day vectors
yr  = zeros(length(hr),1);
mth = zeros(length(hr),1);
day = zeros(length(hr),1);
t   = 24 * datenum([yr mth day hr min sec]);   % Convert vectors into decimal days time format

for i=1:length(t)
    if nxt(i) == 1
        t(i) = t(i) + 24;    % Add 24 to allow crossing over to next day for plotting purposes
    end
end

if t(end) > 24
    tend = tend + 24;
end

if true(print)
    fprintf('\n')
    for i=1:length(ant)
        fprintf('Antenna %d \t Time: % 7.3f \t Clock: % 7.3f \n', ant(i), t(i), clk(i))
    end
end

[val,pos] = unique(t,'stable');     % Grab the positions of each. 'stable' to keep order of times
ANTENNA   = ANTENNA - 1;
pos       = ANTENNA + pos;          % Shift the 'pos' variable to grab the correct antenna
tdif      = t(pos(2)) - t(pos(1));  % Time differnece between 2nd and 1st blocks

if true(print)
    fprintf('\n')
    fprintf('Time difference between 2nd and 1st icrf blocks for Antenna %d is: %.3f \n', ant(pos(end)), tdif)
    fprintf('Time difference between usr time and last block for Antenna %d is: %.3f \n', ant(pos(end)), tend-t(end))
end

cdif = clk(pos(2)) - clk(pos(1));   % Clock difference between 2nd and 1st instance
clkr = cdif/tdif;                   % Clock rate per unit hour

clkend = clk(pos(end)) + (tend - t(end))*clkr;

if true(print)
    plot(t(pos),clk(pos),'*')
    hold on
    plot(tend,clkend,'r*')
    hold off
end

fprintf('\n')
fprintf('Clock for Antenna %d at Time %.3f is: %.3f \n', ant(pos(end)), tend, clkend)

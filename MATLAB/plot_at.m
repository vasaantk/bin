%% Plot_ATMOS is a script to plot observatory clocks
%  in ATMOS.FITS

% 16th October 2015

% hr,min,sec are the usr desired end-pt for extrapolation; script
% automatically takes care of the day
function plot_at(reqAnt)

ANTENNA = reqAnt;
%tend = 24 * datenum([0 0 0 hr min sec]);    % Usr specified end time
%% Initialize variables.
filename = '/Users/satellite/Dropbox/v255/IONEX/V255Y_AT_1.FITS';
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

scatter(t(find(ant==ANTENNA)),clk(find(ant==ANTENNA)),'fo')

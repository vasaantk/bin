function sn(res,option,delim);

% Function to read in the multi-band delays (1st instance) from FRING and plot them out. Vasaant Krishnan.

% Script for importing  from the following text file:
%
%    /Users/satellite/Dropbox/bin/MATLAB/SN/head.txt
%    /Users/satellite/Dropbox/bin/MATLAB/SN/tail.txt
%

% The files 'head.txt' and 'tail.txt' have come from the MBDEL FRING SN
% table using the following grep commands to extract the useful
% information:
% grep -E "^\s+[0-9]+\s+[0-9]/" this.txt | head    -370  > head.txt
% grep -E "^\s+[0-9]"           this.txt | tail -n +1481 > tail.txt


% USAGE:

% res    = Integer step size to sample the data
% option = Integer options as listed below
% delim  = Character symbol for plotting


% Sample step for plotting
step = res;

beginHarvest = 1;




%%==================================================
%
%
%        Print options for user instead of plotting
%
%
if delim == 'pr'
fprintf('\n       Option:\n')
fprintf('\n\t 1 --> Original dataset aparm(3) = 0 \n\n')
fprintf('\n\t 2 --> Original dataset aparm(3) = 1 (avg LL & RR)\n\n')
fprintf('\n\t 3 --> SPLAT LL2RR (identical to original LL)\n\n')
fprintf('\n\t 4 --> SPLAT RR\n\n')
fprintf('\n\t 5 --> LL2RR + RR + aparm(3) = 0\n\n')
fprintf('\n\t 6 --> LL2RR + RR + aparm(3) = 1\n\n')
fprintf('\n\t 7 --> Original dataset with IFs 3 & 4 flagged\n\n')
fprintf('\n\t 8 --> Original dataset with BIF 1 EIF 2\n\n')
fprintf('\n\t 9 --> LL2RR refant(ATCA)\n\n')
fprintf('\n\t 10 --> LL2RR + VBGLU + MSORT with aparm(3) = 0\n\n')
fprintf('\n\t 11 --> LL2RR + VBGLU + MSORT with aparm(3) = 1\n\n')
fprintf('\n\t 12 --> LL2RR + VBGLU + MSORT with aparm(3) = 0 & BIF/EIF 1/2\n\n')
fprintf('\n\t 13 --> LL2RR + VBGLU + MSORT with aparm(3) = 1 & BIF/EIF 1/2\n\n')
beginHarvest = 0;
end





if beginHarvest == 1;
%%==================================================
%
%
%        Harvest data
%
%
if option == 1
fprintf('\n\t 1 --> Original dataset aparm(3) = 0 \n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/aparm3is0_head.txt';
end
if option == 2
fprintf('\n\t 2 --> Original dataset aparm(3) = 1 (avg LL & RR)\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/aparm3is1_head.txt';
end
if option == 3
fprintf('\n\t 3 --> SPLAT LL2RR (identical to original LL)\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/ll2rr_head0000.txt';
end
if option == 4
fprintf('\n\t 4 --> SPLAT RR\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/rr_head0000000.txt';
end
if option == 5
fprintf('\n\t 5 --> LL2RR + RR + aparm(3) = 0\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/glprm3is0_head.txt';
end
if option == 6
fprintf('\n\t 6 --> LL2RR + RR + aparm(3) = 1\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/glprm3is1_head.txt';
end
if option == 7
fprintf('\n\t 7 --> Original dataset with IFs 3 & 4 flagged\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/origFl3n4_head.txt';
end
if option == 8
fprintf('\n\t 8 --> Original dataset with BIF 1 EIF 2\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/bifeif2_head00.txt';
end
if option == 9
fprintf('\n\t 9 --> LL2RR refant(ATCA)\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/ll2rrat_head00.txt';
end
if option == 10
fprintf('\n\t 10 --> LL2RR + VBGLU + MSORT with aparm(3) = 0\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/mstprm3is0head.txt';
end
if option == 11
fprintf('\n\t 11 --> LL2RR + VBGLU + MSORT with aparm(3) = 1\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/mstprm3is1head.txt';
end
if option == 12
fprintf('\n\t 12 --> LL2RR + VBGLU + MSORT with aparm(3) = 0 & BIF/EIF 1/2\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/mstbif1to2head.txt';
% If FRING with BIF/EIF 3/4, there are no solutions found at all
end
if option == 13
fprintf('\n\t 13 --> LL2RR + VBGLU + MSORT with aparm(3) = 1 & BIF/EIF 1/2\n\n')
filename = '/Users/satellite/Dropbox/bin/MATLAB/SN/mtbif1to2n3is1.txt';
end




% Read columns of data as strings:
formatSpec = '%8s%3s%1s%2s%1s%2s%1s%4s%12s%8s%10s%10s%9s%12s%7s%15s%10s%s%[^\n\r]';

% Open, read and close
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
fclose(fileID);

% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,4,6,8,10,11,12,13,14,15,16,17,18]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,2,4,6,8,10,11,12,13,14,15,16,17,18]);
rawCellColumns = raw(:, [3,5,7,9]);

% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

index     = cell2mat(rawNumericColumns(:, 1));
dayx      = cell2mat(rawNumericColumns(:, 2));
VarName3  = rawCellColumns(:, 1); % slash
hour      = cell2mat(rawNumericColumns(:, 3));
VarName5  = rawCellColumns(:, 2);
min       = cell2mat(rawNumericColumns(:, 4));
VarName7  = rawCellColumns(:, 3);
sec       = cell2mat(rawNumericColumns(:, 5));
VarName9  = rawCellColumns(:, 4);
VarName10 = cell2mat(rawNumericColumns(:, 6));
ant       = cell2mat(rawNumericColumns(:, 7));
VarName12 = cell2mat(rawNumericColumns(:, 8));
VarName13 = cell2mat(rawNumericColumns(:, 9));
VarName14 = cell2mat(rawNumericColumns(:, 10));
VarName15 = cell2mat(rawNumericColumns(:, 11));
mdel      = cell2mat(rawNumericColumns(:, 12));
VarName17 = cell2mat(rawNumericColumns(:, 13));
VarName18 = cell2mat(rawNumericColumns(:, 14));

year  = 2013 * ones(length(dayx),1);
month =    8 * ones(length(dayx),1);
day   =   14 * ones(length(dayx),1);
day(find(dayx)) = 15;

tstmp = datenum(year,month,day,hour,min,sec);
ATpos = find(ant==1);
CDpos = find(ant==2);
HHpos = find(ant==3);
HOpos = find(ant==4);
MPpos = find(ant==5);
PApos = find(ant==6);

ATpos = ATpos(1:step:length(ATpos));
CDpos = CDpos(1:step:length(CDpos));
HHpos = HHpos(1:step:length(HHpos));
HOpos = HOpos(1:step:length(HOpos));
MPpos = MPpos(1:step:length(MPpos));
PApos = PApos(1:step:length(PApos));

ATmrk = strcat('r',delim);
CDmrk = strcat('c',delim);
HOmrk = strcat('k',delim);
MPmrk = strcat('g',delim);
PAmrk = strcat('b',delim);

hold on

plot(tstmp(ATpos),mdel(ATpos)+(80E-9),ATmrk,tstmp(CDpos),mdel(CDpos)+(60E-9),CDmrk,tstmp(HOpos),mdel(HOpos)+(40E-9),HOmrk,tstmp(MPpos),mdel(MPpos)+(20E-9),MPmrk,tstmp(PApos),mdel(PApos),PAmrk)
legend('AT','CD','HO','MP','PA')

clear

end % end for the Harvest block
%%==================================================
%%==================================================

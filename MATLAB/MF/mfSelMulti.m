function mfSelMulti(mf,type,sCha,eCha)

% Calls mfSel.m for channels in the cube one-by-one based on sCha and eCha

%   mf = Input file name
% msel = Desired mfSel.m plot option
% sCha = Start channel
% eCha = End channl

axLim  = 800;

function plotter(r,d,a,v)
  scatter(r,d,a,v,'Filled')
  set(gca,'color','black')
  colormap jet
  axis equal
  axis tight
  xlim([-axLim,axLim])
  ylim([-axLim,axLim])
  colorbar
end

%%===============================================================
%
%       Harvest values from POSSM and MFPRT text files
%       First use: grep -E "^\s+[0-9]"
%       to ensure the text files are entirely numerical.
%

%% Initialize variables.
filename   = mf;
startRow   = 0;
formatSpec = '%6f%11f%13f%14f%14f%13f%13f%13f%13f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
textscan(fileID, '%[^\n\r]', startRow, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN,'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Allocate imported array to column variable names
row      = dataArray{:, 1};
mplane   = dataArray{:, 2};
mpk      = dataArray{:, 3};
xOff     = dataArray{:, 4};
yOff     = dataArray{:, 5};
errPkmf  = dataArray{:, 6};
errXmf   = dataArray{:, 7};
errYmf   = dataArray{:, 8};
rmsResid = dataArray{:, 9};
mvel     = dataArray{:, 10};

%% Clear temporary variables
clearvars filename startRow formatSpec fileID dataArray ans;

ra  = [];
dec = [];
amp = [];
vel = [];

planeVals = unique(mplane);
%lenPlaneVals = length(planeVals);

brktVals  = planeVals(find(planeVals>=sCha & planeVals<=eCha));
lenBrktVals = length(brktVals);

for i=1:lenBrktVals
  [r,d,a,v]=mfSel(mf,type,0,brktVals(i));

  for j=1:length(r)
    ra(end+1)  = r(j);
    dec(end+1) = d(j);
    amp(end+1) = a(j);
    vel(end+1) = v(j);
  end
%  fprintf('%d/%d\n',brktVals(i),eCha)
end

plotter(ra,dec,amp,vel)

end %mfSelMulti

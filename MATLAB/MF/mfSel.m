function [ra,dec,amp,vel] = mfSel(mf,type,plot,chan)

ra  = NaN;
dec = NaN;
amp = NaN;
vel = NaN;
colLim = [-38.5,-27.5];
colLim = [-516.6,-456.0];
%  caxis(colLim)
axLim  = 800;

if plot == 1
  plotBool = true;
else
  plotBool = false;
end

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

ra  = xOff;
dec = yOff;
amp = mpk;
vel = mvel;

if (find(mplane==chan)) % Check if desired channel is in MF.OUT
  chanPos = find(mplane==chan);
  ra   =     ra(chanPos);
  dec  =    dec(chanPos);
  amp  =    amp(chanPos);
  vel  =    vel(chanPos);
  errX = errXmf(chanPos);
  errY = errYmf(chanPos);

  wra  = WeightedMean(ra ,amp);
  wdec = WeightedMean(dec,amp);
  wamp = WeightedMean(amp,amp);
  wvel = WeightedMean(vel,amp);

  out  = VLBI_Grouper_simple(ra,dec,vel,amp,500,0.1);

  gra  = [out.WRA];
  gdec = [out.WDec];
  gvel = [out.MVel]';
  gamp = [out.MAmp]';

  if type == 1
    plotter(ra,dec,amp,vel)
  elseif type == 2
    if plotBool
      subplot(211)
      plotter( ra, dec, amp,vel)
      subplot(212)
      plotter(wra,wdec,wamp,wvel)
    end
    ra  = wra;
    dec = wdec;
    amp = wamp;
    vel = wvel;
  elseif type == 3
    if plotBool
      subplot(211)
      plotter( ra, dec, amp,vel)
      subplot(212)
      plotter(gra,gdec,gamp,gvel)
    end
    ra  = gra;
    dec = gdec;
    amp = gamp;
    vel = gvel;
  end
else
  fprintf('Channel %d is not in %s.\n',chan,mf)
end

end % mfSel.m

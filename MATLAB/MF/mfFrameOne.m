function [ra,dec,amp,vel] = mfFrameOne(possm,mf,mask,options,vlbiGrouperVel);
format long
%clf
startScript = 0;    % Determine whether to print info or enter script

ra  = NaN;
dec = NaN;
amp = NaN;
vel = NaN;

% From git log, it seems like mfFrameOne.m is an updated version of mfVelFix.m
% I've called it "*FrameOne" because the first frame is used as a reference, instead of
% the frame with the peak emission (which was the case with mfVelFix.m).

%%===============================================================
%
%       Global vars
%
minGrpSize  = 3;             % Set minimum number of elements to constitute a valid group for VLBI_Grouper
axLim       = 600;           % Axes limit for plotting
colLim      = [-38.5,-27.5]; % Colourbar limits
borderWidth = 800;           % Ignore emission inside borderWidth dimensions (pixels)

if nargin == 0
    fprintf('\n')
    fprintf('============================================================================')
    fprintf('\n')
    fprintf('\n')
    fprintf('\t mfFrameOne( "POSSM.OUT" , "MF.OUT", Mask , Options , MaxVel)\n')
    fprintf('\n')
    fprintf('   Options:\n')
    fprintf('\t 1  --> \t Text of parms.\n')
    fprintf('\t 2  --> \t POSSM spectrum and velocity corrected MFPRT spectrum (of 1 emission per plane).\n')
    fprintf('\t 3  --> \t POSSM spectrum and emission scatter (of the max emission per plane).\n')
    fprintf('\t 4  --> \t POSSM spectrum and emission scatter (of all emission). Flag emission with positional uncertainty > posErr (optional).\n')
    fprintf('\t        \t Need to give maxvel even though it will be ignored. \n')
    fprintf('\t 5  --> \t Enter VLBI Grouper. maxvel - maximum velocity difference between points to be grouped.\n')
    fprintf('\t 6  --> \t Same as option 5 but determine weighted means.\n')
    fprintf('\n\n')
    fprintf('\t Edit global variables (search "Global vars")  manually within script:\n')
    fprintf('\n')
    fprintf('============================================================================\n\n')
else
  startScript = 1;
end

%%===============================================================
%
%       Harvest values from POSSM and MFPRT text files
%       First use: grep -E "^\s+[0-9]"
%       to ensure the text files are entirely numerical.
%

if startScript == 1

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

%%===============================================================
%
%        The POSSM Vars - It looks like POSSM vars are not used
%

%% Initialize variables.
filename   = possm;
startRow   = 0;
formatSpec = '%6f%5f%4s%19f%13f%17f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
textscan(fileID, '%[^\n\r]', startRow, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN,'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Allocate imported array to column variable names
pplane     = dataArray{:, 1};
pvel       = dataArray{:, 5};
ppk        = dataArray{:, 6};

%% Clear temporary varixables
clearvars filename startRow formatSpec fileID dataArray ans;

pVelOne    = pvel(1);                 % Velocity of channel 1 in possm
pVelTwo    = pvel(2);                 % Velocity of channel 2 in possm
velStep    = pVelTwo - pVelOne;       % Velocity step between channels in possm
sPlane     = mplane(1);               % Start MF plane
ePlane     = mplane(end);             % End MF plane
mpl_s      = sPlane:1:ePlane;         % An array of planes from MF file
fvel_s     = zeros(length(pvel),1);   % Create an array for the corrected vels of same length as array of singles. "Fixed vel singles"
fvel_s     = pvel;                    % Now begin to populate the "Fixed vel singles" array by replacing the velocities from POSSM
fvelStep_s = velStep;                 % Required (original) velocity reslolution
a          = zeros(length(pplane),1); % Array to contain frame information

for i = 1:length(pplane)              % WARNING: Assume that POSSM is sampled from channel 1 to channel END with no gaps
  a(i) = sum(mplane == i);            % Determine the number of times each frame is repeated in the MF output, based on the assumption
end

fvel = zeros(length(mvel),1);         % Create "full sized" array to populate with corrected velocities: sum(a) should be the same as length(fvel)
fvelKeeper = 1;

for i = 1:length(a)
  velSto = zeros(a(i),1);             % Create a temp vel storage array large enough to contain the number of spots associated with the plane
  length(velSto);
  i;
  for j = 0:length(velSto)
    if length(velSto) >= 1            % This "if" bloc keeps the velocities in the proper spot by only accpeting them if there is at least one frame
      if j>0                          % Count the positive integers only
        fvel(fvelKeeper) = fvel_s(i); % Populate the "Full sized" velocity array with elements from the singles array. Hold 'i' while iterating through 'j'
        fvelKeeper = fvelKeeper+1;
      end
    end
  end
end

%%=================================================================================
%
%     Only select emission if it falls within the velocity range
%     as specified in the colLim variable, and also exclude emission around
%     the border.
%
if mask == 1
  fvelMasker = find(fvel>colLim(1) & fvel<colLim(2));
  xOff       =     xOff(fvelMasker);
  yOff       =     yOff(fvelMasker);
  mpk        =      mpk(fvelMasker);
  fvel       =     fvel(fvelMasker);
end

if mask == 1
  xMax = borderWidth;
  yMax = xMax;
  borderMask = find(xOff<xMax & xOff>-xMax & yOff<yMax & yOff>-yMax);
  xOff   =   xOff(borderMask);
  yOff   =   yOff(borderMask);
  fvel   =   fvel(borderMask);
  mpk    =    mpk(borderMask);
  errXmf = errXmf(borderMask);
  errYmf = errYmf(borderMask);
end

%%=================================================================================
%
%     Output options
%

%% Print output with fixed vels
if options == 1
  for i=1:length(mpk)
    fprintf('%5d %9.3f Jy %9.3f xmas %9.3f ymas %9.3f km/s %9.3f km/s \n',mplane(i), mpk(i), xOff(i), yOff(i),fvel(i), mvel(i))
    ra  = NaN;
    dec = NaN;
    amp = NaN;
    vel = NaN;
  end
end


%% These are the raw, harvested values from MF.OUT
if options == 2
  ra  = xOff;
  dec = yOff;
  amp = mpk;
  vel = mvel;
end


%% Jamie's VLBI_Grouper_err script
if options == 3
    out = VLBI_Grouper_err(xOff,errXmf,yOff,errYmf,fvel,mpk,vlbiGrouperVel);

    % Only accept maser blobs if they have at least 'minGrpSize' amount of emission
    flagList = [];
    for i = 1:length(out)
        if length(out(i).index) < minGrpSize
            flagList(length(flagList) + 1) = i;    % Next element becomes index of our element < minGrpSize
        end
    end
    clear i
    gdData = out(setdiff(1:length(out),flagList)); % Mathematical 'set' which are not in the index of flags

    ra  = [gdData.RA];
    dec = [gdData.Dec];
    amp = [gdData.Amp];
    vel = [gdData.Vel];

    if options == 2
        wRa  = zeros(length(gdData),1);    % Weighted RA
        wDec = zeros(length(gdData),1);
        mMpk = zeros(length(gdData),1);    % Mean mpk
        wVel = zeros(length(gdData),1);

        for i=1:length(gdData)
            % summ=[
            %  1 max(Amp(CurrentGroup)),
            %  2 mean(RA(CurrentGroup)),
            %  3 mean(Dec(CurrentGroup)),
            %  4 WRA,
            %  5 WDec,
            %  6 std(RA(CurrentGroup)),
            %  7 std(Dec(CurrentGroup)),
            %  8 WRARMS,
            %  9 WDecRMS,
            % 10 mean(Vel(CurrentGroup)),
            % 11 std(Vel(CurrentGroup))];

            wRa(i)  = gdData(i).summ(4);
            wDec(i) = gdData(i).summ(5);
            mMpk(i) = gdData(i).summ(1);
            wVel(i) = gdData(i).summ(10);
        end

        ra  = wRa;
        dec = wDec;
        amp = mMpk;
        vel = wVel;
    end % options == 2
end

%prVelAmp = max(amp(find(vel>-36.0 & vel<-35.0)))
%vel(find(amp==prVelAmp))
%velfind = @(epoch) find(amp==max(amp(find(vel>-36.0 & vel<-35.0))));
%vel(velfind(vel))

end  % startScript if statement

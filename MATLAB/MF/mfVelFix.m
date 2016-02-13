function [ra,dec,amp,vel] = mfVelFix(possm,mf,options,vlbiGrouperVel,usrPosErr);

%clf

startScript = 0;    % Determine whether to print info or enter script

if nargin == 0
    fprintf('\n')
    fprintf('============================================================================')
    fprintf('\n')
    fprintf('\n')
    fprintf('\t mfVelFix( POSSM.OUT , MF.OUT , options , maxvel [option 5/6], posErr [option 4/5/6])\n')
    fprintf('\n')
    fprintf('Options:\n')
    fprintf('\t 1  --> \t Text of parms.\n')
    fprintf('\t 2  --> \t POSSM spectrum and velocity corrected MFPRT spectrum (of 1 emission per plane).\n')
    fprintf('\t 3  --> \t POSSM spectrum and emission scatter (of the max emission per plane).\n')
    fprintf('\t 4  --> \t POSSM spectrum and emission scatter (of all emission). Flag emission with positional uncertainty > posErr (optional). Need to give maxvel even though it will be ignored. \n')
    fprintf('\t 5  --> \t Enter VLBI Grouper. maxvel - maximum velocity difference between points to be grouped.\n')
    fprintf('\t 6  --> \t Same as option 5 but determine weighted means.\n')
    fprintf('\n\n')
    fprintf('\t Edit global variables (search "Global vars")  manually within script:\n')
    fprintf('\n')
    fprintf('============================================================================\n\n')
elseif nargin >= 3
    print = 0;
    startScript = 1;
    enterHere = options;

if options == 4
   if nargin == 3
      enterHere = options;
   elseif nargin == 5
      enterHere = options;
      mfPosErr  = usrPosErr;
   else
       enterHere = options;
   end
end

if options == 5 | options == 6
    if nargin == 4
        enterHere = options;
    elseif nargin == 5
        enterHere = options;
        mfPosErr  = usrPosErr;
    else
        enterHere = 0;
    end
end

end % if nargin == 0


%%===============================================================
%
%       Global vars
%
minGrpSize  = 3;             % Set minimum number of elements to constitute a valid group for VLBI_Grouper
axLim       = 600;           % Axes limit for plotting
colLim      = [-38.5,-27.5]; % Colourbar limits
colLim      = [-34.0,-31.0]; % Colourbar limits
refVel      = -33.1;      % The velocity for the reference plane in MF
velStep     = -0.0439;       % Step size in the velocity
borderWidth = 500;           % Ignore emission inside borderWidth dimensions (pixels)



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

%% Clear temporary variables
clearvars filename startRow formatSpec fileID dataArray ans;


%%=================================================================================
%
%     Only select emission if the formal errors in its position are
%     less than defined in the mfPosErr variable
%
if options == 5 | options == 6
if mfPosErr ~= 0
  mfErrMasker = find(errXmf<mfPosErr & errYmf<mfPosErr);
  row         =      row(mfErrMasker);
  mplane      =   mplane(mfErrMasker);
  mpk         =      mpk(mfErrMasker);
  xOff        =     xOff(mfErrMasker);
  yOff        =     yOff(mfErrMasker);
  errPkmf     =  errPkmf(mfErrMasker);
  errXmf      =   errXmf(mfErrMasker);
  errYmf      =   errYmf(mfErrMasker);
  rmsResid    = rmsResid(mfErrMasker);
  mvel        =     mvel(mfErrMasker);
end
end

%%=================================================================================
%
%     Align the velocities between mf and possm outputs
%


%%=================================================================================
%
%  Select only the first maser emission spot from each frame in mfplane
%

%% Nomenclature:
% mpk_s    = ["M Peak Single"]     Only peak emission from each frame in mplane
% mpkpos_s = ["M Peak Pos Single"] Correspoinding position in array of the peak emission

[mpk_s mpkpos_s] = unique(mplane);
clear mpk_s    % Use this variable later
mpl_s            = mplane(mpkpos_s);
mpk_s            =    mpk(mpkpos_s);



%%=================================================================================
%
%  Plot maser spots in range of main spectrum (i.e. ignore most of the baseline)
%
[pkFlx_s pkPos_s] = max(mpk_s);   % Am assuming that the ref vel corresponds to the peak flux. Find it's [value, position] in array of singles
clear pkFlx_s                     % ... because I don't need the value of the flux, just its position in the array of singles
fvel_s = zeros(length(mpk_s),1);  % Create an array for the corrected vels of same length as array of singles. "Fixed vel singles"
fvel_s(pkPos_s) = refVel;         % Insert appropriate velocity into the reference plane
fvelStep_s      = velStep;        % Required (original) velocity reslolution

% Now begin to populate the "Fixed vel singles" array
% Iterate backwards from plane adjacent to ref plane to the first plane
for i = pkPos_s-1:-1:1
    % [Velocity of ref plane] - [(Pos of ref plane) - (Distance from reference frame)] * [Step size]
    fvel_s(i) = fvel_s(pkPos_s) - (pkPos_s-i)*fvelStep_s;
end
clear i
% Iterate forwards from plane adjacent to ref plane to the final plane
for i = pkPos_s+1:1:length(fvel_s)
    % [Velocity of ref plane] + [(Distance from reference frame) - (Pos of ref plane)] * [Step size]
    fvel_s(i) = fvel_s(pkPos_s) + (i-pkPos_s)*fvelStep_s;
end
clear i

% Multiply velocities by vector of count of emission spots per plane
a = zeros(length(mpkpos_s),1);
% This algorithm does not appear to grab the final frame? Does it really matter?
for i = 1:1:length(mpkpos_s)-1
    a(i) = mpkpos_s(i+1) - mpkpos_s(i);    % Determine the count of emission spots found between adjacent frames
end                                        % This number reps the count for which the velocity of that plane
clear i                                    % needs to be repeated in order for correct velocity consideration


fvel = zeros(length(mvel),1);              % "Full sized" array to populate with corrected velocities
                                           % Note: sum(a) should be the same as length(fvel)

fvelKeeper = 1;

for i=1:1:length(a)
    velSto = zeros(a(i),1);                      % Create a temp vel storage array large enough to contain the number of spots associated with the plane
    for j=1:1:length(velSto)
        velSto(j) = fvel_s(i);                   % Popultae the temp vel array with the "Fixed vel singles" as we iterate through each plane in 'a' array
    end
    fvel(fvelKeeper:fvelKeeper+a(i)-1) = velSto; % Populate the "Full sized" velocity array with elements from the temp array
    fvelKeeper = fvelKeeper + a(i);              % Move curser to next position in the "Full sized" velocity array
    clear velSto
end
clear i j


%%=================================================================================
%
%     Only select emission if it falls within the velocity range
%     as specified in the colLim variable, and also exclude emission around
%     the border.
%
if 1 == 0
  fvelMasker = find(fvel>colLim(1) & fvel<colLim(2));
  xOff       =     xOff(fvelMasker);
  yOff       =     yOff(fvelMasker);
  %mpk_s      =    mpk_s(fvelMasker);
  mpk        =      mpk(fvelMasker);
  %mpkpos_s   = mpkpos_s(fvelMasker);
  fvel       =     fvel(fvelMasker);
end

if 1 == 0
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
if enterHere == 1
    for i=1:length(mplane)
        fprintf('%5d %9.3f Jy %9.3f xmas %9.3f ymas %9.3f km/s %9.3f km/s \n',mplane(i), mpk(i), xOff(i), yOff(i),fvel(i), mvel(i))
    end
    clear i
end


if enterHere == 2
%    plot(pvel,ppk)
    hold on
    b = 1:5:length(mpk);
%    plot(fvel(mpkpos_s),mpk_s,'r')
    plot(fvel(mpkpos_s),mpk_s)
end


if enterHere == 3
    subplot(121)
    scatter(xOff(mpkpos_s), yOff(mpkpos_s),mpk_s,fvel(mpkpos_s))
    axis equal
    axis tight
    colormap jet
    caxis(colLim)
    colorbar
    subplot(122)
    plot(fvel(mpkpos_s),mpk_s,'r')
end


if enterHere == 4
  subplot(121)
  scatter(xOff, yOff,mpk,fvel)
  axis equal
  axis tight
  xlim([-axLim,axLim])
  ylim([-axLim,axLim])
  colormap jet
  caxis(colLim)
  colorbar
  subplot(122)
  plot(fvel,mpk,'r')

  ra  = xOff;
  dec = yOff;
  amp = mpk;
  vel = fvel;
end


if enterHere == 5 | enterHere == 6
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

    if enterHere == 6
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
    end % enterHere == 6

    colormap jet

    subplot(221)
    scatter(ra,dec,abs(amp),vel)
    xlim([-axLim,axLim])
    ylim([-axLim,axLim])
    set (gca,'Xdir','reverse')
    xlabel('x offset')
    ylabel('y offset')
    title('Flux Weighted if option 6, otherwise, All Points')
    axis equal
    caxis(colLim)
    colorbar

    subplot(222)
    scatter([gdData.RA],[gdData.Dec],abs([gdData.Amp]),[gdData.Vel])
    xlim([-axLim,axLim])
    ylim([-axLim,axLim])
    xlabel('x offset')
    ylabel('y offset')
    title('All Points')
    set (gca,'Xdir','reverse')
    axis equal
    caxis(colLim)
    colorbar

    subplot(223)
    scatter3(vel,ra,dec,abs(amp),vel)
    xlabel('Velocity')
    ylabel('x offset')
    zlabel('y offset')
    title('Flux Weighted if option 6, otherwise, All Points')
    set (gca,'Ydir','reverse')

    subplot(224)
    plot(vel,amp)
    xlabel('Velocity')
    ylabel('Flux')
    title('Spectrum')
end % enterHere == 5 | enterHere == 6

end % startScript

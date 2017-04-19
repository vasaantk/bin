% Vasaan Krishnan. Based on Mark Reid's algorithm.
%clf

% Parameters to allow 'textscan' to harvest data correctly
startRow = 2;
formatSpec = '%11f%10f%10f%10f%f%[^\n\r]';


%%===============================================
%
% First panel: Sky view plot
%
%%===============================================

subplot(1,3,1)
hold on
box on
xoff = 0;
yoff = 0;

traceRA  = importdata('par_fit_model_ra.dat_001');
traceDec = importdata('par_fit_model_dec.dat_001');

% isolate x and y data
colXTra = traceRA(:,2);
colYTra = traceDec(:,2);

xsumTra = sum(colXTra);
ysumTra = sum(colYTra);

xavgTra = xsumTra/length(colXTra);
yavgTra = ysumTra/length(colYTra);

colXTra(:) = colXTra(:) - xavgTra - xoff;
colYTra(:) = colYTra(:) - yavgTra;
plot(colXTra,colYTra,'k')

traFileRA = fopen('par_fit_results_ra.dat_001','r');
traModRA  = textscan(traFileRA, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(traFileRA);
yearTraRA = traModRA{:,1};
dataTraRA = traModRA{:,2};
mdelTraRA = traModRA{:,3};
resiTraRA = traModRA{:,4};
serrTraRA = traModRA{:,5};

traFileDec = fopen('par_fit_results_dec.dat_001','r');
traModDec  = textscan(traFileDec, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(traFileDec);
yearTraDec = traModDec{:,1};
dataTraDec = traModDec{:,2};
mdelTraDec = traModDec{:,3};
resiTraDec = traModDec{:,4};
serrTraDec = traModDec{:,5};

mdelTraRA(:)  = mdelTraRA(:) - xavgTra - xoff;
mdelTraDec(:) = mdelTraDec(:) - yavgTra;
plot(mdelTraRA,mdelTraDec,'ok')

dataTraRA(:)  = dataTraRA(:) - xavgTra - xoff;
dataTraDec(:) = dataTraDec(:) - yavgTra;
plot(dataTraRA, dataTraDec,'r^')
errorbar( dataTraRA, dataTraDec, serrTraRA, 'r', 'Marker', 'none', 'LineStyle', 'none')
herrorbar(dataTraRA, dataTraDec, serrTraDec,'.r')

xlim([floor(min(colXTra))-0.5,ceil(max(colXTra))+0.5])
ylim([floor(min(colYTra))-0.5,ceil(max(colYTra))+0.5])
set(gca,'Xdir','reverse');

xlabel('East Offset (mas)')
ylabel('North Offset (mas)')

text( 2.7,  0.8, '2013.2')
text(-1.5, -0.9, '2013.9')




% Store these values for plotting proper motion from data
xRA = traModRA{:,1};
yRA = traModRA{:,2};

xDe = traModDec{:,1};
yDe = traModDec{:,2};






%%===============================================
%
% Second panel: x & y vs. t with proper motion
%
%%===============================================

subplot(1,3,2)
hold on
box on

xoff = 0;
yoff = 0;

pmSigRA = importdata('par_fit_model_ra.dat_001');
% isolate x and y data
colXPM = pmSigRA(:,1);
colYPM = pmSigRA(:,2);

ysumPM = sum(colYPM);
yavgPM = ysumPM/length(colYPM);
colYPM(:) = colYPM(:) - yavgPM - yoff;
plot(colXPM,colYPM,'r')

% Plot data points
fileIDPM = fopen('par_fit_results_ra.dat_001','r');
pmDataRA = textscan(fileIDPM, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileIDPM);
yearRApm = pmDataRA{:,1};
dataRApm = pmDataRA{:,2};
mdelRApm = pmDataRA{:,3};
resiRApm = pmDataRA{:,4};
serrRApm = pmDataRA{:,5};

dataRApm(:) = dataRApm(:) - yavgPM - yoff;
plot(yearRApm,dataRApm,'r^')


xoff = 0;
yoff = 1;


pmSigDec = importdata('par_fit_model_dec.dat_001');
% isolate x and y data
colXPM = pmSigDec(:,1);
colYPM = pmSigDec(:,2);

ysumPM = sum(colYPM);
yavgPM = ysumPM/length(colYPM);
colYPM(:) = colYPM(:) - yavgPM - yoff;
plot(colXPM,colYPM,'--b')

% Plot data points
fileIDPM = fopen('par_fit_results_dec.dat_001','r');
pmDataDec = textscan(fileIDPM, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileIDPM);
yearDecpm = pmDataDec{:,1};
dataDecpm = pmDataDec{:,2};
mdelDecpm = pmDataDec{:,3};
resiDecpm = pmDataDec{:,4};
serrDecpm = pmDataDec{:,5};

dataDecpm(:) = dataDecpm(:) - yavgPM - yoff;
plot(yearDecpm,dataDecpm,'bo')

xlim([floor(min(colXPM)),ceil(max(colXPM))])
% Use limits from sky plot (Tra) to keep panel dimensions the same
% ylim([floor(min(colYTra)),ceil(max(colYTra))])

% Alternatively use limits based on proper motion data points
yLimitOptions = [abs(floor(min(dataDecpm))) ceil(max(dataDecpm)) abs(floor(min(dataRApm))) ceil(max(dataRApm))];
posLim = max(yLimitOptions);
negLim = -max(yLimitOptions);
ylim([negLim,posLim])

xlabel('Epoch (years)')
ylabel('Offset (mas)')












%%===============================================
%
% Thrid panel: Parallax plot
%
%%===============================================

subplot(1,3,3)
hold on
box on

% Parallax signature for RA and Dec
parSigRA = importdata('par_fit_model_desloped_ra.dat_001');
plot(parSigRA(:,1), parSigRA(:,2),'r')
parSigDec = importdata('par_fit_model_desloped_dec.dat_001');
plot(parSigDec(:,1), parSigDec(:,2),'--b')

% Dashed horizontal line
dashMin = floor(parSigRA(1,1));
dashMax = ceil(parSigRA(end,1));
dashRange = linspace(dashMin, dashMax, length(parSigRA));
Y = zeros(length(parSigRA));
plot(dashRange, Y, '--k','LineWidth',0.05)

xlim([floor(parSigRA(1,1)),ceil(parSigRA(end,1))])
ylim([-0.8,0.8])
ylim([-1.2,1.2])

% Parallax model datapoints RA
fileIDRA = fopen('par_fit_results_desloped_ra.dat_001','r');
parModRA = textscan(fileIDRA, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileIDRA);
yearRA = parModRA{:,1};
dataRA = parModRA{:,2};
mdelRA = parModRA{:,3};
resiRA = parModRA{:,4};
serrRA = parModRA{:,5};
plot(yearRA,dataRA,'r^')
errorbar(yearRA,dataRA,serrRA,'r', 'Marker', 'none', 'LineStyle', 'none')

% Parallax model datapoint declination
fileIDDec = fopen('par_fit_results_desloped_dec.dat_001','r');
parModDec = textscan(fileIDDec, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileIDDec);
yearDec = parModDec{:,1};
dataDec = parModDec{:,2};
mdelDec = parModDec{:,3};
resiDec = parModDec{:,4};
serrDec = parModDec{:,5};
%plot(yearDec,dataDec,'bo')
%errorbar(yearDec,dataDec,serrDec,'b', 'Marker', 'none', 'LineStyle','none')

xlabel('Epoch (years)')
ylabel('Offset (mas)')

#!/usr/bin/env python

# This script reads in the file name of the argument from the command line and plots out the multiband delays and fringe rates against universal time. The abovementioned file is any .dat output from Mark Reid's fit_geoblocs.f fortran program.

# End the commandline input with the word: save - to automatically get a .eps file of the output
# End the commandline input with the word: show - to display a graph

import re
from pylab import *
import sys
import matplotlib.gridspec as gridspec

# Integer to keep count of the number of rows of figures which will be plotted
figureNumber = 0

# Array to keep track of ALL the universal times from ALL the .dat files which are being processed by this script
timeKeeper = []

# The list of .dat files to be processed by this script
nameList = sys.argv[1:]

# The scrip chooses whether to use the default figure size or not
if len(nameList) >= 4:
       fig = figure(figsize=(1.25*len(nameList),1.25*len(nameList)))
else:
       fig = figure()

if nameList[len(nameList)-1] == "save":
       saveFigure = True
       nameList = nameList[0:len(nameList)-1]
else:
       saveFigure = False
if nameList[len(nameList)-1] == "show":
       showFigure = True
       nameList = nameList[0:len(nameList)-1]
else:
       showFigure = False

# The script starts from here!
for item in nameList:
       universalTime = []

       delayData = []
       delayModel = []
       delayResidual = []

       rateData = []
       rateModel = []
       rateResidual = []

       delayDataABS = []
       delayModelABS = []
       delayResidualABS= []

       rateDataABS = []
       rateModelABS = []
       rateResidualABS = []

       rmsDelResArray = []

# The co-ordinates for the individual points for the graphs are harvested here
       for line in open(item,'r'):
              requiredInformation = re.search("\s+(\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)",line)
              titleInformation = re.search("(\d-\s\d)",line)
              if requiredInformation:
                     universalTime.append(float(requiredInformation.group(1)))
                     delayData.append(float(requiredInformation.group(2)))
                     delayModel.append(float(requiredInformation.group(3)))
                     delayResidual.append(float(requiredInformation.group(4)))
                     rateData.append(float(requiredInformation.group(5)))
                     rateModel.append(float(requiredInformation.group(6)))
                     rateResidual.append(float(requiredInformation.group(7)))
              if titleInformation:
                     graphTitle = titleInformation.group(1)
       close(item)

# This next block of code is to harvest the data (as done in the previous block) but in this instance, to automatically determine the maximum and minimum values for the y-axes of both Multiband Delay and Fringe Rate plots.
       for line in open(item,'r'):
              absRequiredInformation = re.search("\s+(\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)",line)
              if absRequiredInformation:
                     delayDataABS.append(abs(float(absRequiredInformation.group(2))))
                     delayModelABS.append(abs(float(absRequiredInformation.group(3))))
                     delayResidualABS.append(abs(float(absRequiredInformation.group(4))))
                     rateDataABS.append(abs(float(absRequiredInformation.group(5))))
                     rateModelABS.append(abs(float(absRequiredInformation.group(6))))
                     rateResidualABS.append(abs(float(absRequiredInformation.group(7))))
       close(item)

# This bloc print out the RMS of the delays
       for element in delayResidual:
              rmsDelResArray.append(element**2)
              rmsDelRes = sqrt(mean(rmsDelResArray))
       print "The mean residual delay of baseline ("+str(graphTitle)+") is = " + str(round(rmsDelRes,3))

# These blocs of code determine the greatest of 3 values to use as max and min of the y-axes, only if there is data in the .dat file which is being read
       if requiredInformation:
              if max(delayDataABS) > max(delayModelABS):
                     if max(delayDataABS) > max(delayResidualABS):
                            delayPlotAxVal = ceil(max(delayDataABS))
                     else:
                            delayPlotAxVal = ceil(max(delayResidualABS))
              else:
                     if max(delayModelABS) > max(delayResidualABS):
                            delayPlotAxVal = ceil(max(delayModelABS))
                     else:
                            delayPlotAxVal = ceil(max(delayResidualABS))
              if max(rateDataABS) > max(rateModelABS):
                     if max(rateDataABS) > max(rateResidualABS):
                            ratePlotAxVal = ceil(max(rateDataABS))
                     else:
                            ratePlotAxVal = ceil(max(rateResidualABS))
              else:
                     if max(rateModelABS) > max(rateResidualABS):
                            ratePlotAxVal = ceil(max(rateModelABS))
                     else:
                            ratePlotAxVal = ceil(max(rateResidualABS))

# The next couple of lines of code are to keep track of all the universal times of all the data which have been harvested. This will be used in the plotting bloc (of code) to standarise the x-axis.
       for time in universalTime:
              timeKeeper.append(time)

# The plotting and figure characteristics are determined from here on.
       subplot2grid((len(nameList),2),(figureNumber,0))
       scatter(universalTime,delayData,c='green',linewidth=0,label="Data")
       scatter(universalTime,delayModel,linewidth=0,label="Delay Model")
       scatter(universalTime,delayResidual,c='r',marker='4',label="Delay Residuals'")
       plot([floor(min(timeKeeper))-0.5,ceil(max(timeKeeper))+0.5],[0,0],'--',c='black')
       xlim(floor(min(timeKeeper))-0.5,ceil(max(timeKeeper))+0.5)
       ylim(-delayPlotAxVal,delayPlotAxVal)
       yticks([-delayPlotAxVal,0,delayPlotAxVal])
       title('('+graphTitle+')',fontsize=10)
       # Only the bottom-most figure gets axis labels and full title
       if figureNumber == len(nameList)-1:
              xticks()
              xlabel("Universal Time (Hours)",weight='bold')
              title('Baseline ('+graphTitle+')',fontsize=10)
       else:
              xticks([])

       subplot2grid((len(nameList),2),(figureNumber,1))
       scatter(universalTime,rateData,c='green',linewidth=0,label="Data")
       scatter(universalTime,rateModel,linewidth=0,label="Delay Model")
       scatter(universalTime,rateResidual,c='r',marker='4',label="Delay Residuals")
       plot([floor(min(timeKeeper))-0.5,ceil(max(timeKeeper))+0.5],[0,0],'--',c='black')
       xlim(floor(min(timeKeeper))-0.5,ceil(max(timeKeeper))+0.5)
       ylim(-ratePlotAxVal,ratePlotAxVal)
       yticks([-ratePlotAxVal,0,ratePlotAxVal])
       title('('+graphTitle+')',fontsize=10)
       # Only the bottom-most figure gets axis labels and full title
       if figureNumber == len(nameList)-1:
              xticks()
              xlabel("Universal Time (Hours)",weight='bold')
              title('Baseline ('+graphTitle+')',fontsize=10)
       else:
              xticks([])

       fig.subplots_adjust(left=0.125, right=0.9, bottom=0.05, top=0.95, wspace=0.5, hspace=0.25)

       figureNumber += 1

fig.text(0.05,0.55,'Multi-band Delays (nsec)',weight='bold',horizontalalignment='center',verticalalignment='top',rotation='vertical')
fig.text(0.52,0.55,'Fringe Rates (MHz)',weight='bold',horizontalalignment='center',verticalalignment='top',rotation='vertical')

if saveFigure:
       savefig("geodeticPlotter.eps", format='eps')
elif showFigure:
       show()

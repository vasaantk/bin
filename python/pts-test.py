#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Friday, 18 March 2016.

import re
from pylab import *
import sys
import numpy as np
from functions import *



usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "# pts-test.py takes input from *.PTS files to study the"
    print "# component allocation from Luca Moscadelli's pts-diff.f."
    print "# The component positions and velocities are flux weighted"
    print "# using the algorithm from functions.py."
    print "# First argument must be *.PTS. Order for remaining options"
    print "# does not matter:"
    print ""
    print "# plot* = options are: plot, seq and comp."
    print "# atate = annotates the spots with their component."
    print "# vel   = allows user specified velocty range for the colourbar."
    print "# scale = scales the peak flux of the data by a constant factor."
    print ""
    print "--> pts-test.py file_name.COMP plot* vel=xx.x,yy.y atate scale=xx"
    print ""
    exit()




#=====================================================================
#   Define variables:
#
cTmp = []                   # chan temp
vTmp = []                   # velo temp
iTmp = []                   # flux temp (integrated)
pTmp = []                   # peak temp
xTmp = []                   # xoff temp
xeTp = []                   # xerr temp
yTmp = []                   # yoff temp
yeTp = []                   # xerr temp
mTmp = []                   # Co(m)p temp

chan = []
vels = []
flux = []
peak = []
xoff = []
xerr = []
yoff = []
yerr = []
comp = []

compMask   = []             # Subset of arrays which are not blank
velAvg     = []             # Average of each component
homoVelTmp = []
homoVel    = []             # Homogenised velocity

defaultVels  = True         # Otherwise usrVelLim
defaultScale = True         # Otherwise usrScale

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans



#=====================================================================
#   Scale the maser spots by a factor of userScale:
#
for i in usrFile:
    userScale = re.search('scale='+'([+-]?\d+)',i)
    if userScale:
        defaultScale = False # Don't use scaleFactor = 1 if user has defined it in usrFile
        scaleFactor  = int(userScale.group(1))
if defaultScale:             # This allows "scale=" to appear anywhere in usrFile
    scaleFactor = 1



#=====================================================================
#   Harvest values:
#
for line in open(usrFile[0],'r'):

    reqInfo = re.search(ints + floats + ints + manyFloats, line)
    if reqInfo:                                    # Populate temp arrays, which are reset after each component is harvestedo
        mTmp.append(  str(reqInfo.group(1)))       # String format for annotations for scatterplots
        vTmp.append(float(reqInfo.group(2)))
        cTmp.append(  int(reqInfo.group(3)))
        iTmp.append(float(reqInfo.group(4)))
        pTmp.append(float(reqInfo.group(5)))
        xTmp.append(float(reqInfo.group(8)))
        xeTp.append(float(reqInfo.group(9)))
        yTmp.append(float(reqInfo.group(10)))
        yeTp.append(float(reqInfo.group(11)))

    if line == '\n':                               # This statement allows each component to exist as its own list within the complete array
        comp.append(mTmp)
        vels.append(vTmp)
        chan.append(cTmp)
        flux.append(iTmp)
        peak.append(pTmp)
        xoff.append(xTmp)
        xerr.append(xeTp)
        yoff.append(yTmp)
        yerr.append(yeTp)

        mTmp = []                                  # Reset temp arrays
        vTmp = []
        cTmp = []
        iTmp = []
        pTmp = []
        xTmp = []
        xeTp = []
        yTmp = []
        yeTp = []

close(usrFile[0])



#=====================================================================
#   The final values from *Tmp need to be mannualy added:
#
comp.append(mTmp)
vels.append(vTmp)
chan.append(cTmp)
flux.append(iTmp)
peak.append(pTmp)
xoff.append(xTmp)
xerr.append(xeTp)
yoff.append(yTmp)
yerr.append(yeTp)



#=====================================================================
#   Based on 'comp' array, determine the positions of the '\n's:
#
for i in xrange(len(comp)):
    if comp[i] != []:
        compMask.append(int(i))



#=====================================================================
#   Remove the '\n's:
#
comp = [comp[i] for i in compMask]
vels = [vels[i] for i in compMask]
chan = [chan[i] for i in compMask]
flux = [flux[i] for i in compMask]
peak = [peak[i] for i in compMask]
xoff = [xoff[i] for i in compMask]
xerr = [xerr[i] for i in compMask]
yoff = [yoff[i] for i in compMask]
yerr = [yerr[i] for i in compMask]



#=====================================================================
#   Determine weighted means:
#
vels = [wMean(vels[i],flux[i]) for i in xrange(len(comp))]
xoff = [wMean(xoff[i],flux[i]) for i in xrange(len(comp))]
xerr = [wMean(xerr[i],flux[i]) for i in xrange(len(comp))]
yoff = [wMean(yoff[i],flux[i]) for i in xrange(len(comp))]
yerr = [wMean(yerr[i],flux[i]) for i in xrange(len(comp))]

# These do not need weighted means, only the first (or max) is used:
comp = [comp[i][0] for i in xrange(len(comp))]
chan = [chan[i][0] for i in xrange(len(chan))]
flux = [flux[i][0] * scaleFactor for i in xrange(len(comp))]
peak = [peak[i][0] * scaleFactor for i in xrange(len(comp))]



#=====================================================================
#   Find mean velocity of each comp:
#   (previously used for comp-test.py. Not needed here)

# for i in xrange(len(vels)):
#     velAvg.append(float(sum(vels[i])/len(vels[i])))



#=====================================================================
#   Determine if user has requested for custom vel range:
#
for i in usrFile:
    usrVelLim = re.search('vel='+'([+-]?\d+.?\d+),([+-]?\d+.?\d+)',i)
    if usrVelLim:
        defaultVels = False  # Don't use defaultVels if user has defined it in usrFile
        velOne = float(usrVelLim.group(1))
        velTwo = float(usrVelLim.group(2))
        if velOne > velTwo:
            velMax = velOne
            velMin = velTwo
        elif velTwo > velOne:
            velMax = velTwo
            velMin = velOne
        elif velOne == velTwo:
            print "User velocities are identical. Reverting to default."
            defaultVels = True
if defaultVels:              # Default vels are the min/max of the velAvg for each comp.
    velMin = min(vels)
    velMax = max(vels)
    # Previously used for comp-test.py. Not needed here:
    # velMin = min(velAvg)
    # velMax = max(velAvg)



#=====================================================================
#   Each component is assigned a single homogenised vel for all spots,
#   instead of each spot having its own individual vel:
#
homoVel = vels
# Previously used for comp-test.py. Not needed here:
# for i in xrange(len(velAvg)):
#     for j in vels[i]:
#         homoVelTmp.append(velAvg[i])
#     homoVel.append(homoVelTmp)
#     homoVelTmp = []




#=====================================================================
#   Plot user specified components:
#
if 'comp' in usrFile:

    xoffAdd = []
    yoffAdd = []
    peakAdd = []
    fluxAdd = []
    velsAdd = []
    compAdd = []

    print "Enter 'q' to quit."
    print ""
    machineQuery = 'Component ID: '
    response     = raw_input(machineQuery)
    while response != 'q':
        usrComp = int(response)
        for i in xrange(len(comp)):               # Iterate through the list
            if usrComp == int(comp[i]):
                xoffAdd.append(xoff[i])
                yoffAdd.append(yoff[i])
                peakAdd.append(peak[i])
                fluxAdd.append(flux[i])
                velsAdd.append(vels[i])
                compAdd.append(comp[i])
        if xoffAdd != []:                         # Catch scrip in-case first choice is empty array
            scatter(xoffAdd,yoffAdd,s=fluxAdd,c=velsAdd,vmin=velMin,vmax=velMax)
            if 'atate' in usrFile:
                for i in xrange(len(compAdd)):
                    annotate(compAdd[i],xy=(xoffAdd[i],yoffAdd[i]))
            xlabel('x offset')
            ylabel('y offset')
            cbar = colorbar()
            cbar.set_label('Velocity')
            gca().invert_xaxis()
            show(block = False)

        response = raw_input(machineQuery)
        clf()
        close()



#=====================================================================
#   Plots entire sequence of compoments:
#
if 'seq' in usrFile:
    print "Enter 'q' to quit."
    print ""
    for i in xrange(len(comp)):

        scatter(xoff[i],yoff[i],s=flux[i],c=vels[i],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax)

        if 'atate' in usrFile:
            annotate(comp[i],xy=(xoff[i],yoff[i]))

        xlabel('x offset')
        ylabel('y offset')
        cbar = colorbar()
        cbar.set_label('Velocity')
        gca().invert_xaxis()
        show(block = False)

        response = raw_input('Component '+str(comp[i][0])+':')
        if response == 'q':
            exit()
        else:
            clf()
            close()



#=====================================================================
#   Plots spot map of maser emission:
#
if 'plot' in usrFile:
    for i in xrange(len(chan)):
        scatter(xoff[i],yoff[i],s=flux[i],c=homoVel[i],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax)
        if 'atate' in usrFile:
            annotate(comp[i],xy=(xoff[i],yoff[i]))

        # Format to match input .PTS file:
        print '%6d %10.3f %4d %13.5f %13.5f %33.6f %25.6f' %(int(comp[i]),float(vels[i]),int(chan[i]),float(flux[i]),float(peak[i]),float(xoff[i]),float(yoff[i]))
    gca().invert_xaxis()
    xlabel('x offset')
    ylabel('y offset')
    cbar = colorbar()
    cbar.set_label('Velocity')
    show()

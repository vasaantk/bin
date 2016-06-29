#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Friday, 18 March 2016.

import re
from pylab import *
import sys
import numpy as np
from functions import *
import random


usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "# pts-test.py takes input from a single .PTS file to study the"
    print "# component allocation from Luca Moscadelli's pts-diff.f."
    print "# The component positions and velocities are flux weighted"
    print "# using the algorithm from functions.py."
    print "# First argument must be *.PTS. Order for remaining options"
    print "# does not matter:"
    print ""
    print "# plot*  = options are: plot, seq, print and comp."
    print "# err    = plots fluxweighted errorbars."
    print "# atate  = annotates the spots with their component."
    print "# vatate = annotates the spots with their velocity."
    print "# vel    = allows user specified velocty range for the colourbar."
    print "# scale  = scales the peak flux of the data by a constant factor."
    print "# print  = print the details of the flux weighted components."
    print ""
    print "--> pts-test.py file_name.PTS plot* vel=xx.x,yy.y atate scale=xx"
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
    if reqInfo:                                    # Populate temp arrays, which are reset after each component is harvested
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

# These do not need weighted means, using the element with greatest flux:
comp = [comp[i][0] for i in xrange(len(comp))]
chan = [chan[i][flux[i].index(max(flux[i]))] for i in xrange(len(chan))]
peak = [peak[i][flux[i].index(max(flux[i]))] * scaleFactor for i in xrange(len(comp))]
flux = [flux[i][flux[i].index(max(flux[i]))] * scaleFactor for i in xrange(len(comp))]



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
    xerrAdd = []
    yerrAdd = []

    print "Enter 'q' to quit."
    print ""
    machineQuery = 'Component ID: '
    response     = raw_input(machineQuery)
    while response != 'q':
        if response == '' or float(response) < 0:
            response = raw_input(machineQuery)
        else:
            usrComp = int(response)
            for i in xrange(len(comp)):               # Iterate through the list
                if usrComp == int(comp[i]):
                    xoffAdd.append(xoff[i])
                    yoffAdd.append(yoff[i])
                    peakAdd.append(peak[i])
                    fluxAdd.append(flux[i])
                    velsAdd.append(vels[i])
                    compAdd.append(comp[i])
                    xerrAdd.append(xerr[i])
                    yerrAdd.append(yerr[i])
            if xoffAdd != []:                         # Catch scrip in-case first choice is empty array
                scatter( xoffAdd,yoffAdd,s=fluxAdd,c=velsAdd,vmin=velMin,vmax=velMax)
                if 'err' in usrFile:
                    errorbar(xoffAdd,yoffAdd,xerrAdd,yerrAdd)
                if 'atate' in usrFile:
                    for i in xrange(len(compAdd)):
                        annotate(compAdd[i],xy=(xoffAdd[i],yoffAdd[i]))
                if 'vatate' in usrFile:
                    for i in xrange(len(compAdd)):
                        annotate(float("{0:.1f}".format(velsAdd[i])),xy=(xoffAdd[i],yoffAdd[i]))
                title(str(usrFile[0]))
                xlabel('x offset')
                ylabel('y offset')
                cbar = colorbar()
                cbar.set_label('Velocity')
                gca().invert_xaxis()
                show(block = False)
            response = raw_input(machineQuery)
            clf()
            close()

    # Replaced this block with if/else above on Wednesday, 25 May 2016, 12:24 PM.
    # while response != 'q':
    #     usrComp = int(response)
    #     for i in xrange(len(comp)):               # Iterate through the list
    #         if usrComp == int(comp[i]):
    #             xoffAdd.append(xoff[i])
    #             yoffAdd.append(yoff[i])
    #             peakAdd.append(peak[i])
    #             fluxAdd.append(flux[i])
    #             velsAdd.append(vels[i])
    #             compAdd.append(comp[i])
    #             xerrAdd.append(xerr[i])
    #             yerrAdd.append(yerr[i])
    #     if xoffAdd != []:                         # Catch scrip in-case first choice is empty array
    #         scatter( xoffAdd,yoffAdd,s=fluxAdd,c=velsAdd,vmin=velMin,vmax=velMax)
    #         if 'err' in usrFile:
    #             errorbar(xoffAdd,yoffAdd,xerrAdd,yerrAdd)
    #         if 'atate' in usrFile:
    #             for i in xrange(len(compAdd)):
    #                 annotate(compAdd[i],xy=(xoffAdd[i],yoffAdd[i]))
    #         if 'vatate' in usrFile:
    #             for i in xrange(len(compAdd)):
    #                 annotate(float("{0:.1f}".format(velsAdd[i])),xy=(xoffAdd[i],yoffAdd[i]))

    #         xlabel('x offset')
    #         ylabel('y offset')
    #         title(str(usrFile[0]))
    #         cbar = colorbar()
    #         cbar.set_label('Velocity')
    #         gca().invert_xaxis()
    #         show(block = False)
    #     response = raw_input(machineQuery)
    #     clf()
    #     close()



#=====================================================================
#   Plots entire sequence of compoments:
#
if 'seq' in usrFile:
    print "Enter 'q' to quit."
    print ""
    for i in xrange(len(comp)):

        scatter( xoff[i],yoff[i],s=flux[i],c=vels[i],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax)
        if 'err' in usrFile:
            errorbar(xoff[i],yoff[i],xerr=xerr[i],yerr=yerr[i])
        if 'atate' in usrFile:
            annotate(comp[i],xy=(xoff[i],yoff[i]))
        if 'vatate' in usrFile:
            annotate(float("{0:.1f}".format(vels[i])),xy=(xoff[i],yoff[i]))

        xlabel('x offset')
        ylabel('y offset')
        title(str(usrFile[0]))
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
#   Format to match input .PTS file:
#
if 'print' in usrFile:
    print ""
    for i in xrange(len(chan)):
        print '%6d %10.3f %4d %13.5f %13.5f %33.6f %10.7f %14.6f %10.7f'%(
              int(comp[i]),float(vels[i]),int(chan[i]),float(flux[i]/scaleFactor),
            float(peak[i]/scaleFactor),float(xoff[i]),float(xerr[i]),float(yoff[i]),
            float(yerr[i]))
    print ""



#=====================================================================
#   Plots spot map of maser emission:
#
if 'plot' in usrFile:
    for i in xrange(len(chan)):
        scatter( xoff[i],yoff[i],s=flux[i],c=homoVel[i],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax)
        if 'err' in usrFile:
            errorbar(xoff[i],yoff[i],xerr=xerr[i],yerr=yerr[i])
        if 'atate' in usrFile:
            annotate(comp[i],xy=(xoff[i],yoff[i]))
        if 'vatate' in usrFile:
            annotate(float("{0:.1f}".format(vels[i])),xy=(xoff[i],yoff[i]))

    gca().invert_xaxis()
    title(str(usrFile[0]))
    xlabel('x offset')
    ylabel('y offset')
    cbar = colorbar()
    cbar.set_label('Velocity')
    show()

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Friday, 27 May 2016.

import re
from pylab import *
import sys
from mpldatacursor import datacursor

usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "# pts-frag.py takes input from multiple COMP.PTS files from"
    print "# Luca Moscadelli's pts-diff.f and plots the individual"
    print "# spots of a user specified feature."
    print "# The script is useful for determining if the spots in a"
    print "# feature are self-consistent throughout epochs."
    print ""
    print "# comp   = user specified component/feature of interest."
    print "# plot   = produces scatterplot."
    print "# err    = plots flux weighted errorbars."
    print "# atate  = annotate the spots with their component number."
    print "# vatate = annotate the spots with their velocity identifier."
    print "# vel    = specify velocty range for the colourbar."
    print "# scale  = scale the size of the datapoints by a factor."
    print "# print  = print the details of the flux weighted components."
    print "# sort   = options are: chan, vels, flux, xoff, yoff"
    print "# spec   = Produces a spectrum of the component/feature"
    print ""
    print "--> pts-frag.py file_name.COMP.PTS plot* vel=xx.x,yy.y atate scale=xx sort=xxxx comp=xx spec"
    print ""
    exit()

defaultVels   = True        # Otherwise usrVelLim
defaultScale  = True        # Otherwise usrScale
offsetRequest = False       # Reposition the centre position
atLeastOnce   = False       # Need the user component to be present at least once

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans



#=====================================================================#
#=====================================================================#
#                     Setup preliminaries.                            #
#=====================================================================#
#=====================================================================#

#=====================================================================
#   Adaptation of J. Mac's MATlAB function
#
def wMean(x,W,rms=False):
    wmean = sum(multiply(x,W))/sum(W)      # element-by-element multiplication
    if len(x) == 1:
        wrms = 0
    else:
        x = [(x - wmean)**2 for x in x]
        wrms = sqrt(sum(multiply(x,W))/sum(W))
    if rms:
        return wmean,wrms
    else:
        return wmean


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
#   Determine which are the COMP.PTS files:
#
ptsFiles = []
for i in usrFile:
    compPTS = re.search('COMP.PTS',i)
    if compPTS:
        ptsFiles.append(i)


#=====================================================================
#   Determine the user requested component
#
for i in usrFile:
    usrComp = re.search('comp='+'(\d+)',i)
    if usrComp:
        userComp = int(usrComp.group(1))


#=====================================================================
#   Find the maximum/minimum velocities for userComp from all .COMP.PTS files:
#
vels    = []
velMask = []
velsOk  = False
for pts in range(len(ptsFiles)):
    for line in open(ptsFiles[pts],'r'):
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:                                # Populate temp arrays, which are reset after each component is harvested
            if int(reqInfo.group(1)) == userComp:
                vels.append(float(reqInfo.group(2)))
                velsOk = True
    close(ptsFiles[pts])
if velsOk:
    for n in xrange(len(vels)):
        if vels[n] != []:
            velMask.append(int(n))
    vels = [vels[m] for m in velMask]
    velsAbsMax = max(vels)
    velsAbsMin = min(vels)


#=====================================================================
#   Sorting
#   http://stackoverflow.com/questions/6618515/sorting-list-based-on-values-from-another-list
sortRequest = 'chan'
for i in usrFile:
    usrSort = re.search('sort=(\S+)',i)
    if usrSort:
        if usrSort.group(1) in ['comp','vels','xoff','yoff','flux','chan']:
            sortRequest = str(usrSort.group(1))
            usrFile.append('print')


#=====================================================================
#   Condition to automatically toggle plotting
#
if 'atate' in usrFile or 'vatate' in usrFile or 'spec' in usrFile:
    usrFile.append('plot')

#=====================================================================#
#=====================================================================#
#                        End preliminaries.                           #
#=====================================================================#
#=====================================================================#



#=====================================================================#
#=====================================================================#
#                   Main script starts here.                          #
#=====================================================================#
#=====================================================================#

for pts in range(len(ptsFiles)): # Iterate through each of the input files.

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

    featurePosition = 0         # Position of requested array of spots

    allGoodFlag  = False        # Do not create a plot unless userComp exists. Set to FALSE for each new .COMP.PTS file


    #=====================================================================
    #   Harvest values:
    #
    for line in open(ptsFiles[pts],'r'):
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:                                    # Populate temp arrays, which are reset after each component is harvested
            mTmp.append(  int(reqInfo.group(1)))
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
    close(ptsFiles[pts])


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
    for n in xrange(len(comp)):
        if comp[n] != []:
            compMask.append(int(n))


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

    for feature in comp:
        if feature[0] == userComp:
            featureFound = featurePosition
            allGoodFlag  = True   # Do not create a plot unless userComp exists
        featurePosition += 1

    if allGoodFlag:

        atLeastOnce = True

        comp = comp[featureFound]
        vels = vels[featureFound]
        chan = chan[featureFound]
        flux = flux[featureFound]
        peak = peak[featureFound]
        xoff = xoff[featureFound]
        xerr = xerr[featureFound]
        yoff = yoff[featureFound]
        yerr = yerr[featureFound]

        #=====================================================================
        #   Sorting
        #
        if sortRequest == 'vels':
            comp = [x for (y,x) in sorted(zip(vels,comp),key=lambda pair: pair[0],reverse=True)]
            xoff = [x for (y,x) in sorted(zip(vels,xoff),key=lambda pair: pair[0],reverse=True)]
            xerr = [x for (y,x) in sorted(zip(vels,xerr),key=lambda pair: pair[0],reverse=True)]
            yoff = [x for (y,x) in sorted(zip(vels,yoff),key=lambda pair: pair[0],reverse=True)]
            yerr = [x for (y,x) in sorted(zip(vels,yerr),key=lambda pair: pair[0],reverse=True)]
            chan = [x for (y,x) in sorted(zip(vels,chan),key=lambda pair: pair[0],reverse=True)]
            flux = [x for (y,x) in sorted(zip(vels,flux),key=lambda pair: pair[0],reverse=True)]
            peak = [x for (y,x) in sorted(zip(vels,peak),key=lambda pair: pair[0],reverse=True)]
            vels = sorted(vels,reverse=True)
        if sortRequest == 'xoff':
            vels = [x for (y,x) in sorted(zip(xoff,vels),key=lambda pair: pair[0],reverse=True)]
            comp = [x for (y,x) in sorted(zip(xoff,comp),key=lambda pair: pair[0],reverse=True)]
            xerr = [x for (y,x) in sorted(zip(xoff,xerr),key=lambda pair: pair[0],reverse=True)]
            yoff = [x for (y,x) in sorted(zip(xoff,yoff),key=lambda pair: pair[0],reverse=True)]
            yerr = [x for (y,x) in sorted(zip(xoff,yerr),key=lambda pair: pair[0],reverse=True)]
            chan = [x for (y,x) in sorted(zip(xoff,chan),key=lambda pair: pair[0],reverse=True)]
            flux = [x for (y,x) in sorted(zip(xoff,flux),key=lambda pair: pair[0],reverse=True)]
            peak = [x for (y,x) in sorted(zip(xoff,peak),key=lambda pair: pair[0],reverse=True)]
            xoff = sorted(xoff,reverse=True)
        if sortRequest == 'yoff':
            vels = [x for (y,x) in sorted(zip(yoff,vels),key=lambda pair: pair[0],reverse=True)]
            xoff = [x for (y,x) in sorted(zip(yoff,xoff),key=lambda pair: pair[0],reverse=True)]
            xerr = [x for (y,x) in sorted(zip(yoff,xerr),key=lambda pair: pair[0],reverse=True)]
            comp = [x for (y,x) in sorted(zip(yoff,comp),key=lambda pair: pair[0],reverse=True)]
            yerr = [x for (y,x) in sorted(zip(yoff,yerr),key=lambda pair: pair[0],reverse=True)]
            chan = [x for (y,x) in sorted(zip(yoff,chan),key=lambda pair: pair[0],reverse=True)]
            flux = [x for (y,x) in sorted(zip(yoff,flux),key=lambda pair: pair[0],reverse=True)]
            peak = [x for (y,x) in sorted(zip(yoff,peak),key=lambda pair: pair[0],reverse=True)]
            yoff = sorted(yoff,reverse=True)
        if sortRequest == 'flux':
            vels = [x for (y,x) in sorted(zip(flux,vels),key=lambda pair: pair[0],reverse=True)]
            xoff = [x for (y,x) in sorted(zip(flux,xoff),key=lambda pair: pair[0],reverse=True)]
            xerr = [x for (y,x) in sorted(zip(flux,xerr),key=lambda pair: pair[0],reverse=True)]
            yoff = [x for (y,x) in sorted(zip(flux,yoff),key=lambda pair: pair[0],reverse=True)]
            yerr = [x for (y,x) in sorted(zip(flux,yerr),key=lambda pair: pair[0],reverse=True)]
            chan = [x for (y,x) in sorted(zip(flux,chan),key=lambda pair: pair[0],reverse=True)]
            comp = [x for (y,x) in sorted(zip(flux,comp),key=lambda pair: pair[0],reverse=True)]
            peak = [x for (y,x) in sorted(zip(flux,peak),key=lambda pair: pair[0],reverse=True)]
            flux = sorted(flux,reverse=True)
        if sortRequest == 'chan':
            vels = [x for (y,x) in sorted(zip(chan,vels),key=lambda pair: pair[0])]
            xoff = [x for (y,x) in sorted(zip(chan,xoff),key=lambda pair: pair[0])]
            xerr = [x for (y,x) in sorted(zip(chan,xerr),key=lambda pair: pair[0])]
            yoff = [x for (y,x) in sorted(zip(chan,yoff),key=lambda pair: pair[0])]
            yerr = [x for (y,x) in sorted(zip(chan,yerr),key=lambda pair: pair[0])]
            comp = [x for (y,x) in sorted(zip(chan,comp),key=lambda pair: pair[0])]
            flux = [x for (y,x) in sorted(zip(chan,flux),key=lambda pair: pair[0])]
            peak = [x for (y,x) in sorted(zip(chan,peak),key=lambda pair: pair[0])]
            chan = sorted(chan)


        #=====================================================================
        #   Format to match input .PTS file:
        #
        if 'print' in usrFile:
            print ""
            print str(ptsFiles[pts])
            for k in xrange(len(chan)):
                print '%6d %10.3f %4d %13.5f %13.5f %33.6f %10.7f %14.6f %10.7f'%(
                      int(comp[k]),float(vels[k]),int(chan[k]),float(flux[k]),
                    float(peak[k]),float(xoff[k]),float(xerr[k]),float(yoff[k]),
                    float(yerr[k]))
            print ""


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
            velMin = velsAbsMin
            velMax = velsAbsMax


        #=====================================================================
        #   Plots spot map of maser emission:
        #
        if 'plot' in usrFile:
            for j in xrange(len(chan)):
                if 'spec' in usrFile:
                    if pts == 0:   # First marker is a circle....
                        plot(vels[j],flux[j],marker="o")
                    else:          # ... second marker onwards corresponds to number of corners.
                        plot(vels[j],flux[j],marker=(pts+1,1,0))
                    xaxis = 'velocity'
                    yaxis = 'flux'
                    cbarFlag = False
                else:
                    cbarFlag = True
                    if pts == 0:   # First marker is a circle....
                        # Add 1 to ensure that components with flux<1 are not negative when log.
                        scatter( xoff[j],yoff[j],s=scaleFactor*log(flux[j]+1),c=vels[j],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax,marker="o")
                    else:          # ... second marker onwards corresponds to number of corners.
                        # Add 1 to ensure that components with flux<1 are not negative when log.
                        scatter( xoff[j],yoff[j],s=scaleFactor*log(flux[j]+1),c=vels[j],cmap=matplotlib.cm.jet,vmin=velMin,vmax=velMax,marker=(pts+1,1,0))
                    if 'err' in usrFile:
                        errorbar(xoff[j],yoff[j],xerr=xerr[j],yerr=yerr[j])
                    if 'atate' in usrFile:
                        annotate(comp[j],xy=(xoff[j],yoff[j]))
                    if 'vatate' in usrFile:
                        annotate(float("{0:.1f}".format(vels[j])),xy=(xoff[j],yoff[j]))
                    xaxis = 'x offset'
                    yaxis = 'y offset'
    else:    # Closes "if allGoodFlag:"
        print "\n\t\tWARNING. Component ** %d ** not found in %s"%(userComp,ptsFiles[pts])



#=====================================================================#
#=====================================================================#
#                  The main for-loop stops here.                      #
#=====================================================================#
#=====================================================================#



#=====================================================================
#   Plot title and axes info.
#
if 'plot' in usrFile and atLeastOnce:
    titleName = ''
    for i in range(len(ptsFiles)):
        titleName = titleName + ptsFiles[i][:-9] + '  **  '
    #titleName = titleName[:-5]    # Remove the trailing "**  " for the final title name
    gca().invert_xaxis()
    title(titleName + 'comp = '+str(userComp))
    xlabel(xaxis)
    ylabel(yaxis)
    if cbarFlag:
        cbar = colorbar()
        cbar.set_label('Velocity')
    datacursor(hover=True)
    show()

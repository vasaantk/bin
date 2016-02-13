#! /usr/bin/env python

# For program details run "mfPlotter.py" with no command-line arguments

from pylab import *
import re
import sys
from oct2py import octave

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Variables begin here       %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

# Command-line argument variables used by this script:
userFiles = sys.argv[1:]
inpCount = len(userFiles)
userInp = 0

if userFiles == []:
    print "# mfPlotter.py takes input from AIPS MFPRT (31DEC12) with: 'box 1 2 4 5 12 14 15 32 42 0' option. Command-line arguments (order does not matter):"
    print "# Numerical values shown are for example and can take up to several decimal places"
    print "#--> show"
    print "#--> chan"
    print "#--> spec"
    print "#--> vel=-23.2,-18.3             No spaces!"
    print "#--> ra=-0.3,3.4                 No spaces!"
    print "#--> dec=-0.3,3.4                No spaces!"
    print "#--> MF.OUT_(YOUR_FILE_NAME)"
    print "#--> VEL_RANGE.txt      (If you wish to define your own velocity ranges of maser clusters. See comment in the next paragraph for instructions on setting up the .txt file)"
    print "#--> snr=21.2"
    print "#--> print"
    print "#--> frames=30,100,300,480       No spaces!"
    print "#--> group=0.01,0.05             No spaces!"
    print ""
    print "# Create a VEL_RANGE.txt file and define your own velocity ranges of maser clusters. Format of file MUST be:"
    print "#-30.3,-34.2"
    print "#-36.1,-38.9"
    print "#-42.4,-56.3"

# Recurrant regex from which vales are to be harvested
spaceDigits = "\s+(-?\d+.\d+)"

# Arrays defined here:

# Arrays for 'harvestValues' loop:
planeArray = []           # Plane number variable
peakFlux = []             # Flux strength variable
xOff = []                 # RA offset variable
yOff = []                 # Dec offset variable
velArray = []             # Velocity variable
peakFluxErr = []          # Flux error
xOffErr = []              # RA error
yOffErr = []              # Dec error
residueRMS = []           # RMS of plane?

raOffSub = []             # RA offset corrected for peak flux RA position
decOffSub = []            # Dec offset corrected for peak flux Dec position
raSubErr = []             # RA offset corrected for peak flux RA position error
decSubErr = []            # Dec offset corrected for peak flux Dec position error

# Arrays for 'groupClusters' loop:
startVel = []             # Column one from VEL_RANGE.txt (most +ve)
stopVel = []              # Column two from VEL_RANGE.txt (most -ve)

velSubArray = []          # Subset of velocities as determined by VEL_RANGE.txt
planeSubArray = []        # Subset of planes as determined by VEL_RANGE.txt
peakFluxSub = []          # Subset of fluxes as determined by VEL_RANGE.txt
xSubOff = []              # Subset of RA as determined by VEL_RANGE.txt
ySubOff = []              # Subset of Dec as determined by VEL_RANGE.txt
peakFluxSubErr = []       # Subset of flux error as determined by VEL_RANGE.txt
xOffSubErr = []           # Subset of RA error as determined by VEL_RANGE.txt
yOffSubErr = []           # Subset of Dec error as determined by VEL_RANGE.txt
residueSubRMS = []        # Subset of RMS? as determined by VEL_RANGE.txt

velPlotArray = []         # Velocity subset of each individual cluster (reset in block 233)
peakFluxPlot = []         # Peak flux subset of each individual cluster (reset in block 233)
xSubPlot = []             # RA subset of each individual cluster (reset in block 233)
ySubPlot = []             # Dec subset of each individual cluset (reset in block 233)

signalLevel = []          # SNR level for VEL_RANGE.txt

# Arrays for 'groupClusters' loop:
beginNoisyFrames = []     # Fluxes of first set of frames for noise average
finishNoisyFrames = []    # Fluxes of second set of frames for noise average

# Arrays for 'allGrouperVarsDefined' loop:
weightedRA = []           # Combined RAs of constituents of each grouped maser spot
weightedDec = []          # Combined Decs of constituents of each grouped maser spot
weightedVel = []          # Combined Vels of constituents of each grouped maser spot
maxAmp = []               # Max Amp of constituents of each grouped maser spot
weightedRAErr = []        # Error of combined RAs of constituents of each grouped maser spot
weightedDecErr = []       # Error of combined Decs of constituents of each grouped maser spot

# Switching options for user:
harvestValues = False     # From MF.OUT
groupClusters = False     # From VEL_RANGE.txt
showPlot = False          # Scatter of MF.OUT. Toggled with --> show <-- in command-line
showSpectrum = False      # Spectrum of MF.OUT. Toggled with --> spec <-- in command-line
specInChannels = False    # Plot spectrum in channels instead of velocity. Toggled with --> chan --< in command-line
userVelRange = False      # Use user-defined velo range instead of automatically from array. Toggled with --> vel= <-- in command-line
userDecRange = False      # Use user-defined dec range instead of automatically from array. Toggled with --> dec= <-- in command-line
userRaRange = False       # Use user-defined ra range instead of automatically from array. Toggled with --> ra= <-- in command-line
harvestSNR = False        # Use user-defined SNR to filter data in harvestValues block. Toggled with --> snr= <-- in command-line
singleFrameOnly = False   # Pick only one emission fitting per frame. Depending on how SAD's parameters are set up, this should be the max emission for that frame
saveFigure = False        # Save the figure
printStats = False        # Print the harvested values automatically concatenating the last char from the MF.OUT file. Toggles with --> print <-- in command-line
noisyFrames = False       # Use user-defined frames to calculate SNR to filter data in harvestValues block. Toggled with --> frames= <-- in command-line
vlbiGrouper = False       # Group masers in associated channels together. Toggled with --> group= <-- in command-line
grpVarsDefined = False    # Checks that spot distance and velocity range are defined in proper format

# Counter Variables:
arrayPos = 0              # Position of peak flux in peakFlux array
figureNumber = 0          # Which cluser in VEL_RANGE.txt is being plotted
prevFrame = 0.0           # One maser spot. One frame. Otherwise, SAD's output can give several spots spread over a range of frames, all with the same frame count

# From Jamie's VLBI_Grouper.m:
# Group(k+1).summ=[max(Amp(CurrentGroup)), mean(RA(CurrentGroup)), mean(Dec(CurrentGroup)), WRA, WDec, std(RA(CurrentGroup)), std(Dec(CurrentGroup)), WRARMS, WDecRMS, WVel, std(Vel(CurrentGroup))];
SUMM_COMPONENTS = 11
AMP = 0
WRA = 3
WDEC = 4
WRA_ERR = 7
WDEC_ERR = 8
WVEL = 9

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Script begins from here    %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

# 'For' loop to determine what user has requested/defined
for i in userFiles:
    if re.match('print',i):
        printStats = True
    if re.match('show',i):
        showPlot = True
    if re.match('spec',i):
        showSpectrum = True
    if re.match('save',i):
        saveFigure = True
    if re.match('single',i):
        singleFrameOnly = True
    if re.match('cha',i):
        specInChannels = True
        showSpectrum = True
    if re.match('MF.OUT',i):
        harvestValues = True
        harvestFile = userInp
    if re.match('snr=',i):
        harvestSNR = True
        userSNR = userInp
    if re.match('VEL',i):
        groupClusters = True
        velocityFile = userInp
    if re.match('vel=',i):
        userVelRange = True
        userVel = userInp
    if re.match('ra=',i):
        userRaRange = True
        userRA = userInp
    if re.match('dec=',i):
        userDecRange = True
        userDec = userInp
    if re.match('frames=',i):
        noisyFrames = True
        userFrames = userInp
    if re.match('group=',i):
        vlbiGrouper = True
        grouperPos = userInp
    userInp += 1 # userInp keeps track of which position in the cmd line arg a specific user defined setting is

################################
# User defined values for velocity, snr, ra, dec (in the command line) are harvested here
################################
if userVelRange:
    requiredRangeInfo = re.search("vel=(-?\d+.\d+),(-?\d+.\d+)",userFiles[userVel])
    if requiredRangeInfo:
        colorbarMin = float(requiredRangeInfo.group(1))
        colorbarMax = float(requiredRangeInfo.group(2))
if userRaRange:
    requiredRAInfo = re.search("ra=(-?\d+.\d+),(-?\d+.\d+)",userFiles[userRA])
    if requiredRAInfo:
        raMin = float(requiredRAInfo.group(1))
        raMax = float(requiredRAInfo.group(2))
if userDecRange:
    requiredDecInfo = re.search("dec=(-?\d+.\d+),(-?\d+.\d+)",userFiles[userDec])
    if requiredDecInfo:
        decMin = float(requiredDecInfo.group(1))
        decMax = float(requiredDecInfo.group(2))
if harvestSNR:
    requiredSNRInfo = re.search("snr=(-?\d+.\d+)",userFiles[userSNR])
    if requiredSNRInfo:
        snrLimit = float(requiredSNRInfo.group(1))
if vlbiGrouper:
    requiredGrouper = re.search("group=(\d+.\d+),(\d+.\d+)",userFiles[grouperPos])
    if requiredGrouper:
        grpVarsDefined = True
        spotDist = float(requiredGrouper.group(1))
        velRange = float(requiredGrouper.group(2))
    else:
        print "'group=' syntax has not been defined properly, use: grouper=Max_Spot_Separation,Max_Velocity_Range"
if noisyFrames:
    requiredNoisyFrames = re.search("frames=(\d+),(\d+),(\d+),(\d+)",userFiles[userFrames])
    if requiredNoisyFrames:
        beginStartFrame = float(requiredNoisyFrames.group(1))
        beginEndFrame = float(requiredNoisyFrames.group(2))
        finishStartFrame = float(requiredNoisyFrames.group(3))
        finishEndFrame = float(requiredNoisyFrames.group(4))
    with open(userFiles[harvestFile]) as file:
        for line in file:
            requiredInfo = re.search("\s+(\d+)" + 9*spaceDigits, line)
            if requiredInfo:
                currentFrame = float(requiredInfo.group(2))
                # 'if' statements to sieve through to grab user-defined frames
                if currentFrame >= beginStartFrame and currentFrame <= beginEndFrame:
                    beginNoisyFrames.append(float(requiredInfo.group(3)))
                if currentFrame >= finishStartFrame and currentFrame <= finishEndFrame:
                    finishNoisyFrames.append(float(requiredInfo.group(3)))
                # Algorithm to manually set the peak flux average in-case of empty beginNoisyFrames or finishNoisyFrames arrays
                if len(beginNoisyFrames) == 0:
                    beginAvgNoisy = 0
                else:
                    beginAvgNoisy = sum(beginNoisyFrames) / len(beginNoisyFrames)
                if len(finishNoisyFrames) == 0:
                    finishAvgNoisy = 0
                else:
                    finishAvgNoisy = sum(finishNoisyFrames) / len(finishNoisyFrames)
    # Noise average calculated here
    noisyFramesAvgFlux = (beginAvgNoisy + finishAvgNoisy) / 2.

################################
# Build-up various arrays here into which values from MF.OUT file are harvested
################################
if harvestValues:
    with open(userFiles[harvestFile]) as file:
        for line in file:
            # group(1)   group(2)      group(3)       group(4)     group(5)     group(6)       group(7)       group(8)      group(9)     group(10)
            #   Row       Plane        Peak int       X-offset     Y-offset     Err peak       Err X-off      Err Y-off     Resid rms    Velocity
            requiredInfo = re.search("\s+(\d+)" + 9*spaceDigits, line)
            if requiredInfo:
                if harvestSNR and singleFrameOnly:
                    if float(requiredInfo.group(3))/float(requiredInfo.group(9)) >= snrLimit and float(requiredInfo.group(2)) != prevFrame:
                        planeArray.append(float(requiredInfo.group(2)))
                        peakFlux.append(float(requiredInfo.group(3)))
                        xOff.append(float(requiredInfo.group(4))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        yOff.append(float(requiredInfo.group(5))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        peakFluxErr.append(float(requiredInfo.group(6)))
                        xOffErr.append(float(requiredInfo.group(7)))
                        yOffErr.append(float(requiredInfo.group(8)))
                        residueRMS.append(float(requiredInfo.group(9)))
                        velArray.append(float(requiredInfo.group(10)))
                        prevFrame = float(requiredInfo.group(2))
                elif noisyFrames and harvestSNR:
                    if float(requiredInfo.group(3))/noisyFramesAvgFlux >= snrLimit:
                        planeArray.append(float(requiredInfo.group(2)))
                        peakFlux.append(float(requiredInfo.group(3)))
                        xOff.append(float(requiredInfo.group(4))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        yOff.append(float(requiredInfo.group(5))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        peakFluxErr.append(float(requiredInfo.group(6)))
                        xOffErr.append(float(requiredInfo.group(7)))
                        yOffErr.append(float(requiredInfo.group(8)))
                        residueRMS.append(float(requiredInfo.group(9)))
                        velArray.append(float(requiredInfo.group(10)))
                elif harvestSNR:
                    if float(requiredInfo.group(3))/float(requiredInfo.group(9)) >= snrLimit:
                        planeArray.append(float(requiredInfo.group(2)))
                        peakFlux.append(float(requiredInfo.group(3)))
                        xOff.append(float(requiredInfo.group(4))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        yOff.append(float(requiredInfo.group(5))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        peakFluxErr.append(float(requiredInfo.group(6)))
                        xOffErr.append(float(requiredInfo.group(7)))
                        yOffErr.append(float(requiredInfo.group(8)))
                        residueRMS.append(float(requiredInfo.group(9)))
                        velArray.append(float(requiredInfo.group(10)))
                elif singleFrameOnly:
                    if float(requiredInfo.group(2)) != prevFrame:
                        planeArray.append(float(requiredInfo.group(2)))
                        peakFlux.append(float(requiredInfo.group(3)))
                        xOff.append(float(requiredInfo.group(4))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        yOff.append(float(requiredInfo.group(5))*0.0003) # 0.0003 to convert units from pixels to arcsec
                        peakFluxErr.append(float(requiredInfo.group(6)))
                        xOffErr.append(float(requiredInfo.group(7)))
                        yOffErr.append(float(requiredInfo.group(8)))
                        residueRMS.append(float(requiredInfo.group(9)))
                        velArray.append(float(requiredInfo.group(10)))
                        prevFrame = float(requiredInfo.group(2))
                else:
                    planeArray.append(float(requiredInfo.group(2)))
                    peakFlux.append(float(requiredInfo.group(3)))
                    xOff.append(float(requiredInfo.group(4))*0.0003) # 0.0003 to convert units from pixels to arcsec
                    yOff.append(float(requiredInfo.group(5))*0.0003) # 0.0003 to convert units from pixels to arcsec
                    peakFluxErr.append(float(requiredInfo.group(6)))
                    xOffErr.append(float(requiredInfo.group(7)))
                    yOffErr.append(float(requiredInfo.group(8)))
                    residueRMS.append(float(requiredInfo.group(9)))
                    velArray.append(float(requiredInfo.group(10)))

    # 'For' loop to determine which frame in 'peakArray' has the max flux
    maxFlux = max(peakFlux)
    for element in peakFlux:
        if element != maxFlux:
            arrayPos += 1
        else:
            arrayCount = arrayPos

    raSubtractVal = xOff[arrayCount]
    decSubtractVal = yOff[arrayCount]

    # Arrays of subtrated RA and Dec offsets w.r.t maximum flux position
    for item in xOff:
        raOffSub.append(item - raSubtractVal)
    for item in yOff:
        decOffSub.append(item - decSubtractVal)

    xOff = raOffSub
    yOff = decOffSub

################################
# This is the section of code to group and plot the masers using Jamie McCallum's VLBI_Grouper.m and WeightedMean.m (which have to be in: /usr/share/octave/CURRENT_VERSION_FOLDER/m/)
################################
if grpVarsDefined:
    octavedGroups = octave.VLBI_Grouper(xOff, yOff, velArray, peakFlux, spotDist, velRange)
    groupCount = len(octavedGroups['RA'])

    if userVelRange:
        velMin=colorbarMin
        velMax=colorbarMax
    else:
        velMin=min(velArray)
        velMax=max(velArray)

    for i in xrange(groupCount):
        # To weed out groups with only one maser element member: I've done a type() check because ones with multiple members are of type ndarray
        if type(octavedGroups['index'][i]) != float64:
            # octavedGroups['summ'][SUMM_COMPONENTS*i+WRA] --> because 'summ' array is 2D in MATLAB but 1D in python and the wrap-around is after each 11th element in the latter
            weightedRA.append(octavedGroups['summ'][SUMM_COMPONENTS*i+WRA])
            weightedDec.append(octavedGroups['summ'][SUMM_COMPONENTS*i+WDEC])
            weightedVel.append(octavedGroups['summ'][SUMM_COMPONENTS*i+WVEL])
            maxAmp.append(octavedGroups['summ'][SUMM_COMPONENTS*i+AMP])
            weightedRAErr.append(octavedGroups['summ'][SUMM_COMPONENTS*i+WRA_ERR])
            weightedDecErr.append(octavedGroups['summ'][SUMM_COMPONENTS*i+WDEC_ERR])

    if showPlot:
        subplot2grid((2,1),(0,0)) # Subplot of combined weighted groups
        scatter(weightedRA, weightedDec, s=maxAmp, c=weightedVel, facecolors='none', vmin=velMin, vmax=velMax, marker='o')
        gca().invert_xaxis() # For some reason this is sufficient to flip the x-axis

        subplot2grid((2,1),(1,0)) # Sublot of uncombined weighted groups
        scatter(xOff, yOff, s=peakFlux, c=velArray, facecolors='none', vmin=velMin, vmax=velMax, marker='D')
        gca().invert_xaxis() # For some reason this is sufficient to flip the x-axis

        cbarCluster = colorbar(orientation='horizontal')
        cbarCluster.set_alpha(1)
        cbarCluster.draw_all()

        showPlot = False # To stop plotting later on
        show()

    if printStats:
        xOff = weightedRA
        yOff = weightedDec
        peakFlux = maxAmp
        velArray = weightedVel
        xOffErr = weightedRAErr
        yOffErr = weightedDecErr
        planeArray = []
        peakFluxErr = []
        residueRMS = []

################################
# This is the section of code to group the masers into user-defined clusters
################################
if groupClusters and harvestValues:
    with open(userFiles[velocityFile]) as file:
        for line in file:
            requiredVelInfo = re.search("(-?\d+.\d+),(-?\d+.\d+),(\d+.\d+)", line)
            if requiredVelInfo:
                startVel.append(float(requiredVelInfo.group(1)))
                stopVel.append(float(requiredVelInfo.group(2)))
                signalLevel.append(float(requiredVelInfo.group(3)))
    for i in range(0,len(startVel),1):
        velStartPos = 0
        velStopPos = 0
        requiredSignal = signalLevel[i]
        # figRows tells the script to plot only one row of maser emission if only one velocity set is given. Otherwise it plots n + 1 rows
        if i > 0:
            figRows = 1
        else:
            figRows = 0

        for item in velArray:
            # Selection condition of valid data from the original velocity dataset
            if item > startVel[i]:
                velStartPos += 1
            if item > stopVel[i]:
                velStopPos += 1

        for m in arange(velStartPos,velStopPos,1):
            # These arrays contain the information of all the individual clusters as determined by user. They are plotted in block 222
            if peakFlux[m]/residueRMS[m] >= requiredSignal:
                velSubArray.append(velArray[m])
                planeSubArray.append(planeArray[m])
                peakFluxSub.append(peakFlux[m])
                xSubOff.append(xOff[m])
                ySubOff.append(yOff[m])
                peakFluxSubErr.append(peakFluxErr[m])
                xOffSubErr.append(xOffErr[m])
                yOffSubErr.append(yOffErr[m])
                residueSubRMS.append(residueRMS[m])

            # This 4-line block maintains the values for the current cluster only. After the cluster in question is plotted, the block arrays are reset block 206
            if peakFlux[m]/residueRMS[m] >= requiredSignal:
                velPlotArray.append(velArray[m])
                peakFluxPlot.append(peakFlux[m])
                xSubPlot.append(xOff[m])
                ySubPlot.append(yOff[m])

            if userVelRange:
                velMin=colorbarMin
                velMax=colorbarMax
            else:
                velMin=min(velArray)
                velMax=max(velArray)

            # subplot2grid *** len(startVel) + 1 + figRows ***
            # len(startVel) --> One plot for each velocity range
            # + 1           --> For the colorbar
            # + figRows     --> For the superimposed scatter plot of ALL user defined clusters
            rowSpan = len(startVel) + figRows

            if i == figureNumber:
                figureNumber = figureNumber
            else:
                # Scatter plot of each user defined cluster; EXCLUDING the final one (which is created on block 246)
                subplot2grid((rowSpan,1),(figureNumber,0))
                scatter(xSubPlot, ySubPlot, s=peakFluxPlot, c=velPlotArray, cmap=matplotlib.cm.jet, facecolors='none', alpha=0.5, vmin=velMin, vmax=velMax)
                ylabel(str(startVel[figureNumber]) + ' to ' + str(stopVel[figureNumber]) + ' km/s' , weight='bold', rotation='horizontal')
                gca().invert_xaxis()
                gca().set_aspect('equal')
                figureNumber += 1
                velPlotArray = []
                peakFluxPlot = []
                xSubPlot = []
                ySubPlot = []

    # Scatter plot of FINAL user defined cluster (as it gets omitted from the 'else' statement from above)
    subplot2grid((rowSpan,1),(figureNumber,0))
    scatter(xSubPlot, ySubPlot, s=peakFluxPlot, c=velPlotArray, cmap=matplotlib.cm.jet, facecolors='none', alpha=0.5, vmin=velMin, vmax=velMax)
    gca().invert_xaxis()
    gca().set_aspect('equal')
    ylabel(str(startVel[figureNumber]) + ' to ' + str(stopVel[figureNumber]) + ' km/s' , weight='bold', rotation='horizontal')
    # Scatter plot of sum total of ALL user defined clusters
    # (figureNumber + figRows) to define y-position of the graph as greater than previously determined by loop
    subplot2grid((rowSpan,1),(figureNumber + figRows,0))
    scatter(xSubOff, ySubOff, s=peakFluxSub, c=velSubArray, cmap=matplotlib.cm.jet, facecolors='none', alpha=0.5, vmin=velMin, vmax=velMax)
    gca().set_aspect('equal')
    gca().invert_xaxis()
    # Colorbar
    # (figureNumber + figRows + 1 ) to define y-position of the graph as greater than previously determined for colorbar
    #cbarAx = subplot2grid((rowSpan,1),(figureNumber + figRows + 1,0))
    cbarCluster = colorbar(orientation='horizontal')
    cbarCluster.set_alpha(1)
    cbarCluster.draw_all()
    show()

if showPlot:
    if harvestValues:
        if userVelRange:
            scat=scatter(xOff, yOff, s=peakFlux, c=velArray, cmap=matplotlib.cm.jet, facecolors='none', alpha=0.5, vmin=colorbarMin, vmax=colorbarMax)
        else:
            scatter(xOff, yOff, s=peakFlux, c=velArray, cmap=matplotlib.cm.jet, facecolors='none', alpha=0.5, vmin=min(velArray), vmax=max(velArray))
        gca().invert_xaxis() # For some reason this is sufficient to flip the x-axis
        gca().set_aspect('equal')
        xlabel('arc sec')
        ylabel('arc sec')
        cbar = colorbar(orientation='horizontal')
        cbar.set_alpha(1)
        cbar.draw_all()
        cbar.set_label('km/s')
        if userRaRange:
            xlim(raMax, raMin)
        if userDecRange:
            ylim(decMin, decMax)
        if saveFigure:
            savefig('figMFplotter.eps',format='eps')
        show()

if showSpectrum:
    if harvestValues:
        if specInChannels:
            plot(planeArray,peakFlux)
            gca().invert_xaxis() # For some reason this is sufficient to flip the x-axis
        else:
            plot(velArray,peakFlux)
        show()

if printStats:
    print 'plane_'+str(userFiles[harvestFile][-1])+'='+str(planeArray) # [harvestFile][-1] grabs last char of the MF.OUT_* file
    print 'flux_'+str(userFiles[harvestFile][-1])+'='+str(peakFlux)
    print 'xOff_'+str(userFiles[harvestFile][-1])+'='+str(xOff)
    print 'yOff_'+str(userFiles[harvestFile][-1])+'='+str(yOff)
    print 'fluxErr_'+str(userFiles[harvestFile][-1])+'='+str(peakFluxErr)
    print 'xErr_'+str(userFiles[harvestFile][-1])+'='+str(xOffErr)
    print 'yErr_'+str(userFiles[harvestFile][-1])+'='+str(yOffErr)
    print 'rms_'+str(userFiles[harvestFile][-1])+'='+str(residueRMS)
    print 'vel_'+str(userFiles[harvestFile][-1])+'='+str(velArray)

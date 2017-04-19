#! /usr/bin/env python

# Vasaant Krishnan. For program details run "fringPlotter.py" with no command-line arguments 16 February 2014

from pylab import *
import re
import sys
import datetime

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Variables begin here       %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

# Command-line argument variables used by this script:
userFiles = sys.argv[1:]

if userFiles == []:
    print "# fringPlotter.py takes input from AIPS FRING (31DEC13) output in PRTMSG."
    print "# The timerange of the date is harvested along with: antenna number, phase, rate, delay and snr."
    print "# Note: This script was written to harvest information from distinctive ICRF blocs in the V255 suite of observations"
    print ""
    print "--> ./fringPlotter.py     FRING.OUT     ICRF_BLOCK_NUMBER     PRINT_OPTIONS (short/full)"

timeArray     = []
antArray      = []
phasArray     = []
rateArray     = []
delayArray    = []
snrArray      = []
rmsDelayArray = []
antPosArray   = []
antFreqArray  = []

harvestValues = False
runCode       = True
harvestDelays = False
printShort    = False
printFull     = False
doThis        = False

prevDateTime   = datetime.datetime(year=1, month=1, day=1, hour=1, minute=1, second=1)
prevHr         = 0
counter        = 0
antFreqCounter = 0


SPACE_DIGITS = "\s*(-?\d+.\d+)\s*"
harvestFile  = 0

if len(userFiles) > 0:
    reqBlock = re.search("(\d)",userFiles[1])
    if reqBlock:
        blockNumber = int(reqBlock.group(1))
    harvestValues = True

if len(userFiles) > 2:
    printOption = re.search("(\S+)",userFiles[2])
    if printOption:
        if str(printOption.group(1)) == 'short':
            printShort = True
        elif str(printOption.group(1)) == 'full':
            printFull = True
            printShort = True

################################
# Build-up various arrays here into which values from FRING file are harvested
################################

if harvestValues:
    with open(userFiles[harvestFile]) as file:
        for line in file:
            #####################                           group(1) (2)(3)(4)
            #1    2   13-FEB-2014  15:02:40     FRING     Time=   0/ 12 38 27, Polarization = 1
            reqDateTime = re.search("Time=\s+(\d)\S\s+(\d\d)\s(\d\d)\s(\d\d)", line)
            #####################

            #####################                        group(1)          (2)            (3)              (4)        (5)
            #1    3   13-FEB-2014  15:03:03     FRING     Ant(01): Phas=   5.3 rate=     -4.32 delay=      2.50 SNR=  62.6
            reqPRDS = re.search("Ant\S(\d+)\S:\sPhas=" + SPACE_DIGITS + "rate=" + SPACE_DIGITS + "delay=" + SPACE_DIGITS + "SNR=" + SPACE_DIGITS, line)
            #####################
            if reqDateTime:
                # Harvesting of the times happens in this bloc
                if runCode:
                    dayGrab  = int(reqDateTime.group(1)) + 1 # AIPS takes day=0 as the first day of observation, but datetime() needs it to be at least 1
                    hourGrab = int(reqDateTime.group(2))
                    minGrab  = int(reqDateTime.group(3))
                    secGrab  = int(reqDateTime.group(4))

                    # Because the delay, rate, phase info. in FRING is bracketed by the same timerange, sift out only the first instance to print
                    currentDateTime = datetime.datetime(year=1, month=1, day=dayGrab, hour=hourGrab, minute=minGrab, second=secGrab)
                    if prevDateTime != currentDateTime:
                        timeArray.append(currentDateTime)
                        prevDateTime = currentDateTime
                        if printFull:
                            print "Time    " + str(dayGrab) , str(hourGrab) , str(minGrab) , str(secGrab)

                    # Determine which ICRF block the code is iterating though via 'counter' variable
                    currHr = hourGrab
                    if abs(prevHr - currHr) > 2: # This filters the ICRF blocks according to timerange since we know that they cannot span more than 2 hrs
                        prevHr = currHr
                        counter += 1

            # Switch on delay harvesting only if code is currently in the correct loop
            if counter == blockNumber:
                harvestDelays = True
            if counter != blockNumber:
                harvestDelays = False

            if reqPRDS:

                # Harvesting of the antenna, phase, rate, delay and SNR happens here
                if harvestDelays:
                    antGrab   =   int(reqPRDS.group(1))
                    phasGrab  = float(reqPRDS.group(2))
                    rateGrab  = float(reqPRDS.group(3))
                    delayGrab = float(reqPRDS.group(4))
                    snrGrab   = float(reqPRDS.group(5))

                    if printShort:
                        print antGrab , delayGrab

                    # Arrays populated
                    antArray.append(     antGrab)
                    phasArray.append(   phasGrab)
                    rateArray.append(   rateGrab)
                    delayArray.append( delayGrab)
                    snrArray.append(     snrGrab)

                    # Determine the RMS of the delays for the ICRF block in question
                    for element in delayArray:
                        rmsDelayArray.append(element**2)
                        rmsDelayMean = sqrt(mean(rmsDelayArray))

    print "The RMS delay for ICRF block " + str(blockNumber) + " is: " + str("%.3f"%rmsDelayMean) + " ns"
    print "The median is: " + str(median(delayArray)) + " ns"

firstIter = True
doThis = False
antDict = {}
if doThis:
    antCount = max(antArray)
    for i in xrange(1, antCount + 1):
        antPosCount = 0 # Counter variable to determine the position of a particular antenna
        if antPosCount == 0:
            # Determine how many readings are from a particular antenna when code checks subsequent antenna
            antFreqArray.append(antArray.count(i))
            if antArray.count(i) > 0:
                newAntArray.append(i)
        for antenna in antArray:
            if antenna == i:
                antPosArray.append(antPosCount)
            antPosCount += 1


    for freq in antFreqArray:
        if firstIter:
            startCount = 1
            endCount = freq
        else:
            startCount += freq
            endCount += freq
        rmsDelayArray = []
        for j in xrange(startCount, endCount):
            rmsDelayArray.append(delayArray[antPosArray[j]]**2)
            if freq == 0:
                rmsDelayMean = 'No data'
            else:
                rmsDelayMean = sqrt(mean(rmsDelayArray))
        firstIter = False
        print rmsDelayMean

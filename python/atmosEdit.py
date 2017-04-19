#!/usr/bin/env python
# Vasaant Krishnan
import re
import sys
import random

userFiles = sys.argv[1:]
inpCount = len(userFiles)
userInp = 0

SPACES = "     "
GAUSS_SIGMA = 5

printOrig = False
setUserGauss = False
setRandDZen = False
enterLoop = True

if userFiles == []:
    enterLoop = False
    print ""
    print "# atmosEdit.py reads in ATMOS.FITS from either fits_geoblocks.f or from AIPS task and produces another ATMOS.FITS format output."
    print "# This output consists of random values for: zenith, clock, dzenith and dclock delays."
    print "# The purpose of this was to test the effect of random zenith delays on QSO position determination in the v255 experiments."
    print "# Command-line options are"
    print "#--> orig          Prints out the original ATMOS.FITS values"
    print "#--> gauss=        Sets GAUSS_SIGMA to user-defined integer value (default 5)"
    print "#--> dzen          Includes random dZenith contribution. Otherwise, dzenith is assumed to be 0.0"
    print ""

for i in userFiles:
    if re.match('orig',i):
        printOrig = True
    if re.match('gauss',i):
        setUserGauss = True
        gaussPos = userInp
    if re.match('dzen',i):
        setRandDZen = True
    userInp += 1

# This function allows the script to compute how many spaces need to be alloted to ensure equally spaced columns of: zenith, clock, dzenith and dclock delays
def space_compare(charOfInterest):
    charDiff = len(str("%.3f"%charOfInterest)) - len(SPACES)
    if charDiff < 0:
        spaceDiff = len(SPACES) + abs(charDiff)
    elif charDiff > 0:
        spaceDiff = len(SPACES) - charDiff
    else:
        spaceDiff = len(SPACES)
    return str(spaceDiff*" ")

# Grab the user-defined Gaussian sigma level as defined by the user
if setUserGauss:
    reqGaussInfo = re.search('gauss=(\d+)',userFiles[gaussPos])
    if reqGaussInfo:
        GAUSS_SIGMA = int(reqGaussInfo.group(1))

# Values from original ATMOS.FITS file harvested here
if enterLoop:
    # This is just a no. at the very first line of ATMOS.FITS output from fit_geoblocks.f which tells AIPS how many lines in the ATMOS.FITS file.
    print "   15"

    for line in open(userFiles[0],'r'):
        requiredInformation = re.search("(\s+\d\s+\d\s+\d+\s+\d+\s+\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+?)\s+(-?\d+.\d+)\s+(-?\d+.\d+)",line)
        if requiredInformation:
            universalTime = requiredInformation.group(1)
            zenithDelay =  requiredInformation.group(2)
            clockDelay = requiredInformation.group(3)
            dZenithDelay = requiredInformation.group(4)
            dClockDelay =  requiredInformation.group(5)

            # A random delay is determined for the respective parameter based on a Gaussian and sigma
            randomZenith = random.gauss(float(zenithDelay), GAUSS_SIGMA)
            randomClock =  random.gauss(float(clockDelay), GAUSS_SIGMA)
            randomDZenith = random.gauss(float(dZenithDelay), GAUSS_SIGMA)
            randomDClock =  random.gauss(float(dClockDelay), GAUSS_SIGMA)

            # Computation of number of spacings required for neatly aligned columns
            zenithSpaceDiff =  space_compare(randomZenith)
            clockSpaceDiff = space_compare(randomClock)
            dZenithSpaceDiff = space_compare(randomDZenith)

            if printOrig:
                print str(universalTime) + SPACES + str(zenithDelay) + space_compare(float(zenithDelay)) + str(clockDelay) + space_compare(float(clockDelay)) + str(dZenithDelay) + space_compare(float(dZenithDelay)) + str(dClockDelay)
            elif setRandDZen:
                print str(universalTime) + SPACES + str("%.3f"%randomZenith) + zenithSpaceDiff + str("%.3f"%randomClock) + clockSpaceDiff +  str("%.3f"%randomDZenith) + dZenithSpaceDiff + str("%.3f"%randomDClock)
            else:
                print str(universalTime) + SPACES + str("%.3f"%randomZenith) + zenithSpaceDiff + str("%.3f"%randomClock) + clockSpaceDiff +  str(dZenithDelay) + SPACES + str("%.3f"%randomDClock)

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Thursday, 14 April 2016, 12:11 PM
# Run without arguments for instructions.

import re
from pylab import *
import sys
import numpy as np
from scipy import *
from scipy import constants as sc

usrFile = sys.argv[1:]

#=====================================================================
#   Please check your script parameters:
#
channels   = 2048           # No. of channels 1 - End
chanOffset = 1100           # First channel in the image cube
suVel      = 23.45637423    # SU table velocity after SETJY (km/s)
freqStep   = 9.7656250*1e2  # SU table frequency            (Hz)
setjyChan  = 1025           # Centre channel in POSSM
bandStart  = 6.669*1e9      # Start frequency of the LINE data
bandWidth  = 2e6            # Bandwidth of the LINE data
#=====================================================================


if len(usrFile) == 0:
    print ""
    print "In the v255 experiments, we have to image the masers with modified FQ"
    print "tables. This results in incorrect velocities for each plane in the"
    print "IMAGE cube."
    print ""
    print "This script fixes the velocities for the output from AIPS MFPRT;"
    print "optype = 'line', using a Doppler approximation and based on the"
    print "following parameters (which you need to check):"
    print ""
    print "Number of channels in POSSM       [channels]: %d"%channels
    print "First plane in the image cube   [chanOffset]: %d"%chanOffset
    print "SU table velocity after SETJY        [suVel]: %f km/s"%suVel
    print "SU table frequency after SETJY    [freqStep]: %f Hz"%freqStep
    print "Centre channel in POSSM          [setjyChan]: %d"%setjyChan
    print "Start frequency of the LINE data [bandStart]: %g Hz"%bandStart
    print "Bandwidth of the LINE data       [bandWidth]: %g Hz"%bandWidth
    print ""
    print "As of Tuesday, 19 April 2016, the corrections are accurate to 2"
    print "decimal places for most frames, and 1 decimal place at the higher"
    print "frames. This is because I am still unable to determine the exact"
    print "velocity step size which is used in POSSM."
    print ""
    print "--> vel-fix.py userfile.MF"
    print ""
    exit()
else:
    mfFile = usrFile[0]
    startScript = True


#=====================================================================
#   Define variables:
#
spaDigs = '\s+(\d+)'           # 'Space digits'
spaFlot = '\s+?([+-]?\d+.\d+)' # 'Space floats'
metres2kilo = 1e-3             # Convert Metres to Kilometres

mfCha      = []  # MF channel
mfPks      = []  # MF peak
mfXoff     = []  # MF xOff
mfYoff     = []  # MF yOff
mfMajAx    = []  # MF major axis
mfMinAx    = []  # MF minor axis
mfPosAng   = []  # MF position angle
mfDeconMaj = []  # MF deconvolved beam major axis
mfDeconMin = []  # MF deconvolved beam minor axis
mfDeconPos = []  # MF deconvolved beam position angle
mfVel      = []  # MF velocity

chanVel    = []  # Array of computed vels
fixedVels  = []  # Final array of fixe3d fixed
#=====================================================================


if startScript:

    chanOffsetCorrected = chanOffset-1

    #=====================================================================
    #   Doppler corrections:
    #
    bandStop    = bandStart + bandWidth
    # Frequencies exactly as in POSSM:
    chanFreqs   = linspace(bandStart,bandStop,channels)
    centreFreq  = chanFreqs[setjyChan]
    # Doppler approximation:
    velStep     = -sc.c * freqStep/centreFreq * metres2kilo
    # Create array of velocities based on Doppler computations:
    for i in xrange(channels):
        chanVel.append(suVel + velStep*int(i))
    #=====================================================================


    #=====================================================================
    #   Harvest values:
    #

    for line in open(mfFile,'r'):
        reqInfo = re.search(  spaFlot   # (1)  Channel
                            + spaFlot   # (2)  Peak
                            + spaFlot   # (3)  X-off
                            + spaFlot   # (4)  Y-off
                            + spaFlot   # (5)  MajAxis
                            + spaFlot   # (6)  MinAxis
                            + spaFlot   # (7)  PosAng
                            + spaFlot   # (8)  DeconMaj
                            + spaFlot   # (9)  DeconMin
                            + spaFlot   # (10) DeconPA
                            + spaFlot,  # (11) Vel
                            line)
        if not reqInfo:
            print line,
        else:
            for i in xrange(len(chanVel)):
                if i == int(float(reqInfo.group(1))):
                    print "%9.3f%11.3f%12.3f%12.3f%11.3f%11.3f%11.3f%11.3f%11.3f%11.3f%11.3f"%(
                        float(reqInfo.group(1)),
                        float(reqInfo.group(2)),
                        float(reqInfo.group(3)),
                        float(reqInfo.group(4)),
                        float(reqInfo.group(5)),
                        float(reqInfo.group(6)),
                        float(reqInfo.group(7)),
                        float(reqInfo.group(8)),
                        float(reqInfo.group(9)),
                        float(reqInfo.group(10)),
                        chanVel[i+chanOffsetCorrected])
    close(mfFile)

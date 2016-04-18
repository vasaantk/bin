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

# possCha    = []  # POSSM channel
# possVel    = []  # POSSM velocity
# possPks    = []  # POSSM fluxes
# possmSecondPass = False
# possmSequential = True
# findVelStep     = True
#=====================================================================



# if len(usrFile) == 2:
#     possm  = usrFile[0]
#     mfFile = usrFile[1]
# else:
#     print "Check your input files."
#     startScript = False



if startScript:
    #=====================================================================
    #   Harvest values:
    #

    # for line in open(possm,'r'):
    #     reqInfo = re.search(  spaDigs        # (1) Channel
    #                         + spaDigs        # (2) IF
    #                         + '\s+\S+\s+'    #     Stokes
    #                         + spaFlot        # (3) Freq
    #                         + spaFlot        # (4) Vel
    #                         + spaFlot        # (5) Real(Jy)
    #                         + spaFlot,       # (6) Imag(Jy)
    #                         line)
    #     if reqInfo:
    #         possCha.append(  int(reqInfo.group(1)))
    #         # Check if adjacent channels are sequential or not from
    #         # the second pass onwards:
    #         if possmSecondPass:
    #             if (possCha[-1] - possCha[-2]) != 1:
    #                 print "POSSM channels %d and %d are not in sequence."%(possCha[-2],possCha[-1])
    #                 possmSequential = False
    #         possVel.append(float(reqInfo.group(4)))
    #         possPks.append(float(reqInfo.group(5)))
    #         possmSecondPass = True
    # close(possm)

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
        if reqInfo:
            mfCha.append( int(float(reqInfo.group(1))))
            mfPks.append(     float(reqInfo.group(2)))
            mfXoff.append(    float(reqInfo.group(3)))
            mfYoff.append(    float(reqInfo.group(4)))
            mfMajAx.append(   float(reqInfo.group(5)))
            mfMinAx.append(   float(reqInfo.group(6)))
            mfPosAng.append(  float(reqInfo.group(7)))
            mfDeconMaj.append(float(reqInfo.group(8)))
            mfDeconMin.append(float(reqInfo.group(9)))
            mfDeconPos.append(float(reqInfo.group(10)))
            mfVel.append(     float(reqInfo.group(11)))
    close(mfFile)

    #====================================================================#
    #                                                                    #
    #   I have been trying to fix the velocities in Q_339.COMP as a      #
    #   result of the changes in the FQ table in AIPS before applying    #
    #   delay calibration.                                               #
    #                                                                    #
    #   I have managed to figure out 2-ways to implement this. One using #
    #   emipircal data from POSSM, and the second using the Doppler      #
    #   approximation to determine the velocity resolution.              #
    #                                                                    #
    #   Option 1 naturally gives the more accurate result, as the vels   #
    #   are determined directly from POSSM. Here,                        #
    #   Delta_V=-0.0438961406936981 km/s.                                #
    #                                                                    #
    #   Option 2 gives Delta_V=-0.0438929579312 km/s.                    #
    #                                                                    #
    #   The fractional difference between the two may only               #
    #   -7.25119154072e-05, but afer about 10 iterations, it starts to   #
    #   hit the velocity resolution of the bins in POSSM, and so an      #
    #   offset begins to appear in the spectra.                          #
    #                                                                    #
    #   So for now, I am going to use Option 1 to fix the problem, but   #
    #   it would be good to constrain Option 2, as it is an analytic     #
    #   solution.                                                        #
    #                                                                    #
    #====================================================================#


    #=====================================================================
    #   Option 1:
    #

    # chanVel = linspace(23.4564,-66.3990,2048,retstep=True)
    # chanVel    = linspace(23.4564,-66.3990,channels)
    #=====================================================================


    #=====================================================================
    #   Option 2:
    #
    bandStop    = bandStart + bandWidth
    # Frequencies exactly as in POSSM:
    chanFreqs   = linspace(bandStart,bandStop,channels)
    centreFreq  = chanFreqs[setjyChan]
    # Doppler approximation:
    velStep     = -sc.c * freqStep/centreFreq * metres2kilo
    # Create array of velocities based on Doppler computations:
    # for i in linspace(1,channels,channels):
    for i in xrange(channels):
        chanVel.append(suVel + velStep*int(i))
    #=====================================================================

    # 0 vs. 1 offsets in Python/AIPS arrays:
    chanOffsetCorrected = chanOffset-1

    for i in xrange(len(mfCha)):
        mfCurrentChan = mfCha[i]
        for j in xrange(len(chanVel)):
            if j == mfCurrentChan:
                fixedVels.append(chanVel[j+chanOffsetCorrected])
        # Print format to be consistent with AIPS MFPRT; optype = 'line':
        print "%9.3f%11.3f%12.3f%12.3f%11.3f%11.3f%11.3f%11.3f%11.3f%11.3f%11.3f"%(
            mfCha[i],
            mfPks[i],
            mfXoff[i],
            mfYoff[i],
            mfMajAx[i],
            mfMinAx[i],
            mfPosAng[i],
            mfDeconMaj[i],
            mfDeconMin[i],
            mfDeconPos[i],
            fixedVels[i])

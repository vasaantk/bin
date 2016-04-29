#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Tuesday, 19 April 2016, 14:35 PM.
# Run without arguments for instructions.

import re
from pylab import *
import sys
import numpy as np
from scipy import *
from scipy import constants as sc

usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "In the v255 experiments, we have to image the masers with modified FQ"
    print "tables. This results in incorrect velocities for each plane in the"
    print "IMAGE cube."
    print ""
    print "This script fixes the velocities for the output from AIPS MFPRT;"
    print "optype = 'line' and matches the frames with the velocities from"
    print "the autocorrelation spectra from POSSM."
    print ""
    print "Ensure that all floats are in decimal and not scientific format."
    print ""
    print "The 'offset' option is used if only a subset of the channels are"
    print "CLEANed. E.g. if bchan/echan in IMAGR is 500/1000, then offset=500."
    print ""
    print "--> vel-fix.py userfile.possm userfile.MF [offset=0]"
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
#=====================================================================



#=====================================================================
#   Check user inputs:
#
if len(usrFile) >= 2:
    possm  = usrFile[0]
    mfFile = usrFile[1]

    for i in usrFile:
        usrOffset = re.search('offset=(\d+)',i)
        if usrOffset:
            chanOffset = int(usrOffset.group(1))
        else:
            chanOffset = 0
else:
    print "Check your input files."
    startScript = False
#=====================================================================



#=====================================================================
#   Harvest values:
#
if startScript:
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
            # If data exists, grab the channel:
            currentChanMF = int(float(reqInfo.group(1)))
            for line in open(possm,'r'):
                reqPossInfo = re.search(  spaDigs        # (1) Channel
                                        + spaDigs        # (2) IF
                                        + '\s+\S+\s+'    #     Stokes
                                        + spaFlot        # (3) Freq
                                        + spaFlot        # (4) Vel
                                        + spaFlot        # (5) Real(Jy)
                                        + spaFlot,       # (6) Imag(Jy)
                                          line)
                if reqPossInfo:
                    currentChanPoss = int(float(reqPossInfo.group(1)))
                    # Compare the POSSM and MF channels. Need to offset by the "First plane in the image cube":
                    if currentChanPoss == currentChanMF+chanOffset:
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
                            float(reqPossInfo.group(4)))
            close(possm)
    close(mfFile)
#=====================================================================

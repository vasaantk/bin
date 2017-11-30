#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 27 September 2017.
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
    print "# This script served the exact function as its predecessor vel-fix.py."
    print "# The frames from POSSM are matched with the channels from ISPEC when"
    print "# executing step 18) of METH_MASER_PROCEDURE.HELP."
    exit()
else:
    mfFile = usrFile[0]
    startScript = True



#=====================================================================
#   Check user inputs:
#
if len(usrFile) >= 2:
    possm  = usrFile[0]
    mfFile = usrFile[1]

    for i in usrFile:
        usrOffset = re.search('offset=([+-]?\d+)',i)
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
        reqInfo = re.search('\s+(\d+)\s+([+-]?\d+.\d+[eE][+-]?\d\d)\s+([+-]?\d+.\d+[eE][+-]?\d\d)',line)
        # reqInfo = re.search('\s+(\d+)\s+([+-]?\d+.\d+[eE][+-]?\d\d)\s+([+-]?\d+.\d+[eE][+-]?\d\d)\s+([+-]?\d+.\d+[eE][+-]?\d\d)',line)
        if not reqInfo:
            print line,
        else:
            # If data exists, grab the channel:
            currentChanMF = int(float(reqInfo.group(1)))
            for line in open(possm,'r'):
                reqPossInfo = re.search('\s+(\d+)\s+\d+\s+\S+\s+\d+.\d+\s+([+-]?\d+.\d+)\s+\d+.\d+\s+\s+\d+.\d+\s+',line)
                if reqPossInfo:
                    currentChanPoss = int(float(reqPossInfo.group(1)))
                    # Compare the POSSM and MF channels. Need to offset by the "First plane in the image cube":
                    if currentChanPoss == currentChanMF+chanOffset:
                        print "%5d %17.8E %16.7E"%(
                            int(reqInfo.group(1)),
                            float(reqPossInfo.group(2))*1e3,   # Convert from km/s to m/s to work with linpol.sm
                            float(reqInfo.group(3)))
                        # print "%5d %17.8E %16.7E %16.7E"%(
                        #     int(reqInfo.group(1)),
                        #     float(reqPossInfo.group(2)),
                        #     float(reqInfo.group(3)),
                        #     float(reqInfo.group(4)))
            close(possm)
    close(mfFile)
#=====================================================================

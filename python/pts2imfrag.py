#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Tuesday, 12 December 2017

# pts2imfrag.py reads in user defined comps from stdin and converts
# them to a python dictonary format. Encapsulate the output in a
# "features = {}" variable to use in imagrFrag.py.

# Recommended usage is along the lines of:
# for i in {1,4,6,7,8,9,10} ; do grep -E "^\s+ $i " G024.78_EM117K.COMP.PTS | sort -nrk 5,5 | head -n 1 | pts2imfrag.py 1500 175 ; done

# The above unix command greps the entries from the .COMP.PTS on a
# comp-by-comp basis from the 'for' loop. These are sorted by the peak
# flux (column 5) and then we use 'head' to grab the channel with the
# greatest flux for that comp. In "pts2imfrag.py 1500 175", 1500 is
# the bchan relative to channel 1 of the .COMP.PTS. 175 is the number
# of channels to clean. Think of it as:
# "bchan = peak channel (from "head -n 1") + 1500 - 175"
# "echan = peak channel (from "head -n 1") + 1500 + 175"

import re
import sys
import string
from pylab import *

#=====================================================================
#   Define variables:
#
comp       = []
chan       = []
xoff       = []
yoff       = []

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans



#=====================================================================
#   Check the arguments
#
if len(sys.argv) <= 2:
    proceedFlag = False
    print "Provide 2 sets of channels."
else:
    strtChan = sys.argv[1]        # Channel in AIPS corresponding to channel 1 in .COMP.PTS
    numChans = sys.argv[2]        # Number of channels to clean per side of the peak (i.e. output will be 2*numChans)
    if numChans.isdigit() and strtChan.isdigit():
        strtChan    = int(strtChan)
        numChans    = int(numChans)
        proceedFlag = True
    else:
        print "Channals must be int."
        proceedFlag = False



if proceedFlag:
    #=====================================================================
    #   Harvest values from .COMP.PTS:
    #
    for line in sys.stdin:
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:
            comp.append(  int(reqInfo.group(1)))
            chan.append(  int(reqInfo.group(3)))
            xoff.append(float(reqInfo.group(8)))
            yoff.append(float(reqInfo.group(10)))

    for i in range(len(xoff)):
        bchan = (chan[i]-1) + strtChan - numChans    # chan[i]-1 to convert from .COMP.PTS frame to AIPS frame
        echan = (chan[i]-1) + strtChan + numChans

        bchanStr = '  (' + str(bchan) + ' < ' + str(chan[i]) + ' + ' + str(strtChan) + ' - ' + str(numChans) + ')'
        echanStr = '  (' + str(echan) + ' < ' + str(chan[i]) + ' + ' + str(strtChan) + ' + ' + str(numChans) + ')'

        if bchan < 0 or echan < 0:
            print "Something is wrong with your channel selection for comp %d."%(comp[i])
            print ""
            doPrint = False
        else:
            doPrint = True

        if doPrint:
            print "'%d' : [%11.6f,%20s"%(comp[i],xoff[i],'# imagr.rashift')
            print "%18.6f, %20s"%(               yoff[i],'# imagr.decshift')
            print "%18d,   %43s"%(               bchan,  '# imagr.bchan '+ bchanStr)
            print "%18d],  %43s"%(               echan,  '# imagr.echan '+ echanStr)
            print ""

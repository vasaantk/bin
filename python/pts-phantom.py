#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Friday, 28 April 2017.

# pts-phantom.py determines the mean of the velocity, xoff, yoff, xerr
# and yerr from standard input from the "print" option** output of
# pts-multi.py. This is used to create a "phantom" feature with a
# barycentre independent of any arbitrarily assigned feature,
# consisting of an average of the above values. The output can be
# placed at in the respective .COMP.PTS file under a user defined
# "phantom" feature.

#** Note use -->$ pts-multi.py FILE.COMP.PTS print | grep -E ' 1 | 3 | n | k '
#   to select features 1, 3, n and k to pass into pts-phantom.py.

import re
import sys
import numpy as np

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats =  6*floats            # space+floats seq gets repeated this many times after chans
filler     = -1000.0              # Filler found in .COMP.PTS files but not in by pts-multi.py output
fillDec    =  1.0                 # Filler found in .COMP.PTS files but not in by pts-multi.py output

chan = []
vels = []
flux = []
peak = []
xoff = []
xerr = []
yoff = []
yerr = []
comp = []

for line in sys.stdin:
    #=====================================================================
    #   Harvest values:
    #
    reqInfo = re.search(ints + floats + ints + manyFloats, line)
    if reqInfo:
        comp.append(  int(reqInfo.group(1)))
        vels.append(float(reqInfo.group(2)))
        chan.append(  int(reqInfo.group(3)))
        flux.append(float(reqInfo.group(4)))
        peak.append(float(reqInfo.group(5)))
        xoff.append(float(reqInfo.group(6)))
        xerr.append(float(reqInfo.group(7)))
        yoff.append(float(reqInfo.group(8)))
        yerr.append(float(reqInfo.group(9)))

comp = np.mean(comp)
vels = np.mean(vels)
chan = chan[0]
flux = flux[0]
peak = peak[0]
xoff = np.mean(xoff)
xerr = np.mean(xerr)
yoff = np.mean(yoff)
yerr = np.mean(yerr)

print '%6d %10.3f %4d %13.5f %13.5f %8.1f %9.3f %14.6f %10.7f %14.6f %10.7f %9.2f %7.2f %7.2f %10.2f %7.2f %7.2f'%(
       int(comp),float(vels),int(chan),float(flux),float(peak),
     float(filler),float(fillDec),float(xoff),float(xerr),float(yoff),
     float(yerr),float(fillDec),float(fillDec),float(fillDec),float(fillDec),float(fillDec),float(fillDec))
print ""

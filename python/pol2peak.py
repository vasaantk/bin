#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Friday, 22 September 2017, 15:46 PM

# pipe2peak.py reads in entries from .COMP.PTS files line-by-line from
# stdin. It then prints out the channel, xpixel, ypixel, velocity,
# peak and integrated flux densities. The output format is consistent
# with "output_peaktable.dat" from METH_MASER_PROCEDURE.HELP.

# Note you must have a "polvars.inp" file in the pwd with the
# following:

# imsize   = 8192               # Image size during CLEAN      (int)
# cellsize = 0.0001             # Cellsize used during CLEAN   (float)

# Recommended usage is along the lines of:
# for i in {1,4,6,7,8,9,10,11,12,14,15} ; do grep " $i " G024.78_EM117K.COMP.PTS | sort -nrk 4,4 | head -n 1 | pipe2peak.py ; done | sort >> output_peaktable.dat

# The above unix command greps the entries from the .COMP.PTS on a
# comp-by-comp basis. These are sorted by the peak flux (column 4) and
# then we use head to grab the channel with the greatest flux for that
# comp. pipe2peak.py does the conversion before the converted values
# for comps {1,4,6,7,8,9,10,11,12,14,15} are sorted according to
# channel.

import re
import sys
import string
from pylab import *

#=====================================================================
#   Define variables:
#
chan = []      # chan
vels = []      # velo
flux = []      # flux
peak = []      # peak
xoff = []      # xoff
yoff = []      # yoff

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans

imFlag   = False    # imsize
cellFlag = False    # cellsize
polvars  = []       # Array to store the harvested values




#=====================================================================
#   Grab user variables from polvars.inp
#
for line in open('polvars.inp','r'):
    imsize   = re.search(  'imsize\s*=\s*(\S*)\s*',line)
    cellsize = re.search('cellsize\s*=\s*(\S*)\s*',line)
    if imsize:
        imsize = imsize.group(1)
        if re.search('^\d+$',imsize) or re.search('^\d+.\d+$',imsize):    # Check harvested imsize format
            imsize = int(float(imsize))
            polvars.append(imsize)
            imFlag = True
    if cellsize:
        cellsize = cellsize.group(1)
        if re.search('^\d+.\d+$',cellsize):    # Check harvested cellsize format
            cellsize = float(cellsize)
            polvars.append(cellsize)
            cellFlag = True
close('polvars.inp')

if imFlag == cellFlag == True:
    proceedFlag = True
    imsize   = polvars[0]
    cellsize = polvars[1]
else:
    proceedFlag = False

if not imFlag:
    print "\n Check imsize in polvars.inp\n"
if not cellFlag:
    print "\n Check cellsize in polvars.inp\n"


if proceedFlag:
    #=====================================================================
    #   Harvest values from .COMP.PTS:
    #
    for line in sys.stdin:
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:
            vels.append(float(reqInfo.group(2)))
            chan.append(  int(reqInfo.group(3)))
            flux.append(float(reqInfo.group(4)))   # Integrated intensity
            peak.append(float(reqInfo.group(5)))   # Peak intensity
            xoff.append(float(reqInfo.group(8)))
            yoff.append(float(reqInfo.group(10)))


    # Compute the pixel offsets from x/y offsets:
    xpix = xoff
    ypix = yoff
    cenx = int(imsize/2)
    ceny = int(imsize/2 + 1)
    xpix = [cenx - i/cellsize for i in xpix]
    ypix = [ceny + i/cellsize for i in ypix]


    for i in range(len(xoff)):
        print "%10d %13.5f %15.5f %15.6f %15.8f %15.9f"%(chan[i],xpix[i],ypix[i],vels[i],peak[i],flux[i])

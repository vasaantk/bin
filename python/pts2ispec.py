#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 06 December 2017

# pts2ispec.py reads in entries from .COMP.PTS files line-by-line from
# stdin. It computes the pixel position of the centroid for each maser
# spot and creates a 3x3 box around that centroid, in units of
# pixels. The calculated pixel centroid is within errors of the
# measured values from JMFIT. The script error scales inversely with
# flux: complete agreement with strong >~few Jy emission to ~1 pix
# with <1 Jy emission. This script mimics the role of
# "spectra_extractor.e" in METH_MASER_PROCEDURE.HELP.

# Note you must have a "polvars.inp" file in the pwd with the
# following:

# cenx     = 256.14             # Pixel corresponding to RA  from IMHEAD in AIPS    (float)
# ceny     = 256.81             # Pixel corresponding to Dec from IMHEAD in AIPS    (float)
# cellsize = 0.0001             # Cellsize used during CLEAN   (float)

# Recommended usage is along the lines of:
# for i in {1,4,6,7,8,9,10} ; do grep -E "^\s+ $i " G024.78_EM117K.COMP.PTS | sort -nrk 4,4 | head -n 1 | pts2ispec.py ; done

# The above unix command greps the entries from the .COMP.PTS file on
# a comp-by-comp basis using the 'for' loop. The comps are sorted by
# the peak flux (column 4) and then we use 'head -n 1' to grab the
# channel with the highest flux for that comp. pts2ispec.py does the
# conversion before the ispec parameters to be used in a runfil are
# output.

# If you have created sub-cubes for each feature (like several imsize
# 512x512) instead of one large cube (imsize 8192x8192), you will
# require different (cenx, ceny) for each individual feature in
# polvars.inp. You can accomplish this by creating:

# polvars_1.inp
# polvars_4.inp
#      ...
#      ...
#      ...
# polvars_10.inp

# in a directory (e.g. "polvars") and implement the relavent
# polvars.inp using the following:

# for i in {1,4,6,7,8,9,10} ; do cp polvars/polvars_$i.inp polvars.inp ; grep -E "^\s+ $i " G024.78_EM117K.COMP.PTS | sort -nrk 4,4 | head -n 1 | pts2ispec.py ; rm polvars.inp ; done

import re
import sys
from pylab import *

#=====================================================================
#   Define variables:
#
name = []      # comp name
chan = []      # chan
vels = []      # velo
flux = []      # flux
peak = []      # peak
xoff = []      # xoff
yoff = []      # yoff

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans

cenxFlag = False    # central x pixel
cenyFlag = False    # central y pixel
cellFlag = False    # cellsize
polvars  = []       # Array to store the harvested values




#=====================================================================
#   Grab user variables from polvars.inp
#
for line in open('polvars.inp','r'):
    cenx     = re.search(    'cenx\s*=\s*(\S*)\s*',line)
    ceny     = re.search(    'ceny\s*=\s*(\S*)\s*',line)
    cellsize = re.search('cellsize\s*=\s*(\S*)\s*',line)
    if cenx:
        cenx = cenx.group(1)
        if re.search('^[+-]?\d+.\d+$',cenx):   # Check harvested cenx format
            cenx = float(cenx)
            polvars.append(cenx)
            cenxFlag = True
    if ceny:
        ceny = ceny.group(1)
        if re.search('^[+-]?\d+.\d+$',ceny):   # Check harvested ceny format
            ceny = float(ceny)
            polvars.append(ceny)
            cenyFlag = True
    if cellsize:
        cellsize = cellsize.group(1)
        if re.search('^\d+.\d+$',cellsize):    # Check harvested cellsize format
            cellsize = float(cellsize)
            polvars.append(cellsize)
            cellFlag = True
close('polvars.inp')

if cenxFlag == cenyFlag == cellFlag == True:
    cenx     = polvars[0]
    ceny     = polvars[1]
    cellsize = polvars[2]
    proceedFlag = True
else:
    proceedFlag = False

if not cenx:
    print "\n Check cenx in polvars.inp\n"
if not ceny:
    print "\n Check ceny in polvars.inp\n"
if not cellFlag:
    print "\n Check cellsize in polvars.inp\n"





#=====================================================================
#   Harvest values from .COMP.PTS:
#
if proceedFlag:
    for line in sys.stdin:
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:
            name.append(  int(reqInfo.group(1)))
            xoff.append(float(reqInfo.group(8)))
            yoff.append(float(reqInfo.group(10)))

    # Compute the pixel offsets from x/y offsets and create a 3x3 box:
    xpix = xoff
    ypix = yoff

    xblc = [(cenx - i/cellsize) - 1 for i in xpix]    # x-1
    yblc = [(ceny + i/cellsize) - 1 for i in ypix]    # y-1

    xtrc = [(cenx - i/cellsize) + 1 for i in xpix]    # x+1
    ytrc = [(ceny + i/cellsize) + 1 for i in ypix]    # y+1

    for i in range(len(xoff)):
        print "inname '%d' ; inseq %5d ; indisk %5d"%(name[i],1,1)   # Mapname, sequence, disk
        print "blc %8.2f %8.2f    0"%(xblc[i],yblc[i])
        print "trc %8.2f %8.2f    0"%(xtrc[i],ytrc[i])
        print "doprint = -3"                                         # Suppresses page headers and most other header information
        print "dotv    = -1"                                         # No tv
        print "inclass  'ICL001'"                                    # Stokes I
        print "outprint 'PWD:%s_I.DATA"%( str(name[i]))
        print "go ; wait"
        print "inclass  'POLI'"                                      # POLI
        print "outprint 'PWD:%s_POLI.DATA"%(str(name[i]))
        print "go ; wait"
        print "inclass  'POLA'"                                      # POLA
        print "outprint 'PWD:%s_POLA.DATA"%(str(name[i]))
        print "go ; wait"
        print "inclass  'VCL001'"                                    # Stokes V
        print "outprint 'PWD:%s_V.DATA"%( str(name[i]))
        print "go ispec ; wait"
    print ""

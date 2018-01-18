#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 06 December 2017

# pts2ispec.py reads in entries from .COMP.PTS files line-by-line from
# stdin. It computes the pixel position of the centroid for each maser
# spot and creates a box around that centroid. The calculated pixel
# centroid is within errors of the measured values from JMFIT (see the
# table at the very end). This script mimics the role of
# "spectra_extractor.e" in METH_MASER_PROCEDURE.HELP.

# Note you must have a "polvars.inp" file in the pwd with the
# following:

# cenx     = 256.14             # Pixel corresponding to RA  from IMHEAD in AIPS    (float)
# ceny     = 256.81             # Pixel corresponding to Dec from IMHEAD in AIPS    (float)
# cellsize = 0.0001             # Cellsize used during CLEAN   (float)

# Recommended usage is along the lines of:
# for i in {1,4,6,7,8,9,10} ; do grep -E "^\s+ $i " G024.78_EM117K.COMP.PTS | sort -nrk 5,5 | head -n 1 | pts2ispec.py ; done

# The above unix command greps the entries from the .COMP.PTS file on
# a comp-by-comp basis from the 'for' loop. The comps are sorted by
# the peak flux (column 5) and then we use 'head -n 1' to grab the
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

# and implement the relavent polvars.inp using the following:

# for i in {1,4,6,7,8,9,10} ; do cp polvars_$i.inp polvars.inp ; grep -E "^\s+ $i " G024.78_EM117K.COMP.PTS | sort -nrk 5,5 | head -n 1 | pts2ispec.py ; rm polvars.inp ; done

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

    # Compute the pixel offsets from x/y offsets and create a box:
    xpix = xoff
    ypix = yoff

    xblc = [(cenx - i/cellsize) - 1 for i in xpix]    # x-1
    yblc = [(ceny + i/cellsize) - 1 for i in ypix]    # y-1

    xtrc = [(cenx - i/cellsize) + 1 for i in xpix]    # x+1
    ytrc = [(ceny + i/cellsize) + 1 for i in ypix]    # y+1

    # Note: The above algorithim which I have used to create the box
    # is the standard to create a 3x3 box around the pixel
    # centroid. In the context of pts2ispec.py, Gabriele says of
    # creating such a box in his EXPLAIN_05.txt that:

    # "... is not important and actually does not reflect the real area
    #  of the box :)"

    for i in range(len(xoff)):
        print "inname '%d' ; inseq %5d ; indisk %5d"%(name[i],1,1)   # Mapname, sequence, disk
        print "blc %8.2f %8.2f    0"%(xblc[i],yblc[i])
        print "trc %8.2f %8.2f    0"%(xtrc[i],ytrc[i])
        print "doprint = -3"                                         # Suppresses page headers and most other header information
        print "dotv    = -1"                                         # No tv
        print "inclass  'ICL001'"                                    # Stokes I
        print "outprint 'PWD:CMP%s_I.DATA"%( str(name[i]))
        print "go ; wait"
        print "inclass  'POLI'"                                      # POLI
        print "outprint 'PWD:CMP%s_POLI.DATA"%(str(name[i]))
        print "go ; wait"
        print "inclass  'POLA'"                                      # POLA
        print "outprint 'PWD:CMP%s_POLA.DATA"%(str(name[i]))
        print "go ; wait"
        print "inclass  'VCL001'"                                    # Stokes V
        print "outprint 'PWD:CMP%s_V.DATA"%( str(name[i]))
        print "go ispec ; wait"
    print ""






#=====================================================================
#   pts2ispec vs. JMFIT
#

# "AIPS CH" is the peak channel from executing IMEAN on the cube
# "PTS CH"  is the peak channel from column 4 of .COMP.PTS
# "JM err (pix)" column gives the error in the centroid measurement from JMFIT

# | CMP |            | pts2ispec | PTS CH |   JMFIT | AIPS CH | pts2ispec-JMFIT (pix) | JM err (pix) |
# |-----+------------+-----------+--------+---------+---------+-----------------------+--------------|
# | 401 | X-position |    255.99 |    167 | 255.989 |     165 |                  1e-3 |       0.0121 |
# |     | Y-position |    257.33 |        | 257.315 |         |                  0.02 |       0.0148 |
# |     |            |           |        |         |         |                       |              |
# | 404 | X-position |    256.03 |    180 | 256.027 |     180 |                  3e-3 |       0.0217 |
# |     | Y-position |    256.98 |        | 256.984 |         |                 -4e-3 |       0.0264 |
# |     |            |           |        |         |         |                       |              |
# | 406 | X-position |    256.89 |    171 | 256.886 |     171 |                  4e-3 |       0.0873 |
# |     | Y-position |    257.54 |        | 257.540 |         |                  0.00 |       0.0922 |
# |     |            |           |        |         |         |                       |              |
# | 407 | X-position |    255.45 |    166 | 256.737 |     172 |                 -1.29 |       0.0881 |
# |     | Y-position |    256.94 |        | 257.679 |         |                 -0.74 |       0.0921 |
# |     |            |           |        |         |         |                       |              |
# | 408 | X-position |    255.74 |    178 | 255.757 |     178 |                 -0.02 |       0.0407 |
# |     | Y-position |    256.97 |        | 256.967 |         |                  3e-3 |       0.0424 |
# |     |            |           |        |         |         |                       |              |
# | 409 | X-position |    255.99 |    177 | 255.987 |     177 |                  3e-3 |       0.0378 |
# |     | Y-position |    256.99 |        | 256.983 |         |                  7e-3 |       0.0468 |
# |     |            |           |        |         |         |                       |              |
# | 410 | X-position |    255.96 |    168 | 255.958 |     168 |                  2e-3 |       0.0742 |
# |     | Y-position |    256.96 |        | 256.964 |         |                 -4e-3 |       0.0901 |
# #+TBLFM: $7=$3-$5;f2

# See Friday, 12 January 2018, 09:34 AM in "00_Notes_em117k.txt" for
# full details.

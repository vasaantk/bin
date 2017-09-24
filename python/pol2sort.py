#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Saturday, 23 September 2017.

# pol2sort.py converts the maser spot information contained in
# .COMP.PTS files to the table_final.txt format used for polarisation
# calibration from step 17) of 'METH_MASER_PROCEDURE.HELP'.
#
# Note you must have a "polvars.inp" file in the pwd with the
# following:

# ra       = 18:36:12.556       # RA  from IMHEAD in AIPS      (hh:mm:ss.s...)
# dec      = -07:12:10.800      # Dec from IMHEAD in AIPS      (dd:mm:ss.s...)
# imsize   = 8192               # Image size during CLEAN      (int)
# cellsize = 0.0001             # Cellsize used during CLEAN   (float)

# Execute by:
# -->$ cat user_file.COMP.PTS | pol2sort.py

import re
import sys
import string
from pylab import *
import ephem as ep
from itertools import groupby

#=====================================================================
#   Define variables:
#
chan = []      # chan
vels = []      # velo
flux = []      # flux
peak = []      # peak
prms = []      # peak rms
xoff = []      # xoff
xerr = []      # xerr
yoff = []      # yoff
yerr = []      # yerr
comp = []      # component
bmaj = []      # beam major axis
bmin = []      # beam minor axis

ints       = '\s+(\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
manyFloats = 14*floats            # space+floats seq gets repeated this many times after chans

raFlag   = False    # RA harvested from polvars.inp
decFlag  = False    # declination
imFlag   = False    # imsize
cellFlag = False    # cellsize
polvars  = []       # Array to store the harvested values




#=====================================================================
#   Define variables:
#
for line in open('polvars.inp','r'):
    ra       = re.search(      'ra\s*=\s*(\S*)\s*#',line)
    dec      = re.search(     'dec\s*=\s*(\S*)\s*#',line)
    imsize   = re.search(  'imsize\s*=\s*(\S*)\s*#',line)
    cellsize = re.search('cellsize\s*=\s*(\S*)\s*#',line)
    if ra:
        ra = str(ra.group(1))
        if re.search('^\d\d:\d\d:\d\d.\d+$',ra):    # Check harvested RA format
            polvars.append(ra)                      # Append RA so it is not "forgotten"
            raFlag = True
    if dec:
        dec = str(dec.group(1))
        if re.search('^[+-]?\d\d:\d\d:\d\d.\d+$',dec):    # Check harvested dec format
            polvars.append(dec)
            decFlag  = True
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

if raFlag == decFlag == imFlag == cellFlag == True:
    proceedFlag = True
    ra       = polvars[0]
    dec      = polvars[1]
    imsize   = polvars[2]
    cellsize = polvars[3]
else:
    proceedFlag = False

if not raFlag:
    print "\n Check ra in polvars.inp\n"
if not decFlag:
    print "\n Check dec in polvars.inp\n"
if not imFlag:
    print "\n Check imsize in polvars.inp\n"
if not cellFlag:
    print "\n Check cellsize in polvars.inp\n"





#=====================================================================
#   Definations:
#

# Adopted from "deg2dec Written by Enno Middelberg 2001"
def deg2dec(deg):
    deg  = float(deg)
    sign = "+"
    if deg < 0:
        sign = "-"
        deg  = deg*(-1)
    if deg > 180:
        print 'deg'+": inputs may not exceed 180!\n"
    if deg > 90:
        print 'deg'+" exceeds 90, will convert it to negative dec\n"
        deg  = deg-90
        sign = "-"
    hh = int(deg)
    mm = int((deg-int(deg))*60)
    ss = ((deg-int(deg))*60-mm)*60
    # return sign+string.zfill('hh',2)+':'+string.zfill('mm',2)+':'+'%8.5f' % ss
    return string.zfill(mm,2)+'  '+'%8.6f' % ss

# Adopted from "deg2ra Written by Enno Middelberg 2001"
def deg2ra(deg):
    deg  = float(deg)
    if deg < 0:
        deg=deg+360
    if deg > 360:
        print 'deg'+": inputs may not exceed 360!\n"
    hh = int(deg/15)
    mm = int((deg-15*hh)*4)
    ss = (4*deg-60*hh-mm)*60
    # return string.zfill('hh',2)+':'+string.zfill('mm',2)+':'+'%8.7f' % ss
    return string.zfill(mm,2)+' '+'%8.7f' % ss

# Adopted from "ra2deg Written by Enno Middelberg 2001"
def ra2deg(inp):
    ra = re.split(':| ',inp)
    hh =  float(ra[0])*15
    mm = (float(ra[1])/60)*15
    ss = (float(ra[2])/3600)*15
    return hh+mm+ss

# Adopted from "dec2deg Written by Enno Middelberg 2001"
def dec2deg(inp):
    dec = re.split(':| ',inp)
    hh  = abs(float(dec[0]))
    mm  =     float(dec[1])/60
    ss  =     float(dec[2])/3600
    if float(dec[0]) < 0:
        return (hh+mm+ss) * -1
    else:
        return  hh+mm+ss




if proceedFlag:
    #=====================================================================
    #   Harvest values from .COMP.PTS:
    #
    for line in sys.stdin:
        reqInfo = re.search(ints + floats + ints + manyFloats, line)
        if reqInfo:
            comp.append(  int(reqInfo.group(1)))
            vels.append(float(reqInfo.group(2)))
            chan.append(  int(reqInfo.group(3)))
            flux.append(float(reqInfo.group(4)))   # Integrated intensity
            peak.append(float(reqInfo.group(5)))   # Peak intensity
            prms.append(float(reqInfo.group(7)))   # Peak rms
            xoff.append(float(reqInfo.group(8)))
            xerr.append(float(reqInfo.group(9)))
            yoff.append(float(reqInfo.group(10)))
            yerr.append(float(reqInfo.group(11)))
            bmaj.append(float(reqInfo.group(12)))  # Beam major axis
            bmin.append(float(reqInfo.group(13)))  # Beam minor axis


    # Sort all elements according to increasing "chan" order:
    vels = [x for (y,x) in sorted(zip(chan,vels),key=lambda pair: pair[0])]
    xoff = [x for (y,x) in sorted(zip(chan,xoff),key=lambda pair: pair[0])]
    xerr = [x for (y,x) in sorted(zip(chan,xerr),key=lambda pair: pair[0])]
    yoff = [x for (y,x) in sorted(zip(chan,yoff),key=lambda pair: pair[0])]
    yerr = [x for (y,x) in sorted(zip(chan,yerr),key=lambda pair: pair[0])]
    comp = [x for (y,x) in sorted(zip(chan,comp),key=lambda pair: pair[0])]
    flux = [x for (y,x) in sorted(zip(chan,flux),key=lambda pair: pair[0])]
    peak = [x for (y,x) in sorted(zip(chan,peak),key=lambda pair: pair[0])]
    prms = [x for (y,x) in sorted(zip(chan,prms),key=lambda pair: pair[0])]
    bmaj = [x for (y,x) in sorted(zip(chan,bmaj),key=lambda pair: pair[0])]
    bmin = [x for (y,x) in sorted(zip(chan,bmin),key=lambda pair: pair[0])]
    chan = sorted(chan)

    # Obtain the Galactic name:
    ra    = re.sub(' ',':',ra)
    dec   = re.sub(' ',':',dec)
    coord = ep.Galactic(ep.Equatorial(ra,dec))
    name  = str(int(degrees(coord.lon)))
    name  = 'G'+string.zfill(name,3)

    # Compute the pixel offsets from x/y offsets:
    xpix = xoff
    ypix = yoff
    xxer = xerr
    yxer = yerr
    cenx = int(imsize/2)
    ceny = int(imsize/2 + 1)
    xpix = [cenx - i/cellsize for i in xpix]
    ypix = [ceny + i/cellsize for i in ypix]
    xxer = [i/cellsize for i in xxer]
    yxer = [i/cellsize for i in yxer]

    # Convert offsets hms:
    ra   =  ra2deg(ra)
    dec  = dec2deg(dec)
    xoff = [deg2ra( ra  + (i/cos(radians(dec)))/3600.0) for i in xoff]
    yoff = [deg2dec(dec +  i/3600.0)                    for i in yoff]


    chanGroups = [list(j) for i, j in groupby(chan)]      # Group "chans" which have more than one maser spot
    alphabet   = ['A','B','C','D','E','F','G','H','I','J','K','L','M',
                  'N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
    for chan in chanGroups:                               # For each group of "chan"
        if len(chan) > 1:                                 # if there is more than one maser spot
            for j in range(len(chan)):
                chan[j] = str(chan[j])+alphabet[j]        # append an alphabet to the channel name
        else:
            chan[0] = str(chan[0])
    chan = [i for item in chanGroups for i in item]       # Flatten out "chanGroups" into a 1D list


    # Header from table_final.txt:
    print " NAME,  CHAN                ALPHA,                       DELTA,               X-position,       Y-position,      Velocity,      Peak intensity,       Integrated intensity          Average Polarization            Average Pol.Angle    "
    print "                             (s)                          (sec)                  (pix)              (pix)          (km/s)          (JY/BEAM)                 (JANSKYS)                       (%)                        (degrees)        "
    print "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"


    for i in range(len(xoff)):
        emaj = bmaj[i]*prms[i]/peak[i]      # Compute err of beam major axis "Delta(W) = Delta(P) / P * W"
        emin = bmin[i]*prms[i]/peak[i]      # from http://aips.nrao.edu/cgi-bin/ZXHLP2.PL?SAD

        # Integrated flux = 2*pi*sigma_x*sigma_y*peak (Condon 1997)
        # So we use the following error propagation algorithm:
        fpk  = (prms[i]/peak[i])**2
        fmaj = (   emaj/bmaj[i])**2
        fmin = (   emin/bmin[i])**2
        eflx = flux[i]*sqrt(fpk+fmaj+fmin)    # Why no 2*pi?!... Perhaps beacuse AIPS uses a variaion of the Condon equation?

        #                  Alpha          Delta         X-position      Y-position    Vel        Peak           Integrated
        print "%6s   %-5s %13s +/- %9.7f %15s +/- %9.7f %8.3f +/- %5.4f %8.3f +/- %5.4f %8.3f %11.4e +/- %10.4e %11.4e +/- %10.4e\n"%(
            name,chan[i],xoff[i],xerr[i],yoff[i],yerr[i],xpix[i],xxer[i],ypix[i],yxer[i],vels[i],peak[i],prms[i],flux[i],eflx)
    print "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    print "The errors of the angles are in the file pol_ang.out"

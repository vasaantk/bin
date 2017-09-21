#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Tuesday, 19 September 2017.
# Run without arguments for instructions.

import re
import sys
import string
from pylab import *
import ephem as ep




# User defined variables:
ra       = '18:36:12.556'     # RA and Dec from 'imh' in AIPS
dec      = '-07:12:10.800'
imsize   = 8192               # Image size during CLEAN
cellsize = 0.0001             # Cellsize used during CLEAN




usrFile = sys.argv[1:]
if len(usrFile) == 0:
    print ""
    print "# pts2pol.py converts the maser spot information contained in"
    print "# .COMP.PTS files to the table_out.txt format used for polarisation"
    print "# calibration from step 15) of 'METH_MASER_PROCEDURE.HELP'."
    print ""
    print "# User defined variables:"
    print ""
    print "  Right ascension:   %10s"%(ra)
    print "      Declination:   %10s"%(dec)
    print "           Imsize:   %d"%(imsize)
    print "         Cellsize:   %f"%(cellsize)
    print ""
    print "  --> pts2pol.py file_name.COMP.PTS"
    print ""
    exit()




# Determine the .COMP.PTS from the user input
for i in usrFile:
    ptsFind = re.search('\S+.COMP.PTS',i)
    if ptsFind:
        ptsFile = i




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
    return string.zfill('mm',2)+'  '+'%8.6f' % ss

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
    return string.zfill('mm',2)+' '+'%8.7f' % ss

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






#=====================================================================
#   Harvest values from .COMP.PTS:
#
for line in open(ptsFile,'r'):
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
close(ptsFile)

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


# Header from table_out.txt:
print " NAME,  CHAN  ALPHA,     DELTA,     X-position, Y-position, Velocity,  Peak intensity, Integrated intensity"
print "                (s)        (sec)      (pix)         (pix)     (km/s)     (JY/BEAM)           (JANSKYS)"
print "---------------------------------------------------------------------------------------------"


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
    print "%6s %5d %15s +/- %9.7f %15s +/- %9.7f %8.3f +/- %5.4f %8.3f +/- %5.4f %8.3f %11.4e +/- %10.4e %11.4e +/- %10.4e"%(
        name,chan[i],xoff[i],xerr[i],yoff[i],yerr[i],xpix[i],xxer[i],ypix[i],yxer[i],vels[i],peak[i],prms[i],flux[i],eflx)

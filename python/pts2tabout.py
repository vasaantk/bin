#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Tuesday, 19 September 2017.

# pts2tabout.py replicates pts2pol.py. The distinction is that the
# former accepts inputs from stdin.

# pts2pol.py converts the maser spot information contained in
# .COMP.PTS files to the table_out.txt format used for polarisation
# calibration from step 15) of 'METH_MASER_PROCEDURE.HELP'. The
# calculated pixel centroid is within errors of the measured values
# from JMFIT. The script error scales inversely with flux: complete
# agreement with strong >~few Jy emission to ~1 pix with <1 Jy
# emission.

# Note you must have a "polvars.inp" file in the pwd with the
# following:

# ra       = 18:36:12.556       # RA  from IMHEAD in AIPS      (hh:mm:ss.s...)
# dec      = -07:12:10.800      # Dec from IMHEAD in AIPS      (dd:mm:ss.s...)
# cenx     = 256.14             # Pixel corresponding to RA  from IMHEAD in AIPS    (float)
# ceny     = 256.81             # Pixel corresponding to Dec from IMHEAD in AIPS    (float)
# cellsize = 0.0001             # Cellsize used during CLEAN   (float)

# Recommended usage is along the lines of:
# for i in {1,4,6,7,8,9,10} ; do grep " $i " G024.78_EM117K.COMP.PTS | pts2tabout.py >> table_out_$i.txt ; done

# The above unix command greps the entries from the .COMP.PTS on a
# comp-by-comp basis. pts2tabout.py does the conversion before the
# converted values for comps {1,4,6,7,8,9,10} are written to their
# individual files.

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

# for i in {1,4,6,7,8,9,10} ; do cp polvars_$i.inp polvars.inp ; grep " $i " G024.78_EM117K.COMP.PTS | pts2tabout.py >> table_out_$i.txt ; rm polvars.inp ; done


import re
import sys
import string
from pylab import *
import ephem as ep

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
cenxFlag = False    # central x pixel
cenyFlag = False    # central y pixel
cellFlag = False    # cellsize
polvars  = []       # Array to store the harvested values




#=====================================================================
#   Grab user variables from polvars.inp
#
for line in open('polvars.inp','r'):
    ra       = re.search(      'ra\s*=\s*(\S*)\s*',line)
    dec      = re.search(     'dec\s*=\s*(\S*)\s*',line)
    cenx     = re.search(    'cenx\s*=\s*(\S*)\s*',line)
    ceny     = re.search(    'ceny\s*=\s*(\S*)\s*',line)
    cellsize = re.search('cellsize\s*=\s*(\S*)\s*',line)
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

if raFlag == decFlag == cenxFlag == cenyFlag == cellFlag == True:
    ra       = polvars[0]
    dec      = polvars[1]
    cenx     = polvars[2]
    ceny     = polvars[3]
    cellsize = polvars[4]
    proceedFlag = True
else:
    proceedFlag = False

if not raFlag:
    print "\n Check ra in polvars.inp\n"
if not decFlag:
    print "\n Check dec in polvars.inp\n"
if not cenx:
    print "\n Check cenx in polvars.inp\n"
if not ceny:
    print "\n Check ceny in polvars.inp\n"
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

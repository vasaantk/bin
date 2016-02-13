#!/usr/bin/env python

# Written by Vasaant S/O Krishnan in 2015. Run without arguments for instrunctions."

import ephem
from numpy import *
import sys
import string

inp=sys.argv[0:]
del inp[0]
if len(inp)==0:
    print" Script to determine the midpoint between two points"
    print" in the sky"
    print" Type 'midPt.py RA1 Dec1 RA2 Dec2'"
    print" All coordinates must be of the form:"
    print" hh:mm:ss(.ssssssss) or hh mm ss(.ssssssss)"
    print" (Don't mix!).\n"
    sys.exit()

##########################################################################
#
# This section from angsep.py
#
# Find and replace any ":" and "=" from inputs
newinp=[]
for x in inp:
    newinp.append(string.replace(x, ":", " "))

inp=newinp

# Find and delete alphanumeric entries like "RA" and "DEC"
newline=""
for x in inp:
    newline=newline+" "
    for y in x:
	newline=newline+y

inp=string.split(newline)

newinp=[]
for x in inp:
    try:
	newinp.append(float(x))
    except ValueError:
	pass

inp=newinp

if len(inp)==4:
    ra1 =string.split(inp[0], ":")
    dec1=string.split(inp[1], ":")
    ra2 =string.split(inp[2], ":")
    dec2=string.split(inp[3], ":")
elif len(inp)==12:
    ra1 =inp[0:3]
    dec1=inp[3:6]
    ra2 =inp[6:9]
    dec2=inp[9:12]
else:
    print" Too few or too many parameters."
    sys.exit()

RA_HH_1  = str(int(ra1[0]))
RA_MM_1  = str(int(ra1[1]))
RA_SS_1  = str(float(ra1[2]))

DEC_DD_1 = str(int(dec1[0]))
DEC_MM_1 = str(int(dec1[1]))
DEC_SS_1 = str(float(dec1[2]))

RA_HH_2  = str(int(ra2[0]))
RA_MM_2  = str(int(ra2[1]))
RA_SS_2  = str(float(ra2[2]))

DEC_DD_2 = str(int(dec2[0]))
DEC_MM_2 = str(int(dec2[1]))
DEC_SS_2 = str(float(dec2[2]))
#
##########################################################################

# This is now my own:
a = ephem.Equatorial(RA_HH_1+':'+RA_MM_1+':'+RA_SS_1,DEC_DD_1+':'+DEC_MM_1+':'+DEC_SS_1)
b = ephem.Equatorial(RA_HH_2+':'+RA_MM_2+':'+RA_SS_2,DEC_DD_2+':'+DEC_MM_2+':'+DEC_SS_2)

midRA  = b.ra  - (b.ra  - a.ra )/2.0
midDec = b.dec - (b.dec - a.dec)/2.0

print ephem.hours(midRA) , ephem.degrees(midDec)

#! /usr/bin/env python

from pylab import *
import re
import sys

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Variables begin here       %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
userFiles = sys.argv[1:]
timeArray   = []

if userFiles == []:
    print ""
    print "# geoTimeGrabber.py takes input from AIPS FRING 'box 1 3 4 9 13 15' option and plots out the geodetic block time segments"
    print "  from 2012MAR08_RATE_MDEL.DAT"
    print ""
    harvestValues = False
else:
    harvestValues = True
    fileName  = userFiles[0]


# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Recurrant regex            %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
spaceDigits = "\s+(-?\d+.\d+)"
spaceDigit  = "\s+(\d+)"
exponent    = "([+-]?\d\d)"


# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Algorithm begins here      %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
if harvestValues:
    with open(fileName) as file:
        for line in file:
            #                             ROW      TIME                       SOURCE ID      ANTENNA                MBDELAY1                          RATE 1          REFANT 1
            #                             1       9.590278D-01                     1             1                0.000E+00                        0.000E+00               1
            requiredInfo = re.search(spaceDigit + spaceDigits + "D" + exponent + spaceDigit + spaceDigit + spaceDigits + "E" + exponent + spaceDigits + "E" + exponent + spaceDigit, line)
            if requiredInfo:
                #print float(requiredInfo.group(2))*10**int(requiredInfo.group(3)) # TIME
                timeArray.append(float(requiredInfo.group(2))*10**int(requiredInfo.group(3)))

    y = timeArray
    x = xrange(0,len(y),1)

    scatter(y,x,marker='x')
    xlabel('Geoblock Time Range')
    ylabel('Count')
    show()

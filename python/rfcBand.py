#!/usr/bin/env python

# Written by Vasaant S/O Krishnan. Monday, 17 October 2016, 17:12 PM.

import re
from ephem import *
from numpy import *
import sys

userInp   = sys.argv[1:]

if len(userInp) == 0:
    print ""
    print "# rfcBand.py takes input from AstroGeo rfc_20*.txt files and selects"
    print "# sources of interest from a required band [s, c, x, u or k]. It"
    print "# also allows you to define the minimum astrometric error."
    print ""
    print "-->$ rfcBand.py band flux_threshold [err=dd.dd]"
    print ""
    exit()



#=====================================================================
#                   Define variables:
#
ints      = '\s+([+-]?\d+)'
floats    = '\s+([+-]?\d+.\d+)'

bandDict  = {'s':13,                   # Columns in rfc file according to the harvest algorithm below
             'c':15,
             'x':17,
             'u':19,
             'k':21}

userBand  =       userInp[1].lower()   # s, c, x, u or k band
userVal   = float(userInp[2])          # Minimum required flux unresolved flux density
fileCol   = int(bandDict[userBand])
firstLine = True                       # For printing the header during output
lastLine  = False                      # For printing the footer during output


for i in userInp:
    errRequest = re.search('err='+'(\d+.\d+)',i)
    if errRequest:
        requiredAstrometry = float(errRequest.group(1))
    else:
        requiredAstrometry = 0.25      # mas




#=====================================================================
#                   Main script starts here:
#
with open(userInp[0]) as file:
    for line in file:
        # Harvest begins here:
        requiredInfo = re.search( '\s+\S+\s'
                                 +'(J\d+[+-]?\d+\s+)' #  1    Source name
                                 + ints               #  2    HH
                                 + ints               #  3    MM
                                 + floats             #  4    SS.SSSSSS
                                 + ints               #  5    DD
                                 + ints               #  6    MM
                                 + floats             #  7    SS.SSSSS
                                 + 3*floats           #  8-10 Error in RA/Dec (mas) and correlation RA/Dec
                                 + ints               # 11    Number of observations
                                 + 10*floats          # 12-21 Band: S (13), C (15), X (17), U (19), K or X/S (21) flux
                                 +'\s+(\S+)\s+'       # 22    Band: S     , C     , X     , U     , K or X/S
                                 +'rfc_\S+'
                                 , line)
        if requiredInfo:
            sourName =             requiredInfo.group(1)
            fileFlux =       float(requiredInfo.group(fileCol))
            fileBand =         str(requiredInfo.group(22)).lower()
            err      =  sqrt(float(requiredInfo.group(8))**2 + float(requiredInfo.group(9))**2)

            if fileFlux >= userVal and fileBand == userBand and err <= requiredAstrometry:
                if firstLine:
                    print ""
                    print " Source Name    Mean positional error    Unresolved flux density    Band"
                    print ""
                    firstLine = False
                else:
                    print "  %s %22.2f %22.3f %12s"%(sourName,err,fileFlux,fileBand.upper())
                    lastLine = True
file.close()

if lastLine:
    print ""

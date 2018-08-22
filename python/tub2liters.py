#! /usr/bin/env python
# Vasaant S/O Krisnan on Thursday, 19 July 2018

import sys
import warnings
import numpy as np
from scipy.optimize import curve_fit

usrInp   = sys.argv[1:]

if len(usrInp) == 0:
    print ""
    print "# Convert the height (cm) of water in a ellipsoidal tub to litres"
    print "# using the trapezoidal rule."
    print ""
    print "--> ./tub2litres.py xx"
    print ""
    exit()



#======================================================================
#    Tub dimensions in cm
baseMajor = 46     # Major axis of base
baseMinor = 33     # Minor axis of base

rimMajor  = 62     # Major axis of rim
rimMinor  = 45     # Minor axis of rim

tubHeight = 28     # Perpendicular height



#======================================================================
#    Code begins here
waterLvl  = abs(float(usrInp[0]))    # Height of water

if waterLvl > tubHeight:
    raise ValueError("Water level exceeds height of tub.")

currLvl   = 0.0                # Initial water height
currVol   = 0.0                # Initial water volume
step      = 0.0001             # Step size for trapezoidal rule (cm)
cubeToLtr = 0.001
pi        = np.pi

bMi  = abs(float(baseMinor))   # Some precautions against jester users....
bMj  = abs(float(baseMajor))
rMi  = abs(float( rimMinor))
rMj  = abs(float( rimMajor))
hgt  = abs(float(tubHeight))

xMaj = [bMj/2.0, rMj/2.0]                # Major [base, rim] x coord
yMaj = [      0,     hgt]                # Major [base, rim] y coord

xMin = [bMi/2.0, rMi/2.0]                # Minor [base, rim] x coord
yMin = [      0,     hgt]                # Minor [base, rim] y coord

warnings.filterwarnings("ignore")        # Ignore optimizer covariance warnings
line   = lambda x, m, c: c + m*x         # Straight line to model slope of sides of tub
modMaj = curve_fit(line, xMaj, yMaj)     # Model the slope along the major axis side
modMin = curve_fit(line, xMin, yMin)     # Model the slope along the minor axis side

gradMaj, ceptMaj = modMaj[0]
gradMin, ceptMin = modMin[0]



#======================================================================
#    Trapezoidal rule
while currLvl < waterLvl:

    yTmpMaj  = currLvl                         # Current height of water level
    yTmpMin  = currLvl                         #

    xTmpMaj  = (yTmpMaj-ceptMaj)/gradMaj       # Determine the new x major axis
    xTmpMin  = (yTmpMin-ceptMin)/gradMin       # Determine the new x minor axis

    currVol += step * pi*xTmpMin*xTmpMaj       # Current cumulative volume in cubic cm
    currLvl += step                            # Increase the water height to the next level....

print "%.2f Litres"%(currVol*cubeToLtr)

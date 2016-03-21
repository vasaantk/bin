#! /usr/bin/env python

import re
from pylab import *
import sys
import numpy as np

usrInp = sys.argv[1:]

if len(usrInp) == 0:
    print ""
    print "# astronErr.py takes the astrometric accuracy (arcsec) as the first argument,"
    print "# the distance (parsec) to the source as the second argument and **estimates**"
    print "# the percentage accuracy of the measurement."
    print "# 's' option for short print."
    print ""
    print "--> ./astronErr.py astrometry distance [s]"
    print ""
elif len(usrInp) == 1:
    print ""
    print "Astrometric accuracy (arcsec) and distance (parsec) required."
    print ""
else:
    astrometry  = float(usrInp[0])
    distance    = float(usrInp[1])
    parallax    = 1.0/distance
    paralErr    = parallax + astrometry
    distWithErr = 1/paralErr
    distDiff    = distance - distWithErr
    percenErr   = distDiff/distance * 100

    if len(usrInp) > 2:
        if  usrInp[2] == 's':
            print "%.2f"%percenErr
    else:
        print "Error in distance = %.2f percent"%percenErr

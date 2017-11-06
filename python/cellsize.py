#! /usr/bin/env python

# Vasaant Krishnan Tuesday, 24 October 2017

import sys
import scipy

usrInp   = sys.argv[1:]
toArcsec = 3600.0

if len(usrInp) == 0:
    print ""
    print "# cellsize.py takes the baseline length (e.g. xx) of the array in units"
    print "# of wavelength and computes the cellsize range between 3 to 5 times"
    print "# smaller than the maximum uv distance to be used for cleaning."
    print ""
    print "--> ./cellsize.py  xx"
    print ""
    exit()

else:
    uvdist          = float(usrInp[0])
    synthesizedBeam = 1./uvdist
    beamInArcsec    = scipy.degrees(synthesizedBeam) * toArcsec

    # http://www.am.ub.edu/~robert/Documents/step-by-step-AIPScontinuum.pdf
    lowerLim        = beamInArcsec/5.0
    upperLim        = beamInArcsec/3.0

    if uvdist < 0:
        print "\n Negative? Sure.... \n"
    print "    %10.6f    %10.6f"%(lowerLim, upperLim)

#! /usr/bin/env python
# Vasaant Krishnan.
import sys

usrInp = sys.argv[1:]

if len(usrInp) != 2:
    print ""
    print "# parErr.py takes a parallax angle with uncertainty"
    print "# and converts it to the parallax distance."
    print ""
    print "\t --> parErr.py   parallax_angle   uncertainty"
    print ""
    sys.exit()

par    = float(usrInp[0])
err    = float(usrInp[1])

parallax = 1./par

parCeil  =  1./(par-err) - parallax
parFloor = -1./(par+err) + parallax

print "%.3f\t+%.3f\t-%.3f"%(parallax,parCeil,parFloor)

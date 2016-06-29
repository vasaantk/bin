#! /usr/bin/env python

import sys
from functions import *

usrInp = sys.argv[1:]

if len(usrInp) != 2:
    print ""
    print "# parErr.py takes a parallax angle with error"
    print "# and converts it to the parallax distance."
    print ""
    print "\t --> parErr.py parallax_angle error"
    print ""
    sys.exit()

par    = float(usrInp[0])
err    = float(usrInp[1])

parallax = 1/par

parCeil  = 1./(par-err) - parallax
parFloor = parallax - 1./(par+err)

print "Parallax   +       -"
print "  "+str(nsf(parallax))+"   "+str(nsf(parCeil))+"   "+str(nsf(parFloor))

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan on Friday, 01 December 2017

# xerr.py reads in table_final.txt and the output of Gabriele Surcis'
# err_pol_angle.sm (e.g. polagnerr.out) and produces an input table
# for "X_weight.sm".

# -->$ xerr.py polagnerr.out

import re
import sys
import numpy as np

usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print "Provide the output table from err_pol_angle.sm."
    exit()

ra      =        '\s+\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
dec     =   '\s+[+-]?\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
spaDigs =        '\s*([+-]?\d+\.\d+) \+/- (\d+\.\d+)\s*'              # "Space digits"
floats  = '\s*(\d+\.\d+[eE][+-]?\d+) \+/- (\d+\.\d+[eE][+-]?\d+)\s*'

tabFin  = "table_final.txt"

flux    = []   # Flux from table_final.txt
name    = []   # Channel from output table of err_pol_angle.sm
polint  = []   # polint  from output table of err_pol_angle.sm
polang  = []   # polang  from output table of err_pol_angle.sm
errf    = []   # errf    from output table of err_pol_angle.sm

with open(tabFin) as file:
    for line in file:
        reqInfo = re.search('\s+\S+\s+(\S+)\s+'  # NAME, CHAN
                            + ra                 # ALPHA
                            + dec                # DELTA
                            + 2*spaDigs          # X-position, Y-position
                            + '\d+\.\d+'         # Velocity
                            + 2*floats           # Peak intensity, Integrated intensity
                            + 2*spaDigs,         # Average Polarisation, Average Pol.Angle
                            line)
        if reqInfo:
            flux.append(float(reqInfo.group(6)))  # Peak intensity (JY/BEAM)

with open(usrFile[0]) as file:
    for line in file:
        reqInfo = re.search('\s+(\d+)\s+(\d+\.\d+)\s+([+-]?\d+\.\d+)\s+([+-]?\d+\.\d+)',line)
        if reqInfo:
            name.append(int(reqInfo.group(1)))
            polint.append(float(reqInfo.group(2)))
            polang.append(float(reqInfo.group(3)))
            errf.append(float(reqInfo.group(4)))

if len(flux) == len(name) == len(polint) == len(polang) == len(errf):
    potentiallyOK = True
else:
    potentiallyOK = False
    print " xerr.py is not working. \n The number of polarisations detected in %s \n is not equal to %s"%(tabFin,usrFile[0])
    print " Proceed manually."

if potentiallyOK:
    for i in range(len(name)):
        print "%d  %f %f %f"%(name[i],polang[i],errf[i],flux[i])

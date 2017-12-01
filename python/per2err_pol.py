#! /usr/bin/env python

# Written by Vasaant S/O Krishnan on Friday, 01 December 2017

# per2err_pol.py reads in table_final.txt and determines the
# polarisaion intensity based on stokes I and polarisation fraction
# (from Gabriele Surcis' linpol.sm). The output is to be used by
# Gabriele Surcis' err_pol_angle.sm.

# -->$ per2err_pol.py

import re

ra      =        '\s+\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
dec     =   '\s+[+-]?\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
spaDigs =        '\s*([+-]?\d+\.\d+) \+/- (\d+\.\d+)\s*'              # "Space digits"
floats  = '\s*(\d+\.\d+[eE][+-]?\d+) \+/- (\d+\.\d+[eE][+-]?\d+)\s*'

tabFin  = "table_final.txt"

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
            name   =   str(reqInfo.group(1))
            peak   = float(reqInfo.group(6))     # Peak intensity (JY/BEAM)
            pkrms  = float(reqInfo.group(7))
            polper = float(reqInfo.group(10))    # Average Polarisation (%)
            polrms = float(reqInfo.group(11))
            polang = float(reqInfo.group(12))    # Average Pol.Angle (degrees)
            angerr = float(reqInfo.group(13))
            linPolInt = 0.01*polper*peak

            print "%s %.5f %.5f %.5f %.5f"%(name, linPolInt, pkrms, polang, angerr)

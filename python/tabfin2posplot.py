#! /usr/bin/env python

# Written by Vasaant S/O Krishnan on Friday, 01 December 2017
# Run without arguments for instructions.

import re
import string
import sys

usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print " # tabfin2posplot.py reads in table_final.txt and outputs the values to"
    print " # be consistent with what is required for posplot.sm."
    print ""
    print " # -->$ tabfin2posplot.py table_final.txt"
    exit()

ra      =        '\s+\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
dec     =   '\s+[+-]?\d\d\s+\d+\.\d+ \+/- \d+\.\d+\s+'
spaDigs =          '\s*[+-]?\d+\.\d+ \+/- \d+\.\d+\s*'              # "Space digits"
floats  =   '\s*\d+\.\d+[eE][+-]?\d+ \+/- \d+\.\d+[eE][+-]?\d+\s*'

BUFFER  = 6    # Number of chars (up to and including the last) in "NAME"

tabFin  = usrFile[0]

with open(tabFin) as file:
    for line in file:
        if not "------" in line and not "degrees" in line and not "Average Polarization" in line and not "angles" in line:
            reqInfo = re.search('\s+\S+(\s+\S+\s+'   # NAME, CHAN
                                + ra                 # ALPHA
                                + dec                # DELTA
                                + 2*spaDigs          # X-position, Y-position
                                + '\d+\.\d+'         # Velocity
                                + 2*floats           # Peak intensity, Integrated intensity
                                + 2*spaDigs+')',     # Average Polarisation, Average Pol.Angle
                                line)

            excludeName = line[BUFFER:]              # Exclude the "NAME" from each line in table_final.txt

            if reqInfo:                              # if polarisation measurements exist
                print " 1" + str(string.replace(str(reqInfo.group(1))," +/- "," ")),
            elif excludeName != "":                  # else if no polarisation measurements exist
                print " 1" + str(string.replace(str(excludeName)," +/- "," "))[:-1] + "  0 0 0 0"
        else:
            print line,

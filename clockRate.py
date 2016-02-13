#! /usr/bin/env python


from pylab import *
import re
import sys
import datetime
import time

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Variables begin here       %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

# Command-line argument variables used by this script:
userFiles = sys.argv[1:]

harvestValues = False

if userFiles == []:
    print "# CL.py takes input from AIPS CL (31DEC13)  >> box 1 2 3 4 17 18 20 28 29 31 << output in PRTAB."
    print "# Plot of DELAY vs. TIME"
    print ""
    print "--> ./fringPlotter.py     CL.OUT     SOURCE_ID     ANT"

timeArray = []
delayArray = []

SPACE_DIGITS = "\s*(-?\d+.\d+)\s*"

REGEX_STR =

if len(userFiles) > 0:
    harvestValues = True

################################
# Build-up various arrays here into which values from FRING file are harvested
################################
if harvestValues:
    with open(userFiles[0]) as file:
        for line in file:
            reqInfo = re.search(REGEX_STR, line)

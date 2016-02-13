#! /usr/bin/env python

from pylab import *
import re
import sys
import datetime
import time
from time import mktime


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
TIME_DIGITS = "(\d\d:\d\d:\d\d.\d)"
# group(n)       n =   1                                          3                  4                                         7                                                     10
#                     TIME                  TIME INTER          SOURCE ID           ANT       REAL1         IMAG1           DELAY 1               REAL2           IMAG2           DELAY 2
#                   09:41:59.0             00:01:00.0               5                2       1.00000        0.0000         0.000E+00             1.000000        0.000000        0.000E+00
REGEX_STR = "\s+" + TIME_DIGITS + "\s+" + TIME_DIGITS + "\s+" + "(\d+)" + "\s+" + "(\d)" + SPACE_DIGITS + SPACE_DIGITS + "(-?\d.\d\d\dE.\d\d)" + SPACE_DIGITS + SPACE_DIGITS + "(-?\d.\d\d\dE.\d\d)"

if len(userFiles) > 0:
    harvestValues = True

################################
# Build-up various arrays here into which values from FRING file are harvested
################################
if harvestValues:
    with open(userFiles[0]) as file:
        for line in file:
            reqInfo = re.search(REGEX_STR, line)
            if reqInfo:
                if int(reqInfo.group(3)) == int(userFiles[1]) and int(reqInfo.group(4)) == int(userFiles[2]):

                    timeStamp = datetime.datetime(*time.strptime(reqInfo.group(1),"%H:%M:%S.%f")[0:6])
                    delayValue = float(reqInfo.group(7))

                    print timeStamp, delayValue

                    timeArray.append(timeStamp)
                    delayArray.append(delayValue)

    scatter(timeArray,delayArray)
    xlim(min(timeArray),max(timeArray))
    ylim(min(delayArray),max(delayArray))
    show()

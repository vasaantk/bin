#! /usr/bin/env python

# Written by Thursday, 09 February 2017, 13:59 PM.

import re
from pylab import *
import sys

usrFile = sys.argv[1:]

if len(usrFile) != 1:
    print ""
    print "# ibledGrabber.py takes input from AIPS FG file and isolates the"
    print "# IBLED flags."
    print ""
    print "    -->$ ibledGrabber.py FG.OUT"
    print ""
    exit()

ibledRowNum = []
rowNum      = []
rowDict     = {}
bledFlag    = False

# Isolate the lines with IBLED only:
for line in open(usrFile[0],'r'):
    reqInfo = re.search('\s+(\d+)(\s+\d+\s+\S1111\S\s+\SIBLED.*)', line)
    if reqInfo:
        ibledRowNum.append(int(reqInfo.group(1)))
close(usrFile[0])

# Assign flags numbers starting from "1":
for i in range(len(ibledRowNum)):
    dictElement = {ibledRowNum[i]:i+1}
    rowDict.update(dictElement)

# Output the IBLED flags only, renumbered from "1":
for line in open(usrFile[0],'r'):
    reqInfo = re.search('\s+(\d+)\s+.*\d+.\dE[+-]?\d+\s+\d+',      line)
    reqBled = re.search('\s+(\d+)(\s+\d+\s+\S1111\S\s+\SIBLED.*)', line)
    if bledFlag:
        # Print the line immediately after IBLED
        print "%55s"%(str(commRow)+line[8:-1])
    if reqInfo:
        if int(reqInfo.group(1)) in ibledRowNum:
            # %78s referes to the line length
            print "%78s"%(str(rowDict[int(reqInfo.group(1))])+line[8:-1])
    if reqBled:
        # Replace the first 8 spaces with the dictionary generated number
        print "%55s"%(str(rowDict[int(reqBled.group(1))])+line[8:-1])
        commRow  = rowDict[int(reqBled.group(1))]
        bledFlag = True    # Flag to print the line immediately after IBLED
    else:
        bledFlag = False   # If not IBLED, do not print the next line
close(usrFile[0])

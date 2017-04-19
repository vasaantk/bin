#! /usr/bin/env python

# Vasaant Krishnan.

import numpy
import re
import sys

FLIP_SIGN  = -1           # -ve if background source is measured w.r.t foreground source, +ve otherwise

usrFile    = sys.argv[1:]
SPACES     = "        "
loopKeeper = 0            # To keep track of index and user to select
decDate    = 1900         # Default date, if script cannot decipher thee true date

re1  ='.*?'	# Non-greedy match on filler
re2  ='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])'	# flx
re3  ='.*?'	# Non-greedy match on filler
re4  ='[+-]?\\d*\\.\\d+(?![-+0-9\\.])'   	# flxErr - Not grabbed
re5  ='.*?'	# Non-greedy match on filler
re6  ='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])'	# xOff
re7  ='.*?'	# Non-greedy match on filler
re8  ='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])'	# xErr
re9  ='.*?'	# Non-greedy match on filler
re10 ='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])'	# yOff
re11 ='.*?'	# Non-greedy match on filler
re12 ='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])'	# yErr

# This function allows the script to compute how many spaces need to be alloted to ensure equally spaced columns
def spacer(charOfInterest):
    charDiff = len(SPACES) - len(charOfInterest)
    return str(charDiff*" ")

prtFull = False
prtSngl = False
entAlgo = True

if len(usrFile) == 1:
    prtFull = True
elif  len(usrFile) > 1:
    if usrFile[-1].isdigit():
        Q = re.search('_Q',usrFile[0])
        R = re.search('_R',usrFile[0])
        S = re.search('_S',usrFile[0])
        T = re.search('_T',usrFile[0])
        U = re.search('_U',usrFile[0])
        V = re.search('_V',usrFile[0])
        if Q:
            decDate = 2012.183
        if R:
            decDate = 2013.210
        if S:
            decDate = 2013.460
        if T:
            decDate = 2013.621
        if U:
            decDate = 2013.887
        if V:
            decDate = 2014.167
        prtSngl = True
else:
    entAlgo = False
    print "#"
    print "# imfGrab.py reads in an output file from AIPS' IMFIT with DOPRINT=-4."
    print "# It grabs the x and y offsets, their errors and the flux."
    print "# These get rearranged into the correct format for M. Reid's fit_parallax_multi_4d.f script"
    print "#"
    print "# If only the file name is in the argument, then info from all the fits are output."
    print "# --> imfGrab.py fit_Q.txt"
    print "#"
    print "# These will have an Index assigned to them."
    print "# Providing file name with desired Index prints out that particular fit only, along with the decimal date for that epoch."
    print "# --> imfGrab.py fit_Q.txt 2"
    print "#"
    print "# The file name to be read in must have '_Q/R/S/T/U/V' in it in order for script to automatically provide date in printout."
    print "#"

if entAlgo:
    with open(usrFile[0]) as file:
        for line in file:
            reqInfo = re.search(re1+re2+re3+re4+re5+re6+re7+re8+re9+re10+re11+re12,line)
            if reqInfo:
                loopKeeper += 1
                flx  = reqInfo.group(1)
                xOff = reqInfo.group(2)
                xErr = reqInfo.group(3)
                yOff = reqInfo.group(4)
                yErr = reqInfo.group(5)
                if prtFull:
                    index = str(loopKeeper)
                    if len(index) == 1:
                        index = ' ' + index
                    if loopKeeper == 1:
                        print "Index", " xOff", "    xErr", "    yOff", "     yErr", "    Flux"
                    print index, spacer(xOff)+str(xOff), spacer(xErr)+str(xErr), spacer(yOff)+str(yOff), spacer(yErr)+str(yErr), spacer(flx)+' '+str(flx), '   ' + line[156:-1] # The final add-on is to grab any notes
                if prtSngl:
                    if loopKeeper == int(usrFile[-1]):
                        print "   "+str("%.3f"%decDate), spacer(xOff)+str(FLIP_SIGN*float(xOff)), spacer(xErr)+str(xErr), spacer(yOff)+str(FLIP_SIGN*float(yOff)), spacer(yErr)+str(yErr), spacer(flx)+' '+str(flx)

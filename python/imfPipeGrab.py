#! /usr/bin/env python

# Vasaant Krishnan. A modification of imfGrab.py to take inputs from pipe.

import re
import sys

filler     = 12*'.'
ints       = '\s+([+-]?\d+)'           # 'Channel' variable from *.COMP
floats     = '\s+([+-]?\d+.\d+)'  # Any float variable from *.COMP
loopkeeper = True
reqInfo    = False

for line in sys.stdin:
    reqInfo = re.search(    filler
                        +   ints
                        +   floats        # Flux
                        +   floats+'\S+?' # Flux err (with units?)
                        #+10*floats
                        + 4*floats
                        + '\s+([+-]?\d+.\d+)\s*?([+-]?\d+.\d+)'
                        + 4*floats
                        + 2*ints
                        + 2*floats
                        +   ints
                        +   floats+'\S+?' # RMS (with units?)
                        +   ints
                        +'(.*)'           # Comments
                        , line)
    if reqInfo:
        if loopkeeper:
            loopkeeper = False
            print ""
            print " %12s %12s %12s %12s %12s  %s"%("xOff","xErr","yOff","yErr","Flux","Comments:")
        flux = float(reqInfo.group(2))
        xOff = float(reqInfo.group(4))
        xErr = float(reqInfo.group(5))
        yOff = float(reqInfo.group(6))
        yErr = float(reqInfo.group(7))
        note = str(  reqInfo.group(21))
        print " %12.3f %12.3f %12.3f %12.3f %12.3f %s"%(xOff,xErr,yOff,yErr,flux,note)
if reqInfo:
    print ""

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 27 September 2017.
# Run without arguments for instructions.

import re
import sys
from pylab import *

usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print "# velfix-ispec.py converts the freqency from the output of ISPEC to"
    print "# velocity by comparing the frequency from the output from POSSM for"
    print "# the source."
    print ""
    print "  -->$ velfix-ispec.py poss.txt ispec.txt"
    startScript = False
elif len(usrFile) >= 2:    # Check user inputs
    possm = usrFile[0]
    ispec = usrFile[1]
    startScript = True
else:
    print "Check your input files."
    startScript = False



ichan = []    # Channels from ispec
ifreq = []    # Frequencies from ispec
ipeak = []    # "avg over area" from ispec
speak = []    # Smoothed freq from ispec

pvels = []    # Possm velocities
pfreq = []    # Possm frequencies

km_To_metres = 1e3



if startScript:
    #=====================================================================
    #   Harvest values:
    #
    for line in open(ispec,'r'):
        reqInfo    = re.search(  '\s+(\d+)'                           # (1) Channel
                               + '\s+([+-]?\d+\.\d+)[eE][+-]?\d\d'    # (2) Freq. (Note that I exclude harvesting the exponent)
                               + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)$'   # (3) "avg over area" is the header in ispec
                               , line)

        reqSmoInfo = re.search(  '\s+(\d+)'                           # (1) Channel
                               + '\s+([+-]?\d+\.\d+)[eE][+-]?\d\d'    # (2) Freq. (Note that I exclude harvesting the exponent)
                               + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)'    # (3) "avg over area" is the header in ispec
                               + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)$'   # (4) freq smoothed
                               , line)

        if reqInfo:
            # Grab the freq (without the exponent), remove the decimal and make it an integer:
            currentFreqMF = int(str(reqInfo.group(2)).replace(".",""))
            ichan.append(int(reqInfo.group(1)))
            ifreq.append(currentFreqMF)
            ipeak.append(float(reqInfo.group(3)))
            smoothApplied = False

        if reqSmoInfo:
            # Grab the freq (without the exponent), remove the decimal and make it an integer:
            currentFreqMF = int(str(reqSmoInfo.group(2)).replace(".",""))
            ichan.append(int(reqSmoInfo.group(1)))
            ifreq.append(currentFreqMF)
            ipeak.append(float(reqSmoInfo.group(3)))
            speak.append(float(reqSmoInfo.group(4)))
            smoothApplied = True
    close(ispec)

    for line in open(possm,'r'):
        reqPossInfo = re.search(  '\s+(\d+)'                       # (1) Channel
                                + '\s+\d+'                         #     IF
                                + '\s+\S+'                         #     Stokes
                                + '\s+(\d+.\d+)'                   # (2) Freq
                                + '\s+([+-]?\d+\.\d+)'             # (3) Vel
                                + '\s+\d+\.\d+'                    #     Real(Jy)
                                + '\s+\d+\.\d+'                    #     Imag(Jy)
                                ,  line)
        if reqPossInfo:
            # Grab the freq, remove the decimal and make it an integer:
            currentFreqPoss = int(str(reqPossInfo.group(2)).replace(".",""))
            pfreq.append(currentFreqPoss)
            pvels.append(reqPossInfo.group(3))
    close(possm)



    #=====================================================================
    #   Determine velocities
    #
    velmask = [i for i, item in enumerate(pfreq) if item in ifreq]     # Positions of corresponding vels
    fixvels = [pvels[i] for i in velmask]                              # Values    of corresponding vels



    #=====================================================================
    #   Print
    #
    with open(ispec,'r') as file:
        printFix = True
        for line in file:
            if smoothApplied:
                reqInfo = re.search(  '\s+(\d+)'                           # (1) Channel
                                    + '\s+([+-]?\d+\.\d+)[eE][+-]?\d\d'    # (2) Freq. (Note that I exclude harvesting the exponent)
                                    + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)'    # (3) "avg over area" is the header in ispec
                                    + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)$'   # (4) freq smoothed
                                    , line)
                if not reqInfo:               # Header & footer
                    print line,
                elif reqInfo and printFix:    # Toggle to ensure that velocities are correctly sandwiched between header & footer
                    for j in xrange(len(fixvels)):
                        print  "%5d %17.8E %16.7E %16.7E"%(        ichan[j],
                                                           float(fixvels[j])*km_To_metres,
                                                                   ipeak[j],
                                                                   speak[j])
                    printFix = False          # Toggle off
            else:
                reqInfo = re.search(  '\s+(\d+)'                           # (1) Channel
                                    + '\s+([+-]?\d+\.\d+)[eE][+-]?\d\d'    # (2) Freq. (Note that I exclude harvesting the exponent)
                                    + '\s+([+-]?\d+\.\d+[eE][+-]?\d\d)$'   # (3) "avg over area" is the header in ispec
                                    , line)
                if not reqInfo:               # Header & footer
                    print line,
                elif reqInfo and printFix:    # Toggle to ensure that velocities are correctly sandwiched between header & footer
                    for j in xrange(len(fixvels)):
                        print  "%5d %17.8E %16.7E"%(        ichan[j],
                                                    float(fixvels[j])*km_To_metres,
                                                            ipeak[j])
                    printFix = False          # Toggle off

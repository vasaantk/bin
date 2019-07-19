#! /usr/bin/env python
# Run script with out arguments for instructions
# Vasaant Krishnan.
import re
import sys


# Ensure equally spaced columns:
def space(charOfInterest,spaces = 3):
    SPACES = spaces * " "
    charDiff = len(str(charOfInterest)) - len(SPACES)
    if charDiff < 0:
        spaceDiff = len(SPACES) + abs(charDiff)
    elif charDiff > 0:
        spaceDiff = len(SPACES) - charDiff
    else:
        spaceDiff = len(SPACES)
    return str(spaceDiff*" ")


userInp = sys.argv[1:]

harvestFile = False               # Start script or enter help
flagBool    = False               # AIPS flag Boolean

if len(userInp) > 2:
    harvestFile = True
    masSrc      = str(userInp[1]) # Maser
    calSrc      = str(userInp[2]) # Continuum

    if userInp[-1] == "flag":     # AIPS flag print-out
        flagBool = True
else:
    print "\n"
    print "This script flags sources which are not sandwitched"
    print "between identical sources for phase referencing."
    print "For example in a NRAO sched .sum file, with maser"
    print "G339.68-1.2 and quasar J1648-4826.\n"
    print "The correct format for phase referencing is:\n"
    print "354  168 16:10:30 G339.68-1.2"
    print "     168 16:12:30 -          "
    print "355  168 16:12:30 J1648-4826 "
    print "     168 16:14:30 -          "
    print "356  168 16:14:30 G339.68-1.2"
    print "     168 16:16:30 -          \n"
    print "This block is incorrect:\n"
    print "354  168 16:10:30 G339.68-1.2"
    print "     168 16:12:30 -          "
    print "355  168 16:12:30 J1648-4826 "
    print "     168 16:14:30 -          "
    print "356  168 16:14:30 G339.884-1.259"
    print "     168 16:16:30 -          \n"
    print "This block is in the correct format for phase referencing,"
    print "but is not our source of interest and will be flagged:\n"
    print "354  168 16:10:30 G305.21+0.21"
    print "     168 16:12:30 -          "
    print "355  168 16:12:30 J1648-4826 "
    print "     168 16:14:30 -          "
    print "356  168 16:14:30 G305.21+0.21"
    print "     168 16:16:30 -          \n"
    print "=========================================================\n"
    print "Running:\n"
    print "\t --> prFlag.py file.sum G339.681.2 J1648-4826\n"
    print "will display when the sources are in an incorrect format"
    print "for phase referencing observations.\n"
    print "\t --> prFlag.py file.sum G339.681.2 J1648-4826 flag\n"
    print "will produce an output for UVFLG in AIPS.\n\n"

scanArray = [] # Scan number
dayArray  = [] # Day number
timeArray = [] # Time
srcArray  = [] # Source

if harvestFile:
    with open(userInp[0]) as file:
        for line in file:
                                        # 419  168 18:36:00 G339.884-1.2  -
            reqInfo = re.search("\s+(\d\d?\d?)\s+(\d\d?\d?)\s(\d\d:\d\d:\d\d)\s(.*)\s+-\s+",line)
            if reqInfo:
                scanArray.append(int(reqInfo.group(1)))
                dayArray.append( int(reqInfo.group(2)))
                timeArray.append(    reqInfo.group(3))
                srcArray.append( str(reqInfo.group(4)).strip()) # Remove whitespace from source string
    dataCount = len(scanArray)

    for i in xrange(1,dataCount-1):
        if scanArray[i+1] < scanArray[i]: # Get index for when .sum file repeats based on the scan number
            wrapIndex = scanArray.index(scanArray[i])

    # Concat arrays to only what is required
    scanArray = scanArray[0:wrapIndex]
    dayArray  =  dayArray[0:wrapIndex]
    timeArray = timeArray[0:wrapIndex]
    srcArray  =  srcArray[0:wrapIndex]

    arrayLen  = len(scanArray)

    calSrcIndices = [i for i,j in enumerate(srcArray) if j == calSrc]  # Get indices of desired continuum source

    obsDays  = list(set(dayArray))  # set() grabs unique elements to see how many days the obs were spread over
    dayCheck = len(obsDays)

    for i in calSrcIndices:
        # Only select the maser of interest and if the sources before and after 'i' are the same
        if srcArray[i-1] == masSrc and srcArray[i-1] != srcArray[i+1] or srcArray[i-1] != masSrc or srcArray[i+1] != masSrc:
            # 'if' statement for readability
            if flagBool == False:
                print str(dayArray[i-1]) +"/"+ str(timeArray[i-1]) + space(timeArray[i-1],6) + str(dayArray[i]) +"/"+ str(timeArray[i]) + "    " + str(dayArray[i+1]) +"/"+ str(timeArray[i+1])
                print                          str( srcArray[i-1]) + space( srcArray[i-1],8) +                        str( srcArray[i]) + "    " +                          str( srcArray[i+1]) + "\n"
            # 'else' statement for AIPS flag printout
            else:
                startFlagDay = str(obsDays.index(dayArray[i]))   # Search for the day number in the flag
                stopFlagDay  = str(obsDays.index(dayArray[i+1])) # Search for the day number in the flag

                print "TIMER" + " " + startFlagDay + " " + str(timeArray[i]).replace(':',' ') + " " + stopFlagDay + " " + str(timeArray[i+1]).replace(':',' ')
                print "go ; wait\n"

#!/usr/bin/env python

# Script to read in a compact array off-source information text file and output it in a format compatible with AIPS uvflgs

# Example inout: atcaFlagger.py monica.log

import re
import csv
import time
import sys

TRACKING = ' TRACKING'

fileName = sys.argv[1:]

antennaInformationFile = csv.reader(open(str(fileName[0]),'rb'))
startFlag = True
stopFlag = True

convertedStartYear = str(0)
startHour = str(0)
startMin = str(0)
startSec = str(0)
startReason = ''

convertedStopYear = str(0)
stopHour = str(0)
stopMin = str(0)
stopSec = str(0)

penultimateInfo = ''

for row in antennaInformationFile:
    # This is the quickest check I can come up with to make sure input is in the right MoniCA format
    if len(row) == 7:
        # Flagging selection starts from here
        if row[2] == row[3] == row[4] == row[5] == row[6] == TRACKING:
            onSource = True
            offSource = False
        else:
            onSource = False
            offSource = True

        if offSource and startFlag:
            # Code won't enter current 'if' statement until the next off-source time block
            startFlag = False
            stopFlag = True
            printKey = True
            #Get the date/time to start flagging
            offSourceDatetimeGrabber = re.search("\s(\d+-\d+-\d+)\s(\d\d):(\d\d):(\d\d.\d\d\d)(.*)",row[1]+row[2]+row[3]+row[4]+row[5]+row[6])
            if offSourceDatetimeGrabber:
                startYear = time.strptime(offSourceDatetimeGrabber.group(1),"%Y-%m-%d")
                convertedStartYear = time.strftime("%j",startYear)
                startHour = offSourceDatetimeGrabber.group(2)
                startMin = offSourceDatetimeGrabber.group(3)
                startSec = offSourceDatetimeGrabber.group(4)
                startReason = offSourceDatetimeGrabber.group(5)

        if onSource and stopFlag:
            # OK to start flagging again (by entering this 'if' statement) as the previous date/time range has been completed
            startFlag = True
            stopFlag = False

            # Get the date/time to stop flagging
            onSourceDatetimeGrabber = re.search("\s(\d+-\d+-\d+)\s(\d\d):(\d\d):(\d\d.\d\d\d)",row[1])
            if onSourceDatetimeGrabber:
                stopYear = time.strptime(onSourceDatetimeGrabber.group(1),"%Y-%m-%d")
                convertedStopYear = time.strftime("%j",stopYear)
                stopHour = onSourceDatetimeGrabber.group(2)
                stopMin = onSourceDatetimeGrabber.group(3)
                stopSec = onSourceDatetimeGrabber.group(4)

            # Print the time range when the antennae were offsource
            print "ant_name='AT' timerang="+convertedStartYear+","+startHour+","+startMin+","+startSec+", "+convertedStopYear+","+stopHour+","+stopMin+","+stopSec+" REASON='"+startReason+"' /"

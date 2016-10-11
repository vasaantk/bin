#! /usr/bin/env python

# Tuesday, 11 October 2016 by Vasaant S/O Krishnan

# sum2decdates.py reads in any .sum file from NRAO SCHED and converts
# the "Start Day" to decimal dates based on the algorithm from
# "decDates.py".

from datetime import datetime
import sys
import calendar
import re

def leap_yr(year):
    yrCond = calendar.isleap(year)
    if yrCond:
        return 366
    else:
        return 365

fileIntro = "Start Day"
fileDoy   = "\s+(\d+)"
fileIsDay = "\s+\S+\s+\S+"
fileDay   = "\s+(\d+)"
fileMonth = "\s+(\S+)"
fileYear  = "\s+(\d+)"
fileMjd   = "\s+MJD\s+\d+"

months={'Jan':1,
        'Feb':2,
        'Mar':3,
        'Apr':4,
        'May':5,
        'Jun':6,
        'Jul':7,
        'Aug':8,
        'Sep':9,
        'Oct':10,
        'Nov':11,
        'Dec':12}

for line in sys.stdin:
    reqInfo = re.search(  fileIntro
                        + fileDoy
                        + fileIsDay
                        + fileDay
                        + fileMonth
                        + fileYear
                        + fileMjd
                        , line)
    if reqInfo:
        day     = int(reqInfo.group(2))
        month   = str(reqInfo.group(3))
        month   = int(months[month])
        year    = int(reqInfo.group(4))

        obsDate = datetime(year, month, day)

        # Convert to Julian Day
        jDay    = float(obsDate.strftime("%j"))
        yearLen = float(leap_yr(year))
        decDate = year + jDay/yearLen

        print decDate

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 19 October 2016.

import sys
from datetime import *
from pytz import *     # http://pytz.sourceforge.net/
import re
# for tz in pytz.all_timezones:
#     print tz

commonZones = {'CPT' : 'Africa/Johannesburg',
               'NY'  : 'America/New_York',
               'LA'  : 'America/Los_Angeles',
               'CH'  : 'America/Chicago',
               'SAN' : 'America/Santiago',
               'AET' : 'Australia/Hobart',
               'AWT' : 'Australia/Perth',
               'ACT' : 'Australia/Adelaide',
               'UK'  : 'Europe/London',
               'CET' : 'Europe/Rome',
               'NZ'  : 'Pacific/Auckland',
               'SGT' : 'Singapore',
               'JPN' : 'Asia/Tokyo',
               'UTC' : 'UTC'}
zoneKey = commonZones.keys()

usrInp = sys.argv[1:]
if len(usrInp) == 0:
    print ""
    print "#  pytime.py converts the day and time [from] one zone [to]"
    print "#  another. If no date/time is given, the current time is used."
    print "#  Available time zones are:"
    print "#"
    for i in sorted(zoneKey):
        print "#  %8s  (%s)"%(i, commonZones[i])
    print "#"
    print "#  -->$ pytime.py   YYYY-MM-DD HH:MM  [from]-[to]"
    print "#  -->$ pytime.py   [from]-[to]"
    print ""
    exit()

#=====================================================================
#   Code begins here
#
timePrintFmt = '%Y-%m-%d  %a  %H:%M'       # Time output format
dateFlag = False
timeFlag = False
zoneFlag = False

usrInp = [i.replace(':',' ').replace('-',' ').replace('/',' ') for i in usrInp]

for i in usrInp:
    rawDate = re.match('(\d\d\d\d \d\d \d\d)', i)
    rawTime = re.match('(\d\d \d\d)[ \d\d.\d+]*', i)
    rawZone = re.match('(\D+) (\D+)', i)

    if rawDate:
        dateFlag = True
        usrDate  = rawDate.group(1).split(' ')
        year     = usrDate[0]
        month    = usrDate[1]
        day      = usrDate[2]
    if rawTime:
        timeFlag = True
        time  = rawTime.group(1).replace(' ','')
    if rawZone:
        zoneFlag = True
        fromZone = rawZone.group(1).upper()
        toZone   = rawZone.group(2).upper()

if not zoneFlag:
    sys.exit("Check your time zones.")

if dateFlag and timeFlag:
    userTime = datetime.strptime(year+month+day+time,'%Y%m%d%H%M')
else:
    userTime = datetime.now()

if fromZone in zoneKey and toZone in zoneKey:
    startZone = timezone(commonZones[fromZone])
    reqZone   = timezone(commonZones[toZone])

    assignTimeZone = startZone.localize(userTime)
    reqTime        = assignTimeZone.astimezone(reqZone)

    print " %s  %s"%(userTime.strftime(timePrintFmt),startZone)
    print " %s  %s"%( reqTime.strftime(timePrintFmt),reqZone)

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan. Wednesday, 19 October 2016.

import sys
from datetime import *
import pytz
from pytz import *

usrInp = sys.argv[1:]

commonZones = {'EDT' : 'America/New_York',
               'PST' : 'America/Los_Angeles',
               'AEST': 'Australia/Hobart',
               'AWST': 'Australia/Perth',
               'ACST': 'Australia/Adelaide',
               'UK'  : 'Europe/London',
               'CET' : 'Europe/Rome',
               'SGT' : 'Singapore',
               'UTC' : 'UTC'}
zoneKey     = commonZones.keys()

if len(usrInp) == 0:
    print ""
    print "#  pytime.py converts the day and time [from] one zone [to]"
    print "#  another. The current available zones are:"
    print "#"
    for i in sorted(zoneKey):
        print "#  %8s  (%s)"%(i, commonZones[i])
    print "#"
    print "#  -->$ pytime.py   YYYY MM DD HHMM  [from]  [to]"
    print ""
    exit()


year     = usrInp[0]
month    = usrInp[1]
day      = usrInp[2]
time     = usrInp[3]
fromZone = usrInp[4].upper()
toZone   = usrInp[5].upper()

userTime = datetime.strptime(year+month+day+time,'%Y%m%d%H%M')




timePrintFmt = '%Y-%m-%d  %a  %H:%M'

if fromZone in zoneKey and toZone in zoneKey:

    startZone = timezone(commonZones[fromZone])
    reqZone   = timezone(commonZones[toZone])

    assignTimeZone = startZone.localize(userTime)
    reqTime        = assignTimeZone.astimezone(reqZone)

    print ""
    print " %s  %s"%(userTime.strftime(timePrintFmt),startZone)
    print " %s  %s"%( reqTime.strftime(timePrintFmt),reqZone)
    print ""

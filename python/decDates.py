#! /usr/bin/env python

# Vasaant Krishnan

from datetime import datetime
import sys
import calendar

userInp = sys.argv[1:]

def leap_yr(year):
    yrCond = calendar.isleap(year)
    if yrCond:
        return 366
    else:
        return 365

if len(userInp) == 0:
    print "# decDates.py takes a date in command-line: YYYY MM DD"
    print "# and converts it to decimal format."
    print "# '-f' option at the end for full print."
    print ""
    print "# Leap years are taken into account."

elif len(userInp) == 3 or len(userInp) == 4:

    year    = int(userInp[0])
    month   = int(userInp[1])
    day     = int(userInp[2])

    obsDate = datetime(year, month, day)

    # Convert to Julian Day
    jDay    = float(obsDate.strftime("%j"))
    yearLen = float(leap_yr(year))

    decDate = year + jDay/yearLen

    print decDate

    if "-f" in userInp:
        print "D.O.Y = " + str(jDay)
        if yearLen == 366:
            print "Leap year  = True"
        else:
            print "Leap year  = False"

else:
    print "Entry not in correct format: YYYY MM DD"

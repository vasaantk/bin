#! /usr/bin/env python

# katRiseSet.py is based on Lindsay's
# "Scheduling_catalogue_tester.ipynb" to compute source rise, transit
# and set times. The input "source_catalogue.csv" is of the format in
# katsdpcatalogue files.
#
# If no date and time is given, current UTC time is used.
# Acceptable time formats:
#
#            2018-09-29 14:23:45.3240
#            2018/09/29 14:23:45.3240
#            2018-09-29 14:23
#
# Usage:
#        -->$ cat source_catalogue.csv | katRiseSet.py -p 2018-09-29 14:23:45.3240
#
# -p = plot the trajectories
#
# Written by Vasaant S/O Krishnan on Saturday, 22 September 2018

import katpoint
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator, MultipleLocator
import matplotlib.dates as mdates
from astropy.time import Time
import re
import sys



#======================================================================
#    Convert decimal to time
def dec2time(decimalTime):
    hours   = int( decimalTime)
    minutes = int((decimalTime*  60) % 60)
    seconds =    ( decimalTime*3600) % 60
    return str(hours).zfill(2)+':'+str(minutes).zfill(2)



#======================================================================
#    Setup some variables
refAnt = katpoint.Antenna('m000, -30.71292524, 21.44380306, 1035')    # the MeerKAT reference point
refAnt.ref_observer.horizon = '20:00:00'                              # horizon set to 20 degrees



#======================================================================
#    Harvest user defined variables and process
usrInp   = sys.argv[1:]
dateFlag = False        # Assume no user date
timeFlag = False        # Assume no user time
priFlag  = True         # Make first 'target' source primary
plotFlag = False        # Assume plot is not requested

if '-p' in usrInp:
    plotFlag = True

usrInp = [i.replace(':',' ').replace('-',' ').replace('/',' ') for i in usrInp]

for i in usrInp:
    if re.match('\d\d\d\d \d\d \d\d', i):
        usrDate  = i.replace(' ','-')
        dateFlag = True
    if re.match('\d\d \d\d[ \d\d.\d+]*', i):
        usrTime  = i.replace(' ',':')
        timeFlag = True

if (not dateFlag or not timeFlag) and len(usrInp) >= 2:
    print "Error in input time. Reverting to current UTC time"
    print ""

if dateFlag and timeFlag:
    startTimeStamp = katpoint.Timestamp(usrDate + ' ' + usrTime)
else:
    startTimeStamp = katpoint.Timestamp()
startEphemTime     = startTimeStamp.to_ephem_date()



#======================================================================
#    Code begins here
cat = katpoint.Catalogue()
cat.antenna = refAnt

if sys.stdin.isatty():    # Only compute rise/set times if inputs is injected via stdin
    print "# Usage:                                                                  "
    print "#        -->$ cat source_catalogue.csv | katRiseSet.py -p 2018-09-29 14:23"
    print "#                                                                         "
    print "# If no date and time is given, current UTC time is used.                 "
    print "# Acceptable time formats:                                                "
    print "#                                                                         "
    print "#            2018-09-29 14:23:45.3240                                     "
    print "#            2018/09/29 14:23:45.3240                                     "
    print "#            2018-09-29 14:23                                             "
    print "#                                                                         "
    print "# -p = Elevation plot                                                     "

else:
    for line in sys.stdin:    # Harvest source info from the input catalogue
        if line[0] != '#':
            cat.add(line)

    # Setup table header
    print "%10s%20s%20s%20s"%('Target','Next Rise (UTC)', 'Next Transit', 'Next Set')
    print 70*"-"

    # Compute rise, transit & set times and populate table
    for tar in cat.targets:
        try:
            riseTime = str((refAnt.ref_observer.next_rising( tar.body,startEphemTime).datetime()))[:16]
        except:
            riseTime = 'No rise'
        try:
            tranTime = str((refAnt.ref_observer.next_transit(tar.body,startEphemTime).datetime()))[:16]
        except:
            tranTime = 'No transit'
        try:
            setTime  = str((refAnt.ref_observer.next_setting(tar.body,startEphemTime).datetime()))[:16]
        except:
            setTime  = 'No set'

        tags = str([i for i in tar.tags if i != 'radec']).replace("[","").replace("]","").replace("'","")

        if 'target' in tar.tags and priFlag:
            priTarg = tar
            priFlag = False

        print "%10s%20s%20s%20s   %s"%(str(tar.name), str(riseTime), str(tranTime), str(setTime), tags)
    print ""

    if priFlag:     # Manually assign primary target if no 'target' found in cat.targets
        priTarg = tar



    #======================================================================
    #    Plot parameters
    t     = startTimeStamp.secs + np.arange(0, 24.*60.*60., 360.)
    tstmp = Time(t, format= 'unix')
    lst   = katpoint.rad2deg(priTarg.antenna.local_sidereal_time(t))/15
    fig, ax1 = plt.subplots()

    plt.subplots_adjust(right=0.8)
    lines  = list()
    labels = list()

    sun = katpoint.Target('Sun, special')
    print "Solar separation (deg):"

    for target in cat.targets:
        elev = katpoint.rad2deg(target.azel(t)[1])
        tags = str([i for i in target.tags if i != 'radec']).replace("[","").replace("]","").replace("'","")
        myplot,= plt.plot_date(tstmp.datetime, elev, fmt = '.', linewidth = 0, label=target.name + ' ' + tags)
        lines.append(myplot)
        labels.append(target.name)
        lst_rise = lst[np.where(elev>20)[0][ 0]]
        lst_set  = lst[np.where(elev>20)[0][-1]]
        print "%20s %5.1f"%(target.name, np.degrees(sun.separation(target, timestamp= t[int(len(t)/2)], antenna= refAnt)))
        # print "%15s is above 20 degrees between LST %05.02f and %05.02f"%(target.name, lst_rise, lst_set)
    plt.xlim(tstmp.datetime[0], tstmp.datetime[-1])    # Set limits to ensure that twiny aligns LST and UTC correctly

    ax1.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
    ax1.xaxis.set_major_locator(mdates.HourLocator(byhour=range(24),interval=1))

    labels = ax1.get_xticklabels()
    plt.setp(labels, rotation= 'vertical', fontsize=10)
    plt.ylim(20, 90)
    plt.grid()
    plt.legend()
    plt.ylabel('Elevation (deg)')
    plt.xlabel('UTC time starting from %s'%startTimeStamp.to_string())

    ax2 = ax1.twiny()
    ax2.xaxis.set_major_locator(MaxNLocator(24))
    minorLocator = MultipleLocator(0.25)
    ax2.xaxis.set_minor_locator(minorLocator)
    new_ticks = plt.xticks(
        np.linspace(0, 1, 24),
        [dec2time(i) for i in lst[np.linspace(1, len(lst), num= 24, dtype= int)-1]],
        rotation= 'vertical')
    plt.xlabel('Local Sidereal Time (hours)')

if plotFlag:
    plt.show()

#! /usr/bin/env python

# meerRiseSet.py is based on Lindsay's
# "Scheduling_catalogue_tester.ipynb" to compute source rise, transit
# and set times. Check the "Antenna parameters".

# Written by Vasaant S/O Krishnan on Saturday, 22 September 2018

# Usage:
#        -->$ sourceCatalogue.csv | meerRiseSet.py -p
#   -p flag is to plot the trajectories.

import katpoint
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator, MultipleLocator
import matplotlib.dates as mdates
from astropy.time import Time
import re
import sys



#======================================================================
#    Setup some variables

ant    = katpoint.Antenna('m000, -30.71292524, 21.44380306, 1035')     # the MeerKAT reference point
ant.ref_observer.horizon = '20:00:00'                                  # horizon set to 20 degrees

priFlag  = True           # Flag to allow first 'target' as primary calibrator.

cat = katpoint.Catalogue()
cat.antenna = ant

usrInp   = sys.argv[1:]
plotFlag = False
if '-p' in usrInp:
    plotFlag = True



for line in sys.stdin:    # Harvest source info from the input catalogue
    if line[0] != '#':
        cat.add(line)

start_timestamp = katpoint.Timestamp()            # use NOW as the start time for the obs table
start_ed        = start_timestamp.to_ephem_date()

# Setup table header:
print "%10s%20s%20s%20s"%('Target','Next Rise (UTC)', 'Next Transit', 'Next Set')
print 70*"-"

# Compute rise, transit & set times and populate table
for tar in cat.targets:
    try:
        rise_time = str((ant.ref_observer.next_rising(tar.body,start_ed).datetime()))[:16]
    except:
        rise_time = 'source does not rise'
    try:
        transit_time = str((ant.ref_observer.next_transit(tar.body,start_ed).datetime()))[:16]
    except:
        transit_time = 'source does not transit'
    try:
        set_time = str((ant.ref_observer.next_setting(tar.body,start_ed).datetime()))[:16]
    except:
        set_time = 'source does not set'

    tags = str([i for i in tar.tags if i != 'radec'])
    tags = tags.replace("[","")
    tags = tags.replace("]","")
    tags = tags.replace("'","")

    if 'target' in tar.tags and priFlag:    # Select first 'target' as primary target
        priTarg = tar
        priFlag = False

    print "%10s%20s%20s%20s   %s"%(str(tar.name), str(rise_time), str(transit_time), str(set_time), tags)
print ""



if priFlag:     # Manually assign primary target incase no 'target' sources in cat.targets
    priTarg = tar



#======================================================================
#    Plot parameters
xlow = katpoint.Timestamp()
xhig = katpoint.Timestamp() + 24*60*60
t    = start_timestamp.secs + np.arange(0, 24. * 60. * 60., 360.)
lst  = katpoint.rad2deg(priTarg.antenna.local_sidereal_time(t)) / 15
fig, ax1 = plt.subplots()

plt.subplots_adjust(right=0.8)
lines  = list()
labels = list()

for target in cat.targets:
    elev = katpoint.rad2deg(target.azel(t)[1])
    timestamps = Time(t, format='unix')
    myplot,= plt.plot_date(timestamps.datetime, elev, fmt = '.', linewidth = 0, label=target.name)
    lines.append(myplot)
    labels.append(target.name)
    lst_rise = lst[np.where(elev>20)[0][ 0]]
    lst_set  = lst[np.where(elev>20)[0][-1]]
    print('%15s is above 20 degrees between LST %05.02f and %05.02f '%(target.name, lst_rise, lst_set))

ax1.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
ax1.xaxis.set_major_locator(mdates.HourLocator(byhour=range(24),interval=1))

labels = ax1.get_xticklabels()
plt.setp(labels, rotation= 'vertical', fontsize=10)
plt.ylim(20,90)
plt.grid()
plt.legend()
plt.ylabel('Elevation (deg)')
plt.xlabel ('Time (UTC) starting from %s'%start_timestamp.to_string())
ax2 = ax1.twiny()
ax2.xaxis.set_major_locator(MaxNLocator(24))
minorLocator = MultipleLocator(0.25)
ax2.xaxis.set_minor_locator(minorLocator)
new_ticks = plt.xticks(
    np.linspace(0,1,24),
    np.round(lst[np.linspace(1, len(lst), num=24, dtype = int)-1], 2),
    rotation= 'vertical')
plt.xlabel('Local Sidereal Time (hours)')

if plotFlag:
    plt.show()

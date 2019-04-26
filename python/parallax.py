#! /usr/bin/env python

from math import *
from pylab import *
from ephem import *

# Script originally from Simon Ellingsen on 5th December 2013
# Modified to more user friendly inputs by Vasaant Krishnan on 11th June 2015

usrArgs = sys.argv[1:]
saveFig = False
argCount = len(usrArgs)

if argCount == 0:
    print "\nCalculate the optimal times of the year to observe the parallax of astrophysical objects."
    print "Factors are from Smart, W. M. 1962 Text-Book on Spherical Astronomy."
    print "(Cambridge Univ. Press, Cambridge)Smart, W. M. (1962)."
    print "Syntax:\n"
    print "\t -->$ parallax.py lon lat dist (save)\n"
    sys.exit()

eps = 23.439281*pi/180 #This is the obliquity of the Earth's orbit

nstep = int(2.0*pi*100.0)

# Set the epoch as the current year and find the date of the vernal equinox
ep            = str(now().tuple()[0])
vernal        = next_vernal_equinox(ep)-Date(ep)
obsstr        = ('3/7','3/18','6/17','8/14','11/19')
obsdat        = range(len(obsstr))
for i in range(len(obsstr)):
    obsdat[i] = (Date(ep+"/"+obsstr[i])-Date(ep))/365.0


if argCount > 3:
    if usrArgs[3] == 'save':
        saveFig = True

l    = float(usrArgs[0])
b    = float(usrArgs[1])
dist = float(usrArgs[2])

galco = Galactic(l*pi/180.0, b*pi/180.0)

eqco = Equatorial(galco, epoch='2000')

para = 1/dist

deltara  = range(nstep)
deltadec = range(nstep)

#Note: DOY 80 is approximately the date of the (northern) vernal equinox when the ecliptic longitude is zero.
long          = range(nstep)
for i in range(nstep):
  y           = (float(i)/float(nstep)-vernal/365.0)*2.0*pi
  deltara[i]  = para*(cos(eqco.ra)*cos(eps)*sin(y)-sin(eqco.ra)*cos(y))
  deltara[i]  = deltara[i]/cos(eqco.dec)
  deltadec[i] = para*(cos(eqco.dec)*sin(eps)*sin(y)-cos(eqco.ra)*sin(eqco.dec)*cos(y)-sin(eqco.ra)*sin(eqco.dec)*cos(eps)*sin(y))
  long[i]     = float(i)/float(nstep)

for i in range(nstep):
  if deltara[i]==max(deltara):
     ramax = long[i]

  if deltara[i]==min(deltara):
    ramin = long[i]

  if max(deltadec)<0.1:
    decmax = 0
  elif deltadec[i]==max(deltadec):
    decmax = long[i]

  if abs(min(deltadec))<0.1:
    decmin = 0
  elif deltadec[i]==min(deltadec):
    decmin = long[i]

ramax=ramax*365
ramin=ramin*365

if ramax>365:
  ramax = ramax-365
elif ramin>365:
  ramin = ramin-365

print "Maximum in RA : %s, Minimum in RA : %s" % (Date(Date(ep)+ramax),Date(Date(ep)+ramin))

if decmax != 0:
  decmax   = decmax*365+80
  decmin=decmin*365+80
  if decmax>365:
    decmax = decmax-365
  elif decmin>365:
    decmin = decmin-365

print "Maximum in Dec : %s, Minimum in Dec : %s" % (Date(Date(ep)+decmax),Date(Date(ep)+decmin))

raobs = range(len(obsdat))
decobs                = range(len(obsdat))
for i in range(len(obsdat)):
    j                 = 0
    raobs[i]          = 0
    decobs[i]         = 0
    while ((j < len(long)) & (raobs[i] == 0)):
        if (abs(obsdat[i]-long[j]) < 1.0/365.0):
            raobs[i]  = deltara[j]
            decobs[i] = deltadec[j]
        j             = j + 1

xlbl = 'Time (yrs)'
ylbl                             = 'mas'
fig                              = 1
plt.figure(fig)
plt.xlabel(xlbl)
plt.ylabel(ylbl)
plt.title(str(l)+"_LBA")
plt.plot(long,deltara,label='RA')
plt.plot(long,deltadec,'r',label = 'Dec')
plt.legend()
plt.plot(obsdat,raobs,'ko')
plt.plot(obsdat,decobs,'ko')
plt.draw()

if saveFig:
    plt.savefig("G"+str(l)+"_parallax.png",format = 'png')
else:
    show()

#!/usr/bin/python

from scipy import *
import scipy.constants as sc

# Vasaant Krishnan. Determines the tropospheric excess delay (Delta_l) based on Equation (2) in Honma et al. (2008)


# Change these as necessary:
tauAtm     = 0.1   # in nanoseconds
maxBase    = 1700  # in kilometres
zenith     = 45    # Zenith angle in degrees
sep        = 2.0   # Separation of phase-ref sources in degrees

# These should not need any changes:
nanoToSec  = 1e-9
kmToMetres = 1e3
toArcsec   = 3600
toMas      = 1e3
toMic      = 1e6
metreToCm  = 1e2

tauAtm_ns  = tauAtm  * nanoToSec
maxBase_m  = maxBase * kmToMetres

c          = sc.c             # Speed of light
deltaZ     = radians(sep)
barZ       = radians(zenith)
tanBarZ    = tan(barZ)
secBarZ    = 1/cos(barZ)
tropExcess = c * tauAtm_ns * secBarZ * tanBarZ * deltaZ  # Delta_l of Equation (2) in Honma et al. (2008)
trop_cm    = tropExcess * metreToCm

astrometry = degrees(tropExcess/maxBase_m) * toArcsec    # Astrometric accuracy converted from rad to deg to asec
milliAsec  = astrometry * toMas                          # To milliarcsec
microAsec  = astrometry * toMic                          # To microarcsec

print 'Atmospheric delay: ' + str(tauAtm)  + ' nsec'
print 'Maximum baseline : ' + str(maxBase) + ' km'
print 'Zenith angle     : ' + str(zenith)  + ' deg'
print 'Source separation: ' + str(sep)     + ' deg\n'

print(8*' '+u'\u0394l = %.3E'%tropExcess+' m')
print(11*' '+'= %.3f'%trop_cm+' cm')
print 'Astrometry = %.3E'%astrometry +'\"'
print '           = %.4s'%milliAsec +' mas'
print '           = %.4s'%microAsec +' '+u'\u03BCas'

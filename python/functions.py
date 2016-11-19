from scipy   import *
from ephem   import *
from astropy import *
from astropy import units



def wave(freq):      # Frequency to Wavelength
    wavelength = c/freq
    return wavelength
def freq(wave):      # Wavelength to Frequency
    frequency  = c/wave
    return frequency



# Adaptation of J. Mac's MATlAB weighted mean function
def wmean(x,W,rms=False):
    wmean = sum(multiply(x,W))/sum(W)      # element-by-element multiplication
    if len(x) == 1:
        wrms = 0
    else:
        x = [(x - wmean)**2 for x in x]
        wrms = sqrt(sum(multiply(x,W))/sum(W))
    if rms:
        return wmean,wrms
    else:
        return wmean



# Variance Weighted Mean. Wednesday, 03 August 2016
def varmean(x,W,rms=False):
    if len(x) == 1:
        wrms = 0
    else:
        W = [1/(i**2) for i in W]
        varmean = sum(multiply(x,W))/sum(W)
        err     = sqrt(1/sum(W))
        if rms:
            return varmean,err
        else:
            return varmean



# mas/yr to km/s, Sunday, 11 September 2016
def masyr2kms(asyr,parsecDistance):
    # Constants conversions:
    parsec2km = units.pc.to(units.km) * parsecDistance
    yr2sec    = 365.2425 * 24 * 60 * 60
    as2rad    = radians(1./3600.)

    # Variable converstions:
    theta     = asyr * as2rad    #  arcsec/yr  -->  radians/yr
    theta     = theta/yr2sec     # radians/yr  -->  radians/sec
    kms       = parsec2km*theta

    return kms

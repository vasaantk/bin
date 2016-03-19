from scipy import *
from ephem import *


# Vasaant's custum functions

def d2r(degrees):    # Degrees to Radians
    radians    = degrees * pi/180.0
    return radians
def d2a(degrees):    # Degrees to arcsec
    arcsec    = 3600 * degrees
    return radians
def r2d(radians):    # Radians to Degrees
    degrees    = radians * 180.0/pi
    return degrees
def a2r(arcsec):     # Arcsec to Radians
    radians    = d2r(arcsec / 3600)
    return radians
def r2a(radians):     # Arcsec to Radians
    arcsec    = d2a(r2d(radians))
    return radians
def freq(freq):      # Frequency to Wavelength
    wavelength = c/freq
    return wavelength
def wave(wave):      # Wavelength to Frequency
    frequency  = c/wave
    return frequency



def equ2gal(sourceRa,sourceDec):    # Equatorial to Galactic
    # North Galactic Pole coordinates from Reid & Brunthaler (2004)
    # NGP_J2000.ra and NGP_J2000.dec are in units of radians
    NGP_J2000 = Equatorial('12:51:26.2817','27:07:42.013')
    n_r       = NGP_J2000.ra     # North Galactic Pole RA
    n_d       = NGP_J2000.dec    # North Galactic Pole Dec

    sixHr     = Equatorial('06:00:00','00:00:00')

    zeroLON   = d2r(122.932)     # Zero longitude for Galactic coordinates

    # Spherical trig
    sinb      = -cos(sourceDec)*sin(sourceRa - n_r - sixHr.ra)*sin(d2r(90) - n_d) + sin(sourceDec)*cos(d2r(90) - n_d)
    cosb      =  cos(arcsin(sinb))
    sinphi    = (cos(sourceDec)*sin(sourceRa - n_r - sixHr.ra)*cos(d2r(90) - n_d) + sin(sourceDec)*sin(d2r(90) - n_d))/cosb
    cosphi    =  cos(sourceDec)*cos(sourceRa - n_r - sixHr.ra)/cosb

    # sourceRa and sourceDec converted to Galactic latitude and longitude b,l
    b         = arcsin(sinb)                          # Latitude
    l         = arcsin(sinphi) + (zeroLON - pi/2)     # Longitude
    return {'b':b,'l':l}



# http://stackoverflow.com/questions/9415939/how-can-i-print-many-significant-figures-in-python
def nsf(num, n=3):    # Convert float to desired sig. fig.
    numstr = ("{0:.%ie}" % (n-1)).format(num)
    return float(numstr)



# This function allows the script to compute how many spaces need to be alloted to ensure equally spaced columns
def space(charOfInterest,spaces = 3):
    SPACES = spaces * " "
    charDiff = len(str(charOfInterest)) - len(SPACES)
    if charDiff < 0:
        spaceDiff = len(SPACES) + abs(charDiff)
    elif charDiff > 0:
        spaceDiff = len(SPACES) - charDiff
    else:
        spaceDiff = len(SPACES)
    return str(spaceDiff*" ")



# Adaptation of J. Mac's MATlAB function
def wMean(x,W,rms=False):
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

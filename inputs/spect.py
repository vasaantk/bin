#! /usr/bin/env python

# Expect peculiar motion to be 0 in all three vectors if maser is rotating at the same
# velocity as the galaxy.

from scipy import *
from ephem import *
from pylab import *
import sys
import re

from functions import *
from spec2gpec_inp import *

def buff(charOfInterest,spaceCount): # Buffer
    charDiff  = len(str(charOfInterest)) - spaceCount
    if charDiff < 0:
        spaceDiff = spaceCount + abs(charDiff)
    elif charDiff > 0:
        spaceDiff = spaceCount - charDiff
    else:
        spaceDiff = spaceCount
    return str(spaceDiff*" ")

userFiles     = sys.argv[1:]
harvestValues = False
SPACE_DIGITS  = '\s+(-?\d+.\d+)'
REGEX_STR     ='\S+' + 6 * SPACE_DIGITS

if userFiles == []:
    print 'No inpts'

if len(userFiles) > 0:
    harvestValues = True

if harvestValues:
    with open(userFiles[0]) as file:
        for line in file:
            reqInfo = re.search(REGEX_STR,line)
            #               group(1)  group(2)   group(3) group(4) group(5)  group(6)
            # G23.0-0.4       23.010    -0.410      81.0    -1.72	-4.12   0.218
            if reqInfo:

                s_gal     = Galactic(str(reqInfo.group(1)),str(reqInfo.group(2)))
                b         = s_gal.lat
                l         = s_gal.lon

                source    = Equatorial(s_gal)
                s_r       = source.ra
                s_d       = source.dec

                v_LSR     = float(reqInfo.group(3))
                x_mu      = float(reqInfo.group(4))
                y_mu      = float(reqInfo.group(5))
                parallax  = float(reqInfo.group(6))

                xOff      = a2r(0.001 * x_mu * YEARS)
                yOff      = a2r(0.001 * y_mu * YEARS)
                D         = 1/parallax


                # Strategy is to get this script to convert to a format which Mark's script can read
                # then manually harves UVW from there..... sigh :-((

                print ''
                print 'c    ' + str(r2d(l)) + '================================'
                print ''
                print '      ra       = ' + str(s_r)
                print '      dec      = ' + str(s_d)
                print '      dist     = ' + str(D)     + 'd0'
                print '      x_motion = ' + str(x_mu)  + 'd0'
                print '      y_motion = ' + str(y_mu)  + 'd0'
                print '      v_lsr    = ' + str(v_LSR) + 'd0'



                # Shifted coords of source
                ra_shift  = s_r + xOff/cos(s_d)
                dec_shift = s_d + yOff
                s_sh      = Equatorial(ra_shift,dec_shift)    # separation([s_sh.ra,s_sh.dec],[s_r,s_d])

                s_gal_sh  = Galactic(s_sh)
                b_sh      = s_gal_sh.lat
                l_sh      = s_gal_sh.lon

                # Proper motion in Galactic coords
                mu_b      = (b_sh - b)/YEARS
                mu_l      = (l_sh - l)/YEARS
                # Proper motion in Galactic coords in linearised components
                nu_l      = D * mu_l * cos(b)
                nu_b      = D * mu_b

                # Heliocentric velocity
                v_H       = v_LSR - (U_std_sol*cos(l) + V_std_sol*sin(l)) * cos(b) - W_std_sol*sin(b)

                # Convert from spherical to Cartesian coordinates at the location of the Sun (U,V,W)
                U1        = (v_H*cos(b) - nu_b*sin(b))*cos(l) - nu_l*sin(l)
                V1        = (v_H*cos(b) - nu_b*sin(b))*sin(l) + nu_l*cos(l)
                W1        = nu_b*cos(b) +  v_H*sin(b)

                # Add the full orbital motions of the sun in (U,V,W)
                U2        = U1 + U_hip_sol
                V2        = V1 + V_hip_sol + Theta_0
                W2        = W1 + W_hip_sol

                # Distance from GC projected in plane
                R_p       = sqrt(R_0**2 + (D*cos(b))**2 - 2*R_0*D*cos(b)*cos(l))

                # Beta is angle bet Sun and source, when viewed from the Galactic centre
                sinBeta   =        D*cos(b)*sin(l) /R_p
                cosBeta   = (R_0 - D*cos(b)*cos(l))/R_p

                # Rotate (U2,V2,W2) by Beta in to get peculiar motion of the source
                U_s       = U2*cosBeta - V2*sinBeta
                V_s       = V2*cosBeta + U2*sinBeta - Theta_0
                W_s       = W2

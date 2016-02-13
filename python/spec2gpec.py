#! /usr/bin/env python

# Expect peculiar motion to be 0 in all three vectors if maser is rotating at the same
# velocity as the galaxy.

from scipy import *
from ephem import *
from pylab import *

from functions import *
from spec2gpec_inp import *



source    = Equatorial(source_ra,source_dec)

xOff      = a2r(0.001 * x_mu * YEARS)
yOff      = a2r(0.001 * y_mu * YEARS)

s_r       = float64(source.ra)          # source RA
s_d       = float64(source.dec)         # source Dec
# s_gal     = equ2gal(s_r,s_d)          # source in Galactic coords
# b         = s_gal['b']
# l         = s_gal['l']

s_gal     = Galactic(source)
b         = s_gal.lat
l         = s_gal.lon

#================================================================================
# IMPORTANT CHECK THE SIGNS OF THE SHIFT IN THE ADDITIONS OF *_shift VARIABLES
#================================================================================

# Shifted coords of source
ra_shift  = source.ra  + xOff/cos(source.dec)
dec_shift = source.dec + yOff
s_sh      = Equatorial(ra_shift,dec_shift)    # separation([s_sh.ra,s_sh.dec],[s_r,s_d])
# s_gal_sh  = equ2gal(s_sh.ra,s_sh.dec)
# b_sh      = s_gal_sh['b']
# l_sh      = s_gal_sh['l']

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

print "\n","%s"%selection, "distance is %.3f"%D, "kpc from Sun"
print "%s"%selection, "distance is %.3f"%R_p, "kpc from GC\n"

print " U_s = %.3f"%U_s    # Source peculiar motion towards GC
print " V_s = %.3f"%V_s    # Source peculiar motion in dir of Gal rotation
print " W_s = %.3f"%W_s    # Source peculiar motion towards NGP


print v_H

Us.append(U_s)
Vs.append(V_s)

X.append(R_p*cos(l))
Y.append(R_p*sin(l))

quiver(X,Y,Us,Vs,width=0.005)
plot(R_0*cos(0-pi/2),R_0*sin(pi-pi/2),'x')
plot(0,0,'ro')
#show()

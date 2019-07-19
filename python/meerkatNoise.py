#! /usr/bin/env python

import numpy as np
import matplotlib.pyplot as plt

# This is based on Sean Passmoor's "MeerKAT Calculations (1).ipynb".
# See email entitiled "MeerKAT Sensitivity" on Thursday, 18 July 2019,
# 09:52 PM.



# markdown:
# $\frac{\Delta\nu}{\Delta velo } = \frac{\nu_{rest}}{c}$ <br/>
# $\nu_{rest} = 1421.0$ MHz <br/>
# c = 2.99792456e+05 $km.s^{-1}$ <br/>
# $ \Delta velo = 16 km.s^{-1}$ <br/>
# $\Delta \nu = 75807.4180101$ Hz <br/>
# A 5$\sigma$ sensitivity in the intensity of an image is found using $5\sigma_{S} = 5 \frac{2 k T_{sys}}{A_{eff} [2N(N-1)\Delta \nu_{\rm RF}\tau]^{1/2}}$ <br/>

# Equations are from http://www.atnf.csiro.au/people/Tobias.Westmeier/tools_hihelpers.php <br/>
# $ T_{\rm B} = \frac{606 \, S}{\vartheta^{2}}$ <br/>
# $\vartheta $ is in arcseconds  , and the flux is in mJy <br/>
# $N_{\rm H\,I} = 1.823 \times 10^{18} \! \int \! T_{\rm B} \, \mathrm{d}v $ <br/>
# $ \mathrm{d}v $ is in $km.s^{-1}$



#======================================================================
#    User inputs
sigma   = 5.0         # Sigma level to be reached
taper   = 1.0         # Robust/tapering factor
obsFreq = 1350.0e6    # Hz
scanLen = 1050        # Seconds
numAnts = 55          #
numPol  = 2           #
bandwidth = 400.0e6   # Hz



#======================================================================
#    Code begins here

# Justin Jonas:
# https://docs.google.com/spreadsheets/d/1otXwwLQt9Yz9QyTMhCTpsiAavDzVfmh8h4SNwsKL-ck/edit#gid=330521686
# http://public.ska.ac.za/meerkat/meerkat-schedule
# Sensitivity (average of two polarizations measured on m063)
# Freq (MHz), SEFD (Jy), Tsys/eta (K), Ae/Tsys (m^2/K)
specs = np.array([[ 900, 578, 30.0, 4.77],
                  [ 950, 559, 29.0, 4.94],
                  [1000, 540, 28.0, 5.11],
                  [1050, 492, 25.5, 5.61],
                  [1100, 443, 23.0, 6.22],
                  [1150, 443, 23.0, 6.22],
                  [1200, 443, 23.0, 6.22],
                  [1250, 443, 23.0, 6.22],
                  [1300, 453, 23.5, 6.09],
                  [1350, 443, 23.0, 6.22],
                  [1400, 424, 22.0, 6.51],
                  [1450, 415, 21.5, 6.66],
                  [1500, 405, 21.0, 6.82],
                  [1550, 405, 21.0, 6.82],
                  [1600, 405, 21.0, 6.82],
                  [1650, 424, 22.0, 6.51]])

k = 1.38e-23          # Boltzmann constant
J = 1.0e26            # Jy to Watts
D = 13.5              # Dish diameter
A = np.pi*(D/2.0)**2
TsysEta = specs[:, 2]
N = numAnts
tau = scanLen

# Grab frequencies and convert to Hz
nu = specs[:, 0]*1.0e6
# Find closest specified freq to user's request
closestFreq = np.argmin(np.abs(nu-obsFreq))
useFreq = specs[:, 0][closestFreq]
TsysPerEta = TsysEta[closestFreq]

# Compute noise
noise = 2*k*TsysPerEta/(A*np.sqrt(N*(N-1)*bandwidth*tau))*J/np.sqrt(numPol)

print "Tsys/eta at %3.0f MHz: %2.1fK"%(useFreq, TsysPerEta)
print "Flux/rms calculated from the observing time:"
string = 'The {0:.0f} sigma noise level after {1:.2f} hours on source is {2:2.4g} mJy and tapered by {3:.2g} is {4:2.4g} mJy gives a rms of {5:2.4g} mJy'
print string.format(sigma, tau/3600.0, sigma*noise*1.0e3, taper, sigma*noise*1.0e3*taper, noise*1.0e3)

# Plot the specs array
plt.plot(specs[:, 0], specs[:, 2])
plt.title('Measured Meerkat Specs')
plt.ylabel('Tsys/$\eta $')
plt.xlabel('Frequency (MHz)')
# plt.show()

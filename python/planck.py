# Simon Ellingsen 2015
from scipy import *

k     = 1.38064852e-23  # Boltzmann m^2 kg/(s^2 K)
c     = 2.99792458e+08  # Light     m/s
h     = 6.62607004e-34  # Planck    m^2 kg/s
mH    = 1.66054e-27*1.007825 # Mass of Hydrogen in kg
G     = 6.67384e-11
parsec_in_metres  = 3.08567758e16
msol_in_kg        = 1.98855e+30  # Solar mass
arcsec_in_radians = 4.84813681e-6
year_in_seconds   = 3.15569e7


def planck(freq,temp):      # Calculate the value of the planck function at a particular wavelength
    return ((2.0*h*freq**3)/(c**2))*1.0/(exp((h*freq)/(k*temp))-1.0)

def dust_mass(flux,dist,dtemp=20,wavelength=1.1e-3,gas_to_dust=100.0,dust_absorption=0.185):
    # Inputs :
    #   flux = Flux density (Jy)
    #   dist = Distance to the source (pc)
    #   dtemp = Dust temperature (K)
    #   wavelength = wavelength at which the flux was measure (m)
    #   gas_to_dust = the assumed gas to dust mass ratio
    #   dust_absorption = Dust absorption coefficient, kappa_d (m^2 kg^-1)
    #                     (multiply values in cm^2 g^-1 by 0.1 to convert)
    #     NOTE: sometimes people use kappa_nu in their calculations, but
    #           kappa_nu = kappa_d/gas_to_dust (hence has an assumed gas to
    #           dust ratio incorporated).
    #     Values of kappa_d to use are typically taken from Ossenkopf &
    #     Henning (1994).  Dunham et al. (2011) has information on extrapolating
    #     values from the table (assumed spectrum of dust opacity etc).
    # Outputs :
    #   The function returns the dust mass (solar masses)

    # Some constants that we need for the calculations

    # Calculate the frequency and the value of the Planck function
    freq = c/wavelength
    B = planck(freq,dtemp)
    return(((flux*1.0e-26*gas_to_dust*(dist*parsec_in_metres)**2)/(B*dust_absorption))/msol_in_kg)

def column_density(flux,dtemp=20,wavelength=1.1e-3,gas_to_dust=100.0,dust_absorption=0.185,
                   mean_mol_weight=2.3,bsa=2.9e-8):
    # Inputs :
    #   flux = Flux density (Jy)
    #   dtemp = Dust temperature (K)
    #   wavelength = wavelength at which the flux was measure (m)
    #   gas_to_dust = the assumed gas to dust mass ratio
    #   dust_absorption = Dust absorption coefficient, kappa (m^2 kg^-1)
    #                     (multiply values in cm^2 g^-1 by 0.1 to convert)
    #   mean_mol_weight = Mean molecular weight of the gas assumed (amu)
    #   bsa = Beam solid angle for the observations in steradians
    # Outputs :
    #   The function returns the beam-averaged column density (cm^-2)

    # Calculate the frequency and the value of the Planck function
    freq = c/wavelength
    B = planck(freq,dtemp)
    return((flux*1.0e-26*gas_to_dust)/(B*bsa*dust_absorption*mean_mol_weight*mH)*1.0e-4)

def sound_speed(temp=25,mean_mol_weight=2.3):
    # Inputs :
    #   temp = temperature of the gas (K)
    #   mean_mol_weight = Mean molecular weight of the gas assumed (amu)
    # Outputs :
    #   The sound speed in the gas (km/s)
    # The equation for the sound speed is cs = sqrt(kT/mu*mH)
    # where mu is the mean molecular mass and mH the mass of the hydrogen
    # atom.

    # The factor of 1000 is to convert from m/s to km/s
    return(math.sqrt((k*temp)/(mean_mol_weight*mH))/1000.0)

def alfven_speed(B=10,n=1.0e4,mean_mol_weight=2.3):
    # Inputs :
    #   B = magnetic field strengh in (microGauss)
    #   n = number density (cm^-3)
    #   mean_mol_weight = Mean molecular weight of the gas assumed (amu)
    # Outputs :
    #   The Alfven speed in the gas (km/s)
    # The equation for the Alfven speed is VA = B/sqrt(mu_0*rho) [m/s]
    # see Stahler & Palla Pg 274, but note that to their equation is in cgs
    # so to convert it to SI we have multiplied B by sqrt(4*pi/mu_0) to get above
    # expression.

    # Convert from number density in particles per cc into density in kgm^-3
    # NOTE: factor of 1.0e6 is the number of cubic centimetres in a cubic metre
    density = mean_mol_weight*mH*n*1.0e6
    # The factor of 10^-10 is to convert B field in microG into T
    # The factor of 1000 is to convert from m/s to km/s
    return(((B*1.0e-10)/math.sqrt(4.0*math.pi*1.0e-7*density))/1000.0)

def freefall_time(n=1.0e4,mean_mol_weight=2.3):
    # Inputs :
    #   n = number density (cm^-3)
    #   mean_mol_weight = Mean molecular weight of the gas assumed (amu)
    # Outputs :
    #   The freefall time for a gas (Myr)
    # The equation for the free-fall time is tff = sqrt((3*pi)/(32*G*rho)) [s]
    # see Stahler & Palla Pg 70.  The free-fall time is the timescale on which the
    # radius of a collapsing cloud reduces by a factor of 2, or alternatively it is
    # the time for a homogeneous sphere with no internal pressure to collapse to
    # a point.
    # Convert from number density in particles per cc into density in kgm^-3
    # NOTE: factor of 1.0e6 is the number of cubic centimetres in a cubic metre
    density = mean_mol_weight*mH*n*1.0e6
    # 3.15559e13 is the number of seconds in a million years
    return(math.sqrt((3.0*math.pi)/(32.0*G*density))/(year_in_seconds*1.0e6))

def vel_disp(fwhm):
    # Inputs :
    #   fwhm = full-width at half maximum of the spectral line (km/s)
    # Outputs :
    #   The velocity dispersion corresponding to that line width (km/s)
    # Equation taken from footnote on Pg 75 of Ward-Thompson and Whitworth
    return(fwhm/math.sqrt(8.0*math.log(2.0)))

def virial_mass(fwhm,R):
    # Inputs :
    #   fwhm = full-width at half maximum of the spectral line (km/s)
    #   R = radius of the cloud in pc
    # Outputs :
    #   The virial mass of a cloud with that velocity dispersion/radius (solar masses)
    # Some constants that we need for the calculations
    return((((vel_disp(fwhm)*1000)**2*R*parsec_in_metres)/G)/msol_in_kg)

def freq_to_wavenumber(freq):
    # Inputs:
    # freq = The frequency of the transition in Hz
    # Outputs:
    # The wavenumber of the transition in cm^-1
    # The factor of 0.01 is to convert m^-1 to cm^-1
    return (freq/c*0.01)

def wavenumber_to_K(wn):
    # Convert an energy expresses as a wavenumber into a temperature in K
    # Inputs:
    # wn = The energy state in cm^-1
    # Outputs:
    # The energy of the state in K
    return ((h*c*wn*100.0)/k)

def population_fraction(wn_low,wn_high,T):
    import math
    # Assuming a Boltzman distribution for a temperature T, calculate
    # the fraction molecules in the upper state of energy wn_high compared
    # with the number in the lower state of energy wn_low.
    # Inputs:
    # wn_low = wavenumber of the lower energy state in cm^-1
    # wn_high = wavenumber of the upper energy state in cm^-1
    # T = temperature in K
    # Outputs:
    # The fraction of molecules in the higher energy state.
    factor = (h*c*100.0*(wn_low-wn_high))/(k*T)
    return(math.exp(factor))

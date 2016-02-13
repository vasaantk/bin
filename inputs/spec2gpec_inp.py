from ephem import *

YEARS      = 10000.0       # Time interval over which to compute position shift

#================================================
#
#       Solar parameters
#

# Standard solar peculiar motion parms
U_std_sol  = 10.27
V_std_sol  = 15.32
W_std_sol  = 7.77
# Hipparcos solar peculiar motion parms
U_hip_sol  = 10.0
V_hip_sol  = 5.25
W_hip_sol  = 7.17
# Rotation speed of LSR (IAU) value. In Reid (2009b) pecular motion of HMSFR is independant of Theta_0
Theta_0    = 240
R_0        = 8.34
#================================================
#================================================

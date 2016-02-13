#! /usr/bin/env python

# Written by Vasaant S/O Krishnan on 31 Oct 2014
# Run w/o arguments for instructions

from pylab import *
import sys
import re
from functions import d2r

usrFile = sys.argv[1:]
spaDigs = '\s+(-?\d+.\d+)'     # spaDigs = "Spaces followed by digits"
REGEX   = '.*?' + 9 * spaDigs

R0      = 8.34 # Solar distance from GC from Reid et al. (2014a)

dist    = []   # Distance
l       = []   # Galactic longitudes
b       = []   # Galactic latitudes
U       = []   # Galactocentric motions U,V,W
V       = []
W       = []
Uerr    = []
Verr    = []
Werr    = []

saveFig = False
showFig = False
atate   = False  # Annotate

if len(usrFile) > 0:
    for i in usrFile:
        if i == 'show':
            showFig = True
        if i == 'save':
            saveFig = True
        if i == 'ann':
            atate = True
    harvest = True
else:
    print ""
    print "Calculate and plot Galactic peculiar motions from output of 'galactic_peculiar_motions.f'"
    print ""
    print "--> pec2plot.py out.txt [options]"
    print "options = save --> save figure"
    print "options = show --> show figure"
    print "options = ann  --> annotate figure in save/show mode"
    print ""
    harvest = False

if harvest:
    with open(usrFile[0]) as file:
        for line in file:
            reqCoords = re.search(REGEX, line)
            if reqCoords:
                dist.append(float(reqCoords.group(1)))    # Parallax dist from Sun
                l.append(   float(reqCoords.group(2)))    # Galactic longitude
                b.append(   float(reqCoords.group(3)))    # Galactic latitude
                U.append(   float(reqCoords.group(4)))    # Peculiar motion towards GC
                Uerr.append(float(reqCoords.group(5)))
                V.append(   float(reqCoords.group(6)))    # Peculiar motion clockwise around GC
                Verr.append(float(reqCoords.group(7)))
                W.append(   float(reqCoords.group(8)))    # Peculiar motion towards NGP
                Werr.append(float(reqCoords.group(9)))

    arrayLen = len(dist)
    D_p      = [0] * arrayLen    # "dist" of source from Sun projected unto Galactic plane
    R_p      = [0] * arrayLen    # Distance of source from GC projected unto Galactic plane
    sin_beta = [0] * arrayLen    # sin of angle formed by Sun-GC-source (i.e. h projection)
    cos_beta = [0] * arrayLen    # cos of angle formed by Sun-GC-source (i.e. v projection)
    X_pos    = [0] * arrayLen    # EW offset from GC
    Y_pos    = [0] * arrayLen    # NS offset from GC
    X_vec    = [0] * arrayLen    # EW projection of U + V
    Y_vec    = [0] * arrayLen    # NS projection of U + V

    for i in xrange(arrayLen):
        D_p[i]      = dist[i]*cos(d2r(b[i]))
        R_p[i]      = sqrt(R0**2 + D_p[i]**2 - 2*R0*D_p[i]*cos(d2r(l[i])))

        sin_beta[i] =       D_p[i]*sin(d2r(l[i])) /R_p[i]
        cos_beta[i] = (R0 - D_p[i]*cos(d2r(l[i])))/R_p[i]

        X_pos[i]    = R_p[i] * sin_beta[i]
        Y_pos[i]    = R_p[i] * cos_beta[i]

        X_vec[i]    =  V[i]*cos_beta[i] + U[i]*sin_beta[i]
        Y_vec[i]    = -U[i]*cos_beta[i] - V[i]*sin_beta[i]

    plot(  X_pos,   Y_pos,    '.')  # Peculiar motions
    quiver(X_pos,   Y_pos,
           X_vec,   Y_vec, width=0.002)
    plot(  X_pos[0],Y_pos[0],'m^')  # G339.884-1.259
    plot(   0,   R0, 'r*')  # Sun
    plot(   0,    0, 'ro')  # GC
    #xticks(arange(-10,10,1))
    #yticks(arange(-5,15,1))
    xlim([-10,10])
    ylim([-5 ,15])

    if atate:
        for i in xrange(arrayLen):
            annotate(str(l[i]),xy=(X_pos[i],Y_pos[i]),xycoords='data')
    if showFig:
        show()
    if saveFig:
        savefig('pec2plot.png',transparent=True)

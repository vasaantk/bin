#!/usr/bin/env python

# This is a script to extract pixel information from an image and display that information graphically.
# Command-line arguments take following options:
# --> hist
# --> 3d=
# --> stats
# --> alpha=
# --> 2d=

from pylab import *
from PIL import *
import sys
import re
import matplotlib as mpl
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Variables begin here       %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

userInp = 0       # Cmd-line argument position keeper

# Variables for histogram
x = []            # x coordinate for RGB histogram; 8-bit
yOne = []         # Red pixel array for RGB histogram
yTwo = []         # Green pixel array for RGB histogram
yThr = []         # Blue pixel array for RGB histogram

# Variables for 3D pixel distribution
lenRed = []       # Red pix count along length of image
widRed = []       # Red pix count along width of image
pixValRed = []    # Red pix intensity value

lenGre = []       # Green Pixels
widGre = []
pixValGre = []

lenBlu = []       # Blue pixels
widBlu = []
pixValBlu = []

# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #
# %%%%                               %%%% #
# %%%%    Script begins from here    %%%% #
# %%%%                               %%%% #
# %%%% # %%%% # %%%% # %%%% # %%%% # %%%% #

# Switching options for user:
showPlot = False  # Plot histogram --> hist <-- in cmd-line
show3D = False    # Plot pixel intensity for (x,y) distribution --> 3d=?? <-- in cmd-line. Sampling freq: ?? is any +ve int
printStat = False # Print some image statistics
alpha3D = False   # Plot pixel intensity for (x,y) distribution --> alpha=?? <-- in cmd-line. Sampling freq: ?? is any +ve int
alpha2D = False   # Plot pixel distrubution --> 2d=?? <-- in cmd-line. Sampling freq: ?? is any +ve int

# Cmd-line options harvested
userFile = sys.argv[1:]

# Image file as requested by user
userImage = Image.open(userFile[0])

# 'For' loop to determine what operations user has requested/defined
for i in userFile:
    if re.match('hist',i):
        showPlot = True
    if re.match('3d=',i):
        show3D = True
        resInfo = userInp
    if re.match('stats',i):
        printStat = True
    if re.match('alpha=',i):
        alpha3D = True
        resInfoAlpha = userInp
    if re.match('2d=',i):
        alpha2D = True
        resAlpha = userInp
    userInp += 1 # userInp keeps track of which position in the cmd line arg a specific user defined setting is

################################
# User defined values for 3D-resolution, etc (in the command line) are harvested here
################################
if show3D:
    reqResolutionInfo = re.search('3d=(\d+)',userFile[resInfo])
    if reqResolutionInfo:
        userRes = int(reqResolutionInfo.group(1))
if alpha3D:
    reqResolutionInfo = re.search('alpha=(\d+)',userFile[resInfoAlpha])
    if reqResolutionInfo:
        userResAlpha = int(reqResolutionInfo.group(1))
if alpha2D:
    reqResolutionInfo = re.search('2d=(\d+)',userFile[resAlpha])
    if reqResolutionInfo:
        userAlpha = int(reqResolutionInfo.group(1))

#im = userImage.point(range(0,256,1)*3)
imageWidth, imageHeight = userImage.size
pixParms = userImage.load()

################################
# Print image statistics
################################
if printStat:
    print "Format: " + str(userImage.format)
    print "Size (pix): " + str(userImage.size)
    print "Mode: " + str(userImage.mode)

################################
# Histogram produced here
################################
if showPlot:
    # Grab the colour histogram of the image in RGB (I'd like to see if there're more color dimensions available)
    pixIntnsty = userImage.histogram()
    # Assuming 8-bit depth, assign yOne:yTwo:yThr as R:G:B
    for i in range(0,len(pixIntnsty),1):
        if i < 256:
            x.append(i)
            yOne.append(pixIntnsty[i])
        elif i >= 256 and i < 512:
            yTwo.append(pixIntnsty[i])
        else:
            yThr.append(pixIntnsty[i])
    xlim(-10,267)
    scatter(x,yOne,c='r',marker='|')
    scatter(x,yTwo,c='y',marker='|')
    scatter(x,yThr,c='b',marker='|')
    show()

################################
# 3D pixel intensity distribution produced here
################################
if show3D:
    for i in xrange(0,imageWidth,userRes):
        for j in xrange(0,imageHeight,userRes):
            widRed.append(i)
            lenRed.append(j)
            pixValRed.append(pixParms[i,j][2])
            widGre.append(i)
            lenGre.append(j)
            pixValGre.append(pixParms[i,j][0])
            widBlu.append(i)
            lenBlu.append(j)
            pixValBlu.append(pixParms[i,j][1])
    plot3D = gca(projection='3d')
    plot3D.scatter(lenRed, widRed, pixValRed, c='r',  marker = 'x')
    plot3D.scatter(lenBlu, widBlu, pixValBlu, c='g',  marker = 'x')
    plot3D.scatter(lenGre, widGre, pixValGre, c='b',  marker = 'x')
    show()

if alpha3D:
    plot3D = gca(projection='3d')
    for i in range(0,imageWidth,userResAlpha):
        for j in range(0,imageHeight,userResAlpha):
            plot3D.scatter(i,j,pixParms[i,j][0], c='r', alpha=pixParms[i,j][0]/257., marker = 'x')
            plot3D.scatter(i,j,pixParms[i,j][1], c='y', alpha=pixParms[i,j][1]/257., marker = 'x')
            plot3D.scatter(i,j,pixParms[i,j][2], c='b', alpha=pixParms[i,j][2]/257., marker = 'x')
    show()

if alpha2D:
    for i in range(0,imageWidth,userAlpha):
        for j in range(0,imageHeight,userAlpha):
            scatter(i,j, c='r', alpha=pixParms[i,j][0]/257., edgecolors='none')
            scatter(i,j, c='g', alpha=pixParms[i,j][1]/257., edgecolors='none')
            scatter(i,j, c='b', alpha=pixParms[i,j][2]/257., edgecolors='none')
    show()

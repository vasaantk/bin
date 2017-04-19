#! /usr/bin/env python

# Vasaant Krishnan. This script has been harvested from definitions_bessel_current.py on 7th November 2013

# It plots the data found in the output from Mark Reid's fit_geoblocks.f script (ATMOS.FITS).

# Script works: ./atmosPlotter.py ATMOS.FITS
# add 'save' to output a .ps file instead of showing the plot

# For Australian LBA numbers in the plot:
# 1 = ATCA
# 2 = Ceduna
# 3 = Hart or Hobart
# 4/5 = Mopra
# 5/6 = Parkes

from matplotlib import *
from pylab import *
import sys


fileName = sys.argv[1:]

argumentCount = len(fileName)

def plotatmos(inter_flag):
    file=str(fileName[0])#'ATMOS.FITS'

    data=loadtxt(file,skiprows=1)

    ant=[]
    data2=[]
    avg=[]
    rms=[]

    for i in range(int(max(data[:,0]))):
        ant.append([])
        data2.append([])
        avg.append(-1)
        rms.append(-1)
    for row in data:
        if (row[0] in ant) == False:
            ant[int(row[0])-1]=int(row[0])
        time=row[1]*24.+(row[2]+row[3]/60.+row[3]/3600.)
        data2[int(row[0])-1].append([int(row[0]), time,row[5], row[6], row[7], row[8]])

    max_ant=len(data2)
    num_ant=0
    for i in ant:
        if i!=[]:
            num_ant+=1

    fig=figure(0)
    n=0
    start=100
    end=0

    for entry in data2:
        n=n+1
        if entry !=[]:
            ant_data=array(entry)
            if start>min(ant_data[:,1]):
                start=min(ant_data[:,1])
            if end<max(ant_data[:,1]):
                end=max(ant_data[:,1])
            sum=0
            for i in range(len(ant_data)):
                sum=sum+ant_data[i][2]
            avg[n-1]=(sum/len(ant_data))
            rms[n-1]=(ant_data[:,2].std())

    n=0
    plot=0
    span=2

    for entry in data2:
        n+=1
        if entry !=[]:
            plot+=1
            ant_data=array(entry)
            ax=fig.add_subplot(num_ant,1,plot)
            line = ' %4d  %12.3f ' % (int(ant_data[0][0]), round(rms[n-1],3))

            if (max(ant_data[:,2])<avg[n-1]+span) and (min(ant_data[:,2])>avg[n-1]-span):
                ax.plot(ant_data[:,1], ant_data[:,2], 'go')
                ax.set_ylim(avg[n-1]-span,avg[n-1]+span)
                line2 = ''
                ax.plot(ant_data[:,1], ant_data[:,2],'black')
            elif (max(ant_data[:,2])<avg[n-1]+2*span) and (min(ant_data[:,2])>avg[n-1]-2*span):
                ax.plot(ant_data[:,1], ant_data[:,2], 'yo')
                ax.set_ylim(avg[n-1]-2*span,avg[n-1]+2*span)
                line2 = '  (variations > '+str(int(span))+' cm from mean)'
                ax.plot(ant_data[:,1], ant_data[:,2],'black')
            elif (max(ant_data[:,2])<avg[n-1]+3*span) and (min(ant_data[:,2])>avg[n-1]-3*span):
                ax.plot(ant_data[:,1], ant_data[:,2], 'ro')
                ax.set_ylim(avg[n-1]-3*span,avg[n-1]+3*span)
                line2 = '  (variations > '+str(int(2*span))+' cm from mean)'
                ax.plot(ant_data[:,1], ant_data[:,2], 'r')
            else:
                ax.plot(ant_data[:,1], ant_data[:,2], 'ro')
                ax.set_ylim(avg[n-1]-4*span,avg[n-1]+4*span)
                line2 = '  (variations > '+str(int(3*span))+' cm from mean)'
                ax.plot(ant_data[:,1], ant_data[:,2], 'black')
            ax.set_xlim(start-1.,end+1.)
            yticks([int(avg[n-1])-2*span,int(avg[n-1]),int(avg[n-1])+2*span])

            ax.text(0.03, 0.60, str(int(ant_data[0][0])), transform=ax.transAxes)

            if n==1:
                title('ATMOS.FITS zenith delays [cm]')
            if n<max_ant:
                ax.xaxis.set_major_locator(NullLocator())
            if n==max_ant:
                 xlabel('UT [hours]')
    if argumentCount == 2:
        if fileName[1] == 'save':
            savefig('atmos.ps')
    else:
        show()

plotatmos(fileName)

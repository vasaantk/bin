#! /usr/bin/env python

import allantools
import numpy as np
import matplotlib.pyplot as plt
import pickle


# allanVariance.py reads in the pickled "data" variable from
# MKAIV-187-stats.py or MKAIV-187-stamp.py. It then derives the
# eponymous statistics.
# Written by Vasaant S/O Krishnan on Wednesday, 10 October 2018.


#======================================================================
#    Sean's Allan Variance from email on Wednesday, 10 October 2018
#
def Overlapped_Allan_Variance_1D(dat, tau= 1.):

    """
    Overlapped_Allan_Variance_1D is a Non-overlapped variable tau
    estimator of the Allan variance. This function takes in an 1D
    array of N elements tau is the length of time in each sample (for
    normalisation)

    returns: an array of (N-1)/2 elements

    Example:
    Overlapped_Allan_Variance_1D(np.random.standard_cauchy(1000000).reshape(1000,1000).mean(axis=1))
    """

    if not len(dat.shape) == 1 : raise ValueError('Array must be a 1D-array')

    def allanv(n, x, tau= 1.):

        """
        x is an array of equaly spaced time mesurements
        tau  Tau is the time between each sample (assumed to be one)
        n is the number of samples to calculate the varence between
        """

        N    = x.shape[0]
        norm = 1./(2.*n**2*tau**2*(N-2*n))
        summ = ((np.lib.stride_tricks.as_strided(x, shape= (N-2*n-1,3), strides= x.strides+(n*x.strides[0],) )*(1,-2,1)).sum(axis=1)**2).sum()
        return norm*summ

    N = dat.shape[0]
    allres = np.zeros(((N-1)/2), dtype= dat.dtype)

    for i in xrange(1, (N-1)/2):
        allres[i] = allanv(i, dat, tau)

    return allres



#======================================================================
#    Setup some variables
antInd   = 0         # Antenna index
bitRate  = 8         # Data bit rate (sec)
phase    = False      # Compute phase angle from data (otherwise amplitude)
pol      = 'h'       # Polarisation
pickFile = '/home/vasaantk/bigData_'+pol+'.p'    # Path to dat file



#======================================================================
#    Code begins here
data    = pickle.load(open(pickFile,'rb'))
dataSub = data[:,antInd] - np.nanmean(data[:,antInd])

if phase:
    allanData = allantools.Dataset(    data= np.angle(dataSub), rate= 1./bitRate, taus='all')
    allanSean = Overlapped_Allan_Variance_1D(np.angle(dataSub),  tau= 1./bitRate)
    title     = 'Phase'
else:
    allanData = allantools.Dataset(    data= abs(dataSub), rate= 1./bitRate, taus='all')
    allanSean = Overlapped_Allan_Variance_1D(abs(dataSub),  tau= 1./bitRate)
    title     = 'Amplitude'

seanVar = np.sqrt(allanSean)
adev    = allanData.compute('adev')
oadev   = allanData.compute('oadev')
# mdev    = allanData.compute('mdev')
# tdev    = allanData.compute('tdev')
totdev  = allanData.compute('totdev')

plt.loglog(  adev['taus'],   adev['stat'], label= 'adev'  , c= 'b', alpha=0.4)
plt.loglog( oadev['taus'],  oadev['stat'], label= 'oadev' , c= 'g')
# plt.loglog(  mdev['taus'],   mdev['stat'], label= 'mdev'  , c= 'k')
# plt.loglog(  tdev['taus'],   tdev['stat'], label= 'tdev'  , c= 'c')
plt.loglog(totdev['taus'], totdev['stat'], label= 'totdev', c= 'r')
plt.loglog( oadev['taus'],        seanVar, label= 'Sean'  , c= 'r', alpha=0.4)

plt.xlabel('Averaging time, $\\tau $, (sec)')
plt.ylabel('Allan deviation, $\sigma _(\\tau )$')
plt.title(title)

plt.legend()
plt.grid(linestyle= '--', which= 'both')
plt.show()

#! /usr/bin/env python

# Written by Vasaant S/O Krishnan Friday, 19 May 2017
# Run without arguments for instructions.

import sys
usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "# Script to read in file of the CODA format and perform some basic"
    print "# statistical computations. An index.txt and chain.txt file must be"
    print "# provided and the script will automatically identify them for internal"
    print "# use. Options are:"
    print ""
    print "# print = Outputs mean, std and confidence interval (default 95%)."
    print "# var   = Specify your required variable for hist, trace."
    print "# per   = Specify your required confidence interval (requires var=)."
    print "# hist  = Plot histogram (requires var=)."
    print "# bins  = Choose bin size (default bins=100)"
    print "# trace = Trace plot (requires var=)."
    print ""
    print " -->$ coda-script.py CODAindex.txt CODAchain.txt per=xx var=xx bins=xx print hist trace"
    print ""
    exit()

import re
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab



#=====================================================================
#   Define variables.
#
ints         = '\s+?([+-]?\d+)'              # Integers for regex
floats       = '\s+?([+-]?\d+(?:\.\d+)?)'    # Floats or int
codaFiles    = []                            # CODAindex and CODAchain files
indexFileFnd = False                         # CODAindex file identified?
chainFileFnd = False                         # CODAchain file identified?
indexCodes   = {}                            # Dictionary containing CODAindex info.
# chainIndx    = []                          # Indexes/Column 1 of CODAchain.txt file
chainData    = []                            #    Data/Column 2 of CODAchain.txt file
percentile   = 95.0                          # Default percentile
bins         = 100                           # Default number of bins for histogram
reqIndxCode  = ''                            # User requested varible for hist, trace
#=====================================================================



#=====================================================================
#   Determine which are the CODAindex and CODAchain files and
#   automatically assign them to their respective variables.
#
for i in usrFile:
    codaSearch = re.search('.txt',i)
    if codaSearch:
        codaFiles.append(i)

if len(codaFiles) == 2:    # Assuming 1 chain  and 1 chain file
    for j in codaFiles:
        with open(j,'r') as chkTyp:    # Run a quick check on the first line only
            firstLine = chkTyp.readline()
            codaIndex = re.search('^(\S+)' + ints   + ints + '$', firstLine)
            codaChain = re.search('^(\d+)' + floats +        '$', firstLine)
            if codaIndex:
                indexFile = j
                indexFileFnd = True
            if codaChain:
                chainFile = j
                chainFileFnd = True
else:
    print "Insfficient files of CODA*.txt format."
    print "Check your input files."
#=====================================================================



#=====================================================================
#   Determine percentile
#
for i in usrFile:
    userPercentile = re.search('per=([+-]?\d+(?:\.\d+)?)',i)
    if userPercentile:
        percentile = abs(float(userPercentile.group(1)))
        usrFile.append('print')
#=====================================================================



#=====================================================================
#   Determine user requested variable from CODAIndex file
#
for i in usrFile:
    userReqCodaIndx = re.search('var=(\S+)',i)
    if userReqCodaIndx:
        reqIndxCode = str(userReqCodaIndx.group(1))

#   ... same for number of bins:
for i in usrFile:
    userReqBins = re.search('bins=(\d+)',i)
    if userReqBins:
        bins = int(userReqBins.group(1))
        usrFile.append('hist')
#=====================================================================



if indexFileFnd and chainFileFnd:
    #=====================================================================
    #    Harvest index file for the variable list and corresponding
    #    [start,stop] coords:
    #
    for line in open(indexFile, 'r'):
        reqIndex = re.search('^(\S+)' + ints   + ints + '$', line)
        if reqIndex:
            key   =  str(reqIndex.group(1))
            value = [int(reqIndex.group(2)), int(reqIndex.group(3))]
        indexCodes[key] = value

    maxElement = max(indexCodes, key = indexCodes.get)    # The key with the largest value
    chainLen   = max(indexCodes[maxElement])              # The largest value (expected amt. of data)
    #=====================================================================



    #=====================================================================
    #    I thought that initialising the arrays before filling them
    #    would be faster. It is not.
    #
    # chainIndx = np.zeros(chainLen)
    # chainData = np.zeros(chainLen)
    # with open(chainFile, 'r') as harvestVals:
    #     for i in range(chainLen):
    #         currLine = harvestVals.readline()
    #         reqChain = re.search('^(\d+)' + floats + '$', currLine)
    #         if reqChain:
    #             chainIndx[i] =   int(reqChain.group(1))
    #             chainData[i] = float(reqChain.group(2))
    #=====================================================================



    #=====================================================================
    #    Harvest chain file
    #
    for line in open(chainFile, 'r'):
        reqChain = re.search('^(\d+)' + floats + '$', line)
        if reqChain:
            #chainIndx.append(  int(reqChain.group(1)))
            chainData.append(float(reqChain.group(2)))
    #chainIndx = np.array(chainIndx)
    chainData = np.array(chainData)
    #=====================================================================



    #=====================================================================
    #    Basic check on the harvest by comparing harvested vs. expected
    #    no. of data.
    #
    if len(chainData) != chainLen:
        print "    Warning! "
        print "    %10d lines expected  from %s."%(chainLen,indexFile)
        print "    %10d lines harvested from %s."%(len(chainData),chainFile)
    #=====================================================================



    #=====================================================================
    #    Output some basic statistics to the terminal.
    #
    if 'print' in usrFile:
        print "\n%20s %10s %10s"%("mean","std",str(percentile)+"%")
        for i in indexCodes:
            strtIndx = indexCodes[i][0] - 1    # Python starts from 0. CODAindex from 1
            stopIndx = indexCodes[i][1]        # ... but np.array needs this to get to the end

            npPerTile = np.percentile(chainData[strtIndx:stopIndx],[0,percentile])
            minPer    = npPerTile[0]
            maxPer    = npPerTile[1]
            print "%8s  %10.4f %10.4f %6d, %6.3f"%(i, chainData[strtIndx:stopIndx].mean(),
                                                      chainData[strtIndx:stopIndx].std(),
                                                     minPer,maxPer
                                                  )
        print ""
    #=====================================================================



    #=====================================================================
    #    Trace plot that gives the variable value as a function of its
    #    rank (or position in the chain)
    #
    if 'trace' in usrFile:
        if reqIndxCode != '':
            for i in indexCodes:
                if reqIndxCode == i:
                    strtIndx = indexCodes[i][0] - 1    # Python starts from 0. CODAindex from 1
                    stopIndx = indexCodes[i][1]        # ... but np.array needs this to get to the end
                    traceRank = range(stopIndx-strtIndx)
                    plt.plot(traceRank,chainData[strtIndx:stopIndx])
                    plt.xlabel('Rank')
                    plt.ylabel('Variable: '+i)
                    plt.show()
        else:
            print "No variable selected by user for trace plot."
    #=====================================================================



    #=====================================================================
    #    Histogram
    #
    if 'hist' in usrFile:
        if reqIndxCode != '':
            for i in indexCodes:
                if reqIndxCode == i:
                    strtIndx = indexCodes[i][0] - 1    # Python starts from 0. CODAindex from 1
                    stopIndx = indexCodes[i][1]        # ... but np.array needs this to get to the end
                    [n, bins, patches] = plt.hist(chainData[strtIndx:stopIndx],
                                                  bins    =  bins,
                                                  normed  =  True,
                                                  histtype= 'step'
                                                  )

                    y = mlab.normpdf(bins, chainData[strtIndx:stopIndx].mean(),
                                           chainData[strtIndx:stopIndx].std()
                                     )

                    npPerTile = np.percentile(chainData[strtIndx:stopIndx],[0,percentile])
                    maxPer    = npPerTile[1]
                    plt.axvline(x=maxPer, color='k', label=str(percentile)+'%',ls=':',lw=0.8)

                    plt.plot(bins,y,'--')
                    plt.ylabel('Variable: '+i)
                    plt.legend(frameon=False)
                    plt.show()
        else:
            print "No variable selected by user for histogram."
    #=====================================================================

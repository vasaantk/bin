#! /usr/bin/env python

# Written by Vasaant S/O Krishnan Friday, 19 May 2017
# Run without arguments for instructions.

import sys
usrFile = sys.argv[1:]

if len(usrFile) == 0:
    print ""
    print "# Script to read in file of the CODA format and plot a multivariate"
    print "# distribution with contours."
    print "# An index.txt and chain.txt file must be provided and the script"
    print "# will automatically identify them for internal use. Options are:"
    print ""
    print "# samp = Sample chain.txt data at this frequency (computational consideration)."
    print ""
    print " -->$ coda-cont.py CODAindex.txt CODAchain.txt samp=xx"
    print ""
    exit()

import re
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns



#=====================================================================
#   Define variables.
#
ints         = '\s+?([+-]?\d+)'              # Integers for regex
#floats       = '\s+?([+-]?\d+(?:\.\d+)?)'    # Floats or int
floats       = '\s+?([+-]?\d+(?:\.\d+)?|\.\d+)([eE][+-]?\d+)?'    # Floats or int or scientific
codaFiles    = []                            # CODAindex and CODAchain files
indexFileFnd = False                         # CODAindex file identified?
chainFileFnd = False                         # CODAchain file identified?
indexCodes   = {}                            # Dictionary containing CODAindex info.
# chainIndx    = []                          # Indexes/Column 1 of CODAchain.txt file
chainData    = []                            #    Data/Column 2 of CODAchain.txt file
varOne       = ''                            # x data
varTwo       = ''                            # y data
#=====================================================================



#=====================================================================
#   Determine which are the CODAindex and CODAchain files and
#   automatically assign them to their respective variables.
#
for i in usrFile:
    codaSearch = re.search('.txt',i)
    if codaSearch:
        codaFiles.append(i)

if len(codaFiles) == 2:    # Assuming 1 index and 1 chain file
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
#   Determine user requested variable from CODAIndex file
#
for i in usrFile:
    userReqCodaIndx = re.search('var=(\S+),(\S+)',i)
    if userReqCodaIndx:
        varOne = str(userReqCodaIndx.group(1))
        varTwo = str(userReqCodaIndx.group(2))
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

    if   len(indexCodes)  < 2:
        print "Insufficient variables in %s for contour plot."%(indexFile)
        contVarsOk = False
    elif len(indexCodes) == 2:
        varOne = indexCodes.keys()[0]
        varTwo = indexCodes.keys()[1]
        contOne = indexCodes[varOne]
        contTwo = indexCodes[varTwo]
        contVarsOk = True
    else:
        if varOne == '' or varTwo == '':
            print "Manually select variables for contour plot."
            contVarsOk = False
        else:
            contOne = indexCodes[varOne]
            contTwo = indexCodes[varTwo]
            contVarsOk = True
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
    #    Contour plot
    #
    #
    if contVarsOk:
        dataOne = chainData[contOne[0]-1:contOne[1]]    # Python starts from 0. CODAindex from 1
        dataTwo = chainData[contTwo[0]-1:contTwo[1]]

        # Ensure same amount of data from both variables
        if (contOne[0]-contOne[1]) != (contTwo[0]-contTwo[1]):
            print "    %10d lines harvested from %s."%(len(dataOne),varOne)
            print "    %10d lines harvested from %s."%(len(dataTwo),varTwo)
        else:
            # This section to get data to the ~100s for computational consideration...
            if len(dataOne) >= 1000:
                sampleFactor = 10**int(np.floor(np.log10(len(dataOne)) - 2))
            elif len(dataOne) > 500 and len(dataOne) < 1000:
                sampleFactor = int(len(dataOne)/5.0)
            else:
                sampleFactor = 1

            # ... unless you want a customised option:
            for i in usrFile:
                userReqSamp = re.search('samp=(\d+)',i)
                if userReqSamp:
                    if int(userReqSamp.group(1)) < len(dataOne):
                        sampleFactor = int(userReqSamp.group(1))

            dataOne  = dataOne[0::sampleFactor]    # Select data at intervals
            dataTwo  = dataTwo[0::sampleFactor]
            dataComb = {varOne:dataOne,            # Apparently jointplot likes dict format
                        varTwo:dataTwo}
            sns.jointplot(x=varOne,y=varTwo,data=dataComb,kind="kde").set_axis_labels(varOne,varTwo)
            plt.show()
    #=====================================================================

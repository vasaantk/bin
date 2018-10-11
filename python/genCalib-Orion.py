#! /usr/bin/env python

# genCalib-Orion.py is based on Sharmila's "Callibrators and
# observation catalogues.ipynb" from her email on 17 September 2018.
# Here I've modified it to determine the gaincal and bpcal for Bill's
# Orion sources from email 01 October 2018.
#
# Written by Vasaant S/O Krishnan on Wednesday, 10 October 2018
#
# Usage:
#        -->$ cat target.csv | genCalib-Orion.py -w
#
# -w = (w)rite output .csv format for katsdpcatalogues
#
# Where target.csv has format:
#       Abell 33, radec target, 00:27:07.0, -19:30:24



import katpoint
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator, MultipleLocator
import matplotlib.dates as mdates
from astropy.time import Time
import re
import sys



#======================================================================
#    Setup some variables
refAnt = katpoint.Antenna('m000, -30.71292524, 21.44380306, 1035')    # the MeerKAT reference point
refAnt.ref_observer.horizon = '20:00:00'                              # horizon set to 20 degrees

cat_path  = '/home/vasaantk/Applications/katsdp/katsdpcatalogues/'
prop_id   = 'SCI-20180924-FC-01'
PI        = 'Fernando Camilo'
PI_email  = 'fernando@ska.ac.za'
ska_email = 'sharmila@ska.ac.za'
purpose   = 'Science verification - Orion'
phone     = ''



#======================================================================
#    Harvest user defined variables and process
writeOutput = False
usrInp = sys.argv[1:]
if '-w' in usrInp:
    writeOutput = True

header = []
header.append(': '.join(['# ObserverID'      , ska_email]))
header.append(': '.join(['# csv_description' , purpose]))
header.append(': '.join(['# PI_name'         , PI]))
header.append(': '.join(['# PI_email'        , PI_email]))
header.append(': '.join(['# phone'           , phone]))

cal_filename   = cat_path +  'cals_Lband.csv'
bpcal_filename = cat_path + 'three_calib.csv'
cal_cat        = katpoint.Catalogue(file(  cal_filename))
bpcal_cat      = katpoint.Catalogue(file(bpcal_filename))

if not writeOutput:
    print "%23s  %27s %15s %15s      %-27s %5s"%('Name', 'Tags', 'RA', 'dec', 'Info', 'Sep (deg)')
    print 127*'-'
else:
    for title in header:
        print title

for line in sys.stdin:
    primary_target = katpoint.Target(line)
    gaincal, gsep  =   cal_cat.closest_to(primary_target, antenna= refAnt)
    bpcal,   bsep  = bpcal_cat.closest_to(primary_target, antenna= refAnt)

    if not writeOutput:
        priTArr = [i.replace('tags=radec ','') for i in str(primary_target).split(',')]
        gainArr = [i.replace('tags=radec ','') for i in str(       gaincal).split(',')]
        bpClArr = [i.replace('tags=radec ','') for i in str(         bpcal).split(',')]

        priTArr[2] = ' '.join([':'.join([i.zfill(2) for i in priTArr[2].split()[0].replace(':', ' ').split()]), ':'.join([i.zfill(2) for i in priTArr[2].split()[1].replace(':', ' ').split()])])
        gainArr[2] = ' '.join([':'.join([i.zfill(2) for i in gainArr[2].split()[0].replace(':', ' ').split()]), ':'.join([i.zfill(2) for i in gainArr[2].split()[1].replace(':', ' ').split()])])
        bpClArr[2] = ' '.join([':'.join([i.zfill(2) for i in bpClArr[2].split()[0].replace(':', ' ').split()]), ':'.join([i.zfill(2) for i in bpClArr[2].split()[1].replace(':', ' ').split()])])

        priTArr_ra  = priTArr[2].split()[0]
        gainArr_ra  = gainArr[2].split()[0]
        bpClArr_ra  = bpClArr[2].split()[0]

        priTArr_dec = priTArr[2].split()[1]
        gainArr_dec = gainArr[2].split()[1]
        bpClArr_dec = bpClArr[2].split()[1]

        print "%23s  %27s %15s %15s %-36s"      %(priTArr[0], priTArr[1], priTArr_ra, priTArr_dec, priTArr[3])
        print "%23s  %27s %15s %15s %-36s %5.1f"%(gainArr[0], gainArr[1], gainArr_ra, gainArr_dec, gainArr[3], gsep)
        print "%23s  %27s %15s %15s %-36s %5.1f"%(bpClArr[0], bpClArr[1], bpClArr_ra, bpClArr_dec, bpClArr[3], bsep)
        print ""

    else:
        catalogue = katpoint.Catalogue()
        catalogue.add(primary_target)
        catalogue.add(bpcal)
        catalogue.add(gaincal)
        catalogue.antenna = refAnt

        for source in catalogue.targets:
            print source.description

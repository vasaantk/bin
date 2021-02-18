#! /usr/bin/env python3

# hyperef.py opens an input .html/.htm file and checks the hyperlinks
# that are contained within to determine if the absolute or relative
# links exist.
#
# Needs to be run from outside the directory structure
#
# Vasaant Krishnan Thu 18/02/2021

import sys
import re

cmd = sys.argv[1:]
if len(cmd) == 0:
    print("# Usage:")
    print("#        -->$ hyperef.py /full/path/to/source.htm")
    sys.exit()


######################################################################
#    Functions
def grephyperlinks(inputString, prefix, postfix):
    prefixLen = len(prefix)
    findHyperLink = re.search((prefix+'.*'+postfix), inputString)
    if findHyperLink:
        targetString = findHyperLink.group(0)
        prefixIndex = findIndex(targetString, prefix)
        postfixIndex = findIndex(targetString, postfix)

        # Check if the counts of href starts match with counts of stop
        if len(prefixIndex) == len(postfixIndex):
            for j in range(len(prefixIndex)):
                prefixEnd = prefixIndex[j] + prefixLen
                postfixStart = postfixIndex[j]
                linkInfo = targetString[prefixEnd:postfixStart]
                yield linkInfo
        else:
            print("Check format of line: %s"%inputString)


def findIndex(inputString, find):
    stringLen = range(len(inputString))
    index = [i for i in stringLen if inputString.startswith(find, i)]
    return index


def checkLinks(foundLinks, usrInp):
    currFileDir = '/'.join(usrInp.split('/')[0:-1])+'/'
    thisFile = usrInp.split('/')[-1]
    for linkAndText in foundLinks:
        if len(linkAndText.split('>')) == 2:
            linkOnly = linkAndText.split('>')[0]
            # # Currently not using this var:
            # textOnly = linkAndText.split('>')[1]
            rawLink = linkOnly.strip('=').strip('"').strip("'")

            # Determine if the foundLinks is relative or not
            linkFilePath, isRelative = checkForRelativeLink(rawLink)

            # The relative link could be within the current file
            if not linkFilePath:
                linkFilePath = thisFile

            try:
                linkFile = open(currFileDir+linkFilePath, 'r')
                linkFile.close()
                if not isRelative:
                    print("Found: %s"%rawLink)
                    # pass
                else:
                    relativeLink = isRelative
                    definition = '<a\s+name="'+relativeLink+'"'+'\s+'+'id="'+relativeLink+'"'+'></a>'
                    foundRelativeLink = checkRelativeLinkName(currFileDir+linkFilePath,
                                          relativeLink, definition)
                    if foundRelativeLink:
                        print("Found: %s %s"%(rawLink, '(relative)'))
                        # pass
                    else:
                        print("*** Check for %s in %s"%(definition, linkFilePath))

            except FileNotFoundError:
                if not isRelative:
                    print("*** %s does not exist"%rawLink)
                else:
                    print("*** %s does not exist"%rawLink.split('#')[0])


def checkForRelativeLink(rawLink):
    findRelativeLink = rawLink.split('#')
    # This is a relative link
    if len(findRelativeLink) == 2:
        linkPath = findRelativeLink[0]
        relativeLink = findRelativeLink[1]
        return linkPath, relativeLink
    # This is a normal link
    elif len(findRelativeLink) == 1:
        linkPath = rawLink
        relativeLink = False
        return linkPath, relativeLink


def checkRelativeLinkName(rawLink, relativeLink, definition):
    with open(rawLink, 'r') as file:
        relativeLinkExists = False
        for line in file:
            examineRelativeLink = re.search(definition, line)
            if examineRelativeLink:
                relativeLinkExists = True
        if relativeLinkExists:
            return True


######################################################################
#    Code begins here
usrInp = cmd[0]

# The chars on either side of the hyperlink reference
prefix = '<a href'
postfix = '</a>'

with open(usrInp, 'r') as file:
    print('######################################################################')
    print('                     Processing hyperlinks in:')
    print('%s'%usrInp)
    print('######################################################################')
    for line in file:
        foundLinks = grephyperlinks(line, prefix, postfix)
        checkLinks(foundLinks, usrInp)

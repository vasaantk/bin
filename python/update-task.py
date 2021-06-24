#! /usr/bin/env python3

# update-task.py searches the input Help file for the specified task
# number, and updates the QA status from Reqd to Vfied.
#
# Also see updatetask (a bash wrapper).
#
# Vasaant Krishnan Wed 23/06/2021

import sys
import re


def getQArange(helpme):
    # The vast majority of .htm pages have only one declaration of the
    # qaStart string
    qaStart = "\<table\ cellspacing=\"0\"\ width=\"100\%\"\>"
    qaStop = "</table>"
    startRange = []
    stopRange = []

    with open(helpme, 'r') as file:
        lineNum = 1
        for line in file:
            if re.search(qaStart, line):
                startRange.append(lineNum)
            if re.search(qaStop, line):
                stopRange.append(lineNum)
                # Exit once the end of the QA section is reached
                return [startRange[0], stopRange[0]]
            lineNum += 1


def getjiras(helpme, qaEndLineNum, updateTask):
    lineNum = 1
    reqds = []
    vfieds = []
    taskNum = "({0})".format(updateTask)
    with open(helpme, 'r') as file:
        for line in file:
            zoneReqd = re.search('Reqd', line)
            zoneVfied = re.search('Vfied', line)

            if zoneReqd:
                startZone = True
            if zoneVfied:
                startZone = False

            # Need to modify this to work on strings as well
            jiraNum = re.findall("\(\d+\)", line)
            if jiraNum and startZone:
                reqds += jiraNum
            if jiraNum and not startZone:
                vfieds += jiraNum
            if lineNum == qaEndLineNum:
                taskIndex = reqds.index(taskNum)
                vfieds.append(reqds.pop(taskIndex))

                formatReqds = "".join(splitlongtasklines(reqds))
                formatVfieds = "".join(splitlongtasklines(vfieds))

                # Exit once the end of the QA section is reached
                return formatReqds, formatVfieds

            lineNum += 1


def splitlongtasklines(taskline):
    lineLen = 10
    if len(taskline) > lineLen:
        taskschunk = []
        multitasklines = [taskline[i:i+lineLen]
                          for i in range(0, len(taskline), lineLen)]
        for i in multitasklines:
            taskschunk.append("".join(i)+"<br />"+"\n")
        taskschunk[-1] = taskschunk[-1].replace("<br />", "")
        taskschunk[-1] = taskschunk[-1].replace("\n", "")
        return taskschunk
    else:
        return taskline


def updateQAsection(reqds, vfieds):
    newQA = \
        """   <table cellspacing="0" width="100%">
    <col width="74" />
    <col width="707" />
    <tr style="vertical-align: top;">
      <?rh-cbt_start condition="QA" ?>
      <td colspan="2" style="padding-right: 10px; padding-left: 10px;" width="781">
        <p class="QAStatus">QA Status: PageNotVerified</p>
      </td>
      <?rh-cbt_end ?>
    </tr>
    <tr style="vertical-align: top;">
      <?rh-cbt_start condition="QA" ?>
      <td style="padding-right: 10px; padding-left: 10px;" width="74">
        <p class="QAStatus">Reqd:</p>
      </td>
      <?rh-cbt_end ?>
      <?rh-cbt_start condition="QA" ?>
      <td class="QAStatus" style="padding-right: 10px; padding-left: 10px;" width="707">
        <p class="QAStatus">
          {reqdsJiras}
        </p>
      </td>
      <?rh-cbt_end ?>
    </tr>
    <tr style="vertical-align: top;">
      <?rh-cbt_start condition="QA" ?>
      <td style="padding-right: 10px; padding-left: 10px;" width="74">
        <p class="QAStatus">Vfied:</p>
      </td>
      <?rh-cbt_end ?>
      <?rh-cbt_start condition="QA" ?>
      <td style="padding-right: 10px; padding-left: 10px;" width="707">
        <p class="QAStatus">
          {vfiedsJiras}
        </p>
      </td>
      <?rh-cbt_end ?>
    </tr>
    </table>""".format(reqdsJiras=reqds, vfiedsJiras=vfieds)
    print(newQA)


def genHelpFile(helpme, updateTaskNumber, beginLine, endLine):
    with open(helpme, 'r') as file:
        lineNum = 1
        for line in file:
            if lineNum < beginLine:
                print(line, end='')
            if lineNum == beginLine:
                reqds, vfieds = getjiras(helpFile, qaEndLine, updateTaskNumber)
                updateQAsection(reqds, vfieds)
            if lineNum > endLine:
                print(line, end='')
            lineNum += 1


# =====================================================================
#    Script starts here
#
helpFile = sys.argv[1]
taskNumber = sys.argv[2]
qaRange = getQArange(helpFile)
qaBegLine = qaRange[0]
qaEndLine = qaRange[1]
genHelpFile(helpFile, taskNumber, qaBegLine, qaEndLine)

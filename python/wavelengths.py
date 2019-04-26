#! /usr/bin/env python

print "This script can convert wavelengths to frequencies or vice versa."
speedlight = raw_input("Would you like an (1)exact value of the speed of light, or the (2)rounded value?\n" )
if speedlight == "1":
    sol = 299792458.00
elif speedlight == "2":
    sol = 3e8
else:
    print "Please choose a valid option."

#attempting split up of formulae into functions
def bands(wavelength):
#    targetband == ()
    if wavelength >=1000:
        return "Theoretically long Radio wave"
    if wavelength <= 1000 and wavelength >= 0.01:
        return "Radio Wave"
    elif wavelength <= 0.01 and wavelength >= 0.00001:
        return "Microwave"
    elif wavelength <= 0.00001 and wavelength >= 0.0000005:
        return "Infra Red"
    elif wavelength <= 0.0000005 and wavelength >= 0.00000001:
        return "Visible Light"
    elif wavelength <= 0.00000001 and wavelength >= 0.0000000001:
        return "Ultra Violet"
    elif wavelength <= 0.0000000001 and wavelength >= 0.000000000001:
        return "X-Rays"
    elif wavelength <= 0.000000000001:
        return "Gamma Rays"
    else:
        return "Not within a range generally observed"


def wavelength():
    counter = 0
    print "Ok, Please enter your wavelength in Metres. (syntax for scientific notation is e.g. '1000 = 1e3' or '0.001 = 1e-3')"
    wavelength = float(raw_input ())
    answerfreq = sol / wavelength
    print "the frequency is %r Hz" % (answerfreq)
    print "%r" % bands(wavelength)  + ' at ' + '%.2e' % answerfreq + ' Hz '

def frequency():
    print "Ok, Please enter your frequency in Hz. (syntax for scientific notation is e.g. '1000 = 1e3' or '0.001 = 1e-3')"
    frequency = float(raw_input ())
    wavelength = sol / frequency
    print "the wavelength is %rm " % wavelength
    print "%r" % bands(wavelength) + ' at ' + '%.2e' % wavelength + ' m '


choice_options = {
    1: wavelength,
    2: frequency,
}

choice = 0
while choice not in choice_options:
    print "do you have (1) a wavelength, or (2) a frequency?"
    choice = int(raw_input())


choice_options[choice]()

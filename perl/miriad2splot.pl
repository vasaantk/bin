#!/usr/bin/perl -w

# Perl script for converting files written in miriad's text output format into
# splot format.
#
# History
#
# 1.0 - Initial version, based on xspec2splot.pl version 1.2

# Standard perl modules
use Carp;
use Getopt::Long;
use strict;

# Non-standard perl modules
use notastro;

# Command line options
my $help=0;
my $imspec=0;
my $input='miriad.log';
my $label;
my $mx=0;
my $options;
my $output='miriad.spt';
my $scale=1.0;
my $skip=0;
my $stokes;
my $title='Miriad Spectrum';
my $version=0;
my $xlabel='Velocity w.r.t. LSR (kms\\u-1\\d)';
my $ylabel='Flux Density (Jy)';

GetOptions('help!'=>\$help,
	   'imspec!'=>\$imspec,
           'input=s'=>\$input,
	   'label=s'=>\$label,
	   'mx!'=>\$mx,
	   'options=s'=>\$options,
           'output=s'=>\$output,
	   'scale=f'=>\$scale,
	   'skip=i'=>\$skip,
	   'stokes=s'=>\$stokes,
	   'title=s'=>\$title,
           'version!'=>\$version,
	   'xlabel=s'=>\$xlabel,
	   'ylabel=s'=>\$ylabel);

# Global variables
my $VERSION=1.3;
my $DATE='27 March 2012';
my (@data, @vel, $vmin, $vmax, $first, $last);

# If the user requires it print some help
if ($help) {
  print <<HELP;
  This perl script is intended for converting files written in miriad text
  output format into splot format.  For automatic processing of a large number
  of files the script can take some of its options from a file (specified
  with --options).  The format of this file should be as follows:
    file: <native format file>
    <option1>=<value1>
    <option2>=<value2>
    file: <native format file>
     ...
  where the valid options are imspec, scale, stokes, style, title, xlabel 
  and ylabel.  For the imspec option, it doesn't matter what value is placed
  after the =, it is ignored.

      Usage : $0 [options]

    The following options are available
      --help                 Produce this output.
      --imspec               The imspec task produces a different format
                             output from uvspec (default=false).
      --input=<filename>     The miriad text output file to be converted
                             (default=miriad.log).
      --label=<string>       The label (top right hand corner) to put on the
                             plot (default no label).
      --mx                   The domx script for multibeam MX processing
                             produces output similar to miriad files and
                             using this option we can convert them to 
                             splot format (default=false).
      --options=<filename>   Read scaling and plot title information from
                             a file.  This is mainly useful if the script
                             is being run from in some sort of automatic
                             mode (default=none).  Values in the options 
                             file will override any command line specification
                             of the same option.
      --output=<filename>    The name of the splot format file to write
                             the data into (default=miriad.spt).
      --scale=<number>       Scale the amplitude of the data by this
                             number (default=1.0).
      --skip=<integer>       Skip this number of lines at the start of the
                             file, due to header information, or similar 
                             (default=0).
      --stokes=<I,Q,U,V>     If this option is specified the stokes parameter
                             is specified in the splot file.  This is 
                             required for the various splot polarization 
                             options.  If it is not present then this keyword
                             is not writen to the splot file (default none).
      --title=<string>       The title for the plot (default "Miriad 
                             spectrum").
      --version              Give the version number of the script.
      --xlabel=<string>      The label to put on the x axis of the
	                     plot (default='velocity w.r.t. LSR (kms\\u-1\\d)')
      --ylabel=<string>      The label to put on the y axis of the
	                     plot (default='Flux Density (Jy)').
HELP
} elsif ($version) {
  print <<VERSION;
  $0 ; Version : $VERSION ; Date : $DATE
VERSION
}
if ($help || $version) {exit(0);}

# Read any options file
if (defined $options) {
  open (OPTIONS, $options) or
    croak "Problem opening options file $options ($!)\n";
  my $get_options = 0;
  while(<OPTIONS>) {
    if (/^file:\s*(.+)$/) {
      
      # File name specified, check if it matches the current one
      my $optfile = $1; 
      if ($optfile =~ m!/([^/]+)$!) {
	$optfile = $1;
      }
      my $curfile = $input;
      if ($curfile =~ m!/([^/]+)$!) {
	$curfile = $1;
      }
      $get_options = ($optfile ne $curfile) ? 0 : 1;
    } elsif ($get_options && (/(\S+)\s*=\s*(.+)/)) {
      my $option = lc $1;
      if ($option eq 'imspec') {
	$imspec = 1;
	print "--imspec (from options file)\n";
      } elsif ($option eq 'label') {
	$label = $2;
	print "--label=$label (from options file)\n";
      } elsif ($option eq 'scale') {
	$scale = $2;
	print "--scale=$scale (from options file)\n";
      } elsif ($option eq 'skip') {
	$skip = $2;
	print "--scale=$scale (from options file)\n";
      } elsif ($option eq 'stokes') {
	$stokes = $2;
	print "--stokes=$stokes (from options file)\n";
      } elsif ($option eq 'title') {
	$title = $2;
	print "--title=$title (from options file)\n";
      } elsif ($option eq 'xlabel') {
	$xlabel = $2;
	print "--xlabel=$xlabel (from options file)\n";
      } elsif ($option eq 'ylabel') {
	$ylabel = $2;
	print "--ylabel=$ylabel (from options file)\n";
      }
    }
  }
}

open(INPUT, $input) or 
  croak "Problem opening miriad text output format file $input ($!)\n";

my $n = 0;
while(<INPUT>) {
  if ($n < $skip) {
    # Do nothing, skip this line
  } elsif ($imspec) {
    if (/^\s*(\S+)\s+      # The line number
        (\S+)\s+           # The velocity
        (\S+)\s+           # The amplitude
        (\S+)\s+           # Phase?
        (\S+)\s*$/x) {     # Some other number?
      push @vel, $2;
      push @data, $3;
    } else {
      carp "The format of the the line below doesn't match that expected\n".
	"$_";
      if (scalar @vel) {
	printf "Terminating reading of the input file after $n lines\n";
	printf "Output file will be written.\n";
      }
      last;
    }
  } elsif ($mx) {
    if (/^\s*(\S+)\s+      # The line number
        (\S+)\s+           # The velocity
        (\S+)\s*$/x) {     # The amplitude
      push @vel, $2;
      push @data, $3;
    } else {
      croak "The format of the the line below doesn't match that expected\n".
	"$_";
    }
  } else {
    if (/^\s*(\S+)\s+      # The velocity
        (\S+)\s*$/x) {     # The amplitude
      push @vel, $1;
      push @data, $2;
    } else {
      croak "The format of the the line below doesn't match that expected\n".
	"$_";
    }
  }
  $n++;
}
close(INPUT);


open(OUTPUT, '>'.$output) ||
  croak "Problem opening splot output file $output ($!)\n";

# Determine the minimum and maximum of the velocity and amplitude axis
($vmax, $vmin) = maxmin(@vel);
my ($amax, $amin) = maxmin(@data);
my $delta = $amax-$amin;
$amax += 0.1*$delta;
$amin -= 0.1*$delta;

# Output the splot file header
print OUTPUT "heading\n$title\n";
if (defined $stokes) {
  if (($stokes eq 'I') || ($stokes eq 'Q') || ($stokes eq 'U') || 
      ($stokes eq 'V')) {
    print OUTPUT "stokes $stokes\n";
  } else {
    carp "Unrecognised stokes parameter value; $stokes\n";
  }
}
if (defined $label) {
  print OUTPUT "label\n$label\n";
}
print OUTPUT "xlabel\n$xlabel\n";
print OUTPUT "ylabel\n$ylabel\n";
printf OUTPUT "baxis\n%12.6f\n%12.6f\n", $vmin, $vmax;
printf OUTPUT "laxis\n%12.6f\n%12.6f\n", $scale*$amin, $scale*$amax;
printf OUTPUT "data\n%5d\n", scalar @data;

# Output the splot file data
for (my $i=0 ; $i<scalar @data ; $i++) {
  printf OUTPUT "%12.6f %12.6f\n", $vel[$i], $scale*$data[$i];
}
print OUTPUT "end\n";
close OUTPUT;

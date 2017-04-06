#!/usr/bin/perl -w

# This perl script reads a simple format of text file and plots the
# data stored in the text file using PGPLOT. Simon Ellingsen.

=head1 NAME

splot.pl - produce spectral line plots for a simple format text file

=head1 SYNOPSIS

  splot.pl --device=temp.ps/ps --stack <filenames>

  For more information on command line options :

  splot.pl --help

  For more information on the splot file format, read below.

=head1 DESCRIPTION

This perl script is intended to allow flexible plotting and combining
of spectral line data.  It reads a simple format of text file and
plots the data stored in the text file using PGPLOT.  It allows you to
add text to the spectrum in any location and also simple line
graphics.  It can cope with multiple spectra either in one file, or
separate files and plot them in a variety of ways.  When plotting
mulitple spectra on the one page you may have to fiddle with the
settings of the character size and gap as these are set to sensible
values for one plot per page and they don't necessarily suit multiple
plots per page, or different aspect ratios.

Adding further functionality, or features to the script should be
relatively easy, provided you are familiar with perl and PGPLOT.
Please send any improvements, or suggestions for improvements to the
author.

=head1 AUTHOR

Simon Ellingsen (Simon.Ellingsen@utas.edu.au)

=head1 TODO

Add a command for writing text information at the side of the plot

Add the ability to specify the command line options at the start of
the file

Add ability to layout spectra in a grid format.

Add ability to produce contour plots of velocity/channel ranges.

=head1 SPLOT FORMAT

splot.pl uses a simple keyword value format of input and perl regexp
to read the information from the file.  This means that the format is
relatively free form, the keywords and values can appear anywhere on a
line, provided they appear in the appropriate order.  Blank lines are
ignored, as are lines starting with a #.  The following keywords
are currently recognised :

=head2 arrow

The next line should contain 4 numbers, being the X,Y of the tail and
head of the arrow respectively, in units of velocity and amplitude.
Any arrow keywords should be after the data they refer to.

=head2 baxis

The next two lines should contain the minimum and maximum values
(respectively) to be displayed upon the bottom (velocity) axis.  This
will also set the range of data displayed.  If this keyword isn't found
in the file then the whole available range of data will be displayed.
Only the first occurrence of baxis is used, subsequent ones are ignored.

=head2 colour <value> || color <value>

Either English or American spelling of colour/color is accepted,
followed by one of the values black, white, red, green, blue, cyan,
magenta or yellow.  This colour is used as the foreground colour for
the plot.

=head2 style <value>

style followed by one of the values solid, dashed, dash_dot, dotted 
or dash_3dot. This line style is used for the spectrum.

=head2 data

This keyword signals that the following region of file contains the
data for a spectrum, the next line contains the number of points in
the spectrum and the lines after that each contain one data point as
a velocity/amplitude pair.  

=head2 end

This keyword signifies the end of the data, it should be consistent
with the number of lines of data specified in the line after the data
statement.

=head2 gauss <colour> || gauss dashed

This keyword signifies that the next line should contain three numbers
defining the position, amplitude and width of a Gaussian.  These will
be plotted in the specifed colour, or as a dashed line (gauss dashed)
unless the --nogauss command line option is used.

=head2 heading

The string on the next line is used as the title for the spectrum.  If
there are multiple heading keywords in the file, the first is used and
subsequent ones are ignored.

=head2 label <value>

The string on the next line is used as a label, placed in the top right corner
of the plot (if the --label option is specified as a command line option.  It
can be used to hold for example stokes parameter information, or transition
information.

=head2 laxis

The next two lines should contain the minimum and maximum values
(respectively) to be displayed upon the left (amplitude) axis.  This
will also set the range of data displayed.  If this keyword isn't found
in the file then the whole available range of data will be displayed.

=head2 line

The next line should contain 4 numbers, being the X,Y of the start and
finish of the line respectively, in units of velocity and amplitude.
Any line keywords should be after the data they refer to.

=head2 raxis

The next two lines should contain the minimum and maximum values
(respectively) to be displayed upon the right axis.  This would normally
be something like an alternative amplitude scale corresponding to the
values of laxis.  If this keyword isn't present the right axis is not
labelled.

=head2 sidetext

The next line should contain the number of lines of text to be printed
at the right hand side of the plot and the subsequent lines contain
the text to be printed.  This text only appears if splot.pl is called
with the --sidetext option.

=head2 stokes <value>

This states what stokes parameter the spectrum has, this information
is required to produce plots of total linear polarization and position
angle and also percentage linear polarization.  Allowed values of the
stokes parameter are I, Q, U, V, L (LCP) and R (RCP).

=head2 taxis

The next two lines should contain the minimum and maximum values
(respectively) to be displayed upon the top axis.  This would normally
be something like a frequency or channel scale corresponding to the
values of baxis.  If this keyword isn't present the top axis is not
labelled.

=head2 text <justification>

The next line should contain 2 numbers being the X,Y coordinates at
which to place the text.  The justification of the text with respect
to the position can be either centre (or center), right or left, if
nothing is specified the default is left. Any text keywords should be
after the data they refer to.  The text information will be written to
the plot, unless the --notext command line option is used.

=head2 xlabel

The string on the next line is used as the X-axis label for the
spectrum.  If there are multiple xlabel keywords in the file, the
first is used and subsequent ones are ignored.

=head2 ylabel

The string on the next line is used as the Y-axis label for the
spectrum.  If there are multiple ylabel keywords in the file, the
first is used and subsequent ones are ignored.

=cut

# Standard modules
use Carp;
use Getopt::Long;
use POSIX qw ( atan );
use strict;

# Additional modules
use Astro::Time qw ( $PI );
use PGPLOT;
use notastro;

# Command line options
my $bottom_boundary=0.15;
my $char_size=1.0;
my $difference=0;
my $gap=0.05;
my $gauss=1;
my $help=0;
my $info=0;
my $label=0;
my $left_boundary=0.175;
my $one=0;
my $maxpol=1.0;
my $normalise=0;
my $pair=0;
my $pgplot_device='/xs';
my $plabel;
my $polarization;
my $print=0;
my $report=0;
my $right_boundary=0.9;
my $scale;
my $sidetext=0;
my $splot=0;
my $stack=0;
my $ticks=0;
my $threshold=1.0;
my $heading;
my $top_boundary=0.85;
my $uncertainty=0.4;
my $write_text=1;
my $version=0;
my $vertical;
my $vmin;
my $vmax;
my $vshift;
my $ymin;
my $ymax;
my $zshift;

# Get the command line options
GetOptions('bottom=f'=>\$bottom_boundary,
	   'char_size=f'=>\$char_size,    # The size of the characters to
	                                  # use on plot headings etc.
	   'device=s'=>\$pgplot_device,   # The PGPLOT device
	   'difference!'=>\$difference,   # Take the difference between 
	                                  # the first two spectra
           'gap=f'=>\$gap,                # The gap (percentage at the top
	                                  # and bottom of the plots
           'gauss!'=>\$gauss,             # Allow the plotting of any specified
	                                  # Gaussians to be superimposed on 
                                          # the data
	   'help!'=>\$help,
	   'info!'=>\$info,               # Output some basic information on
                                          # the splot file
	   'label!'=>\$label,             # If the file has a label defined
	                                  # put it in the corner of the plot
	   'left=f'=>\$left_boundary,     # The boundaries of the plot
	                                  # in world coordinates
           'one_label!'=>\$one,           # Only put one label on the y axis
	                                  # for a stack plot.
	   'maxpol=f'=>\$maxpol,          # The maximum believable percentage 
	                                  # of polarization in the spectrum.
	   'normalise!'=>\$normalise,     # Normalise the spectra for overlay
                                          # plotting.
	   'pair!'=>\$pair,               # The pair option is the same as the
                                          # stack, but consecutive pairs of
                                          # spectra are overlayed.  This is
                                          # useful for stacked plots of
                                          # multiple OH maser transitions, but
                                          # with LCP/RCP overlayed for each
                                          # transition.
	   'plotlabel=s'=>\$plabel,       # If this is defined then use it as
                                          # the plot label (or the first plot label
                                          # for a stacked plot).
           'pol=s'=>\$polarization,       # Plot the spectrum using one of
                                          # of the polarization options
           'print!'=>\$print,             # If used with the --pol=linear, lcp
                                          # --pol=perlinear or --difference
	                                  # option then print out the linear,
	                                  # percentage linear or difference
                                          # spectrum.
           'report!'=>\$report,           # Give some basic details on the 
                                          # velocity range, peak flux density
                                          # and velocity and integrated flux
                                          # density (default=false).
	   'right=f'=>\$right_boundary,
           'scale=f'=>\$scale,            # Scale the flux density by this factor.
	   'sidetext!'=>\$sidetext,       # Leave space on the right of the
	                                  # plot for additional text
                                          # contained in a sidetext command
	   'splot!'=>\$splot,             # This is the same as the print
	                                  # option, the only difference being
                                          # that the output is produced in
                                          # the splot file format
	   'stack!'=>\$stack,	          # Stack multiple data
           'text!'=>\$write_text,         # Allow the plotting of text strings
                                          # on the screen      
           'ticks!'=>\$ticks,             # Don't put ticks on the opposite
	                                  # axes to the labels
           'title=s'=>\$heading,          # Title for the plot.
           'threshold=s'=>\$threshold,    # The threshold above which 
                                          # position angle is calculated for
                                          # a linear polarization plot
                                          # (default=1.0).  If the --report
                                          # option is being used, this
                                          # threshold determines where the 
                                          # velocity range and integrated flux
                                          # are calculated over.
	   'top=f'=>\$top_boundary,
	   'uncertainty=f'=>\$uncertainty,# The percentage uncertainty in
                                          # the polarization calibration
           'version!'=>\$version,
	   'vertical=s'=>\$vertical,      # The velocity at which to place
                                          # a vertical dashed line (or lines)
           'vmin=f'=>\$vmin,              # The minimum velocity to plot on
	                                  # the spectrum
           'vmax=f'=>\$vmax,              # The maximum velocity to plot on
                                          # the spectrum
	   'vshift=f'=>\$vshift,          # A velocity shift to apply to the
	                                  # spectrum
           'ymin=f'=>\$ymin,              # The minimum flux density to plot
	                                  # on the spectrum.
	   'ymax=f'=>\$ymax,              # The maximum flux density to plot
                                          # on the spectrum.
           'zshift=f'=>\$zshift);         # The velocity shift due to Zeeman
                                          # splitting to apply.  A shift
                                          # of this sign will be applied to
                                          # RCP data, for LCP a shift of the
                                          # same magnitude, but opposite
                                          # sign will be used.

# Global variables
my $VERSION=1.23;
my $DATE='5 September 2011';

# If the user requires it print some help
if ($help) {
  print <<HELP;
  This perl script is intended to allow flexible plotting and combining of
  spectral line data.  It reads a simple format of text file and plots the data
  stored in the text file using PGPLOT

      Usage : $0 [options] <splot file(s)>

    The following options are available
      --bottom=<percentage>  The bottom boundary of the plot in world
                             coordinates (default=0.15).
      --char_size=<number>   The size of the characters to be used on the plot
                             headings etc (default = 1.0).
      --device=<PGPLOT dev>  The PGPLOT device on which to produce the output
                             (default = /xs).
      --difference           This option assumes that two spectra have been
                             passed to the program and it calculates the
                             difference between the two spectra (default=false)
      --gap=<percentage>     The percentage gap to leave at the top and bottom
                             of each plot (default=0.05).  Normally 5% (the
                             default is about right, however, for a large
                             number of stacked plots you might want to
                             increase this.
      --gauss                If there are any Gaussian's specified in the splot
                             file, then plot them (default=true).
      --help                 Produce this output.
      --info                 Print some information on the spectra stored
                             in the splot file, rather than displaying the
                             spectra (default=false).
      --label                If the file contains label information print it in the
                             top right corner of the plot (default=false).
      --left=<percentage>    The left-hand boundary of the plot in world
                             coordinates (default=0.175). 
      --one                  Have only one y axis label on a stack plot, 
                             rather than an individual label for each sub-plot
                             (which is the default).
      --maxpol=<percentage>  The maximum believable percentage polarization
                             in the linear polarization spectrum (default 
                             = 100).  In some cases noise or artifacts in 
                             the Q/U spectra can produced linearly polarized
                             intensities greater than the total intensity at
                             the same velocity.  Setting this parameter
                             less than 100 blanks linear polarization at lower
                             levels (say 80%).
      --normalise            Normalise the spectra (so that they have a peak of
                             1), to allow for a different (easy) comparison of the
                             spectral features (default=false).  This option will
                             override any scaling.
      --pair                 This option is similar to the --stack option,
                             but consecutive pairs of spectra are overlayed.
                             So if you have multiple OH maser transitions and
                             want to produce a stack plot, but also want to
                             overlay LCP/RCP for individual transitions, then
                             this option is the one you want (default false).
      --plotlabel=<string>   Put this label at the top right corner of the plot
                             (default none).
      --pol=<pol option>     Plot a polarzation spectrum.  The valid options
                             are :
                               linear - linear intensity and pos. angle
                               perlinear - percentage linear polarization
                               lcp - from stokes I & V produce an LCP spectrum
                               rcp - from stokes I & V produce an RCP spectrum
      --print                If one of the --pol=linear ,--pol=perlinear,
                             --pol=lcp, pol=rcp, or --difference options is 
                             being used then this option will print out the 
                             values for the linear intensity, percentage 
                             linear or difference spectra (default=false).
      --report               Print out information on the velocity range, 
                             peak and integrated flux density and velocity 
                             of the peak (default=false).
      --right=<percentage>   The right-hand boundary of the plot in world
                             coordinates (default=0.90).
      --scale=<factor>       Scale the flux density by this factor
                             (default=no scaling)
      --sidetext             Leave space on the right of the plot for
                             additional text contained in any sidetext 
                             commands in the plot (default=don't plot side
                             text).
      --splot                This is the same as the --print option, the
                             difference being that the output is in 
                             splot format (default=false).
      --stack                Stack multiple data entries, rather than
                             overlaying the spectra (default = overlay).
      --text                 If there are any text strings specified in the
                             splot file, then plot them (default=true).
      --ticks                Don't put ticks on the top and right axes (the
                             default is to do this).
      --title=<string>       The title to put at the top of the plot.  This 
                             overrides the value in any splot files 
                             (default none).
      --threshold=<flux>     The threshold in (Jy) linearly polarized intensity
                             below which no position angle information is
                             calculated (default = 1.0).  If the --report
                             option is being used, this threshold determines 
                             where the velocity range and integrated flux
                             are calculated over.
      --top=<percentage>     The top boundary of the plot in world coordinates
                             (default = 0.85).
      --uncertainty=<percent>
                             The percentage uncertainty in the polarization
                             calibration - which is used to put error bars
                             on polarization plots (default = 0.4%)
      --version              Give the version number of the script.
      --vertical=<velocities>
                             Insert a vertical dashed line at the listed
                             velocities.  For more than one line use a comma
                             separated list (default none).
      --vmin=<velocity>      The minimum velocity (in km/s) to plot in the 
                             spectrum.  If this is not present then the
                             minumum velocity present in the data is plotted.
      --vmax=<velocity>      The maximum velocity (in km/s) to plot in the 
                             spectrum.  If this is not present then the
                             maxumum velocity present in the data is plotted.
      --vshift=<velocity>    The velocity shift to apply (in km/s) to the data
                             (default = 0.0)
      --ymin=<flux density>  The minimum flux density (in Jy) to plot in the 
                             spectrum.  If this is not present then the
                             minumum flux density present in the data is 
                             plotted.
      --ymax=<flux density>  The maximum flux density (in km/s) to plot in the 
                             spectrum.  If this is not present then the
                             maxumum flux density present in the data is 
                             plotted.
      --zshift=<velocity>    The velocity shift due to Zeeman splitting to
                             apply.  A shift of the given sign will be
                             applied to RCP data, for LCP a shift of the
                             same magnitude, but opposite sign will be
                             used (default=none).  For data which is not
                             RCP or LCP this option is ignored.
HELP
} elsif ($version) {
  print <<VERSION;
  $0 ; Version : $VERSION ; Date : $DATE
VERSION
}
if ($help || $version) {exit(0);}

if (defined $polarization) {
  if ((lc $polarization ne 'linear') && (lc $polarization ne 'perlinear') && 
      (lc $polarization ne 'lcp') && (lc $polarization ne 'rcp')) {
    croak "The --pol option must be one of :\n".
      "  linear - A plot of the linear polarization intensity and position ".
      "angle\n".
      "  perlinear - A plot of the percentage linear polarization\n".
      "  lcp    - A plot of the LCP spectrum produced from stokes I & V\n".
      "  rcp    - A plot of the RCP spectrum produced from stokes I & V\n";
  }
}

# Constants
my $PGPLOT_BLACK=0;
my $PGPLOT_WHITE=1;
my $PGPLOT_RED=2;
my $PGPLOT_GREEN=3;
my $PGPLOT_BLUE=4;
my $PGPLOT_CYAN=5;
my $PGPLOT_MAGENTA=6;
my $PGPLOT_YELLOW=7;

my $PGPLOT_SOLID=1;
my $PGPLOT_DASHED=2;
my $PGPLOT_DASH_DOT=3;
my $PGPLOT_DOTTED=4;
my $PGPLOT_DASH_3DOT=5;

# Global variables
my (@velocity, @amplitude, @data, @colour, @style); # Data read from the file
my (@line_x1, @line_y1, @line_x2, @line_y2, @lines, @linecol);
my (@arrow_x1, @arrow_y1, @arrow_x2, @arrow_y2, @arrows, @arrowcol);
my (@text, @justification, @text_x, @text_y, @texts);
my (@gaussian, @gauss_col, @gpos, @gamp, @gwid);
my (@sidetext, @sides);
my (@stokes);
my (@plotlabel);
my (@vertlines);
my ($xlabel, $ylabel);
my ($npts, $nline, $narrow, $ntext, $nside, $ngauss);
my ($bmin, $bmax, $tmin, $tmax, $lmin, $lmax, $rmin, $rmax, $ndata, $size, 
    $plotlab, $shift);
my $stokes_par = 'I';
my $i=0;			# Working variables within code

if (!defined $scale) {
  $scale=1.0;
}

# Read the information from the file
while (<>) {
  # Remove comments
  s/\#.*/\n/;

  if (/\bheading\b/i) {
    if (!defined $heading) {
      $heading = <>;
      chomp $heading;
    } else {
      print STDERR "Only the first heading keyword in the file(s) is used\n";
      my $tmp=<>;
    }
  } elsif (/\bxlabel\b/i) {
    if (!defined $xlabel) {
      $xlabel = <>;
      chomp $xlabel;
    } else {
      print STDERR "Only the first xlabel keyword in the file(s) is used\n";
      my $tmp=<>;
    }
  } elsif (/\bylabel\b/i) {
    if (!defined $ylabel) {
      $ylabel = <>;
      chomp $ylabel;
    } else {
      print STDERR "Only the first ylabel keyword in the file(s) is used\n";
      my $tmp=<>;
    }
  } elsif (/\bbaxis\b/i) {
    if (defined $bmin && defined $bmax && !$stack) {
      print STDERR "Only the first baxis keyword in the file(s) is used in ".
	"overlay mode \n";
      my $tmp=<>; $tmp=<>;
    } elsif (!defined $bmin || !defined $bmax) {
      $bmin = <>;
      $bmax = <>;
      chomp ($bmin, $bmax);
    } else {
      my $tmp=<>; $tmp=<>;
    }
  } elsif (/\btaxis\b/i) {
    if (defined $tmin && defined $tmax && !$stack) {
      print STDERR "Only the first taxis keyword in the file(s) is used in ".
	"overlay mode \n";
      my $tmp=<>; $tmp=<>;
    } elsif (!defined $tmin || !defined $tmax) {
      $tmin = <>;
      $tmax = <>;
      chomp ($tmin, $tmax);
    } else {
      my $tmp=<>; $tmp=<>;
    }
  } elsif (/\blaxis\b/i) {
    if (defined $lmin && defined $lmax && !$stack) {
      print STDERR "Only the first laxis keyword in the file(s) is used in ".
	"overlay mode \n";
      my $tmp=<>; $tmp=<>;
    } elsif (!defined $lmin || !defined $lmax) {
      $lmin = <>;
      $lmax = <>;
      chomp ($lmin, $lmax);
      if (defined $scale) {
	$lmin *= $scale;
	$lmax *= $scale;
      }
    } else {
      my $tmp=<>; $tmp=<>;
    }
  } elsif (/\braxis\b/i) {
    if (defined $rmin && defined $rmax && !$stack) {
      print STDERR "Only the first raxis keyword in the file(s) is used in ".
	"overlay mode \n";
      my $tmp=<>; $tmp=<>;
    } elsif (!defined $rmin || !defined $rmax) {
      $rmin = <>;
      $rmax = <>;
      chomp ($rmin, $rmax);
      if (defined $scale) {
	$rmin *= $scale;
	$rmax *= $scale;
      }
    } else {
      my $tmp=<>; $tmp=<>;
    }
  } elsif (/\bvshift\b/i) {
    if (!defined $vshift) {
      $shift = <>;
      chomp $shift;
    }
  } elsif (/\bscale\b/i) {
    $scale = <>;
    chomp $scale;
  } elsif (/^\s*colour\b/i || /^\s*color\b/i) {
    if (/\bblack\b/i) {
      push @colour, $PGPLOT_BLACK;
    } elsif (/\bwhite\b/i) {
      push @colour, $PGPLOT_WHITE;
    } elsif (/\bred\b/i) {
      push @colour, $PGPLOT_RED;
    } elsif (/\bgreen\b/i) {
      push @colour, $PGPLOT_GREEN;
    } elsif (/\bblue\b/i) {
      push @colour, $PGPLOT_BLUE;
    } elsif (/\bcyan\b/i) {
      push @colour, $PGPLOT_CYAN;
    } elsif (/\bmagenta\b/i) {
      push @colour, $PGPLOT_MAGENTA;
    } elsif (/\byellow\b/i) {
      push @colour, $PGPLOT_YELLOW;
    } else {
      printf STDERR "Problem reading colour command : %s\n", $_;
    }
  } elsif (/^\s*style\b/i) {
    if (/\bsolid\b/i) {
      push @style, $PGPLOT_SOLID;
    } elsif (/\bdashed\b/i) {
      push @style, $PGPLOT_DASHED;
    } elsif (/\bdash_dot\b/i) {
      push @style, $PGPLOT_DASH_DOT;
    } elsif (/\bdash_dotted\b/i) {
      push @style, $PGPLOT_DOTTED;
    } elsif (/\bdash_dash_3dot\b/i) {
      push @style, $PGPLOT_DASH_3DOT;
    } else {
      printf STDERR "Problem reading style command : %s\n", $_;
    }
  } elsif (/\bdata\b/i) {
    if (scalar @data > 0) {
      push @lines, $nline;
      push @arrows, $narrow;
      push @texts, $ntext;
      push @sides, $nside;
      push @gaussian, $ngauss;
    }
    $nline = $narrow = $ntext = $nside = $ngauss = 0;
    if ((!defined $shift) && (defined $vshift)) {
      $shift = $vshift;
    } elsif (!defined $shift) {
      $shift = 0.0;
    }
    $npts = <>;
    chomp $npts;
    $i=0;
    my $line= <>;
    while ((defined $line) && ($i < ($npts-1)) && ($line !~ /\bend\b/)) {
      if ($line =~ /(\S+)\s+        # velocity
		     (\S+)\s+       # amplitude
		     /x) {
	push @velocity, $1+$shift;
	push @amplitude, $2*$scale;
      } else {
	printf STDERR "Problem reading data line %i\n", $i+1;
      }
      if (!eof) {
	$line = <>;
      } else {
	$line = undef;
      }
      $i++;
    }
    push @data, $i-1;
    if ($i+1 != $npts) {
      printf STDERR "Expected $npts lines of data, but only read $i+1\n";
    }
    push @stokes, $stokes_par;
    $stokes_par = 'I';
    push @plotlabel, $plotlab;
    $plotlab = undef;
    $shift = 0.0;
  } elsif (/\barrow\b/i) {
    $narrow++;
    if ((/arrow\s+colour\s+(\S+)/i) || (/arrow\s+color\s+(\S+)/i)) {
      push @arrowcol, &colour_num($1);
    } else {
      push @arrowcol, $PGPLOT_WHITE;
    }
    $_ = <>;
    if (/(\S+)\s+               # x1
            (\S+)\s+            # y1
            (\S+)\s+            # x2
            (\S+)\s+            # y2
            /x) {
      push @arrow_x1, $1;
      push @arrow_y1, $2;
      push @arrow_x2, $3;
      push @arrow_y2, $4;
    } else {
      printf STDERR "Problem reading arrow line : %s\n", $_;
      $narrow--;
    }
  } elsif (/\bgauss\b/i) {
    $ngauss++;
    my $colour;
    if (/\bgauss\s+dashed\b/i) {
      $colour = 'dashed';
    } elsif (/\bgauss\s+(\S+)/i) {
      $colour = &colour_num($1);
    }
    push @gauss_col, (defined $colour) ? $colour : $PGPLOT_WHITE;
    $_ = <>;
    if (/(\S+)\s+               # position
            (\S+)\s+            # amplitude
            (\S+)\s+            # width
            /x) {
      push @gpos, $1;
      push @gamp, $2*$scale;
      push @gwid, $3;
    } else {
      printf STDERR "Problem reading gauss line : %s\n", $_;
      $ngauss--;
    }
  } elsif (/\bline\b/i) {
    $nline++;
    if ((/line\s+colour\s+(\S+)/i) || (/line\s+color\s+(\S+)/i)) {
      push @linecol, &colour_num($1);
    } else {
      push @linecol, $PGPLOT_WHITE;
    }
    $_ = <>;
    if (/(\S+)\s+           # x1
            (\S+)\s+            # y1
            (\S+)\s+            # x2
            (\S+)\s+            # y2
            /x) {
      push @line_x1, $1;
      push @line_y1, $2;
      push @line_x2, $3;
      push @line_y2, $4;
    } else {
      printf STDERR "Problem reading line line : %s\n", $_;
      $nline--;
    }
  } elsif (/\btext\b/i) {
    $ntext++;
    if (/\bcentre\b/i || /\bcenter\b/i) {
      push @justification, 0.5;
    } elsif (/\bright\b/i) {
      push @justification, 1.0;
    } else {
      push @justification, 0.0;
    }
    my $line = <>;
    chomp $line;
    push @text, $line;
    $_ = <>;
    if (/(\S+)\s+           # x1
         (\S+)\s+           # y1
         /x) {
      push @text_x, $1;
      push @text_y, $2;
    } else {
      printf STDERR "Problem reading text line: %s\n", $_;
      $ntext--;
    }
  } elsif (/\bsidetext\b/) {
    my $sidelines = <>;
    chomp $sidelines;
    $i=0;
    my $line=<>;
    while((defined $line) && ($i<$sidelines)) {
      $nside++;
      chomp $line;
      push @sidetext, $line;
      if (!eof && $i<$sidelines-1) {
	$line = <>;
      } else {
	$line = undef;
      }
      $i++;
    }
  } elsif (/\bstokes\b\s+([IQUVLR])/i) {
    $stokes_par = $1
  } elsif (/\blabel\b/i) {
    if (defined $plabel) {
      $plotlab = $plabel;
      $label = 1;
      $plabel = undef;
    } elsif (!defined $plotlab) {
      $plotlab = <>;
      chomp $plotlab;
    } else {
      print STDERR "Only the first label keyword is used for any set of data\n";
      my $tmp=<>;
    }
  } elsif (/\bend\b/) {
    # This keyword is superfluous if the number of lines of data have been
    # specified correctly.
  } elsif (! /^\s*$/) { # Ignore blanks lines
    warn "Ignoring $_";
  }
}
push @lines, $nline;
push @arrows, $narrow;
push @texts, $ntext;
push @sides, $nside;
push @gaussian, $ngauss;

# If the user only wants information about the contents of the file
# then give it to them
if ($info) {
  exit(0);
}

if (defined $plabel) {
  $label = 1;
  $plotlabel[0] = $plabel;
}

# The pair option is just a variety of stack.
if ($pair) {
  $stack = 1;
}

# See if the user wants any vertical lines
if (defined $vertical) {
  if ($vertical =~ /,/) {
    @vertlines = split(',',$vertical);
  } else {
    $vertlines[0] = $vertical;
  }
}

# If we need to do any velocity shifts due to Zeeman splitting, do
# it here.
if (defined $zshift) {
  $npts = 0;
  for (my $i=0 ; $i<scalar @stokes ; $i++) {
    if ($stokes[$i] eq 'R') {
      for (my $j=$npts ; $j<=$npts+$data[$i] ; $j++){
	$velocity[$j] += $zshift;
      }
    } elsif ($stokes[$i] eq 'L') {
      for (my $j=$npts ; $j<=$npts+$data[$i] ; $j++){
	$velocity[$j] -= $zshift;
      }
    }
    $npts += $data[$i]+1;
  }
  if ($print) {
    print "Zeeman-corrected spectrum\n";
    print "Velocity(km/s)  Intensity(Jy)\n";
    for (my $i=0 ; $i < scalar @amplitude ; $i++) {
      printf "%7.2f %6.1f\n", $velocity[$i], $amplitude[$i];
    }
  } elsif ($splot) {
    print "heading\n$heading\n";
    if ($label && (defined $plotlabel[0])) {
      printf "label\n\%s\n", $plotlabel[0];
    }
    print "xlabel\n$xlabel\n";
    print "ylabel\n$ylabel\n";
    my ($bmax, $bmin) = maxmin(@velocity);
    print "baxis\n$bmin\n$bmax\n";
    my ($lmax, $lmin) = maxmin(@amplitude);
    my $delta = $lmax-$lmin;
    $lmax += 0.15*$delta;
    $lmin -= 0.07*$delta;
    print "laxis\n$lmin\n$lmax\n";
    printf "data\n%i\n", scalar @amplitude+1;
    for (my $i=0 ; $i < scalar @amplitude ; $i++) {
      printf "$velocity[$i] $amplitude[$i]\n";
    }
  }
}

# If we are doing polarization plots, then do the calculations here.
if (defined $polarization && (($polarization eq 'linear') ||
			      ($polarization eq 'perlinear') ||
			      ($polarization eq 'lcp') ||
			      ($polarization eq 'rcp'))) {
  
  my (@Q, @U, @Q_vel, @U_vel, @linear, @posang, @linvel, @posvel);
  my (@I, @V, @I_vel, @V_vel, @errtop, @errbot, @errvel, @errlin);
  my (@perlin, @circular, @cirvel);
  my (%seen, @index);

  # First work out which data contains what stokes parameters Q and U
  $npts = 0;
  for (my $i=0 ; $i<scalar @stokes ; $i++) {
    if ($stokes[$i] eq 'I') {
      if (scalar @I) {
	carp "More than one lot of stokes I data is contained in the input ".
	  "data files\nThe first one will be used in producing the ".
	  "polarization plot\n";
      } else {
	@I = @amplitude[$npts..$npts+$data[$i]];
	@I_vel = @velocity[$npts..$npts+$data[$i]];
      }
    }
    if ($stokes[$i] eq 'Q') {
      if (scalar @Q) {
	carp "More than one lot of stokes Q data is contained in the input ".
	  "data files\nThe first one will be used in producing the ".
          "polarization plot\n";
      } else {
	@Q = @amplitude[$npts..$npts+$data[$i]];
	@Q_vel = @velocity[$npts..$npts+$data[$i]];
      }
    }
    if ($stokes[$i] eq 'U') {
      if (scalar @U) {
	carp "More than one lot of stokes U data is contained in the input ".
	  "data files\nThe first one will be used in producing the total ".
          "linear polarization plot\n";
      } else {
	@U = @amplitude[$npts..$npts+$data[$i]];
	@U_vel = @velocity[$npts..$npts+$data[$i]];
      }
    }
    if ($stokes[$i] eq 'V') {
      if (scalar @U) {
	carp "More than one lot of stokes V data is contained in the input ".
	  "data files\nThe first one will be used in producing the ".
	  "polarization plot\n";
      } else {
	@V = @amplitude[$npts..$npts+$data[$i]];
	@V_vel = @velocity[$npts..$npts+$data[$i]];
      }
    }
    $npts += $data[$i]+1;
  }
  if (($polarization eq 'linear') || ($polarization eq 'perlinear')) {
    if (scalar @Q == 0) {
      croak "No stokes Q data was found, so a plot of linear polarization ".
	"intensity can't be produced\n";
    }
    if (scalar @U == 0) {
      croak "No stokes U data was found, so a plot of linear polarization ".
	"intensity can't be produced\n";
    }
    if (($polarization eq 'perlinear') && (scalar @I == 0)) {
      croak "No stokes I data was found, so a plot of percentage linear ".
	"polarization can't be produced\n";
    } elsif (($polarization eq 'linear') && (scalar @I == 0)) {
      carp "No stokes I data was found, so no uncertainty information ".
	" can be determined\n";
    }
  } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
    if (scalar @I == 0) {
      croak "No stokes I data was found, so a spectrum of LCP/RCP intensity ".
	"can't be produced\n";
    }
    if (scalar @V == 0) {
      croak "No stokes V data was found, so a spectrum of LCP/RCP intensity ".
	"can't be produced\n";
    }
  }

  # Determine whether the velocity correspondance the various stokes 
  # parameters is easy or not.
  if (($polarization eq 'linear') || ($polarization eq 'perlinear')) {
    if (scalar @I == 0) {
      if ((scalar @Q == scalar @U) && ($Q_vel[0] == $U_vel[0]) && 
	  ($Q_vel[$#Q_vel] == $U_vel[$#U_vel])) {
	for (my $i=0 ; $i < scalar @Q_vel ; $i++) {
	  push @index, $i;
	}
      } else {
	
	# Use a hash method to check for velocities that are in both arrays
	foreach my $i (@Q_vel) { 
	  $seen{$i} = 1;
	}
	for (my $i=0 ; $i < scalar @U_vel ; $i++) {
	  if ($seen{$U_vel[$i]}) {
	    push @index, $i;
	  }
	}
      }
    } else {
      if ((scalar @Q == scalar @U) && (scalar @U == scalar @I) && 
	  ($Q_vel[0] == $U_vel[0]) && ($Q_vel[0] == $I_vel[0]) &&
	  ($Q_vel[$#Q_vel] == $U_vel[$#U_vel]) && 
	  ($Q_vel[$#Q_vel] == $I_vel[$#I_vel])) {
	for (my $i=0 ; $i < scalar @Q_vel ; $i++) {
	  push @index, $i;
	}
      } else {
	
	# Use a hash method to check for velocities that are in all arrays
	foreach my $i (@Q_vel) { 
	  $seen{$i} = 1;
	}
	for (my $i=0 ; $i < scalar @U_vel ; $i++) {
	  if ($seen{$U_vel[$i]} && $seen{$I_vel[$i]}) {
	    push @index, $i;
	  }
	}
      }
    }
  } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
    if ((scalar @I == scalar @V) && ($I_vel[0] == $V_vel[0]) && 
	($I_vel[$#I_vel] == $V_vel[$#V_vel])) {
      for (my $i=0 ; $i < scalar @I_vel ; $i++) {
	push @index, $i;
      }
    } else {
      
      # Use a hash method to check for velocities that are in both arrays
      foreach my $i (@I_vel) { 
	$seen{$i} = 1;
      }
      for (my $i=0 ; $i < scalar @V_vel ; $i++) {
	if ($seen{$V_vel[$i]}) {
	  push @index, $i;
	}
      }
    }
  }
  
  # Now produce the linear polarization information
  if (($polarization eq 'linear') || ($polarization eq 'perlinear')) {
    if ($maxpol > 1.0) {
      $maxpol /= 100.0;
    }
    for (my $i=0 ; $i < scalar @index ; $i++) {
      my $linear_intensity = sqrt($Q[$index[$i]]**2 + $U[$index[$i]]**2);
      if (($linear_intensity > $maxpol * $I[$index[$i]]) || 
	  ($linear_intensity < $threshold)) {
	$linear_intensity = 0.0;
      }
      push @linear, $linear_intensity;
      if (($polarization eq 'linear') && ($linear[$#linear] >= $threshold)) {
	push @posang, 0.5*(atan2($U[$index[$i]],$Q[$index[$i]]))*180.0/$PI;
	push @posvel, $U_vel[$index[$i]];
      } elsif ($polarization eq 'perlinear') {
	if (($linear[$i] > $threshold) && ($I[$index[$i]] > 0.0)) {
	  push @perlin, $linear[$i]/$I[$index[$i]] * 100.0;
	} else {
	  push @perlin, 0.0;
	}
      }
      push @linvel, $U_vel[$index[$i]];
      if ($polarization eq 'linear') {
	if ((scalar @I != 0) && ($i % 2 == 0) && ($linear[$i] > $threshold)) {
	  push @errtop, $linear[$i] + ($uncertainty/100.0 * $I[$index[$i]]);
	  push @errbot, $linear[$i] - ($uncertainty/100.0 * $I[$index[$i]]);
	  push @errlin, $linear[$i];
	  push @errvel, $U_vel[$index[$i]];
	}
      } elsif ($polarization eq 'perlinear') { 
	if (($i % 2 == 0) && ($linear[$i] > $threshold)) {
	  push @errtop, $perlin[$i] + $uncertainty;
	  push @errbot, $perlin[$i] - $uncertainty;
	  push @errlin, $perlin[$i];
	  push @errvel, $U_vel[$index[$i]];
	}
      }
    }
  } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
    for (my $i=0 ; $i < scalar @index ; $i++) {
      if ($polarization eq 'lcp') {
	push @circular, 0.5*($I[$index[$i]]-$V[$index[$i]]);
      }  else {
	push @circular, 0.5*($I[$index[$i]]+$V[$index[$i]]);
      }
      push @cirvel, $I_vel[$index[$i]];
    }
  }

  # Print out the stuff for linear polarization or percentage linear 
  # polarization spectra if necessary.
  if ($print) {
    if ($polarization eq 'linear') {
      print "Linear polarization spectrum\n";
      print "Velocity(km/s)  Intensity(Jy)\n";
      for (my $i=0 ; $i < scalar @linear ; $i++) {
	printf "%7.2f %6.1f\n", $linvel[$i], $linear[$i];
      }
      print "Linear polarization spectrum\n";
      print "Velocity(km/s)  Position Angle(%)\n";
      for (my $i=0 ; $i < scalar @posang ; $i++) {
	printf "%7.2f %5.1f\n", $posvel[$i], $posang[$i];
      }
    } elsif ($polarization eq 'perlinear') {
      print "Percentage polarization spectrum\n";
      print "Velocity(km/s)  Percentage pol(%)\n";
      for (my $i=0 ; $i < scalar @perlin ; $i++) {
	printf "%7.2f %4.1f\n", $linvel[$i], $perlin[$i];
      }
    } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
      if ($polarization eq 'lcp') {
	print "Left hand circular spectrum\n";
      } else {
	print "Right hand circular spectrum\n";
      }
      print "Velocity(km/s)  Intensity (Jy)\n";
      for (my $i=0 ; $i < scalar @circular ; $i++) {
	printf "%7.2f %4.1f\n", $circular[$i], $cirvel[$i];
      }
    }
  } elsif ($splot) {
    print "heading\n$heading\n";
    if ($label && (defined $plotlabel[0])) {
      printf "label\n\%s\n", $plotlabel[0];
    }
    print "xlabel\n$xlabel\n";
    if ($polarization eq 'linear') {
      print "ylabel\nLinear Polarization (Jy)\n";
      my ($bmax, $bmin) = maxmin(@linvel);
      print "baxis\n$bmin\n$bmax\n";
      my ($lmax, $lmin) = maxmin(@linear);
      my $delta = $lmax-$lmin;
      $lmax += 0.15*$delta;
      $lmin -= 0.07*$delta;
      print "laxis\n$lmin\n$lmax\n";
      printf "data\n%i\n", scalar @linear;
      for (my $i=0 ; $i < scalar @linear ; $i++) {
	printf "$linvel[$i] $linear[$i]\n"; 
      }
    } elsif ($polarization eq 'perlinear') {
      print "ylabel\nPercentage Linear Polarization\n";
      my ($bmax, $bmin) = maxmin(@linvel);
      print "baxis\n$bmin\n$bmax\n";
      my ($lmax, $lmin) = maxmin(@perlin);
      my $delta = $lmax-$lmin;
      $lmax += 0.1*$delta;
      $lmin -= 0.1*$delta;
      print "laxis\n$lmin\n$lmax\n";
      printf "data\n%i\n", scalar @perlin;
      for (my $i=0 ; $i < scalar @perlin ; $i++) {
	printf "$linvel[$i] $perlin[$i]\n";
      }
    } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
      print "ylabel\nFlux Density (Jy)\n";
      if ($polarization eq 'lcp') {
	print "stokes L\n";
      } else {
	print "stokes R\n";
      }
      my ($bmax, $bmin) = maxmin(@cirvel);
      print "baxis\n$bmin\n$bmax\n";
      my ($lmax, $lmin) = maxmin(@circular);
      my $delta = $lmax-$lmin;
      $lmax += 0.1*$delta;
      $lmin -= 0.1*$delta;
      print "laxis\n$lmin\n$lmax\n";
      printf "data\n%i\n", scalar @circular;
      for (my $i=0 ; $i < scalar @circular ; $i++) {
	printf "$cirvel[$i] $circular[$i]\n";
      }
    }
  }

  # Now make the plot
  pgbeg(0, $pgplot_device, 0, 0);
  pgask(0);
  pgbbuf();
  pgsch($char_size);
  pgsah(2,45.0,1.0);		# My preference for arrow style
  pgscf(2);			# Set Roman as the default font style

  # Work out the velocity and amplitude range.
  if (($polarization eq 'linear') || ($polarization eq 'perlinear')) {
    ($bmax, $bmin) = maxmin(@linvel);
    if (defined $vmin) {
      $bmin = $vmin;
    }
    if (defined $vmax) {
      $bmax = $vmax;
    }
    if ($polarization eq 'linear') {
      ($lmax, $lmin) = maxmin(@linear);
      if ($normalise) {
	for (my $j=0 ; $j < scalar @linear ; $j++) {
	  $linear[$j] /= $lmax;
	}
	$lmax = 1.0;
	$lmin /= $lmax;
	$ylabel="Normalised Flux Density";
      }
      my $delta = $lmax-$lmin;
      $lmax += 0.15*$delta;
      $lmin -= 0.07*$delta;
      if (defined $ymin) {
	$lmin = $ymin;
      }
      if (defined $ymax) {
	$lmax = $ymax;
      }
      
      # Sort out the axis labels
      $size = ($top_boundary-$bottom_boundary)/3;
      pgsvp($left_boundary, $right_boundary, $top_boundary-$size, 
	    $top_boundary);
      pgswin($bmin, $bmax, -120, 120);
      pgbox('BCTS', 0.0, 0, 'BCNTSV', 0.0, 0);
      pgsch(1.5*$char_size);
      if (defined $heading) {
	pgmtxt('T', 1.0, 0.5, 0.5, $heading);
      }
      pgsch($char_size);
      pgmtxt('L', 3.0, 0.5, 0.5, 'Position Angle (deg)');
      
      # First do the position angle information
      pgpt(scalar @posang, \@posvel, \@posang, 2);
      
      # Now do the total linear polarization
      pgsvp($left_boundary, $right_boundary, $bottom_boundary, 
	    $top_boundary-$size);
      pgswin($bmin, $bmax, $lmin, $lmax);
      pgbox('BCNTS', 0.0, 0, 'BCNTSV', 0.0, 0);
      pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
      pgmtxt('L', 3.0, 0.5, 0.5, 'Linear Polarization (Jy)');
      pgmove($linvel[0], $linear[0]);
      if (scalar @errtop != 0) {
	pgline(scalar @linear, \@linvel, \@linear);
	pgsci($PGPLOT_RED);
	pgpt(scalar @errtop, \@errvel, \@errlin, 4);
	pgerry(scalar @errtop, \@errvel, \@errbot, \@errtop, 1.5);
	pgsci($PGPLOT_WHITE);
      } else {
	pgline(scalar @linear, \@linvel, \@linear);
      }
    } elsif ($polarization eq 'perlinear') {
      
      # Sort out the axis labels
      pgsvp($left_boundary, $right_boundary, $bottom_boundary, $top_boundary);
      pgsch(1.5*$char_size);
      if (defined $heading) {
	pgmtxt('T', 1.0, 0.5, 0.5, $heading);
      }
      pgsch($char_size);
      ($lmax, $lmin) = maxmin(@perlin);
      my $delta = $lmax-$lmin;
      $lmax += 0.1*$delta;
      $lmin -= 0.1*$delta;
      if (defined $ymin) {
	$lmin = $ymin;
      }
      if (defined $ymax) {
	$lmax = $ymax;
      }
      pgswin($bmin, $bmax, $lmin, $lmax);
      pgbox('BCNTS', 0.0, 0, 'BCNTSV', 0.0, 0);
      pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
      pgmtxt('L', 3.0, 0.5, 0.5, 'Percentage linear polarization');
      pgmove($linvel[0], $perlin[0]);
      if (scalar @errtop != 0) {
	pgline(scalar @perlin, \@linvel, \@perlin);
	pgsci($PGPLOT_RED);
	pgpt(scalar @errtop, \@errvel, \@errlin, 4);
	pgerry(scalar @errtop, \@errvel, \@errbot, \@errtop, 1.5);
	pgsci($PGPLOT_WHITE);
      } else {
	pgline(scalar @perlin, \@linvel, \@perlin);
      }
    }
  } elsif (($polarization eq 'lcp') || ($polarization eq 'rcp')) {
    ($bmax, $bmin) = maxmin(@cirvel);
    if (defined $vmin) {
      $bmin = $vmin;
    }
    if (defined $vmax) {
      $bmax = $vmax;
    }
    # Sort out the axis labels
    pgsvp($left_boundary, $right_boundary, $bottom_boundary, $top_boundary);
    pgsch(1.5*$char_size);
    if (defined $heading) {
      pgmtxt('T', 1.0, 0.5, 0.5, $heading);
    }
    pgsch($char_size);
    ($lmax, $lmin) = maxmin(@circular);
    if ($normalise) {
      for (my $j=0 ; $j < scalar @circular ; $j++) {
	$circular[$j] /= $lmax;
      }
      $lmax = 1.0;
      $lmin /= $lmax;
      $ylabel="Normalised Flux Density";
    }
    my $delta = $lmax-$lmin;
    $lmax += 0.1*$delta;
    $lmin -= 0.1*$delta;
    if (defined $ymin) {
      $lmin = $ymin;
    }
    if (defined $ymax) {
      $lmax = $ymax;
    }
    pgswin($bmin, $bmax, $lmin, $lmax);
    pgbox('BCNTS', 0.0, 0, 'BCNTSV', 0.0, 0);
    pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
    pgmtxt('L', 3.0, 0.5, 0.5, $ylabel);
    pgmove($cirvel[0], $circular[0]);
    pgline(scalar @circular, \@cirvel, \@circular);
  }
  
  # Plot vertical dashed lines if required
  if (scalar @vertlines > 0) {
    pgsls(2);
    pgsci($PGPLOT_WHITE);
    for (my $j=0 ; $j<scalar @vertlines ; $j++) {
      pgmove($vertlines[$j], $lmin);
      pgdraw($vertlines[$j], $lmax);
    }
    pgsls(1);
  }

  pgebuf;
  pgend;
  exit(0);
}

# If we are doing a difference plot, do the calculations etc here.
if ($difference) {
  
  if (scalar @data < 2) {
    croak "Two spectra are required to produce a difference spectrum\n";
  }
  my (@difference, @diffvel, %seen, @index);
  my $npts=0;
  my @spectrum1 = @amplitude[$npts..$npts+$data[0]];
  my @specvel1 = @velocity[$npts..$npts+$data[0]];
  $npts += $data[0]+1;
  my @spectrum2 = @amplitude[$npts..$npts+$data[1]];
  my @specvel2 = @velocity[$npts..$npts+$data[1]];

  # Determine whether the velocity correspondance between the two spectra 
  # is easy or not.
  if ((scalar @spectrum1 == scalar @spectrum2) && 
      ($specvel1[0] == $specvel2[0]) && 
      ($specvel1[$#specvel1] == $specvel2[$#specvel2])) {
    for (my $i=0 ; $i < scalar @spectrum1 ; $i++) {
      push @index, $i;
    }
  } else {
      
    # Use a hash method to check for velocities that are in both arrays
    foreach my $i (@specvel1) { 
      $seen{$i} = 1;
    }
    for (my $i=0 ; $i < scalar @specvel2 ; $i++) {
      if ($seen{$specvel2[$i]}) {
	push @index, $i;
      }
    }
  }
  
  # Now produce the difference spectrum
  for (my $i=0 ; $i < scalar @index ; $i++) {
    push @difference, ($spectrum1[$index[$i]] - $spectrum2[$index[$i]]);
    push @diffvel, $specvel1[$index[$i]];
  }

  # Print out the difference spectrum if necessary.
  if ($print) {
    print "Difference spectrum\n";
    print "Velocity(km/s)  Intensity(Jy)\n";
    for (my $i=0 ; $i < scalar @difference ; $i++) {
      printf "%7.2f %6.1f\n", $diffvel[$i], $difference[$i];
    }
  }

  # Now make the plot
  pgbeg(0, $pgplot_device, 0, 0);
  pgask(0);
  pgbbuf();
  pgsch($char_size);
  pgsah(2,45.0,1.0);		# My preference for arrow style
  pgscf(2);			# Set Roman as the default font style

  # Work out the velocity and amplitude range.
  ($bmax, $bmin) = maxmin(@diffvel);
  if (defined $vmin) {
    $bmin = $vmin;
  }
  if (defined $vmax) {
    $bmax = $vmax;
  }
  ($lmax, $lmin) = maxmin(@difference);
  if ($normalise) {
    for (my $j=0 ; $j < scalar @difference ; $j++) {
      $difference[$j] /= $lmax;
    }
    $lmax = 1.0;
    $lmin /= $lmax;
    $ylabel="Normalised Flux Density";
  }
  my $delta = $lmax-$lmin;
  $lmax += 0.15*$delta;
  $lmin -= 0.07*$delta;
  if (defined $ymin) {
    $lmin = $ymin;
  }
  if (defined $ymax) {
    $lmax = $ymax;
  }
  
  # Sort out the axis labels
  pgsvp($left_boundary, $right_boundary, $bottom_boundary, $top_boundary);
  pgsch(1.5*$char_size);
  if (defined $heading) {
    pgmtxt('T', 1.0, 0.5, 0.5, $heading);
  }
  pgsch($char_size);
  pgswin($bmin, $bmax, $lmin, $lmax);
  pgbox('BCNTS', 0.0, 0, 'BCNTSV', 0.0, 0);
  pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
  pgmtxt('L', 3.5, 0.5, 0.5, $ylabel);
  pgmove($diffvel[0], $difference[0]);
  pgline(scalar @diffvel, \@diffvel, \@difference);

  # Plot vertical dashed lines if required
  if (scalar @vertlines > 0) {
    pgsls(2);
    pgsci($PGPLOT_WHITE);
    for (my $j=0 ; $j<scalar @vertlines ; $j++) {
      pgmove($vertlines[$j], $lmin);
      pgdraw($vertlines[$j], $lmax);
    }
    pgsls(1);
  }

  pgebuf;
  pgend;
  exit(0);
}

# If the heading, xlabel or ylabel weren't defined in the file, then do
# it here.
if (!defined $heading) {
  $heading='';
}
if (!defined $xlabel) {
  $xlabel='velocity w.r.t LSR (kms\\u-1\\d)';
}
if (!defined $ylabel) {
  $ylabel='flux density (Jy)';
}

# Plot the data from the file
# Set up the device, viewport, character size, arrow style and font
pgbeg(0, $pgplot_device, 0, 0);
pgask(0);
pgbbuf();
pgsch($char_size);
pgsah(2,45.0,1.0);		# My preference for arrow style
pgscf(2);			# Set Roman as the default font style

# Make sure that we have at least one axis for X,Y defined and labeled.
$ndata = scalar @data;
if (!defined $tmin && !defined $tmax) {
  if (!defined $bmin) {
    ($i, $bmin) = maxmin(@velocity);
  }
  if (!defined $bmax) {
    ($bmax, $i) = maxmin(@velocity);
  }
}
if (defined $vmin) {
  $bmin = $vmin;
}
if (defined $vmax) {
  $bmax = $vmax;
}
if (!defined $rmin && !defined $rmax) {
  if (!defined $lmin) {
    ($i, $lmin) = maxmin(@amplitude);
  }
  if (!defined $lmax) {
    ($lmax, $i) = maxmin(@amplitude);
  }
}
if ($normalise) {
  $lmin=-0.1;
  $lmax=1.1;
  $ylabel="Normalised Flux Density";
}
if (defined $ymin) {
  $lmin = $ymin;
}
if (defined $ymax) {
  $lmax = $ymax;
}

# Go 'round the loop for each set of data in the file
$i = 0;
$npts = $nline = $narrow = $ntext = $nside = $ngauss = 0;
if ($pair) {
  $size = ($top_boundary-$bottom_boundary)/($ndata/2);
} else {
  $size = ($top_boundary-$bottom_boundary)/$ndata;
}
while ($i < $ndata) {
  if (!$stack && ($i==0)) {
    if ($sidetext) {
      pgsvp($left_boundary, $right_boundary-0.2, $bottom_boundary, 
	    $top_boundary);
    } else {
      pgsvp($left_boundary, $right_boundary, $bottom_boundary, $top_boundary);
    }
    
    # Plot the scales
    if (defined $bmin && defined $bmax) {
      pgswin($bmin, $bmax, 0.0, 1.0);
      if (defined $tmin && defined $tmax) {
	pgbox('BNTS', 0.0, 0, ' ', 0.0, 0);
      } elsif (!$ticks) {
	pgbox('BCNTS', 0.0, 0, ' ', 0.0, 0);
      }
    }
    if (defined $tmin && defined $tmax) {
      pgswin($tmin, $tmax, 0.0, 1.0);
      if (defined $bmin && defined $bmax) {
	pgbox('CMTS', 0.0, 0, ' ', 0.0, 0);
      } elsif (!$ticks) {
	pgbox('BCMTS', 0.0, 0, ' ', 0.0, 0);
      }
    }
    if (defined $lmin && defined $lmax) {
      pgswin(0.0, 1.0, $lmin, $lmax);
      if (defined $rmin && defined $rmax) {
	pgbox(' ', 0.0, 0, 'BNTSV', 0.0, 0);
      } elsif (!$ticks) {
	pgbox(' ', 0.0, 0, 'BCNTSV', 0.0, 0);
      }
    }
    if (defined $rmin && defined $rmax) {
      pgswin(0.0, 1.0, $rmin, $rmax);
      if (defined $lmin && defined $lmax) {
	pgbox(' ', 0.0, 0, 'CMTSV', 0.0, 0);
      } elsif (!$ticks) {
	pgbox(' ', 0.0, 0, 'BCMTSV', 0.0, 0);
      }
    }
    # Make sure that the plot window is correctly defined.
    pgswin($bmin, $bmax, $lmin, $lmax);
    
    # Plot the axis labels
    pgsch(1.5*$char_size);
    if (defined $heading) {
      pgmtxt('T', 1.0, 0.5, 0.5, $heading);
    }
    pgsch($char_size);
    pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
    pgmtxt('L', 3.5, 0.5, 0.5, $ylabel);

    # If required plot the stokes information
    if ($label && (defined $plotlabel[$i])) {
      pgsch($char_size);
      pgmtxt('T', -2.0, 0.9, 0.5, $plotlabel[$i]);
    }
  } elsif ($stack) {
    
    # Plot the y axis label only once if requested.
    if (($i == 0) && ($one)) {
      pgsvp($left_boundary, $right_boundary, $bottom_boundary, $top_boundary);
      pgsch($char_size);
      pgmtxt('L', 3.75, 0.5, 0.5, $ylabel);
    }
    if (!$pair || ($pair && ($i%2 == 0))) {
      if ($pair) {
	if ($sidetext) {
	  pgsvp($left_boundary, $right_boundary-0.2, 
		$top_boundary-(($i/2+1)*$size), $top_boundary-($i/2*$size));
	} else {
	  pgsvp($left_boundary, $right_boundary, 
		$top_boundary-(($i/2+1)*$size), $top_boundary-($i/2*$size));
	}
      } else {
	if ($sidetext) {
	  pgsvp($left_boundary, $right_boundary-0.2, 
		$top_boundary-(($i+1)*$size), $top_boundary-($i*$size));
	} else {
	  pgsvp($left_boundary, $right_boundary, $top_boundary-(($i+1)*$size), 
		$top_boundary-($i*$size));
	}
      }
    
      # Plot the scales
      if (defined $bmin && defined $bmax) {
	pgswin($bmin, $bmax, 0.0, 1.0);
      }
      if ($ticks) {
	if (($i == $ndata-1) || ($pair && ($i == $ndata-2))) {
	  pgbox('BNTS', 0.0, 0, ' ', 0.0, 0);
	} elsif ($i == 0) {
	  pgbox('BTS', 0.0, 0, ' ', 0.0, 0);
	  pgbox('C', 0.0, 0, ' ', 0.0, 0);
	} else {
	  pgbox('BTS', 0.0, 0, ' ', 0.0, 0);
	}
      } else {
	if (($i == $ndata-1) || ($pair && ($i == $ndata-2))) {
	  pgbox('BCNTS', 0.0, 0, ' ', 0.0, 0);
	} else {
	  pgbox('BCTS', 0.0, 0, ' ', 0.0, 0);
	}
      }
    
      if ($pair) {
	($lmax, $lmin) = maxmin(@amplitude[$npts..$npts+$data[$i]+$data[$i+1]]);
      } else {
	($lmax, $lmin) = maxmin(@amplitude[$npts..$npts+$data[$i]]);
      }
      if ($normalise) {
	for (my $j=$npts ; $j < ($npts+$data[$i]) ; $j++) {
	  $amplitude[$j] /= $lmax;
	}
	$lmin /= $lmax;
	$lmax = 1.0;
	$ylabel="Normalised Flux Density";
      }
      my $delta = $lmax-$lmin;
      $lmax += $gap*$delta;
      $lmin -= $gap*$delta;
      if (defined $ymin) {
	$lmin = $ymin;
      }
      if (defined $ymax) {
	$lmax = $ymax;
      }
      pgswin(0.0, 1.0, $lmin, $lmax);
      if (defined $rmin && defined $rmax) {
	pgbox(' ', 0.0, 0, 'BNTSV', 0.0, 0);
      } elsif (!$ticks) {
	pgbox(' ', 0.0, 0, 'BCNTSV', 0.0, 0);
      } else {
	pgbox(' ', 0.0, 0, 'BNTSV', 0.0, 0);
	pgbox(' ', 0.0, 0, 'C', 0.0, 0);
      }

      # Make sure that the plot window is correctly defined.
      pgswin($bmin, $bmax, $lmin, $lmax);
      
      # Plot the axis labels
      pgsch(1.5*$char_size);
      if (defined $heading && ($i==0)) {
	pgmtxt('T', 0.5, 0.5, 0.5, $heading);
      }
      pgsch($char_size);
      if (($i == $ndata-1) || ($pair && ($i == $ndata-2))) {
	pgmtxt('B', 2.5, 0.5, 0.5, $xlabel);
      }
      if (!$one) {
	pgmtxt('L', 3.5, 0.5, 0.5, $ylabel);
      }

      # If required plot the stokes information
      if ($label && (defined $plotlabel[$i])) {
	pgsch($char_size);
	pgmtxt('T', -2.0, 0.87, 0.5, $plotlabel[$i]);
      }
    }
  }
  
  # Plot the data
  if ($data[$i] > 0) {
    my @x = @velocity[$npts..$npts+$data[$i]]; # Take the appropriate slice
					       # of the data arrays
    my @y = @amplitude[$npts..$npts+$data[$i]];
    if ($normalise) {
      ($lmax, $lmin) = maxmin(@y);
      for (my $j=0 ; $j < scalar @y ; $j++) {
	$y[$j] /= $lmax;
      }
    }
    if (!$stack) {
      if ($i < scalar @colour) {
	pgsci($colour[$i]);
      } else {
	pgsls($i+1);
      }
    } elsif ($pair) {
      if ($i%2 == 0) {
	pgsls(1);
      } else {
	pgsls(2);
      }
    } elsif ($i < scalar @style) {
      pgsls($style[$i]);
    }
    pgmove($x[0], $y[0]);
    pgline($data[$i], \@x, \@y);

    # Output an splot format file if required
    if ($splot) {
      print "heading\n$heading\n";
      if ($label && (defined $plotlabel[0])) {
	printf "label\n\%s\n", $plotlabel[0];
      }
      print "xlabel\n$xlabel\n";
      print "ylabel\n$ylabel\n";
      my ($bmax, $bmin) = maxmin(@velocity);
      print "baxis\n$bmin\n$bmax\n";
      my ($lmax, $lmin) = maxmin(@amplitude);
      my $delta = $lmax-$lmin;
      $lmax += 0.15*$delta;
      $lmin -= 0.07*$delta;
      print "laxis\n$lmin\n$lmax\n";
      printf "data\n%i\n", $data[$i];
      for (my $j=0 ; $j < $data[$i] ; $j++) {
	printf "$x[$j] $y[$j]\n";
      }
      printf "end\n"
    }

    # Report on the data if necessary
    if ($report) {
      my ($vpeak,$vlow,$vhigh,$peak,$integrated,$tmp);
      for (my $j=0 ; $j < scalar @y ; $j++) {
	if (((!defined $vmin) || ($x[$j] >= $vmin)) &&
	    ((!defined $vmax) || ($x[$j] <= $vmax))
	    && ($y[$j] >= $threshold)) {
	  $integrated += $y[$j];
	  if (!defined $vpeak) {
	    $vpeak = $vlow = $vhigh = $x[$j];
	    $peak = $y[$j];
	  } else {
	    if ($y[$j] > $peak) {
	      $peak = $y[$j];
	      $vpeak = $x[$j];
	    }
	    if ($x[$j] > $vhigh) {
	      $vhigh = $x[$j];
	    }
	    if ($x[$j] < $vlow) {
	      $vlow = $x[$j];
	    }
	  }
	}
      }
      # The integrated flux density needs to be divided by the number of
      # spectral channels in 1 km/s, which is the same as multiplying by 
      # the velocity resolution in km/s.
      my $intscale = abs($x[scalar @x - 1] - $x[0])/(scalar @x);
      $integrated *= $intscale;
      if (defined $vpeak) {
	printf("Peak flux density %.1f at velocity %.1f km/s\n",$peak,$vpeak);
	printf("Velocity range %.1f-%.1f km/s\n",$vlow,$vhigh);
	printf("Integrated flux density %.1f Jy km/s\n",$integrated);
      } else {
	print "No data above threshold of $threshold\n";
      }
    }
  }

  # Set the line style and colour
  pgsls(1);
  
  # Plot any lines
  if ($lines[$i] > 0) {
    my $j = $nline;
    if (defined $linecol[$j]) {
      pgsci($linecol[$j]);
    } else {
      pgsci($PGPLOT_WHITE);
    }
    while ($j < $nline+$lines[$i]) {
      pgmove($line_x1[$j], $line_y1[$j]);
      pgdraw($line_x2[$j], $line_y2[$j]);
      $j++;
    }
  }   
  pgsci($PGPLOT_WHITE);
  
  # Plot any arrows
  if ($arrows[$i] > 0) {
    my $j = $narrow;
    if (defined $arrowcol[$j]) {
      pgsci($arrowcol[$j]);
    } else {
      pgsci($PGPLOT_WHITE);
    }
    while ($j < $narrow+$arrows[$i]) {
      pgarro($arrow_x1[$j], $arrow_y1[$j], $arrow_x2[$j], $arrow_y2[$j]);
      $j++;
    }
  }
  pgsci($PGPLOT_WHITE);

  # Plot any Gaussian
  if ($gauss && ($gaussian[$i] > 0)) {
    my $j = $ngauss;
    if ($gauss_col[$j] ne 'dashed') {
      pgsci($gauss_col[$j]);
    } else {
      pgsls(2);
    }
    my (@gvel, @gdata);
    for (my $k=0 ; $k<1000 ; $k++) {
      push @gvel, $bmin+$k*($bmax-$bmin)/1000.0;
      push @gdata, 0.0;
    }
    while ($j < $ngauss+$gaussian[$i]) {
      my $c = $gwid[$j]/(2.0*sqrt(2.0*log(2.0)));
      for (my $k=0 ; $k<1000 ; $k++) {
	$gdata[$k] += $gamp[$j]*exp(-(($gvel[$k]-$gpos[$j])**2)/(2.0*$c**2));
      }
      $j++;
    }
    pgmove($gvel[0], $gdata[0]);
    pgline(1000, \@gvel, \@gdata);
  }
  pgsci($PGPLOT_WHITE);
  pgsls(1);
  
  
  # Plot any text
  if ($write_text && ($texts[$i] > 0)) {
    pgsch(1.25*$char_size);
    my $j = $ntext;
    while ($j < $ntext+$texts[$i]) {
      pgptxt($text_x[$j], $text_y[$j], 0.0, $justification[$j], $text[$j]);
      $j++;
    }
  }

  # Plot vertical dashed lines if required
  if (scalar @vertlines > 0) {
    if ($pair) {
      pgsls(3);
    } else {
      pgsls(2);
    }
    pgsci($PGPLOT_WHITE);
    for (my $j=0 ; $j<scalar @vertlines ; $j++) {
      pgmove($vertlines[$j], $lmin);
      pgdraw($vertlines[$j], $lmax);
    }
    pgsls(1);
  }
  
  # Plot the sidetext (if present and requested)
  if ($sidetext && $sides[$i] > 0) {
    pgsvp($right_boundary-0.18, 0.99, $top_boundary-(($i+1)*$size), 
	  $top_boundary-($i*$size));
    my $height = ($top_boundary-$bottom_boundary)/1.75;
    my $char_size = (0.25*$height)/0.175;
    $char_size = ($char_size > 1.0) ? 1.0 : $char_size;
    pgsch($char_size);
    my $j = $nside;
    while ($j < $nside+$sides[$i]) {
      my $k = $j-$nside+1;
      pgmtxt('T', -1.5*$k+0.5, 0.0, 0.0, $sidetext[$j]);
      $j++;
    }
    pgsvp($left_boundary, $right_boundary-0.2, $bottom_boundary, 
	  $top_boundary);
  }
  
  # Update all the counters
  $npts += $data[$i]+1;
  $nline += $lines[$i];
  $narrow += $arrows[$i];
  $ntext += $texts[$i];
  $nside += $sides[$i];
  $i++;
  pgsch($char_size);
}
pgebuf;
pgend;

sub colour_num ($) {
  
  my $colour_name = $_[0];
  if ($colour_name =~ /\bblack\b/i) {
    return $PGPLOT_BLACK;
  } elsif ($colour_name =~ /\bwhite\b/i) {
    return $PGPLOT_WHITE;
  } elsif ($colour_name =~ /\bred\b/i) {
    return $PGPLOT_RED;
  } elsif ($colour_name =~ /\bgreen\b/i) {
    return $PGPLOT_GREEN;
  } elsif ($colour_name =~ /\bblue\b/i) {
    return $PGPLOT_BLUE;
  } elsif ($colour_name =~ /\bcyan\b/i) {
    return $PGPLOT_CYAN;
  } elsif ($colour_name =~ /\bmagenta\b/i) {
    return $PGPLOT_MAGENTA;
  } elsif ($colour_name =~ /\byellow\b/i) {
    return $PGPLOT_YELLOW;
  } else {
    return undef;
  }
}

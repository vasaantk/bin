#!/usr/bin/perl -w

# Perl script for arbitary astronomical coordinate conversion. Simon Ellingsen.

# Standard perl modules
use Carp;
use Getopt::Long;
use POSIX qw(asin acos);
use strict;

# Non-standard perl modules
use Astro::Coord;
use Astro::Time;

# Constants
my ($EWXY, $AZEL, $HADEC, $DATE, $J2000, $B1950, $GALACTIC) = 0..6;
my ($CD30M, $MP14M, $MP26M) = 0..2;
my @coord_names = ('X/Y (Y oriented East-West)',
		   'Azimuth/Elevation',
		   'Hour Angle/Declination',
		   'Right Ascension/Declination (date)',
		   'Right Ascension/Declination (J2000)',
		   'Right Ascension/Declination (B1950)',
		   'Galactic (1950)');

# Positions for AT22M, MO22M, PK64M, TI70M and HA26M are from the VLBI
# telescope locations list on the ATNF WWW site (August 1997 edition).
# They are only quoted to an accuracy of 1/100th of a degree.  I have
# also given the incorrect mount type for HA26M as the script doesn't know
# about HADEC mounts yet.
my %details = (
	       CD30M      => ['133:48:36.565', '-31:52:05.04', 161, 
				'Ceduna 30m', $AZEL],
	       MP14M      => ['147:26:24.07', '-42:48:13.92', 64,
				'Mt Pleasant 14m', $AZEL],
	       MP26M      => ['147:26:24.07', '-42:48:13.92', 64,
				'Mt Pleasant 26m', $EWXY],
	       AT22M      => ['149:34:12','-30:18:36', 217, 'ATCA 22m',
			      $AZEL],
	       MO22M      => ['149:04:12','-31:18:00',840, 'Mopra 22m',
			      $AZEL],
	       PK64M      => ['148:15:36','-33:00:00',392, 'Parkes 64m',
			      $AZEL],
	       TI70M      => ['148:58:48','-35:24:00',670, 'Tidbinbilla 70m',
			      $AZEL],
	       HA26M      => ['27:40:12','-25:53:24',1391, 
			      'Hartebeesthoek 26m', $AZEL],
	       ST15M      => ['-70:44:04','-29:15:34',2300,
			      'SEST 15m', $AZEL],
	      );

# Limits for AT22M, MO22M, PK64M, TI70M and HA26M are not correct, they
# are simply copies of the CD30M limits with the ELLOW limit set to 10 degrees
my %limits = (
	      CD30M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 0.8/360.0,
			ELHIGH => 90.2/360.0
		       },
	      MP14M => {
			AZLOW  => -161.0/360.0,
			AZHIGH => 282.0/360.0,
			ELLOW  => 8.0/360.0,
			ELHIGH => 92.0/360.0
		       },
	      MP26M => {
			XLOW          => -83.05/360.0,
                        XHIGH         => 83.05/360.0,
                        YLOW          => -75.95/360.0,
                        YHIGH         => 75.95/360.0,
                        XLOW_KEYHOLE  => -78.05/360.0,
			XHIGH_KEYHOLE => 78.05/360.0,
                        YLOW_KEYHOLE  => -71.05/360.0,
                        YHIGH_KEYHOLE => 71.05/360.0
		       },
	      AT22M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 12.0/360.0,
			ELHIGH => 90.2/360.0
		       },
	      MO22M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 12.0/360.0,
			ELHIGH => 90.2/360.0
		       },
	      PK64M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 30.0/360.0,
			ELHIGH => 90.2/360.0
		       },
	      TI70M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 8.0/360.0,
			ELHIGH => 90.2/360.0
		       },
	      HA26M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 10.0/360.0,
			ELHIGH => 90.2/360.0
		       },
	      ST15M => {
			AZLOW  => -144.5/360.0,
			AZHIGH => 300.0/360.0,
			ELLOW  => 15.0/360.0,
			ELHIGH => 90.2/360.0
		       }
	      );
	      
my $ref0 = 0.00005;
$Astro::Time::StrZero=2;

# Command line options
my $ant_name='MP26M';
my $date;
my $decimal=0;
my $ellimit;
my $help;
my $input='B1950';
my $mjd=now2mjd();
my $output='AZEL';
my $rise=0;
my $version=0;

GetOptions('antenna=s'=>\$ant_name,
	   'date=s'=>\$date,
	   'decimal!'=>\$decimal,
	   'ellimit=f'=>\$ellimit,
	   'help:s'=>\$help,
	   'input=s'=>\$input,
           'mjd=f'=>\$mjd,
	   'output=s'=>\$output,
           'rise!'=>\$rise,
           'version!'=>\$version);

# Global variables
my $VERSION=1.5;
my $VER_DATE='3 November 2003';
my ($input_mode, $output_mode, $antenna, $lmst, $left_in_mode, $left_out_mode,
    $longitude, $latitude);

# Switch off buffering
$|=1;

# If the user requires it print some help
if (defined $help) {
  if ($help eq 'mode') {
    
    # The user wants help on coordinate mode specification.
    print <<MODE
      Valid coordinate modes are :
	EWXY     - X/Y mount with Y axis oriented East/West.
        AZEL     - Azimuth/Elevation.
	HADEC    - Hour Angle/Declination.
	DATE     - Right Ascension/Declination (date).
	J2000    - Right Ascension/Declination (J2000).
        B1950    - Right Ascension/Declination (B1950).
        GALACTIC - Galactic coordinate (1950).

      Some other strings may be recognized, but those listed above are
      recommended
MODE
  } elsif ($help eq 'antenna') {

    # The user wants help on antenna specification.
    print <<ANTENNA
      Valid antennas are :
        CD30M    - Ceduna 30m antenna (AZEL mount).
        MP14M    - Mt Pleasant 14m antenna (AZEL mount).
        MP26M    - Mt Pleasant 26m antenna (EWXY mount).
        AT22M    - ATCA 22m antenna (AZEL mount).
        MO22M    - Mopra 22m antenna (AZEL mount).
        PK64M    - Parkes 64m antenna (AZEl mount).
        TI70M    - Tidbinbilla 70m antenna (AZEL mount).
        HA26M    - Hartebeesthoek 26m antenna (HADEC mount - using AZEL
                                               at present).
ANTENNA
  } else {

    # The user wants some general help.
    print <<HELP;
      This perl script is intended to perform arbitary astronomical 
      coordinate conversion.  The coordinates should be separated by commas

        Usage : $0 [options] <coordinates to be converted>

      The following options are available
        --antenna=<name>   The antenna to perform the conversion for
                           (default=MP26M).  This is only required if
                           either (or both) of the input or output modes
                           are HADEC, AZEL or EWXY, or you are getting
                           rise/set information.
        --date=<string>    The time information in the form 
                           HH:MM:SS.S/dd/mm/yyyy with the time in universal
                           time.  If this time format is specified it
                           overrides the --mjd string.
        --decimal          The output coordinates are written in decimal
                           format rather than hours/degrees, minutes, seconds
                           (default is false).  NOTE: X,Y and Az,El are 
                           output in decimal format regardless.
        --ellimit=<degrees>The elevation limit to use for the --rise option.
                           If this is not specified the antennas elevation
                           limit is used.
        --help=<option>    Recognized options are "mode" and "antenna", if no
                           valid option is entered this message is printed.
                           The "mode" option lists valid coordinate modes and
                           the "antenna" option lists valid antennas
        --input=<mode>     The input coordinate mode (default = B1950).
        --mjd=<time>       The time (as modified Julian day) the conversion 
                           should be performed for (default=now).  This is 
                           only required if either of the input or output
                           modes are DATE, HADEC, AZEL or EWXY.
        --output=<mode>    The output coordinate mode (default = AZEL).
        --rise             Give information on the rise and set time for the
                           input positions.  This option is mutually exclusive
                           with coordinate conversion, so if it is specified
                           no conversion will be performed (default is false).
        --version          Give the version number of the script.
HELP
  }
}
if ($version) {
  print <<VERSION;
  $0 ; Version : $VERSION ; Date : $VER_DATE
VERSION
}
if (defined $help || $version) { exit(0); }

# First determine what the input and output modes are.
$input_mode = &getmode($input);
if (!defined $input_mode) {
  croak "Invalid input coordinate mode : $input (try --help=mode)\n", 
} else {
  if (($input_mode == $EWXY) || 
      ($input_mode == $AZEL) || 
      ($input_mode == $GALACTIC)) {
    $left_in_mode = 'D';
  } else {
    $left_in_mode = 'H';
  }
}
$output_mode = &getmode($output);
if (!defined $output_mode) {
  croak "Invalid output coordinate mode : $output (try --help=mode)\n", 
} else {
  if (($output_mode == $EWXY) || 
      ($output_mode == $AZEL) || 
      ($output_mode == $GALACTIC)) {
    $left_out_mode = 'D';
  } else {
    $left_out_mode = 'H';
  }
}

# If the user wants rise/set information, check that the input mode is
# sensible and force the output mode to RA/Dec (date)
if ($rise) {
  if (($input_mode == $EWXY) || ($input_mode == $AZEL) || 
      ($input_mode == $HADEC)) {
    croak "Invalid input mode for rise/set calculation : $input\nThe input".
      "mode must be one of the celestial coordinate systems\n";
  }
  $output_mode = $DATE;
}

# If necessary determine the antenna the conversion is being performed
# for (if either of the modes are HA/Dec, AzEl or EWXY).
if (($input_mode <= $HADEC) || ($output_mode <= $HADEC) || $rise) {
  $antenna = &getant($ant_name);
  if (!defined $antenna) {
    croak "Invalid antenna : $ant_name (try --help=antenna)\n", 
  }
  $longitude = str2turn($details{$antenna}[0],'D');
  $latitude = str2turn($details{$antenna}[1],'D');
} else {
  $antenna = undef;
  $longitude = undef;
  $latitude = undef;
}

# If an elevation limit has been given, override the default
if (defined $ellimit) {
  $limits{$antenna}{ELLOW} = $ellimit/360.0;
  $details{$antenna}[4]=1;
}

print "--COORD.PL--\n";
# Check if the date has been specified in the --date option
if (defined $date) {
  my @date = split('/',$date);
  my $ut = str2turn($date[0],'H');
  $mjd = cal2mjd($date[1],$date[2],$date[3],$ut);
  printf "Date : %2d/%2d/%2d at UT %s corresponds to MJD %.6f\n",
  $date[1],$date[2],$date[3],turn2str($ut,'H',1),$mjd;
}

# Perform the conversion and output the results
if ($rise) {
  print "Rise/Set time calculations\n";
  printf "For antenna                   : %s\n", $details{$antenna}[3];
  if ($details{$antenna}[4] == $AZEL) {
    printf "Using elevation limit         : %.1f degrees\n", $limits{$antenna}{ELLOW}*360.0;
  } elsif ($details{$antenna}[4] == $EWXY) {
    printf "Which is an EWXY mount (no simple elevation limit)\n";
  }
  print "At MJD                        : $mjd\n";
} else {
  print "Coordinate conversion(s) from : $coord_names[$input_mode]\n";
  print "                           to : $coord_names[$output_mode]\n";
  if (defined $antenna) {
    printf "For antenna                   : %s\n", $details{$antenna}[3];
    print "At MJD                        : $mjd\n";
    my $lmst = mjd2lst($mjd, $longitude);
    printf "which is LMST                 : %s\n", turn2str($lmst,'H',0);
  }
}
print "\n";

my $i = 1;
while (<>) {

  # Split the input string into separate coordinates
  chomp $_;
  my @coords = split(",",$_);

  # Check that the coordinate pairs are complete
  my $n = scalar @coords;
  if ($n%2 == 1) {
    croak "Problem on line : $i of input, coordinates must be paired\n";
  }

  # Do the conversion for each pair
  for (my $j=0 ; $j<$n/2 ; $j++) {
    my $input_left = str2turn($coords[$j*2],$left_in_mode);
    my $input_right = str2turn($coords[$j*2+1],'D');

    my ($output_left, $output_right) = 
      coord_convert($input_left, $input_right, $input_mode, $output_mode, 
		    $mjd, $longitude, $latitude, $ref0);
  
    if ($rise) {

      my ($ut, $day, $month, $year, $dayno, $lmst_rise, $lmst_set, $mjd_rise,
	  $mjd_set, $ut_rise, $ut_set);

      # Produce the rise/set output
      ($dayno, $year, $ut) = mjd2dayno(int $mjd);
      if ($i == 1) {
	($day, $month, $year, $ut) = mjd2cal(int $mjd);
	my $utstr = sprintf "UT DOY %03d (%02d/%02d/%4d)", $dayno, $day,
	$month, $year;
	printf "%-32s%-15s%-30s\n", 'Input coordinates', 'LMST', $utstr;
	printf "%-25s%-10s%-10s%-15s%-15s\n", $coord_names[$input_mode], 
	'Rise', 'Set', 'Rise', 'Set';
      }
      my $haset = antenna_rise($output_right, 
			       str2turn($details{$antenna}[1],'D'), 
			       $details{$antenna}[4], $limits{$antenna});
      if ($haset == 1.0) {
	printf "%-25s%35s\n", 
	$coords[$j*2].",".$coords[$j*2+1],"Circumpolar (never sets)";
      } elsif ($haset == 0.0) {
	printf "%-25s%35s\n", 
	$coords[$j*2].",".$coords[$j*2+1],"Never rises";
      } else {
	$lmst_rise = $output_left - $haset;
	if ($lmst_rise < 0.0) { $lmst_rise += 1.0; }
	$lmst_set = $output_left + $haset;
	if ($lmst_set > 1.0) { $lmst_set -= 1.0; }
	$mjd_rise = lst2mjd($lmst_rise, $dayno, $year, 
			    str2turn($details{$antenna}[0],'D'));
	$mjd_set = lst2mjd($lmst_set, $dayno, $year, 
			   str2turn($details{$antenna}[0],'D'));
	if ($mjd_set < $mjd_rise) {
	  ($dayno, $year, $ut) = mjd2dayno(int($mjd) + 1.0);
	  $mjd_set = lst2mjd($lmst_set, $dayno, $year, 
			     str2turn($details{$antenna}[0],'D'));
	}
	$ut_rise = $mjd_rise - int $mjd_rise;
	$ut_set  = $mjd_set - int $mjd_set;
	my $lrstr = turn2str($lmst_rise, 'H', 0);
	my $lsstr = turn2str($lmst_set, 'H', 0);
	($dayno, $year, $ut) = mjd2dayno($mjd_rise);
	my $urstr = sprintf "%03d/%s", $dayno, turn2str($ut_rise, 'H', 0);
	($dayno, $year, $ut) = mjd2dayno($mjd_set);
	my $usstr = sprintf "%03d/%s", $dayno, turn2str($ut_set, 'H', 0);
	printf "%-25s%-10s%-10s%-15s%-15s\n", 
	$coords[$j*2].",".$coords[$j*2+1],$lrstr, $lsstr, $urstr, $usstr;
      }
    } else {

      # Produce the coordinate conversion output
      if ($i == 1) {
	printf "%-40s%-40s\n", 'Input coordinates', 'Output coordinates';
	printf "%-40s%-40s\n", $coord_names[$input_mode], 
	$coord_names[$output_mode];
      }
      printf "%-40s", $coords[$j*2].",".$coords[$j*2+1];
      if ($output_mode == $EWXY) {
	printf "%06.3f,%06.3f\n", $output_left*360.0, $output_right*360.0;
      } elsif ($output_mode == $AZEL) {
	printf "%07.3f,%06.3f\n", $output_left*360.0, $output_right*360.0;
      } elsif (($output_mode >= $HADEC) && ($output_mode <= $B1950)) {
	my $rastr = turn2str($output_left, 'H', 1);
	my $decstr = turn2str($output_right, 'D', 1);
	if ($decimal) {
	  printf "%.4f,%.4f\n", $output_left*360.0, $output_right*360.0;
	} else {
	  print "$rastr,$decstr\n";
	}
      } elsif ($output_mode == $GALACTIC) {
	my $lstr = turn2str($output_left, 'D', 1);
	my $bstr = turn2str($output_right, 'D', 1);
	if ($decimal) {
	  printf "%.4f,%.4f\n", $output_left*360.0, $output_right*360.0;
	} else {
	  print "$lstr,$bstr\n";
	}
      }
    }
    $i++;
  }
}

# Subroutines
sub getmode($) {

  # Convert the passed string into a coordinate mode.
  # undef is returned if if can't be worked out
  $_ = $_[0];
  if (/xy|x\/y|ewxy/i) {
    return $EWXY;
  } elsif (/azel|azimuth\/elevation/i) {
    return $AZEL;
  } elsif (/hadec|hour angle\/declination/i) {
    return $HADEC;
  } elsif (/date|ra\/dec(date)/i) {
    return $DATE;
  } elsif (/j2000|ra\/dec(j2000)/i) {
    return $J2000;
  } elsif (/b1950|ra\/dec(b1950)/i) {
    return $B1950;
  } elsif (/lb|galactic/i) {
    return $GALACTIC;
  } else {
    return undef;
  }
}

sub getant($) {

  # Determine the antenna from the passed string
  $_ = $_[0];
  if (/cd30m|30m|cd|ceduna|ceduna 30m/i) {
    return 'CD30M';
  } elsif (/mp14m|14m|mt pleasant 14m/i) {
    return 'MP14M';
  } elsif (/mp26m|mp|mt pleasant|mt pleasant 26m/i) {
    return 'MP26M';
  } elsif (/at22m|at|atca|narrabri|culgoora/i) {
    return 'AT22M';
  } elsif (/mo22m|mopra|mopra 22m/i) {
    return 'MO22M';
  } elsif (/pk64m|parkes|parkes 64m/i) {
    return 'PK64M';
  } elsif (/ti70m|tid|tidbinbilla|dss 43|tidbinbilla 70m/i) {
    return 'TI70M';
  } elsif (/ha26m|harte|hartebeesthoek|hartebeesthoek 26m/i) {
    return 'HA26M';
  } else {
    return undef;
  }
}

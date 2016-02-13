package notastro;
use strict;
use Carp;
use POSIX qw(floor);

#
# written by Chris Phillips 
#              and change for new format of possm
BEGIN {
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_FAIL 
		      %EXPORT_TAGS);
    $VERSION     = 0.2.5;
    @ISA         = qw(Exporter);
    @EXPORT      = qw(getval read_file minmatch maxmin boundary binit
		      sumlist addlist avlist fitline shuffle stats
		      flatten);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
    @EXPORT_FAIL = qw();

    use FileHandle;
    use POSIX qw(asin);
}

=head1 NAME

notastro - misc routines

=head1 SYNOPSIS

use notastro;

=head1 DESCRIPTION

notastro contains some useful routines, not related to astronomy.

=head1 AUTHOR

Chris Phillips

=head1 TODO

Some routines need better documentation.

=cut

sub getval ($$) {  
#+
# Read a value from STDIN with prompt and default
# Usage:
#   $retval = getval($prompt, $default);
#-
    my($prompt, $default) = @_;
    print "$prompt [$default] ";
    my $out = <STDIN>;
    chomp($out);
    $out = $default if ($out eq "");
    return $out;
}

sub read_file ($\%) {
#+
# Read in a file with a space seperated heading line
# Usage: 
#   Use Filehandle;
#   my $fh = FileHandle->new;
#   open($fh, 'somefile');
#   read_file($fh, %hash);
#
# The hash returned as $$hashref has the headings from
# the heading line UPPERCASED as keys,
# and values are anonymous, zero-index-based arrays corresponding
# to the columns.
#
# Especially useful for routines like pgperl which wouldn't
# know an object model from a common block. (Little does DPR know!)
#-
    my($fh, $hashref) = @_;

    my($eof, $nc, $c, $i, $n);
    my(@columns, @data);
    
    #Read first (non-blank) line of file
    $eof = 1;
    while (<$fh>) {
	if (!/^\s*$/) {
	    @columns = split /\s+/;
	    $eof = 0;
	    last;
	}
    }

    return 2 if $eof;

    # Initialise the hash ref
    $nc = scalar @columns;
    for $c (@columns) {
	$c = uc $c;
	$$hashref{$c} = [()];
    }

    #Read the data in
    $eof = 1;
    $n = 0;
    while (<$fh>) {
	if (!/^\s*$/) {
	    @data = split /\s+/;
	    $n++;
	    for ($i=0; $i<$nc && $i<@data; $i++) {
		push @{$$hashref{$columns[$i]}}, $data[$i];
	    }
	}
    }
    
    croak "$0: No Data read\n" if ($n == 0);

    return $eof;
       
}

sub minmatch {
#+
# Match and return a keyword in list, using minimal matching 
# (ie 'Fr' matches 'Fred' and 'Frank')
# Usage:
#   @list = ( 'Fred', 'Frank', 'William');
#   $key = 'Fr';
#   @matches = minmatch($key, @list);  # Returns ('Fred', 'Frank')
#
# Returns undef if no matches found. 
# Wild cards are allowed:   *   match any number of characters
#                           ?   Match one character
#-
    my($key, $list) = @_;
    
    my ($n, $i);
    my $found = 0;
    my @match = ();
    # Clean up the key
    $key =~ s/\./\\\./g;  # Pass '.'s (. -> \.)
    $key =~ s/\+/\\\+/g;  # Pass '+'s (+ -> \+)
    $key =~ s/\[/\\\[/g;  # Pass '['s (+ -> \[)
    $key =~ s/\]/\\\]/g;  # Pass ']'s (+ -> \])
    $key =~ s/\(/\\\(/g;  # Pass '('s (+ -> \()
    $key =~ s/\)/\\\)/g;  # Pass ')'s (+ -> \))
    $key =~ s/\*/\.\*/g;  # Allow simple wild cards ( * -> .* )
    $key =~ s/\?/\./g;    # ? matches single character (? -> .)

    $i = 0;
    foreach (@$list) {
	if (/^$key/i) {
	    push @match, $_;
	    if (!$found) {
		$n = $i;       # Return index of first match
		$found = 1;
	    } else {
		$n = -1;       # Return -1 if multiple matches
	    }
	}
	$i++;
    }

    if ($found) {
	return $n, @match;
    } else {
	return undef;
    }
};

sub maxmin {
#+
# return max and min of a list
# Usage:
# ($max,$min)=maxmin(@list);
#-
    my $max  = shift(@_);
    my $min  = $max;
    my $val;
    foreach $val (@_) {
        if ($val < $min) {
            $min = $val;
        } elsif ($val > $max) {
            $max = $val;
        }
    }
    return ($max,$min);
}

sub boundary ($$$) {
    my ($max, $min, $factor) = @_;
    
    my $delta = ($max - $min) * $factor;
    $_[0] += $delta;
    $_[1] -= $delta;
}

sub binit ($$$@) {
    my ($x0, $width, $nbin, @data) = @_;

    my $n = scalar(@data);
    my ($i, $bin);

    my @binned = ();
    for ($i=0; $i< $nbin+2; $i++) {
	$binned[$i] = 0;
    }

    for ($i=0; $i<$n; $i++) {
	$bin = floor(($data[$i] - $x0)/$width);
	$bin = $nbin if $bin < 0;
	if ($bin >= $nbin) {
	    $bin = $nbin+1 ;
	}
	$binned[$bin]++;
    }

    return(@binned);
}

sub addlist (\@\@) {
#+
# Add the elements of two list pairwise and return as a list
# Usage:
#  @newlist = addlist(@list1, @list2);
#-
    my ($l1, $l2) = @_;

    my @sum = ();

    my ($i);

    for ($i=0; defined($$l1[$i]) && defined($$l2[$i]); $i++) {
	push @sum, $$l1[$i] + $$l2[$i];
    }

    return (@sum);
}

sub sumlist (@) {
#+ 
# Add the elements of a list
# Usage:
#  $sum = sumlist(@list);
#-
    my ($i, $sum);
    $sum = 0.0;
    for $i (@_) {
	$sum+= $i;
    }
    return($sum);
}

sub avlist (@) {
#+ 
# Return the average value of a list
# Usage:
#  $av = avlist(@list);
#-
    my ($n, $sum);
    $sum = 0.0;
    $n = 0;
    for (@_) {
	$sum+= $_;
	$n++;
    }
    croak 'avlist: Empty list. Called' if ($n == 0);
    return($sum/$n);
}

sub fitline (\@\@) {
#+ 
# Fit a line to some data points, using least squares
# Usage:
#   ($m, $b) = fitline(@x, @y)
# $m          Slope of line
# $b          Y-intercept  (y = mx + b)
# @x, @y      Arrays of data points
#-
    my ($x, $y) = @_;

    my $sx = $$x[0];
    my $sx2 = $$x[0]*$$x[0];
    my $sy = $$y[0];
    my $sy2 = $$y[0]*$$y[0];
    my $sxy = $$x[0]*$$y[0];

    my $n = (@$x<@$y) ? @$x : @$y;

    my $i;
    for ($i = 1; $i<$n; $i++) {
	$sx += $$x[$i];
	$sx2 += $$x[$i]*$$x[$i];
	$sy += $$y[$i];
	$sy2 += $$y[$i]*$$y[$i];
	$sxy += $$x[$i]*$$y[$i];
    }
 
    my $delta = $n*$sx2 - $sx*$sx;
    my $m = ($n*$sxy - $sx*$sy)/$delta;
    my $b = ($sx2*$sy - $sx*$sxy)/$delta;
    return($m,$b);
}

sub flatten (\@\@$$) {
#+ 
# Project a set of x and y values onto the line y = mx + b
# Usage:
#   @a = flatten(@x,@y,$m,$b)
#-
    my ($x, $y, $m, $b) = @_;
    
    return (@{$x}) if ($m == 0.0);

    my @a = ();
    my ($i, $x1, $y1, $a);
    my $n = scalar(@$x) < scalar(@$y) ? scalar(@$x) : scalar(@$y);
    for ($i=0; $i<$n; $i++) {
	$x1 = ($$x[$i] + $m*($$y[$i] - $b))/($m*$m + 1);
	$y1 = $m*$x1 + $b;
	$a = sqrt($x1*$x1 + ($y1-$b)**2);
	$a = -$a if ($$x[$i] < 0.0);
	push @a, $a;
    }
    return @a;
}

sub shuffle (@) {
#+ 
# Shuffle (randomly) the values of a list
# Usage:
#   @sorted = shuffle(@x)
#-
    my (@x) = @_;
    my @new = ();
    my $i;

    while (scalar(@x)) {
	$i = int(rand(scalar(@x)));
	push @new, splice @x, $i, 1;
    }
    return @new;
}

sub stats (@) {
#+
# Return some simple stats on the data in a list
# Usage:
#  ($mean, $dev, $sig) = stats(@data);
#-

    # First pass to get the mean
    my $s = 0;
    my $n = 0;
    foreach (@_) {
	$s += $_;
	$n++;
    }
    return undef if ($n<=1);

    my $av = $s/$n;
    # Second pass to get sigma
    my $ss;
    my $d = 0;
    $s = 0;
    foreach (@_) {
	$ss = $_ - $av;
	$s += $ss*$ss;
	$d += abs($ss);
    }
    # Return mean, average deviation and sigma
    return($av, $d/$n, sqrt($s/($n-1)));
}   
 
END { }
1;


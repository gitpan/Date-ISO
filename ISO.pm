package Date::ISO;

use strict;
use vars qw( $VERSION @ISA @EXPORT );
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( localiso iso inverseiso);
$VERSION = (qw'$Revision: 1.17 $')[1];

=head1 NAME

Date::ISO - Perl extension for converting dates between ISO and
Gregorian formats.

=head1 SYNOPSIS

  use Date::ISO;
  ($yearnumber, $weeknumber, $weekday) = iso($year, $month, $day);

Note that year and month here are as given by localtime, not as given by a
calendar. Hence, January 1, 2001 is (101, 0, 1). This is probably undesired
behavior, and may be changed in a future release.

  ($yearnumber, $weeknumber, $weekday) = localiso(time);
  ($year, $month, $day) = inverseiso($iso_year, $iso_week, $iso_week_day);

Or, using the object interface:

  use Date::ISO qw();
  my $iso = Date::ISO->new( ISO => $iso_date_string );

  $iso_year = $iso->iso_year;
  $year = $iso->year;

  $iso_week = $iso->iso_week;
  $week_day = $iso->iso_week_day;

  $month = $iso->month;
  $day = $iso->day;

=head1 DESCRIPTION

Convert dates between ISO and Gregorian formats.


=head2 iso

	($year, $week, $day) = iso($year, $month, $day);
    ($year, $week, $day) = iso(2001, 4, 28); # April 28, 2001

Returns the ISO year, week, and day of week, when given the (Gregorian)
year, month, and day.

Note that years are full 4 digit years, and months are numbered with January
being 1. 

=cut

sub iso	{
	my ($year, $month, $day) = @_;
	my ($doy, $yy, $c, $g, $janone,	$h,	$weekday,
		$yearnumber, $weeknumber, $i, $j,
		$leap, $lastleap,
		);

    $month--; # It is convenient to have months 0-based internally
    $day += 0;

	my %doy = ( 0 => 0, 1 => 31, 2 => 59, 3 => 90,
		4 => 120, 5 => 151, 6 => 181, 7 => 212, 8 => 243,
		9 => 273, 10 => 304, 11 => 334 );
	$doy = $doy{$month} + $day;
	$leap = isleap($year);
	$lastleap = isleap($year - 1);
	$doy++ if ($leap && $month > 1);
	$yy = ($year - 1) % 100;
	$c = ($year - 1) - $yy;
	$g = $yy + int($yy/4);
	$janone = 1 + (((( (int($c/100)) % 4) * 5) + $g) % 7);
	$h = $doy + ($janone - 1);
	$weekday = 1 + (($h - 1) % 7);
	$i = $leap ? 366 : 365;
	# Is it really the last week of last year?
	if ( ($doy <= (8 - $janone)) && ($janone > 4) )	{
		$yearnumber = $year - 1;
		if ($janone == 5 || ($janone == 6 && $lastleap ))	{
			$weeknumber = 53;
		} else {
			$weeknumber = 52;
		}
	}
	# Is it really the first week of next year?
	elsif ( ($i - $doy) < (4 - $weekday) )	{
		$yearnumber = $year + 1;
		$weeknumber = 1;
	} else {
		$yearnumber = $year;
		$j = $doy +	(7 - $weekday) + ($janone - 1);
		$weeknumber = int ($j / 7);
		if ($janone > 4)	{
			$weeknumber--;
		}
	}
	return ($yearnumber, $weeknumber, $weekday);
    # The ISO year day is apparently $doy - $janone + 1, but I'm not certain.
    # I'll have to think about this a little more.
}
		
=head2 inverseiso

	($year, $month, $day) = inverseiso($year, $week, $day);

Given an ISO year, week, and day, returns year, month, and day, as
localtime would give them to you.

=cut

sub inverseiso	{
	my ($yearnumber, $weeknumber, $weekday) = @_;
	my ($yy, $c, $g, $janone, $eoy,
		$year, $month, $day, $doy,
		);
	$yy = ($yearnumber - 1) % 100;
	$c = ($yearnumber - 1) - $yy;
	$g = $yy + int($yy / 4);
	$janone = 1 + (((( int($c / 100) % 4) * 5) + $g) % 7);
	if (($weeknumber == 1) && ($janone < 5) && ($weekday < $janone))	{
		$year = $yearnumber - 1;
		$month = 12;
		$day = 32 - ($janone - $weekday);
	} else {
		$year = $yearnumber;
	}
	$doy = ($weeknumber - 1) * 7;
	if ($janone < 5)	{
		$doy += $weekday - ($janone - 1);
	} else {
		$doy += $weekday + (8 - $janone);
	}
	if (isleap($yearnumber))	{
		$eoy = 366;
	} else {
		$eoy = 365;
	}
	if ($doy > $eoy)	{
		$year = $yearnumber + 1;
		$month = 1;
		$day = $doy - $eoy;
	} else {
		$year = $yearnumber;
	}
	if ($year == $yearnumber)	{
		my @month = (31, 28, 31, 30, 31,30, 31, 31, 30, 31, 30, 31);
		$month[1] = 29 if (isleap($year));
		my $h = 0;
		$month=0;
		for my $days (@month)	{
			last if $h > $doy;
			$h += $days;
			$month++;
		}
		# $month--;
		$day = $doy - ($h - $month[$month]) + 1;
	}

	return ($year, $month, $day);
}

=head2 localiso

	($year, $week, $day) = localiso(time);

Given a time value (epoch time) returns the ISO year, week, and day.

=cut

sub localiso	{
	my ($datetime) = @_;
	$datetime ||= time;
	my ($day, $month, $year) = (localtime($datetime))[3,4,5];
	return iso($year + 1900, $month + 1, $day);
}

sub isleap	{
	my ($year) = @_;
	return 1 if $year%4==0;
	return 1 if ($year%4==0 && !$year%100);
	return 0;
}

=head1 OO interface

The OO interface allows you to create a date object, and determime from it the
various attributes in the ISO calendar (the year, week, and day of that week)
and in the Gregorian reckoning (the year, month, and day).

=head2 new

    my $iso = Date::ISO->new( ISO => $iso_date_string );

or ...

    my $iso = Date::ISO->new( EPOCH = $epoch_time );

Accepted ISO date string formats are:

    1997-02-05 (Feb 5, 1997)
    19970205 (Same)
    199702 (February 1997)
    1997-W06 (6th week, 1997)
    1997W06 (Same)
    1997-W06-2 (6th week, 2nd day)
    1997W062 (Same as above)
    1997-035 (35th day of 1997)
    1997035 (Same as above)

2-digit representations of the year are not supported at this time.

Time values are not supported at this time.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my %date;
    
    # ISO date string passed in?
    if ($args{ISO} ) {

        # 1997-02-05 or 19970205 formats
        if ( $args{ISO} =~ m/^(\d\d\d\d)-?(\d\d)-?(\d\d$)/ ) {

            @date{ '_year', '_month', '_day' } = ( $1, $2, $3 );

            @date{ '_iso_year', '_iso_week', '_iso_week_day' } = 
                iso( $date{_year}, $date{_month}, $date{_day} );

        # 199702 format
        } elsif ( $args{ISO} =~ m/^(\d\d\d\d)(\d\d)$/ ) {
            @date{ '_year', '_month' } = ( $1, $2 );
            $date{_day} = 1;

            @date{ '_iso_year', '_iso_week', '_iso_week_day' } = 
                iso( $date{_year}, $date{_month}, 1 );

        # 1997-W06-2 or 1997W062 format
        } elsif ( $args{ISO} =~ m/^(\d\d\d\d)-?W(\d\d)-?(\d)$/ ) {
            @date{ '_iso_year', '_iso_week', '_iso_week_day' } 
                = ( $1, $2, $3);
            
            @date{ '_year', '_month', '_day' } = inverseiso( $date{_iso_year},
                $date{_iso_week}, $date{_iso_week_day} );

        # 1997-W06 or 1997W06 format
        } elsif ( $args{ISO} =~ m/^(\d\d\d\d)-?W(\d\d)$/ ) {
            @date{ '_iso_year', '_iso_week' } = ( $1, $2 );
            $date{_iso_week_day} = 1;

            @date{ '_year', '_month', '_day' } = 
                inverseiso( $date{_iso_year}, $date{_iso_week}, 1 );

        # 1997-035 or 1997035 format
        } elsif ( $args{ISO} =~ m/^(\d\d\d\d)-?(\d\d\d)$/ ) {
            
            $date{_iso_year} = $1;
            $date{_iso_week} = int ( $2 / 7 ) + 1;
            $date{_iso_week_day} = ( $2 % 7 ) + 1;

            @date{ '_year', '_month', '_day' } = inverseiso( 
                $date{_iso_year}, $date{_iso_week}, $date{_iso_week_day} );

        # Don't know what the format was
        } else {
            warn('Did not recognize this as valid ISO date string format');
        }

    } elsif ( $args{EPOCH} ) {
    
        @date{ '_day', '_month', '_year' } = 
            ( localtime( $args{EPOCH} ))[3, 4, 5];
        $date{_month}++;
        $date{_year}+=1900;

        @date{ '_iso_year', '_iso_week', '_iso_week_day' } = 
            localiso( $args{EPOCH} );
        
    } else {
        warn('Dude. Read the docs. Sheesh.');
    }

    my $self = bless \%date, $class;
    return $self;
}

sub iso_year     { $_[0]->{_iso_year} }
sub iso_week     { $_[0]->{_iso_week} }
sub iso_week_day { $_[0]->{_iso_week_day} }

sub day   { $_[0]->{_day} }
sub month { $_[0]->{_month} }
sub year  { $_[0]->{_year} }

1;

__END__

=head1 AUTHOR

Rich Bowen (rbowen@rcbowen.com)

=head1 DATE

$Date: 2001/04/30 13:23:35 $

=head1 Additional comments

For more information about this calendar, please see:

http://personal.ecu.edu/mccartyr/ISOwdALG.txt

http://personal.ecu.edu/mccartyr/isowdcal.html

http://www.cl.cam.ac.uk/~mgk25/iso-time.html

=head1 To Do

Need to flesh out test suite some more. Particularly need to test some dates
immediately before and after the first day of the year - days in which you
might be in a different Gregorian and ISO years.

ISO date format also supports a variety of time formats. I suppose I should
accept those as valid arguments.

Need methods to output epoch time, and a variety of valid ISO date strings,
from a Date::ISO object.

=head1 Version History

    $Log: ISO.pm,v $
    Revision 1.17  2001/04/30 13:23:35  rbowen
    Removed AutoLoader from ISA, since it really isn't.

    Revision 1.16  2001/04/29 21:31:04  rbowen
    Added new tests, and fixed a lot of bugs in the process. Apparently the
    inverseiso function had never actually worked, and various other functions
    had some off-by-one problems.

    Revision 1.15  2001/04/29 02:42:03  rbowen
    New Tests.
    Updated MANIFEST, Readme for new files, functionality
    Fixed CVS version number in ISO.pm

    Revision 1.14  2001/04/29 02:36:50  rbowen
    Added OO interface.
    Changed functions to accept 4-digit years and 1-based months.

=cut


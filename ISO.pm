package Date::ISO;

use strict;
use vars qw( $VERSION @ISA @EXPORT );
require Exporter;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( localiso iso inverseiso);
$VERSION = '1.01';

=head1 NAME

Date::ISO - Perl extension for converting dates between ISO and
Gregorian formats.

=head1 SYNOPSIS

  use Date::ISO;
  ($yearnumber, $weeknumber, $weekday) = iso($year, $month, $day);

=head1 DESCRIPTION

Convert dates between ISO and Gregorian formats.

=head2 iso

	($year, $week, $day) = iso($year, $month, $day);

Returns the ISO year, week and day, when given the year, month, and day,
as returned by localtime. (That is, months are zero-based, years are
-1900.)

=cut

sub iso	{
	my ($year, $month, $day) = @_;
	my ($doy, $yy, $c, $g, $janone,	$h,	$weekday,
		$yearnumber, $weeknumber, $i, $j,
		$leap, $lastleap,
		);

	my %doy = ( 0 => 0, 1 => 31, 2 => 59, 3 => 90,
		4 => 120, 5 => 151, 6 => 181, 7 => 212, 8 => 243,
		9 => 273, 10 => 304, 11 => 334 );
	$doy = $doy{$month} + $day;
	$leap = isleap($year);
	$lastleap = isleap($year - 1);
	$year += 1900;
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
	$weeknumber = sprintf('%02d',$weeknumber);
	return ($yearnumber, $weeknumber, $weekday);
}
		
# =head2 inverseiso
# 
# 	($year, $month, $day) = inverse_iso($year, $week, $day);
# 
# Given an ISO year, week, and day, returns year, month, and day, as
# localtime would give them to you.
# 
# =cut

sub inverseiso	{

}

=head2 localiso

	($year, $week, $day) = localiso(time);

Given a time value (epoch time) returns the ISO year, week, and day.

=cut

sub localiso	{
	my ($datetime) = @_;
	my ($year, $month, $day) = (localtime($datetime))[5,4,3];
	return iso($year, $month, $day);
}

sub isleap	{
	my ($year) = @_;
	$year += 1900;
	return 1 if $year%4==0;
	return 1 if ($year%4==0 && !$year%100);
	return 0;
}

1;

__END__

=head1 AUTHOR

Rich Bowen <rbowen@rcbowen.com>

=head1 Additional comments

For more information about this calendar, please see:

http://personal.ecu.edu/mccartyr/ISOwdALG.txt

http://personal.ecu.edu/mccartyr/isowdcal.html

=cut

#$Header: /home/cvs/date-iso/ISO.pm,v 1.19 2001/07/30 00:50:07 rbowen Exp $
package Date::ISO;

use strict;
use warnings;
use base qw(Date::ICal);

our $VERSION = (qw'$Revision: 1.19 $')[1];
use Date::Leapyear qw();

=head1 NAME

Date::ISO - Perl extension for converting dates between ISO and
Gregorian formats.

=head1 SYNOPSIS

  use Date::ISO;
  $iso = Date::ISO->new( iso => $iso_date_string );
  $iso = Date::ISO->new( epoch => $epoch_time );
  $iso = Date::ISO->new( ical => $ical_string );

  $iso_year = $iso->iso_year;
  $year = $iso->year;

  $iso_week = $iso->iso_week;
  $week_day = $iso->iso_week_day;

  $month = $iso->month;
  $day = $iso->day;

=head1 DESCRIPTION

Convert dates between ISO and Gregorian formats.

=head2 new

    my $iso = Date::ISO->new( iso => $iso_date_string );
    my $iso = Date::ISO->new( epoch = $epoch_time );

And, since this is a Date::ICal subclass ...

    my $iso = Date::ISO->new( ical => $ical_string );
    $ical = $iso->ical;

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

sub new {    #{{{
    my $class = shift;
    my %args  = @_;
    my $self;

    $args{iso}   = $args{ISO}   if defined $args{ISO};   # Deprecated
    $args{epoch} = $args{EPOCH} if defined $args{EPOCH}; # Deprecated

    # ISO date string passed in?
    if ( $args{iso} ) {

        # 1997-02-05 or 19970205 formats
        if ( $args{iso} =~ m/^(\d\d\d\d)-?(\d\d)-?(\d\d$)/ ) {

            $self = $class->SUPER::new( year => $1, 
                    month => $2, day => $3, hour => 0,
                    min => 0, sec => 0 );

        }

        # 199702 format
        elsif ( $args{iso} =~ m/^(\d\d\d\d)(\d\d)$/ ) {
            
            $self = $class->SUPER::new( year => $1, month => $2,
                day => 1, hour => 0, min => 0, sec => 0 );
        }

        # 1997-W06-2, 1997W062,, 1997-06-2, 1997062, 1996-06, 1997W06  formats
        # 199706 has already matched above, and means something else.
        elsif ( $args{iso} =~ m/^(\d\d\d\d)-?W?(\d\d)-?(\d)?$/ ) {

            my $iso_day = (defined($3) ? $3 : 1);
            my ( $year, $month, $day ) = 
              from_iso( $1, $2, $iso_day );

            $self = $class->SUPER::new( year => $year, month => $month,
                day => $day, hour => 0, min => 0, sec => 0 );

        # Don't know what the format was
        }
        else {
            warn('Did not recognize this as valid ISO date string format');
        }

    }

    # Otherwise, just pass arguments to Date::ICal
    else {

        $self = $class->SUPER::new( %args );

    }

    bless $self, $class;
    return $self;
}    #}}}

# Pod::Tests inline tests #{{{

=begin testing

use lib '../blib/lib';
use Date::ISO;

my $t1 = Date::ISO->new( day => 25, month => 10, year => 1971 );
ok ($t1->day == 25, 'day()');
ok ($t1->month == 10, 'month()');
ok ($t1->year == 1971, 'year()');
ok ($t1->ical eq '19711025Z', 'ical()');
ok ($t1->epoch == 57196800, 'epoch()');

my $t2 = Date::ISO->new( iso => '1971-W43-1' );
ok ($t2->day == 25, 'day()' );
ok ($t2->month == 10, 'month()');
ok ($t2->year == 1971, 'year()');

=end testing

#}}}

=head2 to_iso

  ( $isoyear, $isoweek, $isoday ) = to_iso( $year, $month, $day );

Returns the iso year, week, and day, given the gregorian year, month,
and day. This should be considered an internal method, and is subject
to change at any time.

=cut

sub to_iso {    #{{{
    my ( $year, $month, $day ) = @_;
    my ( $doy, $yy, $c, $g, $janone, $h, $weekday,
        $yearnumber, $weeknumber, $i,
        $j, $leap, $lastleap, );

    $month--;    # It is convenient to have months 0-based internally
    $day += 0;

    my %doy = (
      0  => 0,
      1  => 31,
      2  => 59,
      3  => 90,
      4  => 120,
      5  => 151,
      6  => 181,
      7  => 212,
      8  => 243,
      9  => 273,
      10 => 304,
      11 => 334
    );
    $doy      = $doy{$month} + $day;
    $leap     = Date::Leapyear::isleap($year);
    $lastleap = Date::Leapyear::isleap( $year - 1 );
    $doy++ if ( $leap && $month > 1 );
    $yy      = ( $year - 1 ) % 100;
    $c       = ( $year - 1 ) - $yy;
    $g       = $yy + int( $yy / 4 );
    $janone  = 1 + ( ( ( ( ( int( $c / 100 ) ) % 4 ) * 5 ) + $g ) % 7 );
    $h       = $doy + ( $janone - 1 );
    $weekday = 1 + ( ( $h - 1 ) % 7 );
    $i       = $leap ? 366 : 365;

    # Is it really the last week of last year?
    if ( ( $doy <= ( 8 - $janone ) ) && ( $janone > 4 ) ) {
        $yearnumber = $year - 1;
        if ( $janone == 5 || ( $janone == 6 && $lastleap ) ) {
            $weeknumber = 53;
        }
        else {
            $weeknumber = 52;
        }
    }

    # Is it really the first week of next year?
    elsif ( ( $i - $doy ) < ( 4 - $weekday ) ) {
        $yearnumber = $year + 1;
        $weeknumber = 1;
    }
    else {
        $yearnumber = $year;
        $j = $doy + ( 7 - $weekday ) + ( $janone - 1 );
        $weeknumber = int( $j / 7 );

        if ( $janone > 4 ) {
            $weeknumber--;
        }
    }

    return ($yearnumber, $weeknumber, $weekday);
}    #}}}

=head2 from_iso

	($year, $month, $day) = from_iso($year, $week, $day);

Given an ISO year, week, and day, returns year, month, and day, as
localtime would give them to you. This should be considered an
internal method, and is subject to change in future versions.

=cut

sub from_iso {    #{{{
    my ( $yearnumber, $weeknumber, $weekday ) = @_;
    my ( $yy, $c, $g, $janone, $eoy, $year, $month, $day, $doy, );
    $yy     = ( $yearnumber - 1 ) % 100;
    $c      = ( $yearnumber - 1 ) - $yy;
    $g      = $yy + int( $yy / 4 );
    $janone = 1 + ( ( ( ( int( $c / 100 ) % 4 ) * 5 ) + $g ) % 7 );
    if ( ( $weeknumber == 1 ) && ( $janone < 5 ) && ( $weekday < $janone ) ) {
        $year  = $yearnumber - 1;
        $month = 12;
        $day   = 32 - ( $janone - $weekday );
    }
    else {
        $year = $yearnumber;
    }
    $doy = ( $weeknumber - 1 ) * 7;

    if ( $janone < 5 ) {
        $doy += $weekday - ( $janone - 1 );
    }
    else {
        $doy += $weekday + ( 8 - $janone );
    }

    if ( Date::Leapyear::isleap($yearnumber) ) {
        $eoy = 366;
    }
    else {
        $eoy = 365;
    }

    if ( $doy > $eoy ) {
        $year  = $yearnumber + 1;
        $month = 1;
        $day   = $doy - $eoy;
    }
    else {
        $year = $yearnumber;
    }

    if ( $year == $yearnumber ) {
        my @month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
        $month[1] = 29 if ( Date::Leapyear::isleap($year) );
        my $h = 0;
        $month = 0;
        for my $days(@month) {
            last if $h > $doy;
            $h += $days;
            $month++;
        }

        $day = $doy - ( $h - $month[$month] ) + 1;
    }

    return ( $year, $month, $day );
}    #}}}

# Attribute acessor methods#{{{

sub iso {
    my $self = shift;
    return sprintf( '%04d-W%02d-%01d',
        $self->iso_year, $self->iso_week, $self->iso_day );
}

sub iso_year     {
    my $self = shift;
    return (to_iso( $self->year, $self->month, $self->day ))[0];
}

sub iso_week     {
    my $self = shift;
    return (to_iso( $self->year, $self->month, $self->day ))[1];
}

sub iso_week_day     {
    my $self = shift;
    return (to_iso( $self->year, $self->month, $self->day ))[2];
}
sub iso_day{iso_week_day(@_)}

#}}}

# Testing other methods inherited from ICal #{{{

=begin testing

my $t3 = Date::ISO->new( iso => '1973-W12-4' );
ok ( $t3->iso eq '1973-W12-4', 'Return the ISO string we started with');
# XXX FIXME - Creating with an ISO string is not working correctly
ok ( $t3->ical eq '19730322Z', 'ical()');
$t3->add( week => 2 );
ok ( $t3->ical eq '19730405Z', 'ical()');
ok ( $t3->iso_week == 14, 'Two weeks later' );
ok ( $t3->iso_week_day == 4, 'Should be the same dow' );
ok ($t3->iso eq '1973-W14-4', 'Adding 2 weeks');

=end testing

#}}}

1;

=head1 AUTHOR

Rich Bowen (rbowen@rcbowen.com)

=head1 DATE

$Date: 2001/07/30 00:50:07 $

=head1 Additional comments

For more information about this calendar, please see:

http://personal.ecu.edu/mccartyr/ISOwdALG.txt

http://personal.ecu.edu/mccartyr/isowdcal.html

http://www.cl.cam.ac.uk/~mgk25/iso-time.html

=head1 To Do, Bugs

Need to flesh out test suite some more. Particularly need to test some dates
immediately before and after the first day of the year - days in which you
might be in a different Gregorian and ISO years.

ISO date format also supports a variety of time formats. I suppose I should
accept those as valid arguments.

Creating a Date::ISO object with an ISO string, and then immediately
getting the ISO string representation of that object, is not giving
back what we started with. I'm not at all sure what is going on.

# CVS History #{{{

=head1 Version History

    $Log: ISO.pm,v $
    Revision 1.19  2001/07/30 00:50:07  rbowen
    Update for the new Date::ICal

    Revision 1.18  2001/07/24 16:08:11  rbowen
    perltidy

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

#}}}


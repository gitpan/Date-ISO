#$Header: /home/cvs/date-iso/lib/Date/ISO.pm,v 1.20 2001/08/23 02:04:00 rbowen Exp $
package Date::ISO;

use strict;
use warnings;
use Exporter;
use Date::ICal;

use vars qw( $VERSION @ISA @EXPORT );

@ISA = qw( Exporter Date::ICal );
$VERSION = (qw'$Revision: 1.20 $')[1];

@EXPORT = qw(iso inverseiso localiso);

use Date::Leapyear qw();
use Memoize;

# Docs {{{

=head1 NAME

Date::ISO - Perl extension for converting dates between ISO and
Gregorian formats.

=head1 SYNOPSIS

  use Date::ISO;
  $iso = Date::ISO->new( iso => $iso_date_string );
  $iso = Date::ISO->new( epoch => $epoch_time );
  $iso = Date::ISO->new( ical => $ical_string );
  $iso = Date::ISO->new( year => $year, month => $month,
                         day => $day );

  $iso_year = $iso->iso_year;
  $year = $iso->year;

  $iso_week = $iso->iso_week;
  $week_day = $iso->iso_week_day;

  $month = $iso->month;
  $day = $iso->day;

And, for backward compatibility:

  ($yearnumber, $weeknumber, $weekday) = iso($year, $month, $day);
  ($yearnumber, $weeknumber, $weekday) = localiso(time);
  ($year, $month, $day) = inverseiso($iso_year, $iso_week,
                                     $iso_week_day);

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

# }}}

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
is($t1->day, 25, 'day()');
is($t1->month, 10, 'month()');
is($t1->year, 1971, 'year()');
is($t1->ical, '19711025Z', 'ical()');
is($t1->epoch, 57196800, 'epoch()');

my $t2 = Date::ISO->new( iso => '1971-W43-1' );
is($t2->day, 25, 'day()' );
is($t2->month, 10, 'month()');
is($t2->year, 1971, 'year()');
=end testing

#}}}

# sub to_iso {{{

=head2 to_iso

  ( $isoyear, $isoweek, $isoday ) = to_iso( $year, $month, $day );

Returns the iso year, week, and day, given the gregorian year, month,
and day. This should be considered an internal method, and is subject
to change at any time.

This algorithm is at http://personal.ecu.edu/mccartyr/ISOwdALG.txt

=cut

memoize( 'to_iso' );
sub to_iso {  
    my ($y, $m, $d) = @_;
    my @mnth=( 0,    31,  59,  90, 120, 151, 
               181, 212, 243, 273, 304, 334 );
    my $doy = $d + $mnth[ $m - 1 ];

    if ( Date::Leapyear::isleap( $y ) && $m > 2 ) {
        $doy ++;
    }

    my $yy = ( $y - 1) % 100;
    my $c = ( $y - 1 ) - $yy;
    my $g = $yy + int( $yy / 4 );
    my $jan_one = 1 + ((((( int($c/100) )%4) * 5 ) + $g ) % 7 );

    my $h = $doy + ( $jan_one - 1 );
    my $weekday = 1 + ( ( $h - 1 ) % 7 );

    my ( $year_no, $week_no );
    if ( ( $doy <= ( 8 - $jan_one ) ) && ( $jan_one > 4 ) ) {
        $year_no = $y - 1;
        if ( $jan_one == 5 || ( $jan_one == 6 &&
                    Date::Leapyear::isleap( $y -1 ) ) ) {
            $week_no = 53;
        } else {
            $week_no = 52;
        }
   } else {
       $year_no = $y;
       my $i;
       if ( Date::Leapyear::isleap( $y )) {
           $i = 366;
       } else {
           $i = 365;
       }
       if ( ($i = $doy) < (4 - $weekday) ) {
           $year_no = $y + 1;
           $week_no = 1;
       } else {
           my $j = $doy + ( 7 - $weekday ) + ( $jan_one - 1 );
           $week_no = int( $j/7 );
           if ( $jan_one > 4 ) {
               $week_no --;
            }
      }
   }

   return ( $year_no, $week_no, $weekday );
}    #}}}

# sub from_iso {{{

=head2 from_iso

	($year, $month, $day) = from_iso($year, $week, $day);

Given an ISO year, week, and day, returns year, month, and day, as
localtime would give them to you. This should be considered an
internal method, and is subject to change in future versions.

=cut

sub inverseiso { return from_iso( @_ ) }
memoize( 'from_iso' );
sub from_iso {
    my ( $yearnumber, $weeknumber, $weekday ) = @_;
    my ( $yy, $c, $g, $janone, $eoy, $year, $month, $day, $doy, );
    $yy     = ( $yearnumber - 1 ) % 100;
    $c      = ( $yearnumber - 1 ) - $yy;
    $g      = $yy + int( $yy / 4 );
    $janone = 1 + ( ( ( ( int( $c / 100 ) % 4 ) * 5 ) + $g ) % 7 );

    if ( ( $weeknumber == 1 ) && ( $janone < 5 ) && 
      ( $weekday < $janone ) ) {
        $year  = $yearnumber - 1;
        $month = 12;
        $day   = 32 - ( $janone - $weekday );
        return ($year, $month, $day);
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
        my @month = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
        $month[2] = 29 if ( Date::Leapyear::isleap($year) );
        my $h = 0;
        my $i = 1;

        while ($h < $doy) {
            $h += $month[$i];
            $i++
        }
        $month = $i-1;

        $day = $doy - ( $h - $month[$i-1] );
    }

    return ( $year, $month, $day );
}    #}}}

# Attribute acessor methods#{{{

sub iso {
    if ( ref $_[0] ) {
        my $self = shift;
        return sprintf( '%04d-W%02d-%01d',
            $self->iso_year, $self->iso_week, $self->iso_day );

    } else {
        my ($year, $month, $day) = @_;
        my $self = Date::ISO->new( year => $year, month => $month, 
                                day => $day );
        return ( $self->iso_year, $self->iso_week,
            $self->iso_week_day);
    }
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
is( $t3->iso, '1973-W12-4', 'Return the ISO string we started with');
is ( $t3->ical, '19730322Z', 'ical()');
$t3->add( week => 2 );
is( $t3->ical, '19730405Z', 'ical()');
is( $t3->iso_week, 14, 'Two weeks later' );
is( $t3->iso_week_day, 4, 'Should be the same dow' );
is($t3->iso, '1973-W14-4', 'Adding 2 weeks');

=end testing

=cut

#}}}

=head1 Backwards compatibiilty methods

The following functional interface is provided for backwards
compatibility with former versions.

=head2 iso

 $iso = iso($year, $month, $day);

=cut

1;

=head1 AUTHOR

Rich Bowen (rbowen@rcbowen.com)

=head1 DATE

$Date: 2001/08/23 02:04:00 $

=head1 Additional comments

For more information about this calendar, please see:

http://personal.ecu.edu/mccartyr/ISOwdALG.txt

http://personal.ecu.edu/mccartyr/isowdcal.html

http://personal.ecu.edu/mccartyr/aboutwdc.htm

http://www.cl.cam.ac.uk/~mgk25/iso-time.html

http://www.fourmilab.ch/documents/calendar/

Finally, many many many thanks to Rick McCarty who provided me with
the algorithms that I'm using for conversions to and from ISO dates.
All the errors in previous versions of this module were entirely my
fault for miscopying something from his algorithm.

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
    Revision 1.20  2001/08/23 02:04:00  rbowen
    Thanks to Rick McCarty, conversions from ISO to gregorian are now
    working correctly. They never worked correctly in earlier versions.
    All of the tests have been updated to use is() rather than ok() so
    that I could actually see what was failing. Schwern++

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


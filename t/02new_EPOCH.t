# Testing object creation passing in an epoch time

use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Date::ISO' );
    use_ok( 'Time::Local' );
}

my $iso;

my $date = timelocal(0,0,0,25,9,1971);
$iso = Date::ISO->new( EPOCH => $date );

ok( $iso->year == 1971, 'year()' );
ok( $iso->month == 10, 'month()' );
ok( $iso->day == 25, 'day()' );

ok( $iso->iso_year == 1971, 'iso_year()' );
ok( $iso->iso_week == 43, 'iso_week()' );
ok( $iso->iso_week_day == 1, 'iso_week_day()' );

$date = timelocal(0,0,0,28,3,2001);
$iso = Date::ISO->new( EPOCH => $date );

ok( $iso->year == 2001, 'year()');
ok( $iso->month == 4, 'month()' );
ok( $iso->day == 28, 'day()' );

ok( $iso->iso_year == 2001, 'iso_year()' );
ok( $iso->iso_week == 17, 'iso_week()' );
ok( $iso->iso_week_day == 6, 'iso_week_day()' );



# Testing object creation passing in an epoch time

use Test;

BEGIN { plan tests => 12 }

use Date::ISO;
use Time::Local;

my $iso;

my $date = timelocal(0,0,0,25,9,1971);
$iso = Date::ISO->new( EPOCH => $date );

ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

$date = timelocal(0,0,0,28,3,2001);
$iso = Date::ISO->new( EPOCH => $date );

ok( $iso->year, 2001);
ok( $iso->month, 4 );
ok( $iso->day, 28 );

ok( $iso->iso_year, 2001 );
ok( $iso->iso_week, 17 );
ok( $iso->iso_week_day, 6 );



# Test object creation, when ISO date is passed in

use Test;

BEGIN { plan tests => 54 }

use Date::ISO;

my $iso;

# Date formats:

# Creating with 1997-02-05 format

$iso = {};
$iso = Date::ISO->new( ISO => '1971-10-25' );
ok( $iso->year, 1971 );
ok( $iso->month, '10' );
ok( $iso->day, '25' );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with 19711025 format

$iso = {};
$iso = Date::ISO->new( ISO => '19711025' );
ok( $iso->year, 1971 );
ok( $iso->month, '10' );
ok( $iso->day, '25' );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with 197110 format

$iso = {};
$iso = Date::ISO->new( ISO => '197110' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 1 ); # Day defaults to first of the month

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 39 );
ok( $iso->iso_week_day, 5 );

# Creating with '1971-W43' format

$iso={};
$iso = Date::ISO->new( ISO => '1971-W43' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with '1971W43' format

$iso={};
$iso = Date::ISO->new( ISO => '1971W43' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with '1971-W43-1' format

$iso={};
$iso = Date::ISO->new( ISO => '1971-W43-1' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with '1971W431' format

$iso={};
$iso = Date::ISO->new( ISO => '1971W431' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with '1971-293' format

$iso={};
$iso = Date::ISO->new( ISO => '1971-294' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );

# Creating with '1971293' format

$iso={};
$iso = Date::ISO->new( ISO => '1971294' );
ok( $iso->year, 1971 );
ok( $iso->month, 10 );
ok( $iso->day, 25 );

ok( $iso->iso_year, 1971 );
ok( $iso->iso_week, 43 );
ok( $iso->iso_week_day, 1 );


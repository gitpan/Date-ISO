# Test object creation, when ISO date is passed in

use Test;

BEGIN { plan tests => 3 }

use Date::ISO;

my $iso;

# Date formats:

# Creating with 1997-02-05 format

$iso = Date::ISO->new( ISO => '1997-02-05' );
ok( $iso->year, 1997 );
ok( $iso->month, '02' );
ok( $iso->day, '05' );


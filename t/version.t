#!perl -Tw

use warnings;
use strict;
use Test::More;

BEGIN {
    plan tests => 3;
    use_ok( 'HTML::Tidy' );
}

my @months = qw( January February March April May June 
                 July August September October November December);
my $months = join '|', @months;

my $version_string = HTML::Tidy->libtidy_version();
like($version_string, qr/\d\d? ($months) \d\d\d\d/);

my $version_nr = HTML::Tidy->libtidy_version( {numeric =>1 } );
ok($version_nr >= 20050901);


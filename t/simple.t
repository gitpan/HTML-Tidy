use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok( 'HTML::Tidy' ); }

my $html = do { local $/ = undef; <DATA> };

my $tidy = HTML::Tidy->new;
isa_ok( $tidy, 'HTML::Tidy' );

$tidy->parse_file( "-", $html );

my @errors = $tidy->errors;
is( scalar @errors, 5 );

$tidy->clear_errors;
is( scalar $tidy->errors, 0, "Cleared the errors" );

__DATA__
<html>
    <body><head>blah blah</head>
        <title>Barf</title>
        <body>
            <p>more blah
            </P>
        </body>
    </html>


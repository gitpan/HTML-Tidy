#!perl -Tw

use warnings;
use strict;

use Test::More tests => 16;

BEGIN { use_ok( 'HTML::Tidy' ); }
BEGIN { use_ok( 'HTML::Tidy::Message' ); }

WITH_LINE_NUMBERS: {
    my $error = HTML::Tidy::Message->new( 'foo.pl', TIDY_ERROR, 2112, 5150, 'Blah blah' );
    isa_ok( $error, 'HTML::Tidy::Message' );

    is( $error->file, 'foo.pl' );
    is( $error->type, TIDY_ERROR );
    is( $error->line, 2112 );
    is( $error->column, 5150 );
    is( $error->text, 'Blah blah' );
    is( $error->as_string, 'foo.pl (2112:5150) Error: Blah blah' );
}

WITHOUT_LINE_NUMBERS: {
    my $error = HTML::Tidy::Message->new( 'bar.pl', TIDY_WARNING, undef, undef, 'Blah blah' );
    isa_ok( $error, 'HTML::Tidy::Message' );

    is( $error->file, 'bar.pl' );
    is( $error->type, TIDY_WARNING );
    is( $error->line, 0 );
    is( $error->column, 0 );
    is( $error->text, 'Blah blah' );
    is( $error->as_string, 'bar.pl - Warning: Blah blah' );
}

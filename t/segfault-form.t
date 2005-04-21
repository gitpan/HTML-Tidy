#!perl -Tw

use strict;
use warnings;
use Test::More tests => 3;

use HTML::Tidy;
my $data = do { local $/; <DATA>; };

my $tidy = HTML::Tidy->new;
isa_ok( $tidy, 'HTML::Tidy' );
$tidy->clean( $data );
isa_ok( $tidy, 'HTML::Tidy' );
pass( "Cleaned OK" );

__DATA__
<form action="http://www.alternation.net/cobra/index.pl">
<td><input name="random" type="image" value="random creature" src="http://www.creaturesinmyhead.com/images/random.gif"></td>
</form>

# $Id: 00.load.t,v 1.1 2004/02/18 04:33:40 andy Exp $

use Test::More tests => 3;

BEGIN { use_ok( 'HTML::Tidy' ); }
BEGIN { use_ok( 'HTML::Tidy::Error' ); }
BEGIN { use_ok( 'Test::HTML::Tidy' ); }

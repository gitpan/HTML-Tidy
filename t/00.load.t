# $Id: 00.load.t,v 1.2 2004/02/21 05:56:56 andy Exp $

use Test::More tests => 3;

BEGIN { use_ok( 'HTML::Tidy' ); }
BEGIN { use_ok( 'HTML::Tidy::Message' ); }
BEGIN { use_ok( 'Test::HTML::Tidy' ); }

#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Linux::FD' ) || print "Bail out!
";
    use_ok( 'Linux::FD::Event' ) || print "Bail out!
";
    use_ok( 'Linux::FD::Signal' ) || print "Bail out!
";
    use_ok( 'Linux::FD::Timer' ) || print "Bail out!
";
}

diag( "Testing Linux::FD $Linux::FD::VERSION, Perl $], $^X" );

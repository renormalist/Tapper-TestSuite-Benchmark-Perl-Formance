#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tapper::TestSuite::Benchmark::Perl::Formance' );
}

diag( "Testing Tapper::TestSuite::Benchmark::Perl::Formance $Tapper::TestSuite::Benchmark::Perl::Formance::VERSION, Perl $], $^X" );

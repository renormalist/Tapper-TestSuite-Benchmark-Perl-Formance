use inc::Module::Install;

name     'Tapper-TestSuite-Benchmark-Perl-Formance';
all_from 'lib/Tapper/TestSuite/Benchmark/Perl/Formance.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

build_requires 'Test::More';
requires 'Benchmark::Perl::Formance' => '0.22';

install_script 'tapper-testsuite-benchmark-perlformance';

auto_install;

WriteAll;


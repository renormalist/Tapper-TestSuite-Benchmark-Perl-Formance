package Tapper::TestSuite::Benchmark::Perl::Formance;

use strict;
use warnings;

our $VERSION = '3.000001';

use IO::Socket::INET;
use Benchmark::Perl::Formance;
use Getopt::Long ":config", "no_ignore_case", "bundling";
use Config;

sub _uname {
        my $uname = `uname -a`;
        chomp $uname;
        return $uname;
}

sub _hostname {
        my $hostname = `hostname`;
        chomp $hostname;
        return $hostname;
}

sub _osname {
        my $osname = `cat /etc/issue.net | head -1`;
        chomp $osname;
        return $osname;
}

sub _cpuinfo {
        my @cpus      = map { chomp; s/^\s*//; $_ } `grep 'model name' < /proc/cpuinfo | cut -d: -f2-`;
        my %cpu_count = ();
        $cpu_count{$_}++ foreach @cpus;

        my $cpuinfo = join(', ', map { $cpu_count{$_}." cores [$_]" } keys %cpu_count);
        return $cpuinfo;
}

sub _ram {
        my $ram = `free -m | grep -i mem: | awk '{print \$2}'`;
        chomp $ram;
        $ram .= 'MB';
        return $ram;
}

sub _starttime_test_program {
        my $starttime_test_program = `date --rfc-2822` ;
        chomp $starttime_test_program;
        return $starttime_test_program;
}

sub _perl_gitversion {
        my $perlpath         = "$^X";
        my $perl_gitversion  = "$perlpath-gitversion";

        if (-x $perl_gitversion) {
                my $gitversion = qx!$perl_gitversion! ;
                chomp $gitversion;
                return $gitversion;
        }
}

sub _suite_name            {
        sprintf("benchmark-perlformance-%d.%d%s",
                $Config{PERL_REVISION},
                $Config{PERL_VERSION},
                ($ENV{PERLFORMANCE_TESTMODE_FAST} ? "-fast" : ""),
               );
}
sub _suite_version         { $VERSION }
sub _suite_type            { 'benchmark' }
sub _reportgroup_arbitrary { $ENV{TAPPER_REPORT_GROUP} }
sub _reportgroup_testrun   { $ENV{TAPPER_TESTRUN}   }

sub tapper_section_meta
{
        my $uname                  = _uname();
        my $osname                 = _osname();
        my $cpuinfo                = _cpuinfo();
        my $ram                    = _ram();
        my $starttime_test_program = _starttime_test_program();
        my $gitversion             = _perl_gitversion();

        my $output = "";
        $output   .= "# Tapper-uname:                   $uname\n";
        $output   .= "# Tapper-osname:                  $osname\n";
        $output   .= "# Tapper-cpuinfo:                 $cpuinfo\n";
        $output   .= "# Tapper-ram:                     $ram\n";
        $output   .= "# Tapper-language-description:    Perl-$]\n";
        $output   .= "# Tapper-changeset:               $gitversion\n" if $gitversion;
        $output   .= "# Tapper-starttime-test-program:  $starttime_test_program\n";
        $output   .= "# Tapper-ticket-url:              http://speed.perlformance.net/changes/?rev=$gitversion\n" if $gitversion;
        #$output   .= "# Tapper-moreinfo-url:            http://speed.perlformance.net/changes/?rev=$gitversion\n" if $gitversion;
}

sub tapper_suite_meta
{
        my $suite_name             = _suite_name();
        my $suite_version          = _suite_version();
        my $suite_type             = _suite_type();
        my $hostname               = _hostname();
        my $reportgroup_arbitrary  = _reportgroup_arbitrary();
        my $reportgroup_testrun    = _reportgroup_testrun();

        # to be used by Tapper::* modules

        my $output = "ok tapper-suite-meta\n";
        $output   .= "# Tapper-reportgroup-arbitrary:   $reportgroup_arbitrary\n" if $reportgroup_arbitrary;
        $output   .= "# Tapper-reportgroup-testrun:     $reportgroup_testrun\n"   if $reportgroup_testrun;
        $output   .= "# Tapper-suite-name:              $suite_name\n";
        $output   .= "# Tapper-suite-version:           $suite_version\n";
        $output   .= "# Tapper-suite-type:              $suite_type\n";
        $output   .= "# Tapper-machine-name:            $hostname\n";

        return $output;
}

sub usage
{
        print 'tapper-testsuite-perlformance - Tapper - Wrapper for Benchmark:Perl::Formance

Usage:

   $ tapper-testsuite-perlformance -v
   $ tapper-testsuite-perlformance --perlpath="/opt/bin/perl5.8.9"

Options:

  -h | --help        ... print this help screen
  -v | --verbose     ... some verbose messages to stdout
  --perlpath         ... complete call path of "perl" executable
  --perlformancepath ... complete call path of "benchmark-perlformance" script
  --plugins=Foo,Bar  ... plugin list, passed through to benchmark-perlformance
';
}

sub get_options
{
        my $help             = 0;
        my $verbose          = 0;
        my $plugins          = "";
        my $perlpath         = "$^X";
        my $perlformancepath = "";

        my $ok = GetOptions (
                             "help|h"             => \$help,
                             "verbose|v+"         => \$verbose,
                             "plugins=s"          => \$plugins,
                             "perlpath=s"         => \$perlpath,
                             "perlformancepath=s" => \$perlformancepath,
                            );

        do { usage; exit  0 } if $help;
        do { usage; exit -1 } if not $ok;

        if (not $perlformancepath) {
                $perlformancepath = $perlpath;
                $perlformancepath =~ s!^(.*)/[^/]+$!$1/benchmark-perlformance!;
        }

        if ($plugins) {
                $plugins = "--plugins=$plugins";
        } elsif ($ENV{HARNESS_ACTIVE}) {
                $plugins = "--plugins=Shootout,MooseTS";
        }

        return {
                help             => $help,
                verbose          => $verbose,
                perlpath         => $perlpath,
                plugins          => $plugins,
                perlformancepath => $perlformancepath,
               };
}

sub send_report {
        my ($report) = @_;

        my %cfg;
        $cfg{report_server}   = $ENV{TAPPER_REPORT_SERVER}   || 'perlformance.net';
        $cfg{report_api_port} = $ENV{TAPPER_REPORT_API_PORT} || 7358;
        $cfg{report_port}     = $ENV{TAPPER_REPORT_PORT}     || 7357;

        # following options are not yet used in this class
        $cfg{mcp_server}      = $ENV{TAPPER_SERVER};
        $cfg{runtime}         = $ENV{TAPPER_TS_RUNTIME};

        my $sock = IO::Socket::INET->new(PeerAddr => $cfg{report_server},
                                         PeerPort => $cfg{report_port},
                                         Proto    => 'tcp');
        if ($sock) {
                $sock->print($report);
                $sock->close;
        } else {
                warn "# Can't open connection to ", $cfg{report_server}, " ($!)";
        }
        return 0;
}

sub PerlFormanceResults
{
        my ($options) = @_;

        my $perlformancepath = $options->{perlformancepath};
        my ($plugins, $verbose) = @$options{qw(plugins verbose)};
        my $fastmode = ($ENV{PERLFORMANCE_TESTMODE_FAST} ? "--fastmode" : "");
        my $cmd = "$^X $perlformancepath --tapdescription='benchmarks' $fastmode -ccccc -vvvv -p --outstyle=yaml --indent=2 $plugins --codespeed 2>&1";
        print STDERR "# $cmd\n" if $verbose >= 2;
        my $yaml = qx!$cmd!;
        return $yaml;
}

sub main {
        my $options = get_options;

        my $output = "TAP Version 13\n";

        $output   .= "1..1\n";
        $output   .= "# Tapper-Section: metainfo\n";
        $output   .= tapper_suite_meta;
        $output   .= tapper_section_meta;

        $output   .= "1..1\n";
        $output   .= "# Tapper-Section: results\n";
        $output   .= PerlFormanceResults($options);

        return $output;
}

sub run
{
        my $output = main;
        print $output;
        send_report($output) unless $ENV{HARNESS_ACTIVE};
}

1; # End of Tapper::TestSuite::Benchmark::Perl::Formance

__END__


=head1 NAME

Tapper::TestSuite::Benchmark::Perl::Formance - Tapper - Wrapper for Benchmark::Perl::Formance

=head1 SYNOPSIS

You most likely want to run the frontend cmdline tool like this

  $ tapper-testsuite-benchmark-perl-formance -vvv

=head1 FUNCTIONS

=head2 PerlFormanceResults

=head2 tapper_section_meta

=head2 tapper_suite_meta

=head2 send_report

=head2 get_options

=head2 main

=head2 run

=head2 usage

=head1 BUGS

Please report any bugs or feature requests to C<bug-tapper-testsuite-autotest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-TestSuite-Benchmark-Perl-Formance>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tapper::TestSuite::Benchmark::Perl::Formance


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tapper-TestSuite-Benchmark-Perl-Formance>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tapper-TestSuite-Benchmark-Perl-Formance>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tapper-TestSuite-Benchmark-Perl-Formance>

=item * Search CPAN

L<http://search.cpan.org/dist/Tapper-TestSuite-Benchmark-Perl-Formance/>

=back


=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd


=cut

1; # End of Tapper::TestSuite::Benchmark::Perl::Formance

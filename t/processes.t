use strict;
use warnings;
use Test::More;
use Linux::Info;

my @required_files = (
    "/proc/$$/stat",   "/proc/$$/statm",
    "/proc/$$/status", "/proc/$$/cmdline",
    "/proc/$$/wchan"
);

foreach my $file (@required_files) {
    unless ( -r $file ) {
        plan skip_all => "$file is not readable";
        exit(0);
    }
}

my @processes = (
    'ppid',   'nlwp',     'owner',   'pgrp',   'state',   'session',
    'ttynr',  'minflt',   'cminflt', 'mayflt', 'cmayflt', 'stime',
    'utime',  'ttime',    'cstime',  'cutime', 'prior',   'nice',
    'sttime', 'actime',   'vsize',   'nswap',  'cnswap',  'cpu',
    'size',   'resident', 'share',   'trs',    'drs',     'lrs',
    'dtp',    'cmd',      'cmdline', 'wchan',  'fd',
);

plan tests => scalar(@processes);

my $sys = Linux::Info->new();
$sys->set( processes => 1 );
note('Waiting for data');
sleep(1);
my $stats = $sys->get;

unless ( scalar( keys %{ $stats->processes } > 0 ) ) {
    plan skip_all => "processlist is empty";
    exit(0);
}

foreach my $pid ( keys %{ $stats->processes } ) {
    foreach my $process_info (@processes) {
        ok( defined $stats->processes->{$pid}->{$process_info},
            "checking processes $process_info" );
    }
    last;    # we check only one process, that should be enough
}

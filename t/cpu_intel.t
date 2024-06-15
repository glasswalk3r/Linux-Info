use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::Intel';

require_ok($class);
can_ok( $class, qw(get_cores get_threads get_bugs get_frequency) );

my $source_file = 't/samples/cpu/info0';

my $instance = $class->new($source_file);
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_model',       'Intel(R) Pentium(R) 4 CPU 1.80GHz' ],
    [ 'get_arch',        32 ],
    [ 'get_bogomips',    3597.32 ],
    [ 'get_source_file', $source_file ],
    [ 'get_vendor',      'GenuineIntel' ],
    [ 'get_frequency',   '1796.992 MHz' ],
    [ 'get_cache',       '512 KB' ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

ok( $instance->has_multithread, 'processor is multithreaded' );

done_testing;

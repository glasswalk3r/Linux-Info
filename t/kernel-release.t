use strict;
use warnings;
use Test::Most 0.38;

use constant CLASS     => 'Linux::Info::KernelRelease';
use constant TEST_DESC => 'works for instance without mainline version';

require_ok(CLASS);
can_ok(
    CLASS,
    (
        'new',             'get_raw',
        'get_major',       'get_minor',
        'get_patch',       'get_compiled_by',
        'get_gcc_version', 'get_type',
        'get_build_datetime',
    )
);

dies_ok { CLASS->new('xyz') } 'must die with a invalid parameter';
like $@, qr/string\sfor\srelease/, 'got the expected error message';

my $proc_version = join(
    ' ',
    (
'Linux version 2.6.18-92.el5 (brewbuilder@ls20-bc2-13.build.redhat.com)',
        '(gcc version 4.1.2 20071124 (Red Hat 4.1.2-41))',
        '#1 SMP Tue Apr 29 13:16:15 EDT 2008'
    )
);

my $instance = CLASS->new('6.5.0-28-generic');
isa_ok( $instance, CLASS );
cmp_ok( $instance->get_patch, '>=', 0,
    'get_patch returns the expected value with mainline information' )
  or diag( explain($instance) );
is( $instance->get_compiled_by,    undef );
is( $instance->get_gcc_version,    undef );
is( $instance->get_type,           undef );
is( $instance->get_build_datetime, undef );

my $other = CLASS->new('6.5.0-28-generic');
cmp_ok( $instance, '>=', $other,
    $instance->get_raw . ' is higher or equal ' . $other->get_raw );

$other = CLASS->new('6.6.0-28-generic');
cmp_ok( $instance, '<', $other,
    $instance->get_raw . ' is less than ' . $other->get_raw );
is( $other->get_major, 6, 'get_major ' . TEST_DESC );
is( $other->get_minor, 6, 'get_minor ' . TEST_DESC );
is( $other->get_patch, 0, 'get_patch ' . TEST_DESC );

done_testing;

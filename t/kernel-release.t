use strict;
use warnings;
use Test::Most;
use Devel::CheckOS 2.01 qw(os_is);
use constant CLASS     => 'Linux::Info::KernelRelease';
use constant TEST_DESC => 'works for instance without mainline version';

require_ok(CLASS);
can_ok(
    CLASS,
    (
        'new',                  'get_raw',
        'get_mainline_version', 'get_abi_bump',
        'get_flavour',          'get_major',
        'get_minor',            'get_patch',
        'get_compiled_by',      'get_gcc_version',
        'get_type',             'get_build_datetime',
    )
);

dies_ok { CLASS->new } 'must die without any parameter';
like $@, qr/hash\sreference/, 'got the expected error message';

dies_ok { CLASS->new('xyz') } 'must die with a invalid parameter';
like $@, qr/hash\sreference/, 'got the expected error message';

dies_ok { CLASS->new( {} ) } 'must die with a missing "release" key';
like $@, qr/release\skey\sis\srequired/, 'got the expected error message';

dies_ok { CLASS->new( { release => 'xyz' } ) }
'must die with a invalid release string';
like $@, qr/string\sfor\srelease/, 'got the expected error message';

dies_ok { CLASS->new( { release => '6.5.0-28-generic', foo => 'bar' } ) }
'must die with a invalid key in the hash reference';
like $@, qr/key\sis\sinvalid/, 'got the expected error message';

my $proc_version = join(
    ' ',
    (
'Linux version 2.6.18-92.el5 (brewbuilder@ls20-bc2-13.build.redhat.com)',
        '(gcc version 4.1.2 20071124 (Red Hat 4.1.2-41))',
        '#1 SMP Tue Apr 29 13:16:15 EDT 2008'
    )
);

my $instance = CLASS->new(
    {
        release  => '6.5.0-28-generic',
        mainline => 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.13',
        version  => $proc_version,
    }
);
isa_ok( $instance, CLASS );

if ( os_is('Linux::Ubuntu') ) {
    cmp_ok( $instance->get_patch, '>=', 0,
        'get_patch returns the expected value' );
}
else {
    is( $instance->get_patch, 0, 'get_major returns the expected value' );
}

is( $instance->get_compiled_by,    'brewbuilder@ls20-bc2-13.build.redhat.com' );
is( $instance->get_gcc_version,    '4.1.2' );
is( $instance->get_type,           'SMP' );
is( $instance->get_build_datetime, 'Tue Apr 29 13:16:15 EDT 2008' );

my $other = CLASS->new(
    {
        release  => '6.5.0-28-generic',
        mainline => 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.12'
    }
);

cmp_ok( $instance, '>=', $other,
        $instance->get_mainline_version
      . ' is higher or equal '
      . $other->get_mainline_version );

cmp_ok( $instance, '>', $other,
        $instance->get_mainline_version
      . ' is higher than '
      . $other->get_mainline_version );

$other = CLASS->new(
    {
        release  => '6.5.0-28-generic',
        mainline => 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.13'
    }
);
cmp_ok( $instance, '>=', $other,
        $instance->get_mainline_version
      . ' is higher or equal '
      . $other->get_mainline_version );

$other = CLASS->new(
    {
        release  => '6.5.0-28-generic',
        mainline => 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.16'
    }
);
cmp_ok( $instance, '<', $other,
        $instance->get_mainline_version
      . ' is less than '
      . $other->get_mainline_version );

$other = CLASS->new( { release => '6.6.0-28-generic', mainline => undef } );
cmp_ok( $instance, '<', $other,
        $instance->get_mainline_version
      . ' is less than '
      . $other->get_mainline_version );

is( $other->get_major, 6, 'get_major ' . TEST_DESC );
is( $other->get_minor, 6, 'get_minor ' . TEST_DESC );
is( $other->get_patch, 0, 'get_patch ' . TEST_DESC );
is( $other->get_mainline_version, '6.6.0',
    'get_mainline_version ' . TEST_DESC );

done_testing;

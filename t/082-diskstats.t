use strict;
use warnings;
use Test::Most;
use Regexp::Common;
use Hash::Util qw(lock_hash);
use constant KERNEL_INFO => 'kernel major version >= 6';

use lib './t/lib';
use Helpers qw(total_lines);

require_ok('Linux::Info::DiskStats');

my %opts = (
    source_file          => 't/samples/diskstatus-6.1.0-20.txt',
    backwards_compatible => 0
);
lock_hash(%opts);

note(   'Validating '
      . $opts{source_file}
      . ' information for '
      . KERNEL_INFO
      . ' with backwards compatible turned '
      . ( $opts{backwards_compatible} ? 'on' : 'off' ) );

my $instance = Linux::Info::DiskStats->new(%opts);

ok( $instance->init, 'calls init successfully' );
is( $instance->fields_read, 21,
    'got the expected number of fields read for ' . KERNEL_INFO );
is( ref $instance->raw, 'HASH', 'raw returns an array reference' );

my $result = $instance->get;
is( ref $result, 'HASH', 'get returns an array reference' );
is(
    scalar( keys( %{$result} ) ),
    total_lines( \%opts ),
    'Found all devices in the file'
);

my $int_regex         = qr/$RE{num}->{int}/;
my $real_regex        = qr/$RE{num}->{real}/;
my $device_name_regex = qr/^\w+$/;
my %table             = (
    major  => $int_regex,
    minor  => $int_regex,
    rdreq  => $real_regex,
    rdbyt  => $real_regex,
    wrtreq => $real_regex,
    wrtbyt => $real_regex,
    ttreq  => $real_regex,
    ttbyt  => $real_regex,
);

TODO: {
    local $TODO = 'Must properly map the new fields format';

    bail_on_fail;

    for my $device_name ( keys( %{$result} ) ) {
        note("Testing the device $device_name");
        like( $device_name, $device_name_regex,
            'the device has an appropriated name' );
        is( ref $result->{$device_name},
            'HASH', "information from $device_name is a hash reference" );
        for my $stat ( keys(%table) ) {
            ok( exists $result->{$device_name}->{$stat}, "$stat is available" )
              or diag( explain( $result->{$device_name} ) );
            like( $result->{$device_name}->{$stat},
                $table{$stat}, "$stat has the expected value type" );
        }
    }
}

done_testing;

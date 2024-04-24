use strict;
use warnings;
use Test::Most;
use Regexp::Common;
use Hash::Util qw(lock_hash);
use constant KERNEL_INFO => 'kernel version >= 6';

if ( !-r '/proc/diskstats' || !-r '/proc/partitions' ) {
    plan skip_all =>
"your system doesn't provide disk statistics - /proc/diskstats and /proc/partitions is not readable";
    exit(0);
}

note( 'Validating /proc/diskstats information for ' . KERNEL_INFO );

require_ok('Linux::Info::DiskStats');

my %files = (
    files => {
        path      => 't/samples',
        diskstats => 'diskstatus-6.1.0-20.txt'
    }
);
lock_hash(%files);

my $instance = Linux::Info::DiskStats->new(%files);

isa_ok( $instance, 'Linux::Info::DiskStats' );
can_ok( $instance, qw(new init get raw _load _deltas fields_read) );
dies_ok { $instance->get } 'dies if calling get() before init()';
like(
    $@,
    qr/there are no initial statistics defined/,
    'got the expected error message'
);

ok( $instance->init, 'calls init successfully' );
is( $instance->fields_read, 21,
    'got the expected number of fields read for ' . KERNEL_INFO );
my $result = $instance->get;
is( ref $result, 'HASH', 'get returns an array reference' );
is(
    scalar( keys( %{$result} ) ),
    total_lines( \%files ),
    'Found all devices in the file'
);

for my $device_info ( keys( %{$result} ) ) {
    is( ref $result->{$device_info},
        'HASH', 'device information is a hash reference' );
}

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

bail_on_fail;

for my $device_info ( keys %{$result} ) {
    note("Testing the device $device_info");
    like( $device_info, $device_name_regex,
        'the device has an appropriated name' );

    for my $stat ( keys(%table) ) {
        ok( exists $result->{$device_info}->{$stat}, "$stat is available" )
          or diag( explain( $result->{$device_info} ) );
        like( $result->{$device_info}->{$stat},
            $table{$stat}, "$stat has the expected value type" );
    }
}

done_testing;

sub total_lines {
    my $files_ref = shift;
    my $file =
      $files_ref->{files}->{path} . '/' . $files_ref->{files}->{diskstats};
    my $line_counter = 0;

    open( my $in, '<', $file ) or die "Cannot read $file: $!";
    while (<$in>) {
        $line_counter++;
    }
    close($in) or die "Cannot close $file: $!";
    return $line_counter;
}

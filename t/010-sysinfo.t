use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

BEGIN { use_ok('Linux::Info::SysInfo') }

my $obj = new_ok('Linux::Info::SysInfo');
my @sysinfo =
  qw(get_raw_time get_hostname get_domain get_kernel get_release get_version get_mem get_swap get_pcpucount get_tcpucount get_interfaces get_arch get_proc_arch get_cpu_flags get_uptime get_idletime);
can_ok( $obj, @sysinfo );

my @pf = qw(
  /proc/sys/kernel/hostname
  /proc/sys/kernel/domainname
  /proc/sys/kernel/ostype
  /proc/sys/kernel/osrelease
  /proc/sys/kernel/version
  /proc/cpuinfo
  /proc/meminfo
  /proc/uptime
);

foreach my $f (@pf) {
    if ( !-r $f ) {
        plan skip_all => "$f is not readable";
        exit(0);
    }
}

like( $obj->get_raw_time, qr/^[01]$/, 'raw_time is boolean' );

foreach my $method (
    qw(get_hostname get_domain get_kernel get_release get_version get_mem get_swap get_arch get_uptime get_idletime)
  )
{

    like( $obj->$method, qr/\w+/, "$method returns a string" );

}

foreach my $method (qw(get_pcpucount get_tcpucount get_proc_arch)) {

    ok( looks_like_number( $obj->$method ), "$method returns a number" );

}

foreach my $method (qw(get_cpu_flags get_interfaces)) {

    is( ref( $obj->$method ), 'ARRAY', "$method returns an array reference" );

}

my $obj2 = Linux::Info::SysInfo->new( { raw_time => 1 } );

note('Testing times returned by instance with raw_time attribute set to true');

foreach my $method (qw(get_uptime get_idletime)) {

    ok( looks_like_number( $obj2->$method ), "$method returns a number" );

}

done_testing();

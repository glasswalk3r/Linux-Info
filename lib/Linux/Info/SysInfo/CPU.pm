package Linux::Info::SysInfo::CPU;
use strict;
use warnings;
use Carp       qw(croak);
use Hash::Util qw(lock_keys);
use Class::XSAccessor getters => {};

# VERSION

# ABSTRACT: Collects CPU information from /proc/cpuinfo

sub _parse {

}

sub new {
    my ( $class, $source_file ) = @_;
    my $self = {
        multithread  => 0,
        model        => undef,
        pcpucount    => 0,
        tcpucount    => 0,
        cpu_flags    => [],
        architecture => undef,
    };
    $source_file = '/proc/cpuinfo'
      unless ( ( defined($source_file) ) and ( $source_file ne '' ) );

    croak "The file $source_file is not available for reading"
      unless ( -r $source_file );
}

1;

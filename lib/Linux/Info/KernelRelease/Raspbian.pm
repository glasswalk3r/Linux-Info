package Linux::Info::KernelRelease::Raspbian;

use warnings;
use strict;
use parent 'Linux::Info::KernelRelease';
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_binutils_version => 'binutils_version',
    get_build_number     => 'build_number',
};

# VERSION

# ABSTRACT: a subclass of Linux::Info::KernelRelease specific to parse Alpine kernel information

sub _set_proc_ver_regex {
    my $self = shift;
    $self->{proc_regex} =
qr/^Linux\sversion\s(?<version>\d+\.\d+\.\d+\+?)\s\((?<compiled_by>[\w\.\-\@]+)\)\s\(arm-linux-\w+-gcc-\d+\s\(.*\)\s(?<gcc_version>\d+\.\d+\.\d+),\sGNU\sld\s\(.*\)\s(?<binutils_version>\d+\.\d+)\)\s\#(?<build_number>\d+)\s(?<build_datetime>.*)/;
}

=head1 METHODS

=head2 new

Extends parent method to further parse the kernel version string to fetch
additional information.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{type} = undef;
}

=head2 get_binutils_version

Returns the binutils package version used to compile the kernel.

=head2 get_build_number

Returns the number of the building this kernel was created.

=cut

1;

package Linux::Info::KernelRelease::Ubuntu;

use warnings;
use strict;
use parent 'Linux::Info::KernelRelease';
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_abi_bump => 'abi_bump',
    get_flavour  => 'flavour',
    get_upload   => 'upload',
    get_sig_raw  => 'sig_raw',
};

# VERSION

# ABSTRACT: a subclass of Linux::Info::KernelRelease specific to parse Ubuntu kernel information

sub _parse_ver_sig {
    my $self = shift;
    my $line = $self->{source}->get_version_signature;

    # <base kernel version>-<ABI number>.<upload number>-<flavour>
    # Ubuntu 6.5.0-35.35~22.04.1-generic 6.5.13
    my $regex =
qr/^Ubuntu\s\d\.\d\.\d\-(\d+)\.(\d+)\~\d+\.\d+\.\d+\-(\w+)\s(\d+\.\d+\.\d+)$/;
    confess "Failed to match '$line' with the regular expression $regex"
      unless ( $line =~ $regex );

    $self->{sig_raw}  = $line;
    $self->{abi_bump} = $1;
    $self->{upload}   = $2;
    $self->{flavour}  = $3;

    # this match provides the patch number
    $self->_parse_version($4);
}

=head1 METHODS

=head2 new

Overrides parent method, introducing the parsing of content from the
corresponding L<Linux::Info::KernelSource> C<get_version_signature> method
string returns.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_parse_ver_sig;
    return $self;
}

sub _set_proc_ver_regex {
    my $self = shift;
    my $regex =
qr/^Linux\sversion\s(?<version>\d+\.\d+\.\d+\-\d+\-generic)\s\((?<compiled_by>\w+\@[\w\-]+)\)\s\(.*\s\(.*\)\s(?<gcc_version>\d+\.\d+\.\d+)\,.*\(.*\)\s(?<binutils_version>\d+\.\d+)\)\s\#\d+\~\d+\.\d+\.\d+-Ubuntu\s(?<type>\w+\s[\w+_]+)\s(?<build_datetime>.*)/;
    $self->{proc_regex} = $regex;
}

=head2 get_abi_bump

Returns the application binary interface (ABI) bump from the kernel.

=head2 get_flavour

Returns the kernel flavour parameter.

=head2 get_upload

Returns the upload number.

=head2 get_sig_raw

Returns the raw information from F</proc/version_signature>.

=cut

1;

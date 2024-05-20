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

    my $source = '/proc/version_signature';
    my $line;

    if ( -r $source ) {
        open( my $in, '<', $source ) or confess("Cannot read $source: $!");
        $line = <$in>;
        chomp $line;
        close($in) or confess("Cannot close $source: $!");
    }
    else {
        confess "Missing $source, which is supposed to exists on Ubuntu!";
    }

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
    my $old_raw = $self->{raw};

    # this match provides the patch number
    $self->{raw} = $4;
    $self->_parse_version;
    $self->{raw} = $old_raw;
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;
    $self->_parse_ver_sig;
    return $self;
}

sub _set_proc_ver_regex {
    my $self = shift;

# Linux version 6.5.0-35-generic (buildd@lcy02-amd64-079) (x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #35~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Tue May  7 09:00:52 UTC 2
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

=head1 SEE ALSO

=over

=item *

https://ubuntu.com/kernel

=back

=cut

1;

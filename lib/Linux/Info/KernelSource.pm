package Linux::Info::KernelSource;

use warnings;
use strict;
use Carp qw(confess);

# VERSION

# ABSTRACT: defines the files that are source of kernel information

=head1 METHODS

=head2 new

Creates a instance.

Optionally, can receive a hash reference to configure customized paths
instead of the default ones.

The expected keys/values are:

=over

=item *

C<sys_version>: path to a corresponding F</proc/sys/kernel/version> file path.

=item *

C<version>: path to a corresponding F</proc/version> file path.

=item *

C<version_signature>: path to a corresponding F</proc/version_signature> file
path. This one is specific to Ubuntu Linux.

=back

=cut

sub new {
    my ( $class, $opts_ref ) = @_;
    my $self;

    if ( ( defined($opts_ref) ) and ( ref $opts_ref eq 'HASH' ) ) {
        $self = {
            sys_version => $opts_ref->{sys_version}
              || '/proc/sys/kernel/version',
            version           => $opts_ref->{version} || '/proc/version',
            version_signature => $opts_ref->{version_signature}
              || '/proc/version_signature',
        };
    }
    else {
        $self = {
            sys_version       => '/proc/sys/kernel/version',
            version           => '/proc/version',
            version_signature => '/proc/version_signature',
        };
    }

    bless $self, $class;
    return $self;
}

=head2 get_sys_version

Getter for the C<sys_version> file path content.

=cut

sub get_sys_version {
    my $self = shift;
    my $file = $self->{sys_version};
    open( my $in, '<', $file ) or confess "Cannot read $file: $!";
    my $release = <$in>;
    chomp $release;
    close($in) or confess "Cannot close $file: $!";
    return $release;
}

=head2 get_version

Getter for the C<version> file path content.

=cut

sub get_version {
    my $self = shift;
    my $file = $self->{version};
    open( my $in, '<', $file ) or confess "Cannot read $file: $!";
    my $line = <$in>;
    chomp $line;
    close($in) or confess "Cannot close $file: $!";
    return $line;
}

=head2 get_version_signature

Getter for the C<version_signature> file path content.

=cut

sub get_version_signature {
    my $self   = shift;
    my $source = $self->{version_signature};
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

    return $line;
}

=head1 SEE ALSO

=over

=item *

L<Linux::Info::KernelRelease> and subclasses.

=item *

https://ubuntu.com/kernel

=back

=cut

1;

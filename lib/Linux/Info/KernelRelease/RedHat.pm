package Linux::Info::KernelRelease::RedHat;

use warnings;
use strict;
use parent 'Linux::Info::KernelRelease';
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_revision    => 'revision',
    get_distro_info => 'distro_info',
};

# VERSION

# ABSTRACT: a subclass of Linux::Info::KernelRelease specific to parse RedHat kernel information

sub _set_proc_ver_regex {
    my $self = shift;

# Linux version 2.6.18-92.el5 (brewbuilder@ls20-bc2-13.build.redhat.com) (gcc version 4.1.2 20071124 (Red Hat 4.1.2-41)) #1 SMP Tue Apr 29 13:16:15 EDT 2008
    $self->{proc_regex} =
qr/^Linux\sversion\s(?<version>[\w\._-]+)\s\((?<compiled_by>[\w\.\-\@]+)\)\s\(gcc\sversion\s(?<gcc_version>[\d\.]+).*\)\s#1\s(?<type>\w+)\s(?<build_datetime>.*)/;
}

=head1 METHODS

=head2 new

Overrides parent method, introducing the parsing of content from the
corresponding L<Linux::Info::KernelSource> C<get_version_signature> method
string returns.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;

    # 2.6.18-92.el5
    my $regex = qr/^\d+\.\d+\.\d+\-(\d+)\.(\w+)$/;

    if ( $self->{version} =~ $regex ) {
        $self->{revision}    = $1;
        $self->{distro_info} = $2;
    }
    else {
        confess( 'Failed to match "' . $self->{version} . "\" against $regex" );
    }

    return $self;
}

=head2 get_revision

Return the kernel version.

=head2 get_distro_info

Returns the associated distribution information with the kernel.

=cut

1;

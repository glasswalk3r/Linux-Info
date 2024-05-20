package Linux::Info::KernelFactory;

use warnings;
use strict;
use Carp qw(confess);
use Linux::Info::DistributionFactory;
use Linux::Info::KernelRelease;
use Linux::Info::KernelRelease::RedHat;
use Linux::Info::KernelRelease::Rocky;
use Linux::Info::KernelRelease::Ubuntu;

# VERSION

# ABSTRACT: Factory class to create instances of Linux::Info::KernelRelease and subclasses

=head1 SYNOPSIS

    use Linux::Info::KernelFactory;
    my $release = Linux::Info::KernelFactory->create;

=head1 METHODS

=head2 create

Creates a instance of L<Linux::Info::KernelRelease> or any of it's subclasses.

The returned instance will be related to the Linux distribution where the
factory is executing.

=cut

sub create {
    my $class       = shift;
    my $distro_name = Linux::Info::DistributionFactory->new->distro_name;
    my %map         = (
        redhat => 'RedHat',
        rocky  => 'Rocky',
        ubuntu => 'Ubuntu',
    );

    if ( exists $map{$distro_name} ) {
        my $distro_class = 'Linux::Info::KernelRelease::' . $map{$distro_name};
        return $distro_class->new;
    }

    return Linux::Info::KernelRelease->new;
}

1;

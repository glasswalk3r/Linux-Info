package Linux::Info::KernelFactory;

use warnings;
use strict;
use Carp qw(confess);
use Linux::Info::DistributionFactory;
use Linux::Info::KernelRelease;
use Linux::Info::KernelRelease::RedHat;
use Linux::Info::KernelRelease::Rocky;
use Linux::Info::KernelRelease::Ubuntu;

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

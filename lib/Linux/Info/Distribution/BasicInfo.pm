package Linux::Info::Distribution::BasicInfo;

use warnings;
use strict;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_distro_id => 'distro_id',
    get_file_path => 'file_path',
};

# VERSION

# ABSTRACT - simple class to exchange data between DistributionFinder and DistributionFactory classes

=head1 METHODS

=head2 new

=cut

sub new {
    my ( $class, $distro_id, $file_path ) = @_;

    confess 'Must receive the Linux distribution ID as parameter'
      unless ( defined $distro_id );
    confess 'Must receive the file path as parameter'
      unless ( defined $file_path );

    my $self = {
        distro_id => $distro_id,
        file_path => $file_path,
    };
    bless $self, $class;
    return $self;
}

=head2 get_distro_id

Returns the respective Linux distribution ID (an string in lower case).

=head2 get_file_path

Returns the complete path to the file where the Linux distribution information
is stored.

=head1 EXPORTS

Nothing.

=cut

1;

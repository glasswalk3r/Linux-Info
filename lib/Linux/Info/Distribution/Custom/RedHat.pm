package Linux::Info::Distribution::Custom::RedHat;

use warnings;
use strict;
use base 'Linux::Info::Distribution::Custom';
use Class::XSAccessor getters => {
    is_enterprise => 'enterprise',
    get_type      => 'type',
    get_codename  => 'codename'
};

# VERSION

# ABSTRACT: a subclass of Linux::Info::Distribution::Custom

=head2 DESCRIPTION

This class inherits and overrides the required modules from
L<Linux::Info::Distribution::Custom::RedHat> parent class.

It should be created automatically by the L<Linux::Info::DistributionFactory>
depending on the files availabity of the distribution where is being executed.

Based on the file format, new fields will be available on this instance, added
to those provided by the parent class.

Check the methods to see what information is available.

=head1 METHODS

=head2 is_enterprise

Returns "true" (1) or "false" (0) depending if this distribution if a
"Enterprise" class of RedHat.

=head2 get_type

Returns a string meaning the type of the running distribution, which can be
"Server" or "Workstation".

=head2 get_codename

Returns a string of the distribution version "codename" or alias.

=head1 EXPORTS

Nothing.

=cut

sub _set_regex {
    my $self = shift;
    $self->{regex} =
qr/^Red\sHat\s(?<enterprise>Enterprise)?\sLinux\s(?<type>Server|Workstation)?\srelease\s(?<release>[\d\.]+) \((?<codename>\w+)\)/;
}

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{type} = $data_ref->{type};

    if ( defined( $data_ref->{enterprise} ) ) {
        $self->{enterprise} = 1;
        $self->{name}       = 'Red Hat Linux Enterprise ';
    }
    else {
        $self->{enterprise} = 0;
        $self->{name}       = 'Red Hat Linux ';
    }

    $self->{name} .= $self->{type};
    $self->{version_id} = $data_ref->{release};
    $self->{version} =
      'release ' . $data_ref->{release} . ', codename ' . $data_ref->{codename};
    $self->{codename} = $data_ref->{codename};
}

1;

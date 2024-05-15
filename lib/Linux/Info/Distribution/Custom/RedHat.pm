package Linux::Info::Distribution::Custom::RedHat;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::Custom';
use Class::XSAccessor getters => {
    is_enterprise => 'enterprise',
    get_type      => 'type',
    get_codename  => 'codename'
};

# VERSION

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

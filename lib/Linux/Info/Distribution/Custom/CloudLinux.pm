package Linux::Info::Distribution::Custom::CloudLinux;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::Custom';
use Class::XSAccessor getters => { get_codename => 'codename', };

# VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::Custom

=head1 METHODS

=head2 get_codename

Returns a string of the distribution codename.

=head1 EXPORTS

Nothing.

=cut

sub _set_regex {
    my $self = shift;
    $self->{regex} =
qr/(?<name>CloudLinux\sServer)\srelease\s(?<version>[\d\.]+)\s\((?<codename>[\w\s]+)\)/;
}

# CloudLinux Server release 5.11 (Vladislav Volkov)

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{name}     = $data_ref->{name};
    $self->{version}  = $data_ref->{version};
    $self->{codename} = $data_ref->{codename};
}

1;

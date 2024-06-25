package Linux::Info::Distribution::Custom::CentOS;

use warnings;
use strict;
use base 'Linux::Info::Distribution::Custom';
use Class::XSAccessor getters => { get_type => 'type', };

# VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::Custom

=head1 METHODS

=head2 get_type

Returns a string of the distribution type ("Linux" or "Stream").

=head1 EXPORTS

Nothing.

=cut

sub _set_regex {
    my $self = shift;
    $self->{regex} =
      qr/^(?<name>CentOS)\s(?<type>Linux|Stream)\srelease\s(?<version>\d)$/;
}

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{name}    = $data_ref->{name};
    $self->{version} = $data_ref->{version};
    $self->{type}    = $data_ref->{type};
}

1;

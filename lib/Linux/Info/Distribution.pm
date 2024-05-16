package Linux::Info::Distribution;

use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_hash);

use Class::XSAccessor getters => {
    get_name       => 'name',
    get_id         => 'id',
    get_version    => 'version',
    get_version_id => 'version_id',
};

# VERSION

=pod

=head1 NAME

NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.4 LTS (Jammy Jellyfish)"
ID=ubuntu

=cut

sub new {
    my ( $class, $params_ref ) = @_;

    confess 'Must receive a hash reference as parameter'
      unless ( ( defined($params_ref) ) and ( ref $params_ref eq 'HASH' ) );

    my @expected = qw(name id version version_id);

    foreach my $key (@expected) {
        confess "The hash reference is missing the key $key"
          unless ( exists $params_ref->{$key} );
    }

    my $self = {
        name       => $params_ref->{name},
        id         => $params_ref->{id},
        version    => $params_ref->{version},
        version_id => $params_ref->{version_id},
    };

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}

1;

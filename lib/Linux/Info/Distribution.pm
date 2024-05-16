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

Linux::Info::Distribution - base class to handle Linux distribution information

=head1 SYNOPSIS

    my $distro = Linux::Info::Distribution-new({
        name => 'Foobar',
        version_id => '1.0',
        version => '1.0 (Cool Name)',
        id => 'foobar'
    });

=head1 DESCRIPTION

This is a base class that defines the most basic information one could retrieve
from a Linux distribution.

You probably want to the take a look of subclasses of this classes, unless you
looking for creating a entirely new classes tree.

Also, you probably want to use a factory class to create new instances instead
doing it manually.

=head1 METHODS

=head2 new

Creates and returns new instance.

Expects a hash reference with the following keys:

=over

=item *

name: the distribution name

=item *

id: a more concise, short version of the distribution name, normally in all
lowercase.

=item *

version: the long version identification of the distribution.

=item *

version_id: a shorter version of C<version>, generally with only numbers and
dots, possible a semantic version number.

=back

=cut

sub new {
    my ( $class, $params_ref ) = @_;

    confess 'Must receive a hash reference as parameter'
      unless ( ( defined($params_ref) ) and ( ref $params_ref eq 'HASH' ) );

    my @expected = qw(name id version version_id);

    foreach my $key (@expected) {
        confess "The hash reference is missing the key '$key'"
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

=head2 get_name

A getter for the C<name> attribute.

=head2 get_id

A getter for the C<id> attribute.

=head2 get_version

A getter for the C<version> attribute.

=head2 get_version_id

A getter for the C<version_id> attribute.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::Distribution::Custom>

=item *

L<Linux::Info::Distribution::OSRelease>

=item *

L<Linux::Info::Distribution::Factory>

=back

=cut

1;

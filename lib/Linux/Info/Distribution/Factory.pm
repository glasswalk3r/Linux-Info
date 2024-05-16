package Linux::Info::Distribution::Factory;

use warnings;
use strict;
use Hash::Util qw(lock_hash lock_keys);
use Carp       qw(confess);
use Data::Dumper;

use Linux::Info::Distribution::Custom::RedHat;
use Linux::Info::Distribution::OSRelease::Ubuntu;

# VERSION

=pod

=head1 NAME

Linux::Info::Distribution::Factory - implements a factory for Distribution subclasses

=head1 SYNOPSIS

    use Linux::Info::Distribution::Factory;
    use Linux::Info::Distribution::Finder;

    my $instance = Linux::Info::Distribution::Factory->new(
        Linux::Info::Distribution::Finder->new
    );
    print $instance->distro_name, "\n";

=head1 DESCRIPTION

This class implements the design patter of Factory to handle how to create all
existing variations of subclass of L<Linux::Info::Distribution> subclasses.

=cut

my %distros = (
    rocky  => 'Rocky',
    ubuntu => 'Ubuntu',
    redhat => 'RedHat',
);
lock_hash(%distros);

=head1 METHODS

=head2 new

Creates and return a new instance.

Expects a instance of L<Linux::Info::Distribution::Finder> as a parameter.

=cut

sub new {
    my ( $class, $finder ) = @_;
    my $finder_class = 'Linux::Info::Distribution::Finder';

    confess "You must pass a instance of $finder_class"
      unless ( ( ref $finder ne '' ) and ( $finder->isa($finder_class) ) );

    my $self = { finder => $finder, };
    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}

=head2 distro_name

Returns the current Linux distribution name from where the Factory was created.

=cut

sub distro_name {
    return shift->create->get_name;
}

=head2 create

Creates and return a instance of L<Linux::Info::Distribution> subclasses, based
on the several criterias to define the source and format of the data.

Instances will be returned based on subclasses of
L<Linux::Info::Distribution::OSRelease> or
L<Linux::Info::Distribution::Custom>.

=cut

sub create {
    my $self     = shift;
    my $info_ref = $self->{finder}->search_distro;

    unless ( $self->{finder}->has_custom ) {
        my $base_class = 'Linux::Info::Distribution::OSRelease';

        if ( exists $distros{ $info_ref->{id} } ) {
            my $class = $base_class . '::' . $distros{ $self->{id} };
            return $class->new($info_ref);
        }
        else {
            return $base_class->new($info_ref);
        }
    }

    if ( exists $info_ref->{id} ) {
        my $distro_name;

        if ( exists $distros{ $info_ref->{id} } ) {
            $distro_name = $distros{ $info_ref->{id} };
        }
        else {
            confess( 'Do not know how to handle the id ' . $info_ref->{id} );
        }

        my $class = "Linux::Info::Distribution::Custom::$distro_name";
        return $class->new($info_ref);
    }

    confess( 'Missing id, do not know how to handle ' . Dumper($info_ref) );
}

=head1 EXPORTS

Nothing.

=cut

1;
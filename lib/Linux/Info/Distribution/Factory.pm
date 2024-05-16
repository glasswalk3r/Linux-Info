package Linux::Info::Distribution::Factory;

use warnings;
use strict;
use Hash::Util qw(lock_hash lock_keys);
use Carp       qw(confess);
use Data::Dumper;

use Linux::Info::Distribution::Custom::RedHat;
use Linux::Info::Distribution::OSRelease::Ubuntu;

# VERSION

my %distros = (
    rocky  => 'Rocky',
    ubuntu => 'Ubuntu',
    redhat => 'RedHat',
);
lock_hash(%distros);

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

sub distro_name {
    my $self = shift;
    return $self->create->get_name;
}

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

1;

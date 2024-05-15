package Linux::Info::Distribution::Factory;

use warnings;
use strict;
use Hash::Util qw(lock_hash lock_keys);
use Carp       qw(confess);

# VERSION

my %distros = (
    rocky  => 'Rocky',
    ubuntu => 'Ubuntu',
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

sub _init {
    my $self = shift;
    return $self->{finder}->search_distro;
}

sub distro_name {
    my $self = shift;
    my $name = $self->{finder}->distro_name;
    return $name if ( defined $name );
    $self->_init;
    return $self->{finder}->distro_name;
}

sub create {
    my $self = shift;
    $self->_init unless ( $self->{distro_name} );

    if ( $self->{release_info} ) {
        my $base_class = 'Linux::Info::Distribution::OSRelease';

        if ( exists $distros{ $self->{distro_id} } ) {
            my $class = $base_class . '::' . $distros{ $self->{distro_id} };
            return $class->new( $self->{release_info} );
        }
        else {
            return $base_class->new( $self->{release_info} );
        }
    }
    else {
        my $class =
          'Linux::Info::Distribution::Custom::' . $self->{distro_name};
        return $class->new(
            {
                source_file => $self->{file_to_parse},
                name        => $self->{distro_name},
                id          => $self->{distro_id}
            }
        );
    }

}

1;

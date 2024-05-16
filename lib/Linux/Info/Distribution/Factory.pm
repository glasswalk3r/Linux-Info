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

    # TODO: create a method on Finder to define if it is custom or not
    unless ( exists $info_ref->{file_to_parse} ) {
        my $base_class = 'Linux::Info::Distribution::OSRelease';

        if ( exists $distros{ $info_ref->{distro_id} } ) {
            my $class = $base_class . '::' . $distros{ $self->{distro_id} };
            return $class->new($info_ref);
        }
        else {
            return $base_class->new($info_ref);
        }
    }

    if ( exists $info_ref->{distro_id} ) {
        my $distro_name;

        if ( exists $distros{ $info_ref->{distro_id} } ) {
            $distro_name = $distros{ $info_ref->{distro_id} };
        }
        else {
            confess( 'Do not know how to handle the distro_id '
                  . $info_ref->{distro_id} );
        }

        my $class = "Linux::Info::Distribution::Custom::$distro_name";
        return $class->new($info_ref);
    }

    confess(
        'Missing distro_id, do not know how to handle ' . Dumper($info_ref) );
}

1;

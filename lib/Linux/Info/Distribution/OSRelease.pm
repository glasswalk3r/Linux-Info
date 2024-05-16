package Linux::Info::Distribution::OSRelease;

use warnings;
use strict;
use Carp qw(confess);
use parent 'Linux::Info::Distribution';
use Hash::Util qw(lock_hash unlock_hash);

use constant DEFAULT_FILE => '/etc/os-release';

# VERSION

sub parse {
    my $self = shift;
    my $file_path;

    # sub call
    if ( ref($self) eq '' ) {
        $file_path = shift || DEFAULT_FILE;
    }
    else {
        $file_path = $self->{source} || DEFAULT_FILE;
    }

    open my $in, '<', $file_path or confess "Cannot read $file_path: $!";
    my %data;
    while (<$in>) {
        chomp;
        my @pieces = split( '=', $_ );
        $pieces[1] =~ tr/"//d;
        $data{ ( lc $pieces[0] ) } = $pieces[1];
    }
    close $in or confess "Cannot close $file_path: $!";
    return \%data;
}

sub get_source {
    my $self = shift;
    return ( ref($self) ne '' ) ? $self->{source} : DEFAULT_FILE;
}

sub new {
    my ( $class, $file_path ) = @_;
    my $info_ref = parse($file_path);
    my $self     = $class->SUPER::new($info_ref);
    unlock_hash( %{$self} );
    $self->{source} = $file_path || DEFAULT_FILE;
    $self->{cache}  = $info_ref;
    lock_hash( %{$self} );
    return $self;
}

1;

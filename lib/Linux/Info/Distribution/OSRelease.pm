package Linux::Info::Distribution::OSRelease;

use warnings;
use strict;
use Carp qw(confess);
use parent 'Linux::Info::Distribution';
use Hash::Util qw(lock_hash unlock_hash);

use constant DEFAULT_FILE => '/etc/os-release';

# VERSION

=pod

=head1 NAME

Linux::Info::Distribution::OSRelease - a subclass with data from /etc/os-release file

=head1 SYNOPSIS

    use Linux::Info::Distribution::OSRelease;
    my $os = Linux::Info::Distribution::OSRelease->new;

    # fetch the default file location
    print Linux::Info::Distribution::OSRelease::DEFAULT_FILE, "\n";

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::Distribution>, which data is retrieved by
reading the standard F</etc/os-release> file, which usually provides more
fields than custom files.

Such file might contain only the minimal informatior required by the base
class, but most probably will provide more fields.

    NAME="Ubuntu"
    VERSION_ID="22.04"
    VERSION="22.04.4 LTS (Jammy Jellyfish)"
    ID=ubuntu

This classes provides a parser to retrieve those fields and more from the
default location or any other provided.

=head1 METHODS

=head2 parse

A class method, i.e., doesn't require a instance to be invoked.

Optionally, accepts a file path to the different file insteade using the
default one.

Returns a hash reference, with all fields/values retrieve from the file.

The fields, stored as keys, will be forced to be on lowercase.

=cut

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

=head2 new

Creates and returns a new instance.

Expects the same optional parameter of C<parse>, and uses this same method
to parse the file content.

=cut

sub new {
    my $class     = shift;
    my $file_path = shift || DEFAULT_FILE;
    my $info_ref  = parse($file_path);
    my $self      = $class->SUPER::new($info_ref);
    unlock_hash( %{$self} );
    $self->{source} = $file_path;
    $self->{cache}  = $info_ref;
    lock_hash( %{$self} );
    return $self;
}

=head2 get_source

Returns a string with the file path from where the information was retrieved.

=cut

sub get_source {
    return shift->{source};
}

=head1 EXPORTS

Nothing.

The default location of the source file can be retrieved with the
C<DEFAULT_FILE> constant.

=cut

1;

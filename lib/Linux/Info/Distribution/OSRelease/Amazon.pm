package Linux::Info::Distribution::OSRelease::Amazon;

use warnings;
use strict;
use base 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_ansi_color => 'ansi_color',
    get_cpe_name   => 'cpe_name',
};

# VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Amazon Linux makes available.

See the methods to check which additional information is available.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=cut

sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );

    my @attribs = ( 'ansi_color', 'cpe_name', );

    foreach my $attrib (@attribs) {
        $self->{$attrib} = $self->{cache}->{$attrib};
    }

    $self->clean_cache;
    lock_hash( %{$self} );
    return $self;
}

=head2 get_ansi_color

Returns the string of the respective ANSI color code.

=head2 get_cpe_name

Returns the CPE name.

=cut

1;
